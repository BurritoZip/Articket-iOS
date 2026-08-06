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

    func fetchArtistRecommendations(
        popularLimit: Int,
        forYouLimit: Int
    ) async throws -> ArtistRecommendationsResult {
        let popular = [
            RecommendedArtistItem(
                id: UUID(), name: "Mock 인기 아티스트 A", avatarUrl: nil,
                followersCount: 12_000, upcomingEventCount: 3, rank: 1, reasons: []
            ),
            RecommendedArtistItem(
                id: UUID(), name: "Mock 인기 아티스트 B", avatarUrl: nil,
                followersCount: 8_500, upcomingEventCount: 1, rank: 2, reasons: []
            ),
        ]
        let forYou = [
            RecommendedArtistItem(
                id: UUID(), name: "Mock 추천 아티스트 C", avatarUrl: nil,
                followersCount: 3_200, upcomingEventCount: 2, rank: nil,
                reasons: ["회원님이 팔로우한 OO와 같은 무대에 섰어요", "같은 소속사 (목업 엔터) 아티스트예요"]
            ),
        ]
        return ArtistRecommendationsResult(
            popular: Array(popular.prefix(popularLimit)),
            forYou: Array(forYou.prefix(forYouLimit)),
            forYouColdStart: false
        )
    }
}
