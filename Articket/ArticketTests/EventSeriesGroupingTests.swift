import XCTest
@testable import Articket

// 회차 공연 묶기(EventSeriesGrouping) 순수 로직 검증.
final class EventSeriesGroupingTests: XCTestCase {

    private func ev(_ title: String, _ venue: String, _ m: Int, _ d: Int) -> Event {
        TestFixtures.event(title: title, venue: venue, start: TestFixtures.date(2026, m, d))
    }

    func test_같은공연_다른날짜_2회차_대표1건으로_접힘() {
        let result = EventSeriesGrouping.group([
            ev("아무개 콘서트 Day 1", "올림픽홀", 8, 1),
            ev("아무개 콘서트 Day 2", "올림픽홀", 8, 2),
        ])
        XCTAssertEqual(result.count, 1, "회차는 대표 1건으로 접힘")
        XCTAssertEqual(result[0].sessionCount, 2)
        XCTAssertEqual(result[0].startDate, TestFixtures.date(2026, 8, 1), "대표는 가장 이른 시작일")
    }

    func test_공연장다르면_전국투어로_각자유지() {
        let result = EventSeriesGrouping.group([
            ev("아무개 콘서트", "서울올림픽홀", 8, 1),
            ev("아무개 콘서트", "부산벡스코", 8, 5),
        ])
        XCTAssertEqual(result.count, 2, "공연장이 다르면 회차로 안 묶임")
    }

    func test_같은날_중복은_회차아님_한건만() {
        let id = UUID()
        let a = TestFixtures.event(id: id, title: "아무개 콘서트", venue: "올림픽홀", start: TestFixtures.date(2026, 8, 1))
        let result = EventSeriesGrouping.group([a, a])
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].sessionCount, 1, "같은 날 중복은 회차가 아님")
    }

    func test_공연장없으면_그룹핑제외() {
        let result = EventSeriesGrouping.group([
            ev("아무개 콘서트 Day 1", "", 8, 1),
            ev("아무개 콘서트 Day 2", "", 8, 2),
        ])
        XCTAssertEqual(result.count, 2, "공연장명 없으면 서로 다른 공연 취급(안 묶음)")
    }

    func test_등장순서_보존() {
        let result = EventSeriesGrouping.group([
            ev("비 공연", "홍대클럽", 9, 1),
            ev("아무개 콘서트 Day 1", "올림픽홀", 8, 1),
            ev("아무개 콘서트 Day 2", "올림픽홀", 8, 2),
            ev("가 페스티벌", "잠실", 10, 1),
        ])
        XCTAssertEqual(result.map { $0.title }.first, "비 공연", "원래 등장 순서 보존")
        XCTAssertEqual(result.count, 3)
    }
}
