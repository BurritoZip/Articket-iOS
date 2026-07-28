import Foundation

protocol MyPageRepositoryProtocol: Sendable {
    func fetchUserProfile() async throws -> UserProfile
    func fetchMyArtists() async throws -> [Artist]
    func fetchReviewableShows() async throws -> [Event]
    func fetchYearlyShows() async throws -> [Event]
    /// 내가 작성한 후기 총 개수 — 마이페이지 "나의 후기" 메뉴 뱃지용
    func fetchMyReviewCount() async throws -> Int
    func updateDisplayName(_ name: String) async throws
    func updateAvatar(imageData: Data) async throws -> String
}
