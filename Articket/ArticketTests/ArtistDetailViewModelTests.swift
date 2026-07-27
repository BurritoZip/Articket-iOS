import XCTest
@testable import Articket

// 아티스트 상세 로드·탭 전환·다가오는 티켓팅 더보기 검증.
// (toggleFollow는 AuthService.shared 싱글턴 로그인 상태에 의존해 유닛 비결정적 → 제외)
@MainActor
final class ArtistDetailViewModelTests: XCTestCase {

    func test_viewDidLoad_상세와_팔로우상태_병합() async {
        let repo = StubArtistDetailRepo(isFollowing: true)
        let vm = ArtistDetailViewModel(artistId: UUID(), repository: repo)
        let loaded = expectation(description: "loaded"); loaded.assertForOverFulfill = false
        vm.onStateChanged = { if !vm.state.isLoading { loaded.fulfill() } }
        vm.viewDidLoad()
        await fulfillment(of: [loaded], timeout: 3)

        XCTAssertFalse(vm.state.isLoading)
        XCTAssertTrue(vm.state.detail.artist.isFollowing, "fetchIsFollowing 결과가 detail에 병합")
    }

    func test_selectTab_변경() {
        let vm = ArtistDetailViewModel(artistId: UUID(), repository: StubArtistDetailRepo())
        var notified = false
        vm.onStateChanged = { notified = true }
        vm.selectTab(1)
        XCTAssertEqual(vm.state.selectedTab, 1)
        XCTAssertTrue(notified)
    }

    func test_requestUpcomingList_콜백으로_이벤트전달() async {
        let events = [TestFixtures.event(title: "예정1"), TestFixtures.event(title: "예정2")]
        let repo = StubArtistDetailRepo(upcoming: events)
        let vm = ArtistDetailViewModel(artistId: UUID(), repository: repo)

        let got = expectation(description: "upcoming")
        var received: [Event] = []
        vm.onUpcomingListLoaded = { received = $0; got.fulfill() }
        vm.requestUpcomingList()
        await fulfillment(of: [got], timeout: 3)
        XCTAssertEqual(received.count, 2)
    }
}

private struct StubArtistDetailRepo: ArtistDetailRepositoryProtocol {
    var isFollowing: Bool = false
    var upcoming: [Event] = []

    func fetchArtistDetail(artistId: UUID) async -> ArtistDetail { .placeholder }
    func fetchIsFollowing(artistId: UUID) async -> Bool { isFollowing }
    func toggleFollow(artistId: UUID, currentlyFollowing: Bool) async throws {}
    func fetchUpcomingEvents(artistId: UUID) async throws -> [Event] { upcoming }
}
