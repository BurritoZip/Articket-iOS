import Foundation

protocol BookingRepositoryProtocol: Sendable {
    func fetchMyBookings() async throws -> [Booking]
    func fetchMyStats() async throws -> MyStats
    func fetchArtistRankings() async throws -> [ArtistRankEntry]
}
