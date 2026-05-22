import Foundation

struct EventArtistRow: Decodable {
    let id: UUID
    let eventId: UUID
    let artistId: UUID
    let artistName: String
    let role: String
    let displayOrder: Int
    let sourceName: String?
    let createdAt: Date
    let updatedAt: Date
}
