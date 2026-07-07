import Foundation

protocol BookingRepositoryProtocol: Sendable {
    func fetchMyBookings() async throws -> [Booking]
    func fetchCancelledBookings() async throws -> [Booking]
    func fetchMyStats() async throws -> MyStats
    func fetchArtistRankings() async throws -> [ArtistRankEntry]
    /// 공연 상세에서 '예매 완료'로 표시 — user_bookings에 completed 행 insert
    func markBooked(eventId: UUID) async throws
    /// 해당 공연이 이미 예매(active/completed)된 상태인지
    func isBooked(eventId: UUID) async throws -> Bool
}
