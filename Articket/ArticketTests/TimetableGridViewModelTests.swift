import XCTest
@testable import Articket

// 타임테이블 그리드 순수 로직(시간 범위·스테이지·공연 조회·선택 토글·표시 문자열) 검증.
@MainActor
final class TimetableGridViewModelTests: XCTestCase {

    private func perf(_ start: String, _ end: String, artist: String = "A", stage: String = "STAGE A") -> Performance {
        Performance(id: UUID(), startTime: start, endTime: end, artistName: artist, stageName: stage, genre: "")
    }

    private func event(_ performances: [Performance]) -> TimetableEvent {
        TimetableEvent(id: UUID(), title: "페스", posterUrl: nil, dateRange: "",
                       venueName: "홀",
                       days: [TimetableDay(dayNumber: 1, dateString: "D1", performances: performances)])
    }

    func test_선택된_공연만_그리드에_노출() {
        let p1 = perf("12:00", "13:00"); let p2 = perf("14:00", "15:00")
        let vm = TimetableGridViewModel(event: event([p1, p2]), selectedPerformanceIds: [p1.id])
        XCTAssertEqual(vm.state.allPerformances.map { $0.id }, [p1.id], "선택된 것만 표시")
        XCTAssertEqual(vm.state.allServerPerformances.count, 2, "시트용 전체 목록은 2개")
    }

    func test_시작_끝시간_범위_계산() {
        let vm = TimetableGridViewModel(
            event: event([perf("12:30", "13:00"), perf("18:00", "19:30")]),
            selectedPerformanceIds: []
        )
        // allPerformances 비면 기본값(11 / 23). 선택해서 채움:
        let p1 = perf("12:30", "13:00", stage: "A"); let p2 = perf("18:00", "19:30", stage: "B")
        let vm2 = TimetableGridViewModel(event: event([p1, p2]), selectedPerformanceIds: [p1.id, p2.id])
        XCTAssertEqual(vm2.state.startHour, 12, "가장 이른 시작 시(hour)")
        XCTAssertEqual(vm2.state.endHour, 20, "가장 늦은 종료 시 +1")
        XCTAssertEqual(vm.state.startHour, 11, "빈 경우 기본 11")
    }

    func test_스테이지_순서_중복제거() {
        let a = perf("12:00", "13:00", stage: "STAGE A")
        let b = perf("12:00", "13:00", stage: "STAGE B")
        let a2 = perf("14:00", "15:00", stage: "STAGE A")
        let vm = TimetableGridViewModel(event: event([a, b, a2]),
                                        selectedPerformanceIds: [a.id, b.id, a2.id])
        XCTAssertEqual(vm.state.stageNames, ["STAGE A", "STAGE B"], "등장순서·중복제거")
    }

    func test_시간슬롯으로_공연조회() {
        let p = perf("12:00", "13:30", stage: "STAGE A")
        let vm = TimetableGridViewModel(event: event([p]), selectedPerformanceIds: [p.id])
        XCTAssertEqual(vm.performance(atHour: 12, stage: "STAGE A")?.id, p.id, "12시 슬롯에 걸침")
        XCTAssertNotNil(vm.performance(atHour: 13, stage: "STAGE A"), "13:30까지라 13시 슬롯도 걸침")
        XCTAssertNil(vm.performance(atHour: 14, stage: "STAGE A"), "14시엔 없음")
        XCTAssertNil(vm.performance(atHour: 12, stage: "STAGE B"), "다른 스테이지엔 없음")
    }

    func test_토글로_선택_추가삭제() {
        let p = perf("12:00", "13:00")
        let vm = TimetableGridViewModel(event: event([p]), selectedPerformanceIds: [])
        XCTAssertFalse(vm.isSelected(id: p.id))
        vm.togglePerformance(id: p.id)
        XCTAssertTrue(vm.isSelected(id: p.id))
        vm.togglePerformance(id: p.id)
        XCTAssertFalse(vm.isSelected(id: p.id))
    }

    func test_duration_subtitle_문자열() {
        let p = perf("12:00", "13:30", artist: "밴드", stage: "메인")
        let vm = TimetableGridViewModel(event: event([p]), selectedPerformanceIds: [p.id])
        XCTAssertEqual(vm.durationString(of: p), "12:00 - 13:30 (90')")
        XCTAssertEqual(vm.subtitleString(of: p), "메인 · 90분 · 12:00 ~ 13:30")
    }

    func test_잘못된_날짜인덱스_안전() {
        let vm = TimetableGridViewModel(event: event([perf("12:00", "13:00")]), selectedPerformanceIds: [])
        vm.selectDay(at: 99)   // 범위 밖 → 무시
        XCTAssertEqual(vm.state.selectedDayIndex, 0, "범위 밖 인덱스는 무시")
        XCTAssertEqual(vm.state.currentDay.dayNumber, 1, "currentDay는 유효 day")
    }
}
