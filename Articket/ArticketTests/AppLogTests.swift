import XCTest
@testable import Articket

final class AppLogTests: XCTestCase {
    private func makeLog() -> AppLog { AppLog(clock: { Date(timeIntervalSince1970: 0) }) }

    func test_screen이_currentScreen_갱신하고_흔적남김() {
        let log = makeLog()
        log.screen("HomeViewController")
        XCTAssertEqual(log.currentScreen, "HomeViewController")
        XCTAssertEqual(log.snapshot().last?.kind, .screen)
        XCTAssertEqual(log.snapshot().last?.message, "HomeViewController")
    }

    func test_api_흔적_메타포함() {
        let log = makeLog()
        log.screen("EditProfile")
        log.api(endpoint: "avatars/x.jpg", method: "PUT", status: 403, ms: 120, error: "RLS")
        let last = log.snapshot().last
        XCTAssertEqual(last?.kind, .api)
        XCTAssertEqual(last?.screen, "EditProfile", "발생 시점 현재 화면이 붙는다")
        XCTAssertEqual(last?.meta?["status"], "403")
        XCTAssertEqual(last?.meta?["method"], "PUT")
    }

    func test_링버퍼_최대20_최신우선() {
        let log = makeLog()
        for i in 1...25 { log.action("a\(i)") }
        let snap = log.snapshot()
        XCTAssertEqual(snap.count, 20)
        XCTAssertEqual(snap.last?.message, "a25", "가장 최근이 마지막")
        XCTAssertFalse(snap.contains { $0.message == "a5" }, "오래된 건 밀려남")
    }

    func test_reset_비움() {
        let log = makeLog()
        log.action("x"); log.reset()
        XCTAssertTrue(log.snapshot().isEmpty)
        XCTAssertNil(log.currentScreen)
    }
}
