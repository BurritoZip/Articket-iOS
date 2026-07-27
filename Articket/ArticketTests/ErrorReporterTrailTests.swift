import XCTest
@testable import Articket

private final class SpyReporter: ErrorReporting, @unchecked Sendable {
    var reports: [AppErrorReport] = []
    func report(_ report: AppErrorReport) async { reports.append(report) }
}

final class ErrorReporterTrailTests: XCTestCase {
    func test_capture시_현재화면과_trail이_첨부된다() async {
        let log = AppLog(clock: { Date(timeIntervalSince1970: 0) })
        log.screen("EditProfileViewController")
        log.action("사진저장")
        let spy = SpyReporter()
        let sut = ErrorReporter(reporter: spy, appLog: log)

        sut.capture(.http, message: "storage 403", domain: "test")
        // capture는 내부 Task로 report → 잠깐 대기
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(spy.reports.first?.screen, "EditProfileViewController")
        XCTAssertEqual(spy.reports.first?.breadcrumbs?.count, 2)
        XCTAssertEqual(spy.reports.first?.breadcrumbs?.last?.message, "사진저장")
    }
}
