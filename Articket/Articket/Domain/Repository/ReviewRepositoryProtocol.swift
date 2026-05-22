import Foundation

protocol ReviewRepositoryProtocol: Sendable {
    func fetchMyReviews() async throws -> [ConcertReview]
    func writeReview(eventId: UUID, title: String, starCount: Int, content: String) async throws
}
