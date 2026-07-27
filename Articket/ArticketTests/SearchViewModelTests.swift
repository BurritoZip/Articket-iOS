import XCTest
@testable import Articket

// 최근 검색어 LRU(최대 10, 중복 최신화, 공백 무시) 검증.
// SearchViewModel이 UserDefaults.standard를 직접 쓰므로 각 테스트 전후로 키를 청소한다.
@MainActor
final class SearchViewModelTests: XCTestCase {

    private let key = "search.recentKeywords"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: key)
    }
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: key)
        super.tearDown()
    }

    func test_추가하면_최신이_맨앞() {
        let vm = SearchViewModel()
        vm.addKeyword("아이유")
        vm.addKeyword("검정치마")
        XCTAssertEqual(vm.state.recentKeywords, ["검정치마", "아이유"])
    }

    func test_중복추가시_기존제거후_맨앞으로() {
        let vm = SearchViewModel()
        vm.addKeyword("아이유")
        vm.addKeyword("검정치마")
        vm.addKeyword("아이유")
        XCTAssertEqual(vm.state.recentKeywords, ["아이유", "검정치마"], "중복은 하나만, 최신 위치로")
    }

    func test_최대10개_유지() {
        let vm = SearchViewModel()
        (1...12).forEach { vm.addKeyword("k\($0)") }
        XCTAssertEqual(vm.state.recentKeywords.count, 10)
        XCTAssertEqual(vm.state.recentKeywords.first, "k12", "가장 최근이 맨 앞")
        XCTAssertFalse(vm.state.recentKeywords.contains("k1"), "오래된 항목은 밀려남")
    }

    func test_공백은_무시() {
        let vm = SearchViewModel()
        vm.addKeyword("   ")
        vm.addKeyword("")
        XCTAssertTrue(vm.state.recentKeywords.isEmpty)
    }

    func test_삭제_및_전체삭제() {
        let vm = SearchViewModel()
        vm.addKeyword("a"); vm.addKeyword("b")
        vm.removeKeyword("a")
        XCTAssertEqual(vm.state.recentKeywords, ["b"])
        vm.clearAll()
        XCTAssertTrue(vm.state.recentKeywords.isEmpty)
    }

    func test_영속성_새인스턴스가_불러옴() {
        SearchViewModel().addKeyword("재즈")
        let reloaded = SearchViewModel()
        XCTAssertEqual(reloaded.state.recentKeywords, ["재즈"], "UserDefaults에서 복원")
    }
}
