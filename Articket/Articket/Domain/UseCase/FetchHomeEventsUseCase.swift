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
        async let banners      = (try? repository.fetchBannerEvents()) ?? []
        async let interested   = (try? repository.fetchInterestedEvents()) ?? []
        async let upcoming     = (try? repository.fetchUpcomingEvents()) ?? []
        async let newlyStarted = (try? repository.fetchNewlyStartedEvents()) ?? []
        async let soonEnding   = (try? repository.fetchSoonEndingEvents()) ?? []

        let rawBanners    = deduplicated(await banners).filter(isValidWithPoster)
        let rawInterested = deduplicated(await interested).filter(isValidWithPoster)
        let rawUpcoming   = deduplicated(await upcoming).filter(isValid)
        let rawNewly      = deduplicated(await newlyStarted).filter(isValid)
        let rawSoon       = deduplicated(await soonEnding).filter(isValid)

        // 배너에 있는 공연은 다가오는 이벤트에서 제거
        let bannerIds = Set(rawBanners.map(\.id))
        let filteredUpcoming = rawUpcoming.filter { !bannerIds.contains($0.id) }

        // 진행중 공연이 곧 종료 섹션에도 중복 노출되지 않도록 제거
        let newlyIds = Set(rawNewly.map(\.id))
        let filteredSoon = rawSoon.filter { !newlyIds.contains($0.id) }

        return HomeEventsResult(
            banners: rawBanners,
            interestedEvents: rawInterested,
            upcomingEvents: filteredUpcoming,
            newlyStartedEvents: rawNewly,
            soonEndingEvents: filteredSoon
        )
    }

    private func deduplicated(_ events: [Event]) -> [Event] {
        var seen = Set<UUID>()
        return events.filter { seen.insert($0.id).inserted }
    }

    private func isValid(_ event: Event) -> Bool {
        !event.title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !event.venueName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func isValidWithPoster(_ event: Event) -> Bool {
        isValid(event) && event.posterUrl != nil
    }
}
