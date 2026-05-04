import Foundation

struct ArtistRankEntry: Sendable {
    let id: UUID
    let rank: Int
    let name: String
    let viewCount: Int
    let avatarUrl: String?
    let posterUrls: [String]
    var isExpanded: Bool
}

extension ArtistRankEntry: Hashable {
    static func == (lhs: ArtistRankEntry, rhs: ArtistRankEntry) -> Bool {
        lhs.id == rhs.id && lhs.isExpanded == rhs.isExpanded
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(isExpanded)
    }
}
