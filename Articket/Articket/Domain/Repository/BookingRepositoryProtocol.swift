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

    // MARK: - 예매 의사 확인 CTA

    /// '예매하기'로 외부 예매처에 나간 사실을 기록 (비로그인이면 로컬에 보관)
    func recordBookingIntent(eventId: UUID, eventTitle: String, posterUrl: String?) async
    /// 아직 답하지 않은 가장 최근 intent 1건 (만료·이미 예매 확정된 건 제외)
    func fetchPendingBookingIntent() async -> BookingIntent?
    /// CTA 응답 반영 — .booked면 user_bookings에 completed 행까지 생성한다
    func resolveBookingIntent(eventId: UUID, outcome: BookingIntentOutcome) async throws
}
