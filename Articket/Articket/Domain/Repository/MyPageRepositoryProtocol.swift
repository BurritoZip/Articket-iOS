import Foundation

protocol MyPageRepositoryProtocol: Sendable {
    func fetchUserProfile() async throws -> UserProfile
    func fetchMyArtists() async throws -> [Artist]
    func fetchReviewableShows() async throws -> [Event]
    func fetchYearlyShows() async throws -> [Event]
    func updateDisplayName(_ name: String) async throws
}
