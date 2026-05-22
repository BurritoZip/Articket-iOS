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

    func execute() async throws -> ArtistDataResult {
        async let myArtists = repository.fetchMyArtists()
        async let popular = repository.fetchPopularArtists()
        async let recommended = repository.fetchRecommendedArtists()
        return try await ArtistDataResult(
            myArtists: myArtists,
            popularArtists: popular,
            recommendedArtists: recommended
        )
    }

    func fetchCalendarEvents(year: Int, month: Int) async throws -> [CalendarEvent] {
        try await repository.fetchCalendarEvents(year: year, month: month)
    }

    func fetchFollowedArtistIds() async -> Set<UUID> {
        await repository.fetchFollowedArtistIds()
    }

    func toggleFollow(artistId: UUID, currentlyFollowing: Bool) async throws {
        try await repository.toggleFollow(artistId: artistId, currentlyFollowing: currentlyFollowing)
    }
}
