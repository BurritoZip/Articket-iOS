import Foundation

protocol MyPageRepositoryProtocol: Sendable {
    func fetchUserProfile() -> UserProfile
    func fetchMyArtists() -> [Artist]
    func fetchReviewableShows() -> [Event]
    func fetchYearlyShows() -> [Event]
}
