import Foundation

struct Artist: Sendable {
    let id: UUID
    let name: String
    let avatarAssetName: String?
    let followersCount: Int
    let upcomingEventCount: Int
    var isFollowing: Bool
}

extension Artist: Hashable {
    static func == (lhs: Artist, rhs: Artist) -> Bool { lhs.id == rhs.id && lhs.isFollowing == rhs.isFollowing }
    func hash(into hasher: inout Hasher) { hasher.combine(id); hasher.combine(isFollowing) }
}

struct PopularArtist: Hashable, Sendable {
    let id: UUID
    let name: String
    let imageAssetName: String?
    let badge: String
}
