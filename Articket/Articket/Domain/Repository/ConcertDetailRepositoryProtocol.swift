import Foundation

protocol ConcertDetailRepositoryProtocol: Sendable {
    func fetchConcertDetail(concertId: UUID) async throws -> ConcertDetail
    func fetchIsInterested(concertId: UUID) async -> Bool
    func toggleInterested(concertId: UUID, currentlyInterested: Bool) async throws
}
