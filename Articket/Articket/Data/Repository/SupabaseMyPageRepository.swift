import Foundation

// 유저 프로필 데이터는 인증 필요 — 로그인 구현 전까지 Mock 데이터 사용
struct SupabaseMyPageRepository: MyPageRepositoryProtocol {
    private let mock = MockMyPageRepository()

    func fetchUserProfile() async throws -> UserProfile {
        try await mock.fetchUserProfile()
    }

    func fetchMyArtists() async throws -> [Artist] {
        try await mock.fetchMyArtists()
    }

    func fetchReviewableShows() async throws -> [Event] {
        try await mock.fetchReviewableShows()
    }

    func fetchYearlyShows() async throws -> [Event] {
        try await mock.fetchYearlyShows()
    }
}
