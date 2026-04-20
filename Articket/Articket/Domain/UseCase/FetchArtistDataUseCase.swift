import Foundation

struct ArtistDataResult: Sendable {
    let myArtists: [Artist]
    let popularArtists: [PopularArtist]
    let recommendedArtists: [Artist]
}

final class FetchArtistDataUseCase: Sendable {
    private let repository: any ArtistRepositoryProtocol

    init(repository: some ArtistRepositoryProtocol) {
        self.repository = repository
    }

    func execute() -> ArtistDataResult {
        ArtistDataResult(
            myArtists: repository.fetchMyArtists(),
            popularArtists: repository.fetchPopularArtists(),
            recommendedArtists: repository.fetchRecommendedArtists()
        )
    }

    func fetchCalendarEvents(year: Int, month: Int) -> [CalendarEvent] {
        repository.fetchCalendarEvents(year: year, month: month)
    }
}
