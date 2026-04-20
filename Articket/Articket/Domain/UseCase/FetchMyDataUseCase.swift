import Foundation

struct MyDataResult: Sendable {
    let bookings: [Booking]
    let stats: MyStats
    let artistRankings: [ArtistRankEntry]
}

final class FetchMyDataUseCase: Sendable {
    private let repository: BookingRepositoryProtocol

    init(repository: BookingRepositoryProtocol) {
        self.repository = repository
    }

    func execute() -> MyDataResult {
        MyDataResult(
            bookings: repository.fetchMyBookings(),
            stats: repository.fetchMyStats(),
            artistRankings: repository.fetchArtistRankings()
        )
    }
}
