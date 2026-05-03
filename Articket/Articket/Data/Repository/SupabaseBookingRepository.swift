import Foundation

// 예매 데이터는 인증 필요 — 로그인 구현 전까지 Mock 데이터 사용
struct SupabaseBookingRepository: BookingRepositoryProtocol {
    private let mock = MockBookingRepository()

    func fetchMyBookings() async throws -> [Booking] {
        try await mock.fetchMyBookings()
    }

    func fetchMyStats() async throws -> MyStats {
        try await mock.fetchMyStats()
    }

    func fetchArtistRankings() async throws -> [ArtistRankEntry] {
        try await mock.fetchArtistRankings()
    }
}
