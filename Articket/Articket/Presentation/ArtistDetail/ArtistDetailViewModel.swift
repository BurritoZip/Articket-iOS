import Foundation

@MainActor
final class ArtistDetailViewModel {

    struct State {
        var detail: ArtistDetail
        var selectedTab: Int = 0
        var isLoading: Bool = true
    }

    private(set) var state: State
    var onStateChanged: (() -> Void)?
    var onError: ((String) -> Void)?
    var onLoginRequired: ((@escaping () -> Void) -> Void)?
    var onFollowToggled: ((Bool) -> Void)?
    /// "다가오는 티켓팅 더보기" → 예정 공연 전체 로드 완료 (상위 VC가 리스트로 라우팅)
    var onUpcomingListLoaded: (([Event]) -> Void)?

    private let artistId: UUID
    private let repository: any ArtistDetailRepositoryProtocol

    init(artistId: UUID, repository: some ArtistDetailRepositoryProtocol) {
        self.artistId = artistId
        self.repository = repository
        self.state = State(detail: .placeholder, isLoading: true)
    }

    /// 다가오는 티켓팅 더보기 — 예정 공연 전체를 조회해 콜백으로 전달
    func requestUpcomingList() {
        let id = artistId
        Task {
            let events = (try? await repository.fetchUpcomingEvents(artistId: id)) ?? []
            onUpcomingListLoaded?(events)
        }
    }

    func viewDidLoad() {
        onStateChanged?()
        Task {
            async let detailTask = repository.fetchArtistDetail(artistId: artistId)
            async let isFollowingTask = repository.fetchIsFollowing(artistId: artistId)
            do {
                var loaded = try await detailTask
                loaded.artist.isFollowing = await isFollowingTask
                state = State(detail: loaded, isLoading: false)
            } catch {
                state.isLoading = false
                onError?("아티스트 정보를 불러오지 못했어요")
            }
            onStateChanged?()
        }
    }

    /// 팔로우 버튼 연타 시 중복 요청/알림 발행(unique 위반·팔로워수 오차) 방지 가드
    /// (ConcertDetailViewModel.isTogglingInterested 와 동일 패턴)
    private var isTogglingFollow = false

    func toggleFollow() {
        guard AuthService.shared.isLoggedIn else {
            onLoginRequired? { [weak self] in self?.toggleFollow() }
            return
        }
        // 이전 토글이 끝나기 전 재탭 무시
        guard !isTogglingFollow else { return }
        isTogglingFollow = true
        let wasFollowing = state.detail.artist.isFollowing
        let previousCount = state.detail.artist.followersCount
        state.detail.artist.isFollowing = !wasFollowing
        // 낙관적 팔로워 수 갱신 (DB 트리거가 실제 값을 맞추지만 UI 즉시 반영)
        state.detail.artist.followersCount = wasFollowing ? max(0, previousCount - 1) : previousCount + 1
        onStateChanged?()
        Task {
            defer { isTogglingFollow = false }
            do {
                try await repository.toggleFollow(artistId: artistId, currentlyFollowing: wasFollowing)
                NotificationCenter.default.post(name: .artistFollowDidChange, object: artistId)
                onFollowToggled?(state.detail.artist.isFollowing)
            } catch {
                state.detail.artist.isFollowing = wasFollowing
                state.detail.artist.followersCount = previousCount
                onStateChanged?()
                onError?("팔로우 처리에 실패했어요")
            }
        }
    }

    func selectTab(_ index: Int) {
        state.selectedTab = index
        onStateChanged?()
    }
}
