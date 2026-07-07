import Foundation

@MainActor
final class ConcertDetailViewModel {

    struct State {
        var detail: ConcertDetail
        var selectedTab: Int = 0
        var heroImageAssetName: String?
        var isLoading: Bool = true
        var isInterested: Bool = false
        var isBooked: Bool = false
        /// 로그인 유저가 팔로우한 아티스트 id 집합 — 아티스트 정보 영역 하트 표시 판정용
        var followedArtistIds: Set<UUID> = []
    }

    private(set) var state: State
    var onStateChanged: (() -> Void)?
    var onError: ((String) -> Void)?
    var onLoginRequired: ((@escaping () -> Void) -> Void)?
    var onInterestToggled: ((Bool) -> Void)?
    /// 예매하기 → 유효한 예매 URL이 있을 때 외부 브라우저로 열기
    var onOpenBooking: ((URL) -> Void)?

    private let concertId: UUID
    private let repository: any ConcertDetailRepositoryProtocol
    private let bookingRepository: any BookingRepositoryProtocol
    private let artistRepository: any ArtistRepositoryProtocol
    private let bookingIssueReporter: any BookingIssueReporting

    init(concertId: UUID,
         imageAssetName: String? = nil,
         repository: some ConcertDetailRepositoryProtocol,
         bookingRepository: any BookingRepositoryProtocol = SupabaseBookingRepository(),
         artistRepository: any ArtistRepositoryProtocol = SupabaseArtistRepository(),
         bookingIssueReporter: any BookingIssueReporting = SupabaseBookingIssueReporter()) {
        self.concertId = concertId
        self.repository = repository
        self.bookingRepository = bookingRepository
        self.artistRepository = artistRepository
        self.bookingIssueReporter = bookingIssueReporter
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
            async let isBookedTask = try? bookingRepository.isBooked(eventId: concertId)
            async let followedIdsTask = artistRepository.fetchFollowedArtistIds()
            do {
                let detail = try await detailTask
                state = State(
                    detail: detail,
                    heroImageAssetName: state.heroImageAssetName ?? detail.imageAssetName,
                    isLoading: false,
                    isInterested: await isInterestedTask,
                    isBooked: (await isBookedTask) ?? false,
                    followedArtistIds: await followedIdsTask
                )
            } catch {
                state.isLoading = false
                onError?("공연 정보를 불러오지 못했습니다.")
            }
            onStateChanged?()
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

    func markBooked() {
        guard AuthService.shared.isLoggedIn else {
            onLoginRequired? { [weak self] in self?.markBooked() }
            return
        }
        guard !state.isBooked else { return }
        let previous = state.isBooked
        state.isBooked = true            // 낙관적 반영
        onStateChanged?()
        Task {
            do {
                try await bookingRepository.markBooked(eventId: concertId)
            } catch {
                state.isBooked = previous
                onStateChanged?()
                onError?("예매 완료 처리에 실패했습니다.")
            }
        }
    }

    /// 예매하기 탭 처리 — URL 있으면 열고, 없으면 에러 안내 + Admin 확인용 이슈 기록
    func requestBooking() {
        if let url = state.detail.bookingUrl {
            onOpenBooking?(url)
        } else {
            onError?("예매 링크가 아직 연결되지 않았어요. 확인 후 반영할게요.")
            let eventId = concertId
            let title = state.detail.title
            Task { await bookingIssueReporter.reportMissingBookingLink(eventId: eventId, eventTitle: title) }
        }
    }

    func selectTab(_ index: Int) {
        state.selectedTab = index
        onStateChanged?()
    }
}
