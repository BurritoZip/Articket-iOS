import Foundation

final class FetchConcertDetailUseCase: Sendable {
    private let repository: any ConcertDetailRepositoryProtocol

    init(repository: some ConcertDetailRepositoryProtocol) {
        self.repository = repository
    }

    func execute(concertId: UUID) async throws -> ConcertDetail {
        try await repository.fetchConcertDetail(concertId: concertId)
    }
}
