import XCTest
@testable import Articket

final class BreadcrumbTests: XCTestCase {
    func test_breadcrumb_필드_보관() {
        let t = Date(timeIntervalSince1970: 100)
        let b = Breadcrumb(time: t, kind: .api, screen: "Home",
                           message: "GET events", meta: ["status": "200"])
        XCTAssertEqual(b.kind, .api)
        XCTAssertEqual(b.screen, "Home")
        XCTAssertEqual(b.meta?["status"], "200")
    }

    func test_appErrorReport_screen_breadcrumbs_보관() {
        let b = Breadcrumb(time: Date(), kind: .screen, screen: "Home", message: "Home", meta: nil)
        let r = AppErrorReport(type: .http, message: "boom", screen: "Home", breadcrumbs: [b])
        XCTAssertEqual(r.screen, "Home")
        XCTAssertEqual(r.breadcrumbs?.count, 1)
    }
}
