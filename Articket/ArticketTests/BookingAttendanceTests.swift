import XCTest
@testable import Articket

/// 예매/관람 날짜 경계 (BookingAttendance) 회귀 테스트.
/// end_date 우선, 없으면 start_date — 그릴링 합의(2026-08-06).
final class BookingAttendanceTests: XCTestCase {

    private let now = Date(timeIntervalSince1970: 1_775_000_000) // ~2026-04-30 UTC

    private func date(_ offsetDays: Int) -> Date {
        now.addingTimeInterval(TimeInterval(offsetDays) * 86_400)
    }

    func test_endDate지나면_관람() {
        XCTAssertTrue(BookingAttendance.hasEnded(
            startDate: date(-10), endDate: date(-1), now: now
        ))
        XCTAssertFalse(BookingAttendance.isUpcomingOrOngoing(
            startDate: date(-10), endDate: date(-1), now: now
        ))
    }

    func test_endDate아직이면_예매현황() {
        XCTAssertFalse(BookingAttendance.hasEnded(
            startDate: date(-1), endDate: date(3), now: now
        ))
        XCTAssertTrue(BookingAttendance.isUpcomingOrOngoing(
            startDate: date(-1), endDate: date(3), now: now
        ))
    }

    func test_endDate없으면_startDate기준() {
        // 시작 전이면 예매
        XCTAssertTrue(BookingAttendance.isUpcomingOrOngoing(
            startDate: date(2), endDate: nil, now: now
        ))
        // 시작 지났으면 관람
        XCTAssertTrue(BookingAttendance.hasEnded(
            startDate: date(-2), endDate: nil, now: now
        ))
    }

    func test_다일공연_중간에_아직_예매현황() {
        // 시작은 지났지만 end_date가 미래 → 관람 아님 (다일/페스티벌)
        XCTAssertTrue(BookingAttendance.isUpcomingOrOngoing(
            startDate: date(-2), endDate: date(2), now: now
        ))
    }

    func test_경계_endDate가_now와같으면_아직_안끝남() {
        // hasEnded는 `< now` — 동일 시각은 진행 중으로 본다
        XCTAssertFalse(BookingAttendance.hasEnded(
            startDate: date(-1), endDate: now, now: now
        ))
    }
}
