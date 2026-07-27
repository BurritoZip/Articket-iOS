import XCTest
@testable import Articket

final class SupabaseErrorReporterEncodeTests: XCTestCase {
    func test_screen_breadcrumbs_JSON_인코딩() throws {
        let b = Breadcrumb(time: Date(timeIntervalSince1970: 0), kind: .api,
                           screen: "Home", message: "GET events", meta: ["status": "200"])
        let report = AppErrorReport(type: .http, message: "boom",
                                    screen: "Home", breadcrumbs: [b])
        let data = try SupabaseErrorReporter.encodeForTest(report)
        let json = String(data: data, encoding: .utf8) ?? ""
        XCTAssertTrue(json.contains("\"screen\":\"Home\""))
        XCTAssertTrue(json.contains("breadcrumbs"))
        XCTAssertTrue(json.contains("GET events"))
    }
}
