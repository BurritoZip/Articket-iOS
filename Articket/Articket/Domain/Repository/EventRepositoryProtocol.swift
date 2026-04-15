import Foundation

protocol EventRepositoryProtocol: Sendable {
    func fetchBannerEvents() -> [Event]
    func fetchInterestedEvents() -> [Event]
    func fetchUpcomingEvents() -> [Event]
    func fetchNewlyStartedEvents() -> [Event]
    func fetchSoonEndingEvents() -> [Event]
}
