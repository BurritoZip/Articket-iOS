import Foundation

protocol ArtistRepositoryProtocol: Sendable {
    func fetchMyArtists() -> [Artist]
    func fetchPopularArtists() -> [PopularArtist]
    func fetchCalendarEvents(year: Int, month: Int) -> [CalendarEvent]
    func fetchRecommendedArtists() -> [Artist]
}
