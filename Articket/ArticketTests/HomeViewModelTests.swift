import XCTest
@testable import Articket

// 홈 예매 확인 CTA(대기 intent 조회/응답)·관심공연 중복제거(#7 인접) 검증.
// confirmBookingIntent는 AuthService.shared 로그인 의존이라 유닛 비결정적 → 제외.
@MainActor
final class HomeViewModelTests: XCTestCase {

    private func makeVM(booking: TestBookingRepo, home: StubHomeUseCase = StubHomeUseCase())
        -> HomeViewModel {
        HomeViewModel(
            fetchHomeEventsUseCase: home,
            fetchRecommendationsUseCase: StubRecoUseCase(),
            bookingRepository: booking,
            eventRepository: StubEventRepo()
        )
    }

    func test_refreshBookingIntent_대기건_상태반영() async {
        let booking = TestBookingRepo()
        booking.pendingIntent = BookingIntent(eventId: UUID(), eventTitle: "공연A",
                                              posterUrl: nil, attemptedAt: Date())
        let vm = makeVM(booking: booking)
        let got = expectation(description: "intent"); got.assertForOverFulfill = false
        vm.onStateChanged = { if vm.state.pendingBookingIntent != nil { got.fulfill() } }
        vm.refreshBookingIntent()
        await fulfillment(of: [got], timeout: 3)
        XCTAssertEqual(vm.state.pendingBookingIntent?.eventTitle, "공연A")
    }

    func test_dismissBookingIntent_배너제거_skipped기록() async {
        let intent = BookingIntent(eventId: UUID(), eventTitle: "공연B", posterUrl: nil, attemptedAt: Date())
        let booking = TestBookingRepo(); booking.pendingIntent = intent
        let vm = makeVM(booking: booking)
        // 먼저 대기건 로드
        let got = expectation(description: "intent"); got.assertForOverFulfill = false
        vm.onStateChanged = { if vm.state.pendingBookingIntent != nil { got.fulfill() } }
        vm.refreshBookingIntent()
        await fulfillment(of: [got], timeout: 3)

        vm.dismissBookingIntent()
        XCTAssertNil(vm.state.pendingBookingIntent, "즉시 배너 제거")
        // resolve(skipped)가 비동기로 기록됨
        try? await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(booking.resolved.first?.outcome, .skipped, "skipped로 마감")
    }

    func test_refreshInterestedEvents_중복id_제거() async {
        let dupId = UUID()
        let home = StubHomeUseCase()
        home.result = HomeEventsResult(
            banners: [],
            interestedEvents: [TestFixtures.event(id: dupId, title: "A"),
                               TestFixtures.event(id: dupId, title: "A중복"),
                               TestFixtures.event(title: "B")],
            upcomingEvents: [], newlyStartedEvents: [], soonEndingEvents: []
        )
        let vm = makeVM(booking: TestBookingRepo(), home: home)
        let done = expectation(description: "refreshed"); done.assertForOverFulfill = false
        vm.onStateChanged = { if !vm.state.interestedEvents.isEmpty { done.fulfill() } }
        vm.refreshInterestedEvents()
        await fulfillment(of: [done], timeout: 3)
        XCTAssertEqual(vm.state.interestedEvents.count, 2, "같은 id 중복 제거(diffable 크래시 방어)")
    }
}

// MARK: - Stubs

private final class StubHomeUseCase: FetchHomeEventsUseCaseProtocol, @unchecked Sendable {
    var result = HomeEventsResult(banners: [], interestedEvents: [], upcomingEvents: [],
                                  newlyStartedEvents: [], soonEndingEvents: [])
    func execute() async throws -> HomeEventsResult { result }
}

private struct StubRecoUseCase: FetchRecommendationsUseCaseProtocol {
    func execute(limit: Int, offset: Int) async throws -> RecommendationsResult {
        throw URLError(.unsupportedURL)   // 이 테스트 경로에선 호출되지 않음
    }
}

private struct StubEventRepo: EventRepositoryProtocol {
    func fetchBannerEvents() async throws -> [Event] { [] }
    func fetchInterestedEvents() async throws -> [Event] { [] }
    func fetchUpcomingEvents() async throws -> [Event] { [] }
    func fetchNewlyStartedEvents() async throws -> [Event] { [] }
    func fetchSoonEndingEvents() async throws -> [Event] { [] }
    func fetchTicketOpenSchedule() async throws -> [Event] { [] }
    func searchEvents(keyword: String) async throws -> [Event] { [] }
    func toggleInterested(eventId: UUID, currentlyInterested: Bool) async throws {}
}
