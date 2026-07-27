import XCTest
@testable import Articket

// 1:1 문의 게이팅(canSubmit)·제출·제출 후 초기화/새로고침 검증.
@MainActor
final class InquiryViewModelTests: XCTestCase {

    func test_제목내용_모두있어야_canSubmit() {
        let vm = InquiryViewModel(repository: StubInquiryRepo())
        XCTAssertFalse(vm.state.canSubmit)
        vm.setTitle("제목")
        XCTAssertFalse(vm.state.canSubmit, "내용 비면 불가")
        vm.setContent("내용")
        XCTAssertTrue(vm.state.canSubmit)
    }

    func test_공백만이면_canSubmit_불가() {
        let vm = InquiryViewModel(repository: StubInquiryRepo())
        vm.setTitle("   "); vm.setContent("  ")
        XCTAssertFalse(vm.state.canSubmit)
    }

    func test_조건미충족_submit_무시() {
        let repo = StubInquiryRepo()
        let vm = InquiryViewModel(repository: repo)
        vm.setTitle("제목")   // 내용 없음
        vm.submit()
        XCTAssertEqual(repo.submitCount, 0, "canSubmit 아니면 제출 호출 안 함")
    }

    func test_제출성공시_호출_초기화_콜백() async {
        let repo = StubInquiryRepo()
        let vm = InquiryViewModel(repository: repo)
        vm.setTitle("환불 문의"); vm.setContent("환불 가능한가요")

        let ok = expectation(description: "submitted")
        vm.onSubmitSuccess = { ok.fulfill() }
        vm.submit()
        await fulfillment(of: [ok], timeout: 3)

        XCTAssertEqual(repo.submitCount, 1)
        XCTAssertEqual(repo.lastSubmit?.title, "환불 문의")
        XCTAssertEqual(vm.state.title, "", "제출 후 입력 초기화")
        XCTAssertEqual(vm.state.content, "")
    }

    func test_제출실패시_onError() async {
        let repo = StubInquiryRepo(); repo.submitError = URLError(.notConnectedToInternet)
        let vm = InquiryViewModel(repository: repo)
        vm.setTitle("t"); vm.setContent("c")

        let errored = expectation(description: "error")
        vm.onError = { _ in errored.fulfill() }
        vm.submit()
        await fulfillment(of: [errored], timeout: 3)
    }
}

private final class StubInquiryRepo: InquiryRepositoryProtocol, @unchecked Sendable {
    var submitError: Error?
    private(set) var submitCount = 0
    private(set) var lastSubmit: (title: String, content: String)?

    func fetchMyInquiries() async throws -> [Inquiry] { [] }
    func submitInquiry(title: String, content: String) async throws {
        if let submitError { throw submitError }
        submitCount += 1
        lastSubmit = (title, content)
    }
}
