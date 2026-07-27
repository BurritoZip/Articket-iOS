import XCTest
@testable import Articket

// 후기 작성 게이팅(canSubmit)·제출·관람작 preselect 검증.
@MainActor
final class WriteReviewViewModelTests: XCTestCase {

    private func loadedVM(shows: [Event], preselect: UUID? = nil)
        async -> (WriteReviewViewModel, TestReviewRepo) {
        let myPage = TestMyPageRepo(); myPage.reviewableShows = shows
        let review = TestReviewRepo()
        let vm = WriteReviewViewModel(myPageRepository: myPage, reviewRepository: review,
                                      preselectedEventId: preselect)
        let loaded = expectation(description: "loaded"); loaded.assertForOverFulfill = false
        vm.onStateChanged = { if !vm.state.isLoading { loaded.fulfill() } }
        vm.viewDidLoad()
        await fulfillment(of: [loaded], timeout: 3)
        return (vm, review)
    }

    func test_모든필드_채워야_canSubmit() async {
        let e = TestFixtures.event(title: "공연A")
        let (vm, _) = await loadedVM(shows: [e])
        XCTAssertNotNil(vm.state.selectedEvent, "관람작 있으면 첫 항목 자동 선택")
        XCTAssertFalse(vm.state.canSubmit, "별점/제목/내용 전이면 불가")
        vm.setStarCount(5)
        vm.setReviewTitle("좋았어요")
        XCTAssertFalse(vm.state.canSubmit, "내용 비면 아직 불가")
        vm.setContent("정말 좋은 공연")
        XCTAssertTrue(vm.state.canSubmit, "모두 채우면 가능")
    }

    func test_canSubmit_아니면_submit_무시() async {
        let (vm, review) = await loadedVM(shows: [TestFixtures.event()])
        vm.setStarCount(0)   // 미충족
        vm.submit()
        XCTAssertEqual(review.writeCount, 0, "조건 미충족이면 writeReview 호출 안 함")
    }

    func test_제출_성공시_writeReview_호출_및_콜백() async {
        let e = TestFixtures.event(title: "공연B")
        let (vm, review) = await loadedVM(shows: [e])
        vm.setStarCount(4); vm.setReviewTitle("굿"); vm.setContent("내용")

        let ok = expectation(description: "submit success")
        vm.onSubmitSuccess = { ok.fulfill() }
        vm.submit()
        await fulfillment(of: [ok], timeout: 3)

        XCTAssertEqual(review.writeCount, 1)
        XCTAssertEqual(review.lastWrite?.eventId, e.id)
        XCTAssertEqual(review.lastWrite?.star, 4)
    }

    func test_preselect가_관람작에_있으면_그것을_선택() async {
        let e1 = TestFixtures.event(title: "1"); let e2 = TestFixtures.event(title: "2")
        let (vm, _) = await loadedVM(shows: [e1, e2], preselect: e2.id)
        XCTAssertEqual(vm.state.selectedEvent?.id, e2.id)
    }

    func test_제출실패시_onError() async {
        let e = TestFixtures.event()
        let myPage = TestMyPageRepo(); myPage.reviewableShows = [e]
        let review = TestReviewRepo(); review.writeError = URLError(.timedOut)
        let vm = WriteReviewViewModel(myPageRepository: myPage, reviewRepository: review)
        let loaded = expectation(description: "loaded"); loaded.assertForOverFulfill = false
        vm.onStateChanged = { if !vm.state.isLoading { loaded.fulfill() } }
        vm.viewDidLoad()
        await fulfillment(of: [loaded], timeout: 3)

        vm.setStarCount(5); vm.setReviewTitle("t"); vm.setContent("c")
        let errored = expectation(description: "error")
        vm.onError = { _ in errored.fulfill() }
        vm.submit()
        await fulfillment(of: [errored], timeout: 3)
    }
}
