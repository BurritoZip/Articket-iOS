import Foundation

struct Artist: Sendable {
    let id: UUID
    let name: String
    let nameEn: String?
    let avatarUrl: String?
    // 팔로우 토글 시 낙관적으로 ±1 갱신하므로 var
    var followersCount: Int
    let upcomingEventCount: Int
    var isFollowing: Bool
    // 스코어링 엔진 산출 (artists.popularity_score / trending_score) — 옵셔널 미러
    var popularityScore: Double? = nil
    var trendingScore: Double? = nil
}

extension Artist: Hashable {
    // followersCount 포함 — 팔로워 수만 바뀌어도 diffable 데이터소스가 셀을 재렌더하도록
    static func == (lhs: Artist, rhs: Artist) -> Bool {
        lhs.id == rhs.id && lhs.isFollowing == rhs.isFollowing && lhs.followersCount == rhs.followersCount
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id); hasher.combine(isFollowing); hasher.combine(followersCount)
    }
}

struct PopularArtist: Hashable, Sendable {
    let id: UUID
    let name: String
    let imageUrl: String?
    let badge: String
}
