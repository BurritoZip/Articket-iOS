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

protocol FetchArtistRecommendationsUseCaseProtocol: Sendable {
    func execute(popularLimit: Int, forYouLimit: Int) async throws -> ArtistRecommendationsResult
}

final class FetchArtistRecommendationsUseCase: FetchArtistRecommendationsUseCaseProtocol, Sendable {
    private let repository: any RecommendationRepositoryProtocol

    init(repository: some RecommendationRepositoryProtocol) {
        self.repository = repository
    }

    func execute(popularLimit: Int, forYouLimit: Int) async throws -> ArtistRecommendationsResult {
        try await repository.fetchArtistRecommendations(popularLimit: popularLimit, forYouLimit: forYouLimit)
    }
}
