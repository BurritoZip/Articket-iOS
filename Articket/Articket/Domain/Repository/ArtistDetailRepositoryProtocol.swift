import Foundation

protocol ArtistDetailRepositoryProtocol: Sendable {
    func fetchArtistDetail(artistId: UUID) async throws -> ArtistDetail
    func fetchIsFollowing(artistId: UUID) async -> Bool
    func toggleFollow(artistId: UUID, currentlyFollowing: Bool) async throws
}
