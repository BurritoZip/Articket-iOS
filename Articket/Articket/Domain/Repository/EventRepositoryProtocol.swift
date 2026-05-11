import Foundation

protocol EventRepositoryProtocol: Sendable {
    func fetchBannerEvents() async throws -> [Event]
    func fetchInterestedEvents() async throws -> [Event]
    func fetchUpcomingEvents() async throws -> [Event]
    func fetchNewlyStartedEvents() async throws -> [Event]
    func fetchSoonEndingEvents() async throws -> [Event]
    func searchEvents(keyword: String) async throws -> [Event]
}
