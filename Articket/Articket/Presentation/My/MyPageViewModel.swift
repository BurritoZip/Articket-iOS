import Foundation

@MainActor
final class MyPageViewModel {

    struct State {
        var userProfile: UserProfile?
        var myArtists: [Artist] = []
        var reviewableShows: [Event] = []
        var yearlyShows: [Event] = []
    }

    private let useCase: FetchMyPageDataUseCase
    private(set) var state: State = .init()
    var onStateChanged: (() -> Void)?

    init(useCase: FetchMyPageDataUseCase) {
        self.useCase = useCase
    }

    func viewDidLoad() {
        let data = useCase.execute()
        state.userProfile = data.userProfile
        state.myArtists = data.myArtists
        state.reviewableShows = data.reviewableShows
        state.yearlyShows = data.yearlyShows
        onStateChanged?()
    }
}
