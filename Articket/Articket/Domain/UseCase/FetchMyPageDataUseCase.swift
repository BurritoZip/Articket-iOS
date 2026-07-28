import Foundation

struct MyPageData: Sendable {
    let userProfile: UserProfile
    let myArtists: [Artist]
    let reviewableShows: [Event]
    let yearlyShows: [Event]
    let reviewCount: Int
}

final class FetchMyPageDataUseCase: Sendable {
    private let repository: any MyPageRepositoryProtocol

    init(repository: some MyPageRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> MyPageData {
        async let profile = repository.fetchUserProfile()
        async let artists = repository.fetchMyArtists()
        async let reviewable = repository.fetchReviewableShows()
        async let yearly = repository.fetchYearlyShows()
        async let reviewCount = repository.fetchMyReviewCount()
        return try await MyPageData(
            userProfile: profile,
            myArtists: artists,
            reviewableShows: reviewable,
            yearlyShows: yearly,
            reviewCount: reviewCount
        )
    }

    func fetchMyArtists() async throws -> [Artist] {
        try await repository.fetchMyArtists()
    }
}
