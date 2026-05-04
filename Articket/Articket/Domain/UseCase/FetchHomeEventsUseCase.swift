import Foundation

struct HomeEventsResult: Sendable {
    let banners: [Event]
    let interestedEvents: [Event]
    let upcomingEvents: [Event]
    let newlyStartedEvents: [Event]
    let soonEndingEvents: [Event]
}

// MARK: - Protocol (enables ViewModel unit testing via mock injection)

protocol FetchHomeEventsUseCaseProtocol: Sendable {
    func execute() async throws -> HomeEventsResult
}

// MARK: - Implementation

final class FetchHomeEventsUseCase: FetchHomeEventsUseCaseProtocol, Sendable {
    private let repository: any EventRepositoryProtocol

    init(repository: some EventRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> HomeEventsResult {
        async let banners       = (try? repository.fetchBannerEvents()) ?? []
        async let interested    = (try? repository.fetchInterestedEvents()) ?? []
        async let upcoming      = (try? repository.fetchUpcomingEvents()) ?? []
        async let newlyStarted  = (try? repository.fetchNewlyStartedEvents()) ?? []
        async let soonEnding    = (try? repository.fetchSoonEndingEvents()) ?? []
        return await HomeEventsResult(
            banners: banners,
            interestedEvents: interested,
            upcomingEvents: upcoming,
            newlyStartedEvents: newlyStarted,
            soonEndingEvents: soonEnding
        )
    }
}
