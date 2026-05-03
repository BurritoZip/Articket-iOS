import Foundation

struct MyDataResult: Sendable {
    let bookings: [Booking]
    let stats: MyStats
    let artistRankings: [ArtistRankEntry]
}

final class FetchMyDataUseCase: Sendable {
    private let repository: any BookingRepositoryProtocol

    init(repository: some BookingRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> MyDataResult {
        async let bookings = repository.fetchMyBookings()
        async let stats = repository.fetchMyStats()
        async let rankings = repository.fetchArtistRankings()
        return try await MyDataResult(
            bookings: bookings,
            stats: stats,
            artistRankings: rankings
        )
    }
}
