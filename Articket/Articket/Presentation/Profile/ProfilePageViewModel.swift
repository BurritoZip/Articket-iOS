import Foundation

@MainActor
final class ProfilePageViewModel {

    struct State {
        var userProfile: UserProfile?
        var myArtists: [Artist] = []
        var reviewableShows: [Event] = []
        var yearlyShows: [Event] = []
        var isLoading: Bool = false
    }

    private let useCase: FetchMyPageDataUseCase
    private(set) var state: State = .init()
    var onStateChanged: (() -> Void)?
    var onError: ((String) -> Void)?

    init(useCase: FetchMyPageDataUseCase) {
        self.useCase = useCase
    }

    func viewDidLoad() {
        state.isLoading = true
        onStateChanged?()
        Task {
            do {
                let data = try await useCase.execute()
                state.userProfile = data.userProfile
                state.myArtists = data.myArtists
                state.reviewableShows = data.reviewableShows
                state.yearlyShows = data.yearlyShows
            } catch {
                onError?("내 정보를 불러오지 못했어요")
            }
            state.isLoading = false
            onStateChanged?()
        }
    }

    func refreshMyArtists() {
        Task {
            guard let artists = try? await useCase.fetchMyArtists() else { return }
            state.myArtists = artists
            onStateChanged?()
        }
    }

    /// Pull-to-refresh — 전체 데이터를 다시 불러오되 isLoading은 건드리지 않아
    /// 스켈레톤 대신 새로고침 스피너만 돌게 한다. 완료 콜백으로 endRefreshing 신호.
    func refresh(completion: @escaping () -> Void) {
        Task {
            do {
                let data = try await useCase.execute()
                state.userProfile = data.userProfile
                state.myArtists = data.myArtists
                state.reviewableShows = data.reviewableShows
                state.yearlyShows = data.yearlyShows
            } catch {
                onError?("내 정보를 불러오지 못했어요")
            }
            onStateChanged?()
            completion()
        }
    }
}
