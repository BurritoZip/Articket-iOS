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
                onError?("MY 정보를 불러오지 못했습니다.")
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
}
