import Foundation

protocol FetchRecommendationsUseCaseProtocol: Sendable {
    func execute(limit: Int, offset: Int) async throws -> RecommendationsResult
}

final class FetchRecommendationsUseCase: FetchRecommendationsUseCaseProtocol, Sendable {
    private let repository: any RecommendationRepositoryProtocol

    init(repository: some RecommendationRepositoryProtocol) {
        self.repository = repository
    }

    func execute(limit: Int, offset: Int) async throws -> RecommendationsResult {
        try await repository.fetchRecommendations(limit: limit, offset: offset)
    }
}
