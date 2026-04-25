import Foundation

protocol ArtistDetailRepositoryProtocol {
    func fetchArtistDetail(artistId: UUID) -> ArtistDetail
}
