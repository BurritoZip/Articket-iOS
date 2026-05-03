import Foundation

protocol ConcertDetailRepositoryProtocol: Sendable {
    func fetchConcertDetail(concertId: UUID) async throws -> ConcertDetail
}
