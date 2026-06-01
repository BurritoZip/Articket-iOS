import Foundation

struct RecommendationsResult: Sendable {
    let items: [Event]
    let hasMore: Bool
}

protocol RecommendationRepositoryProtocol: Sendable {
    /// 개인화 추천 공연 — admin /api/recommendations 호출 (로그인 필요)
    func fetchRecommendations(limit: Int, offset: Int) async throws -> RecommendationsResult
}
