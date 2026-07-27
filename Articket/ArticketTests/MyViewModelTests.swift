import XCTest
@testable import Articket

// PLAY 통계 로직(선택 카드 스왑·관람작 필터·top3·더보기 노출·최애 확장) 검증.
// #7(빈 통계 카드 탭) 주변 로직의 회귀 방어.
@MainActor
final class MyViewModelTests: XCTestCase {

    private func loadedVM(stats: MyStats, rankings: [ArtistRankEntry], yearly: [Event])
        async -> MyViewModel {
        let booking = TestBookingRepo()
        booking.stats = stats
        booking.rankings = rankings
        let myPage = TestMyPageRepo()
        myPage.yearlyShows = yearly
        let useCase = FetchMyDataUseCase(repository: booking, myPageRepository: myPage)
        let vm = MyViewModel(fetchMyDataUseCase: useCase)
        let loaded = expectation(description: "loaded"); loaded.assertForOverFulfill = false
        vm.onStateChanged = { if !vm.state.isLoading { loaded.fulfill() } }
        vm.viewDidLoad()
        await fulfillment(of: [loaded], timeout: 3)
        return vm
    }

    private func stats(topMonth: Int) -> MyStats {
        MyStats(year: 2026, monthlyViewCounts: Array(repeating: 1, count: 12),
                topMonth: topMonth, topGenre: "페스티벌", topArtist: "", totalCount: 12)
    }

    func test_최다관람_선택시_해당월_관람작만_필터() async {
        let july = (1...4).map { TestFixtures.event(title: "7월\($0)", start: TestFixtures.date(2026, 7, $0)) }
        let aug = [TestFixtures.event(title: "8월", start: TestFixtures.date(2026, 8, 1))]
        let vm = await loadedVM(stats: stats(topMonth: 7), rankings: [], yearly: july + aug)

        vm.selectStatCard(.topView)
        XCTAssertEqual(vm.statEventsAll.count, 4, "topMonth(7월) 관람작만")
        XCTAssertEqual(vm.statEventRows.count, 3, "상단 노출은 top3")
        XCTAssertTrue(vm.showsStatSeeMore, "3건 초과면 더보기 노출")
    }

    func test_선호장르_선택시_장르로_필터() async {
        let fest = TestFixtures.event(title: "페스A", start: TestFixtures.date(2026, 3, 1), genre: "페스티벌")
        let jazz = TestFixtures.event(title: "재즈A", start: TestFixtures.date(2026, 3, 2), genre: "재즈")
        let vm = await loadedVM(stats: stats(topMonth: 3), rankings: [], yearly: [fest, jazz])

        vm.selectStatCard(.topGenre)
        XCTAssertEqual(vm.statEventsAll.count, 1, "topGenre(페스티벌)만")
        XCTAssertEqual(vm.statEventsAll.first?.title, "페스A")
    }

    func test_최애_top3_노출_및_더보기_확장() async {
        let ranks = (1...5).map { TestFixtures.ranking($0, name: "아티스트\($0)") }
        let vm = await loadedVM(stats: stats(topMonth: 1), rankings: ranks, yearly: [])
        // 기본 선택 = 최애(topArtist)
        XCTAssertEqual(vm.statArtistRows.count, 3, "확장 전 top3")
        XCTAssertTrue(vm.showsStatSeeMore, "3건 초과면 더보기")
        vm.toggleStatExpansion()
        XCTAssertEqual(vm.statArtistRows.count, 5, "확장하면 전체")
    }

    func test_데이터_없으면_빈결과_크래시없음() async {
        let vm = await loadedVM(stats: stats(topMonth: 5), rankings: [], yearly: [])
        vm.selectStatCard(.topView)
        XCTAssertTrue(vm.statEventRows.isEmpty, "관람작 없으면 빈 배열")
        XCTAssertFalse(vm.showsStatSeeMore)
        vm.selectStatCard(.topGenre)
        XCTAssertTrue(vm.statEventsAll.isEmpty)
    }
}
