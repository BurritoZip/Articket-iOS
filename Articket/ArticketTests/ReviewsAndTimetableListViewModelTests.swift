import XCTest
@testable import Articket

// 나의 후기 목록 로드 검증.
@MainActor
final class ReviewsViewModelTests: XCTestCase {

    func test_viewDidLoad_후기목록_로드() async {
        let repo = TestReviewRepo()
        repo.reviews = [
            ConcertReview(id: UUID(), eventId: UUID(), eventTitle: "공연A", eventPosterUrl: nil,
                          title: "최고", starCount: 5, content: "좋았어요",
                          username: "user****", createdAt: Date()),
        ]
        let vm = ReviewsViewModel(repository: repo)
        let loaded = expectation(description: "loaded"); loaded.assertForOverFulfill = false
        vm.onStateChanged = { if !vm.state.isLoading { loaded.fulfill() } }
        vm.viewDidLoad()
        await fulfillment(of: [loaded], timeout: 3)
        XCTAssertEqual(vm.state.reviews.count, 1)
        XCTAssertFalse(vm.state.isLoading)
    }

    func test_로드실패시_onError() async {
        let repo = TestReviewRepo(); repo.fetchError = URLError(.timedOut)
        let vm = ReviewsViewModel(repository: repo)
        let errored = expectation(description: "error")
        vm.onError = { _ in errored.fulfill() }
        vm.viewDidLoad()
        await fulfillment(of: [errored], timeout: 3)
    }
}

// 타임테이블 이벤트 목록 로드/에러 검증.
@MainActor
final class TimetableListViewModelTests: XCTestCase {

    func test_viewDidLoad_이벤트_로드() async {
        let repo = StubTimetableRepo()
        repo.events = [TimetableEvent(id: UUID(), title: "페스", posterUrl: nil, dateRange: "",
                                      venueName: "홀", days: [])]
        let vm = TimetableListViewModel(repository: repo)
        let loaded = expectation(description: "loaded"); loaded.assertForOverFulfill = false
        vm.onStateChanged = { if !vm.state.isLoading { loaded.fulfill() } }
        vm.viewDidLoad()
        await fulfillment(of: [loaded], timeout: 3)
        XCTAssertEqual(vm.state.events.count, 1)
        XCTAssertNil(vm.state.errorMessage)
    }

    func test_로드실패시_errorMessage_설정() async {
        let repo = StubTimetableRepo(); repo.error = URLError(.notConnectedToInternet)
        let vm = TimetableListViewModel(repository: repo)
        let done = expectation(description: "done"); done.assertForOverFulfill = false
        vm.onStateChanged = { if !vm.state.isLoading { done.fulfill() } }
        vm.viewDidLoad()
        await fulfillment(of: [done], timeout: 3)
        XCTAssertNotNil(vm.state.errorMessage, "실패 시 errorMessage 설정")
        XCTAssertTrue(vm.state.events.isEmpty)
    }
}

private final class StubTimetableRepo: TimetableRepositoryProtocol, @unchecked Sendable {
    var events: [TimetableEvent] = []
    var error: Error?
    func fetchTimetableEvents() async throws -> [TimetableEvent] {
        if let error { throw error }
        return events
    }
}
