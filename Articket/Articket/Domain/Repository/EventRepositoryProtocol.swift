import Foundation

protocol EventRepositoryProtocol: Sendable {
    func fetchBannerEvents() async throws -> [Event]
    func fetchInterestedEvents() async throws -> [Event]
    func fetchUpcomingEvents() async throws -> [Event]
    func fetchNewlyStartedEvents() async throws -> [Event]
    func fetchSoonEndingEvents() async throws -> [Event]
    /// 티켓 오픈이 아직 안 온 공연(ticket_open_date >= now)을 임박순으로 — 바로가기 "예매 일정"용
    func fetchTicketOpenSchedule() async throws -> [Event]
    func searchEvents(keyword: String) async throws -> [Event]
    func toggleInterested(eventId: UUID, currentlyInterested: Bool) async throws
}
