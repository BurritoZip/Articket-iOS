import Foundation

struct MyPageData: Sendable {
    let userProfile: UserProfile
    let myArtists: [Artist]
    let reviewableShows: [Event]
    let yearlyShows: [Event]
}

final class FetchMyPageDataUseCase: Sendable {
    private let repository: MyPageRepositoryProtocol

    init(repository: MyPageRepositoryProtocol) {
        self.repository = repository
    }

    func execute() -> MyPageData {
        MyPageData(
            userProfile: repository.fetchUserProfile(),
            myArtists: repository.fetchMyArtists(),
            reviewableShows: repository.fetchReviewableShows(),
            yearlyShows: repository.fetchYearlyShows()
        )
    }
}
