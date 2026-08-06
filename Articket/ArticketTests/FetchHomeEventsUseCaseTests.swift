import XCTest
@testable import Articket

final class FetchHomeEventsUseCaseTests: XCTestCase {

    // MARK: - 배너 필터링

    func test_배너_포스터없으면_제외() async throws {
        let repo = StubEventRepository(banners: [
            makeEvent(id: uuid(), title: "포스터있음", venue: "홀A", posterUrl: "https://img/a.jpg"),
            makeEvent(id: uuid(), title: "포스터없음", venue: "홀B", posterUrl: nil),
        ])
        let result = try await FetchHomeEventsUseCase(repository: repo).execute()
        XCTAssertEqual(result.banners.count, 1)
        XCTAssertEqual(result.banners[0].title, "포스터있음")
    }

    func test_배너_장소없으면_제외() async throws {
        let repo = StubEventRepository(banners: [
            makeEvent(title: "장소있음", venue: "홀A", posterUrl: "https://img/a.jpg"),
            makeEvent(title: "장소없음", venue: "", posterUrl: "https://img/b.jpg"),
        ])
        let result = try await FetchHomeEventsUseCase(repository: repo).execute()
        XCTAssertEqual(result.banners.count, 1)
        XCTAssertEqual(result.banners[0].title, "장소있음")
    }

    // MARK: - 중복 제거

    func test_배너ID_upcoming에서_제거() async throws {
        let sharedId = uuid()
        let repo = StubEventRepository(
            banners: [makeEvent(id: sharedId, title: "공연A", venue: "홀A", posterUrl: "https://img/a.jpg")],
            upcoming: [makeEvent(id: sharedId, title: "공연A", venue: "홀A", posterUrl: "https://img/a.jpg"),
                       makeEvent(title: "공연B", venue: "홀B", posterUrl: "https://img/b.jpg")]
        )
        let result = try await FetchHomeEventsUseCase(repository: repo).execute()
        XCTAssertEqual(result.upcomingEvents.count, 1)
        XCTAssertEqual(result.upcomingEvents[0].title, "공연B")
    }

    func test_newlyStartedID_soonEnding에서_제거() async throws {
        let sharedId = uuid()
        let repo = StubEventRepository(
            newlyStarted: [makeEvent(id: sharedId, title: "공연A", venue: "홀A", posterUrl: "https://img/a.jpg")],
            soonEnding: [makeEvent(id: sharedId, title: "공연A", venue: "홀A", posterUrl: "https://img/a.jpg"),
                         makeEvent(title: "공연B", venue: "홀B", posterUrl: "https://img/b.jpg")]
        )
        let result = try await FetchHomeEventsUseCase(repository: repo).execute()
        XCTAssertEqual(result.soonEndingEvents.count, 1)
        XCTAssertEqual(result.soonEndingEvents[0].title, "공연B")
    }

    func test_같은섹션내_같은ID_중복제거() async throws {
        let sharedId = uuid()
        let repo = StubEventRepository(upcoming: [
            makeEvent(id: sharedId, title: "공연A", venue: "홀A", posterUrl: "https://img/a.jpg"),
            makeEvent(id: sharedId, title: "공연A 중복", venue: "홀A", posterUrl: "https://img/a.jpg"),
        ])
        let result = try await FetchHomeEventsUseCase(repository: repo).execute()
        XCTAssertEqual(result.upcomingEvents.count, 1)
    }

    func test_목록섹션_포스터없으면_제외() async throws {
        let repo = StubEventRepository(upcoming: [
            makeEvent(title: "포스터있음", venue: "홀A", posterUrl: "https://img/a.jpg"),
            makeEvent(title: "포스터없음", venue: "홀B", posterUrl: nil),
        ])
        let result = try await FetchHomeEventsUseCase(repository: repo).execute()
        XCTAssertEqual(result.upcomingEvents.count, 1)
        XCTAssertEqual(result.upcomingEvents[0].title, "포스터있음")
    }

    // MARK: - 빈 데이터

    func test_모두_빈배열이면_빈결과() async throws {
        let result = try await FetchHomeEventsUseCase(repository: StubEventRepository()).execute()
        XCTAssertTrue(result.banners.isEmpty)
        XCTAssertTrue(result.upcomingEvents.isEmpty)
        XCTAssertTrue(result.newlyStartedEvents.isEmpty)
        XCTAssertTrue(result.soonEndingEvents.isEmpty)
    }

    // MARK: - Helpers

    private func uuid() -> UUID { UUID() }

    private func makeEvent(
        id: UUID = UUID(),
        title: String,
        venue: String,
        posterUrl: String? = nil
    ) -> Event {
        let today = Date()
        return Event(
            id: id,
            title: title,
            posterUrl: posterUrl,
            startDate: today,
            endDate: Calendar.current.date(byAdding: .day, value: 1, to: today),
            venueName: venue,
            isInterested: false
        )
    }
}

// MARK: - Stub

private final class StubEventRepository: EventRepositoryProtocol {

    private let _banners: [Event]
    private let _interested: [Event]
    private let _upcoming: [Event]
    private let _newlyStarted: [Event]
    private let _soonEnding: [Event]

    init(
        banners: [Event] = [],
        interested: [Event] = [],
        upcoming: [Event] = [],
        newlyStarted: [Event] = [],
        soonEnding: [Event] = []
    ) {
        _banners = banners
        _interested = interested
        _upcoming = upcoming
        _newlyStarted = newlyStarted
        _soonEnding = soonEnding
    }

    func fetchBannerEvents() async throws -> [Event] { _banners }
    func fetchInterestedEvents() async throws -> [Event] { _interested }
    func fetchUpcomingEvents() async throws -> [Event] { _upcoming }
    func fetchNewlyStartedEvents() async throws -> [Event] { _newlyStarted }
    func fetchSoonEndingEvents() async throws -> [Event] { _soonEnding }
    func fetchTicketOpenSchedule() async throws -> [Event] { [] }
    func searchEvents(keyword: String) async throws -> [Event] { [] }
    func toggleInterested(eventId: UUID, currentlyInterested: Bool) async throws {}
}
