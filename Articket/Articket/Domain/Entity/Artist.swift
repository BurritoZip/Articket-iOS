import Foundation

struct Artist: Sendable {
    let id: UUID
    let name: String
    let nameEn: String?
    let avatarUrl: String?
    let followersCount: Int
    let upcomingEventCount: Int
    var isFollowing: Bool
    // 스코어링 엔진 산출 (artists.popularity_score / trending_score) — 옵셔널 미러
    var popularityScore: Double? = nil
    var trendingScore: Double? = nil
}

extension Artist: Hashable {
    static func == (lhs: Artist, rhs: Artist) -> Bool { lhs.id == rhs.id && lhs.isFollowing == rhs.isFollowing }
    func hash(into hasher: inout Hasher) { hasher.combine(id); hasher.combine(isFollowing) }
}

struct PopularArtist: Hashable, Sendable {
    let id: UUID
    let name: String
    let imageUrl: String?
    let badge: String
}
