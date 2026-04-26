import Foundation

final class FetchConcertDetailUseCase {
    private let repository: ConcertDetailRepositoryProtocol

    init(repository: ConcertDetailRepositoryProtocol) {
        self.repository = repository
    }

    func execute(concertId: UUID) -> ConcertDetail {
        repository.fetchConcertDetail(concertId: concertId)
    }
}
