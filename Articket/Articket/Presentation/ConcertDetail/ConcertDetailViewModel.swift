import Foundation

@MainActor
final class ConcertDetailViewModel {

    struct State {
        var detail: ConcertDetail
        var selectedTab: Int = 0
        var heroImageAssetName: String?
        var isLoading: Bool = true
        var isInterested: Bool = false
        /// 로그인 유저가 팔로우한 아티스트 id 집합 — 아티스트 정보 영역 하트 표시 판정용
        var followedArtistIds: Set<UUID> = []
        /// 선택된 회차 인덱스 (detail.sessions 기준). 단일 공연이면 무시.
        var selectedSessionIndex: Int = 0
        /// 이 공연을 관람한(reviewableShows) 유저인지 — 후기 작성 버튼 노출 게이트
        var canWriteReview: Bool = false
    }

    /// 현재 선택된 회차(없으면 nil — 단일 공연)
    var selectedSession: ConcertSession? {
        let sessions = state.detail.sessions
        guard !sessions.isEmpty else { return nil }
        return sessions[min(state.selectedSessionIndex, sessions.count - 1)]
    }

    /// 회차 선택 변경
    func selectSession(_ index: Int) {
        guard index != state.selectedSessionIndex,
              index >= 0, index < state.detail.sessions.count else { return }
        state.selectedSessionIndex = index
        onStateChanged?()
    }

    private(set) var state: State
    var onStateChanged: (() -> Void)?
    var onError: ((String) -> Void)?
    var onLoginRequired: ((@escaping () -> Void) -> Void)?
    var onInterestToggled: ((Bool) -> Void)?
    /// 예매하기 → 유효한 예매 URL이 있을 때 외부 브라우저로 열기
    var onOpenBooking: ((URL) -> Void)?
    /// 예매처가 2곳 이상일 때 선택 시트를 띄우도록 요청
    var onSelectBookingProvider: (([BookingLink]) -> Void)?

    private let concertId: UUID
    private let repository: any ConcertDetailRepositoryProtocol
    private let artistRepository: any ArtistRepositoryProtocol
    private let bookingIssueReporter: any BookingIssueReporting
    private let bookingRepository: any BookingRepositoryProtocol
    private let myPageRepository: any MyPageRepositoryProtocol

    init(concertId: UUID,
         imageAssetName: String? = nil,
         repository: some ConcertDetailRepositoryProtocol,
         artistRepository: any ArtistRepositoryProtocol = SupabaseArtistRepository(),
         bookingIssueReporter: any BookingIssueReporting = SupabaseBookingIssueReporter(),
         bookingRepository: any BookingRepositoryProtocol = SupabaseBookingRepository(),
         myPageRepository: any MyPageRepositoryProtocol = SupabaseMyPageRepository()) {
        self.concertId = concertId
        self.repository = repository
        self.artistRepository = artistRepository
        self.bookingIssueReporter = bookingIssueReporter
        self.bookingRepository = bookingRepository
        self.myPageRepository = myPageRepository
        self.state = State(
            detail: .placeholder,
            heroImageAssetName: imageAssetName,
            isLoading: true
        )
    }

    func viewDidLoad() {
        onStateChanged?()
        Task {
            async let detailTask = repository.fetchConcertDetail(concertId: concertId)
            async let isInterestedTask = repository.fetchIsInterested(concertId: concertId)
            async let followedIdsTask = artistRepository.fetchFollowedArtistIds()
            do {
                let detail = try await detailTask
                state = State(
                    detail: detail,
                    heroImageAssetName: state.heroImageAssetName ?? detail.imageAssetName,
                    isLoading: false,
                    isInterested: await isInterestedTask,
                    followedArtistIds: await followedIdsTask
                )
            } catch {
                state.isLoading = false
                onError?("공연 정보를 불러오지 못했습니다.")
            }
            onStateChanged?()

            // 관람작 여부 → 후기 작성 버튼 게이팅. 로그인 유저만(비로그인은 노출 안 함).
            if AuthService.shared.isLoggedIn {
                let reviewable = (try? await myPageRepository.fetchReviewableShows()) ?? []
                state.canWriteReview = reviewable.contains { $0.id == concertId }
                onStateChanged?()
            }
        }
    }

    /// 하트 연타 시 요청/알림 중복 발행 → 중복 insert(unique 위반) 및 Home 스냅샷 동시 apply 크래시 방지용 가드
    private var isTogglingInterested = false

    func toggleInterested() {
        guard AuthService.shared.isLoggedIn else {
            onLoginRequired? { [weak self] in self?.toggleInterested() }
            return
        }
        // 이전 토글이 끝나기 전 재탭 무시 (연타 크래시 방지)
        guard !isTogglingInterested else { return }
        isTogglingInterested = true
        let wasInterested = state.isInterested
        state.isInterested = !wasInterested
        onStateChanged?()
        Task {
            defer { isTogglingInterested = false }
            do {
                try await repository.toggleInterested(concertId: concertId, currentlyInterested: wasInterested)
                NotificationCenter.default.post(name: .eventInterestedDidChange, object: concertId)
                onInterestToggled?(state.isInterested)
            } catch {
                state.isInterested = wasInterested
                onStateChanged?()
                onError?("관심 공연 처리에 실패했습니다.")
            }
        }
    }

    /// 예매하기 탭 처리
    /// - 예매처 2곳 이상: 선택 시트 요청 (실제 오픈은 사용자가 예매처를 고른 뒤)
    /// - 예매처 1곳: 바로 오픈 (단일 예매처에서 시트로 탭을 낭비하지 않음)
    /// - booking_links 비어 있고 bookingUrl만 있음: 대표 URL로 폴백 오픈
    /// - 아무 링크도 없음: 에러 안내 + Admin 확인용 이슈 기록
    func requestBooking() {
        // 회차 공연이면 선택된 회차의 예매 링크, 아니면 대표 예매 링크
        let session = selectedSession
        let links = session?.bookingLinks ?? state.detail.bookingLinks
        let fallbackUrl = session?.bookingUrl ?? state.detail.bookingUrl
        if links.count >= 2 {
            onSelectBookingProvider?(links)
        } else if let link = links.first {
            openBooking(url: link.url)
        } else if let url = fallbackUrl {
            openBooking(url: url)
        } else {
            onError?("예매 링크가 아직 연결되지 않았어요. 확인 후 반영할게요.")
            let eventId = concertId
            let title = state.detail.title
            Task { await bookingIssueReporter.reportMissingBookingLink(eventId: eventId, eventTitle: title) }
        }
    }

    /// 선택된 예매처(또는 단일 URL)로 외부 오픈 + intent 기록.
    /// 외부 예매처로 나가면 앱은 결과를 알 수 없다 → 나간 사실을 남겨두고
    /// 복귀 후 홈에서 "예매하셨나요?"로 되묻는다. 기록 실패해도 링크 오픈은 그대로 진행.
    func openBooking(url: URL) {
        let eventId = concertId
        let title = state.detail.title
        let poster = state.detail.imageAssetName
        Task {
            await bookingRepository.recordBookingIntent(
                eventId: eventId, eventTitle: title, posterUrl: poster
            )
        }
        onOpenBooking?(url)
    }

    func selectTab(_ index: Int) {
        state.selectedTab = index
        onStateChanged?()
    }
}
