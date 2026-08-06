import Foundation

struct RecommendationsResult: Sendable {
    let items: [Event]
    let hasMore: Bool
}

/// 아티스트 탭 — 인기 아티스트 + 좋아할만한 아티스트
struct ArtistRecommendationsResult: Sendable {
    let popular: [RecommendedArtistItem]
    let forYou: [RecommendedArtistItem]
    /// 팔로우한 아티스트가 없어 forYou가 인기 기반 폴백인지 여부
    let forYouColdStart: Bool
}

// 인지도 점수 등 운영 지표는 admin 전용. 팔로워수(followersCount)는 탭 UI에 필요해 포함한다.
struct RecommendedArtistItem: Sendable, Hashable, Identifiable {
    let id: UUID
    let name: String
    let avatarUrl: String?
    let followersCount: Int
    let upcomingEventCount: Int?
    /// 인기 목록 순위 (추천 목록은 nil)
    let rank: Int?
    /// 추천 이유 (인기 목록은 빈 배열)
    let reasons: [String]
}

protocol RecommendationRepositoryProtocol: Sendable {
    /// 개인화 추천 공연 — admin /api/recommendations 호출 (로그인 필요)
    func fetchRecommendations(limit: Int, offset: Int) async throws -> RecommendationsResult

    /// 인기 아티스트 + 좋아할만한 아티스트 — /api/recommendations/artists.
    /// 로그인 없으면 인기만, 로그인 시 forYou도 개인화.
    func fetchArtistRecommendations(popularLimit: Int, forYouLimit: Int) async throws -> ArtistRecommendationsResult
}
