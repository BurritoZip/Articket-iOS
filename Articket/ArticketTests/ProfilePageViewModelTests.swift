import XCTest
@testable import Articket

// 마이페이지 데이터 로드 + '내 아티스트' 즉시 갱신(#6) 검증.
@MainActor
final class ProfilePageViewModelTests: XCTestCase {

    private func makeVM(repo: TestMyPageRepo) -> ProfilePageViewModel {
        ProfilePageViewModel(useCase: FetchMyPageDataUseCase(repository: repo))
    }

    private func artist(_ name: String) -> Artist {
        Artist(id: UUID(), name: name, nameEn: nil, avatarUrl: nil,
               followersCount: 0, upcomingEventCount: 0, isFollowing: true)
    }

    func test_viewDidLoad_상태_채움() async {
        let repo = TestMyPageRepo()
        repo.myArtists = [artist("최유리"), artist("리도어")]
        repo.reviewableShows = [TestFixtures.event(title: "관람작")]
        let vm = makeVM(repo: repo)

        let loaded = expectation(description: "loaded"); loaded.assertForOverFulfill = false
        vm.onStateChanged = { if !vm.state.isLoading { loaded.fulfill() } }
        vm.viewDidLoad()
        await fulfillment(of: [loaded], timeout: 3)

        XCTAssertEqual(vm.state.myArtists.count, 2)
        XCTAssertEqual(vm.state.reviewableShows.count, 1)
    }

    func test_refreshMyArtists_목록_즉시반영() async {
        let repo = TestMyPageRepo()
        repo.myArtists = [artist("최유리"), artist("리도어")]
        let vm = makeVM(repo: repo)
        let loaded = expectation(description: "loaded"); loaded.assertForOverFulfill = false
        vm.onStateChanged = { if !vm.state.isLoading { loaded.fulfill() } }
        vm.viewDidLoad()
        await fulfillment(of: [loaded], timeout: 3)
        XCTAssertEqual(vm.state.myArtists.count, 2)

        // 언팔 후 서버 목록이 줄어든 상황 재현 → refresh가 즉시 반영해야 함(#6)
        repo.myArtists = [artist("리도어")]
        let refreshed = expectation(description: "refreshed")
        vm.onStateChanged = { if vm.state.myArtists.count == 1 { refreshed.fulfill() } }
        vm.refreshMyArtists()
        await fulfillment(of: [refreshed], timeout: 3)
        XCTAssertEqual(vm.state.myArtists.map { $0.name }, ["리도어"], "최유리 제거 즉시 반영")
    }
}
