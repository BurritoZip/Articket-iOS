import Foundation

protocol ConcertDetailRepositoryProtocol: Sendable {
    func fetchConcertDetail(concertId: UUID) -> ConcertDetail
}
