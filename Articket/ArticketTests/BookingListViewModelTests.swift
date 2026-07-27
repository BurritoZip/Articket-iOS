import XCTest
@testable import Articket

// 예매/취소 내역 로드·탭 전환·currentBookings 검증.
@MainActor
final class BookingListViewModelTests: XCTestCase {

    func test_viewDidLoad_active_cancelled_로드() async {
        let repo = TestBookingRepo()
        repo.bookings = [TestFixtures.booking(title: "예매1")]
        repo.cancelled = [TestFixtures.booking(title: "취소1", status: .cancelled),
                          TestFixtures.booking(title: "취소2", status: .cancelled)]
        let vm = BookingListViewModel(repository: repo)
        let loaded = expectation(description: "loaded"); loaded.assertForOverFulfill = false
        vm.onStateChanged = { if !vm.state.isLoading { loaded.fulfill() } }
        vm.viewDidLoad()
        await fulfillment(of: [loaded], timeout: 3)

        XCTAssertEqual(vm.state.activeBookings.count, 1)
        XCTAssertEqual(vm.state.cancelledBookings.count, 2)
    }

    func test_currentBookings_선택탭따라_전환() async {
        let repo = TestBookingRepo()
        repo.bookings = [TestFixtures.booking(title: "A")]
        repo.cancelled = [TestFixtures.booking(title: "C", status: .cancelled)]
        let vm = BookingListViewModel(repository: repo)
        let loaded = expectation(description: "loaded"); loaded.assertForOverFulfill = false
        vm.onStateChanged = { if !vm.state.isLoading { loaded.fulfill() } }
        vm.viewDidLoad()
        await fulfillment(of: [loaded], timeout: 3)

        XCTAssertEqual(vm.currentBookings.first?.title, "A", "기본 예매내역 탭")
        vm.selectTab(.cancelled)
        XCTAssertEqual(vm.currentBookings.first?.title, "C", "취소내역 탭으로 전환")
    }

    func test_초기탭_주입() {
        let vm = BookingListViewModel(initialTab: .cancelled, repository: TestBookingRepo())
        XCTAssertEqual(vm.state.selectedTab, .cancelled)
    }
}
