import Foundation

protocol BookingRepositoryProtocol: Sendable {
    func fetchMyBookings() -> [Booking]
    func fetchMyStats() -> MyStats
    func fetchArtistRankings() -> [ArtistRankEntry]
}
