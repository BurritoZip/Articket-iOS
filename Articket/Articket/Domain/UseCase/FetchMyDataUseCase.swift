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

        var fetchedStats = try await stats
        let fetchedRankings = try await rankings

        // user_bookings가 비어있어 topArtist를 계산할 수 없을 때 랭킹 1위로 대체
        if fetchedStats.topArtist.isEmpty, let top = fetchedRankings.first {
            fetchedStats = MyStats(
                year: fetchedStats.year,
                monthlyViewCounts: fetchedStats.monthlyViewCounts,
                topMonth: fetchedStats.topMonth,
                topGenre: fetchedStats.topGenre,
                topArtist: top.name,
                totalCount: fetchedStats.totalCount
            )
        }

        let fetchedBookings = try await bookings
        return MyDataResult(
            bookings: fetchedBookings,
            stats: fetchedStats,
            artistRankings: fetchedRankings
        )
    }
}
