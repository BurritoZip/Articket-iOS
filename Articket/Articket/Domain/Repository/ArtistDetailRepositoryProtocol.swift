import Foundation

protocol ArtistDetailRepositoryProtocol: Sendable {
    func fetchArtistDetail(artistId: UUID) async throws -> ArtistDetail
    func fetchIsFollowing(artistId: UUID) async -> Bool
    func toggleFollow(artistId: UUID, currentlyFollowing: Bool) async throws
    /// 해당 아티스트의 다가오는 공연 전체(start_date >= now, 임박순). "티켓팅 더보기"용.
    func fetchUpcomingEvents(artistId: UUID) async throws -> [Event]
}
