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
    func execute() -> HomeEventsResult
}

// MARK: - Implementation

final class FetchHomeEventsUseCase: FetchHomeEventsUseCaseProtocol, Sendable {
    private let repository: any EventRepositoryProtocol

    init(repository: some EventRepositoryProtocol) {
        self.repository = repository
    }

    func execute() -> HomeEventsResult {
        HomeEventsResult(
            banners: repository.fetchBannerEvents(),
            interestedEvents: repository.fetchInterestedEvents(),
            upcomingEvents: repository.fetchUpcomingEvents(),
            newlyStartedEvents: repository.fetchNewlyStartedEvents(),
            soonEndingEvents: repository.fetchSoonEndingEvents()
        )
    }
}
