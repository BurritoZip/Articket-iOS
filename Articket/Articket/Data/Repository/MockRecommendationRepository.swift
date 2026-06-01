import Foundation

final class MockRecommendationRepository: RecommendationRepositoryProtocol {
    func fetchRecommendations(limit: Int, offset: Int) async throws -> RecommendationsResult {
        let items = [
            Event(
                id: UUID(),
                title: "Mock 추천 공연 1",
                posterUrl: nil,
                startDate: Date().addingTimeInterval(86_400 * 3),
                venueName: "목업 공연장",
                isInterested: false,
                recommendationScore: 0.92,
                recommendationReason: "회원님이 팔로우한 아티스트 2명이 출연해요"
            ),
            Event(
                id: UUID(),
                title: "Mock 추천 공연 2",
                posterUrl: nil,
                startDate: Date().addingTimeInterval(86_400 * 10),
                venueName: "목업 공연장",
                isInterested: false,
                recommendationScore: 0.81,
                recommendationReason: "회원님이 관심 등록한 공연과 비슷해요"
            ),
        ]
        return RecommendationsResult(items: items, hasMore: false)
    }
}
