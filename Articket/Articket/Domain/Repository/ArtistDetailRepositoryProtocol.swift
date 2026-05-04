import Foundation

protocol ArtistDetailRepositoryProtocol: Sendable {
    func fetchArtistDetail(artistId: UUID) async throws -> ArtistDetail
}
