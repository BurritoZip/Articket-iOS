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

    private let artistId: UUID
    private let repository: any ArtistDetailRepositoryProtocol

    init(artistId: UUID, repository: some ArtistDetailRepositoryProtocol) {
        self.artistId = artistId
        self.repository = repository
        self.state = State(detail: .placeholder, isLoading: true)
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
                onError?("아티스트 정보를 불러오지 못했습니다.")
            }
            onStateChanged?()
        }
    }

    func toggleFollow() {
        guard AuthService.shared.isLoggedIn else {
            onLoginRequired? { [weak self] in self?.toggleFollow() }
            return
        }
        let wasFollowing = state.detail.artist.isFollowing
        let previousCount = state.detail.artist.followersCount
        state.detail.artist.isFollowing = !wasFollowing
        // 낙관적 팔로워 수 갱신 (DB 트리거가 실제 값을 맞추지만 UI 즉시 반영)
        state.detail.artist.followersCount = wasFollowing ? max(0, previousCount - 1) : previousCount + 1
        onStateChanged?()
        Task {
            do {
                try await repository.toggleFollow(artistId: artistId, currentlyFollowing: wasFollowing)
                NotificationCenter.default.post(name: .artistFollowDidChange, object: artistId)
                onFollowToggled?(state.detail.artist.isFollowing)
            } catch {
                state.detail.artist.isFollowing = wasFollowing
                state.detail.artist.followersCount = previousCount
                onStateChanged?()
                onError?("팔로우 처리에 실패했습니다.")
            }
        }
    }

    func selectTab(_ index: Int) {
        state.selectedTab = index
        onStateChanged?()
    }
}
