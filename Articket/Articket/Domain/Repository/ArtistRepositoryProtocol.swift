import Foundation

protocol ArtistRepositoryProtocol: Sendable {
    func fetchMyArtists() async throws -> [Artist]
    func fetchPopularArtists() async throws -> [PopularArtist]
    func fetchCalendarEvents(year: Int, month: Int) async throws -> [CalendarEvent]
    func fetchRecommendedArtists() async throws -> [Artist]
    func fetchFollowedArtistIds() async -> Set<UUID>
    func toggleFollow(artistId: UUID, currentlyFollowing: Bool) async throws
    func searchArtists(keyword: String) async throws -> [Artist]
}
