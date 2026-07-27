import XCTest
@testable import Articket

// 타임테이블 상세: 날짜 선택·공연 토글·currentDay 인덱스 안전 검증.
@MainActor
final class TimetableDetailViewModelTests: XCTestCase {

    private func perf(_ id: UUID = UUID()) -> Performance {
        Performance(id: id, startTime: "12:00", endTime: "13:00",
                    artistName: "A", stageName: "S", genre: "")
    }

    private func event(days: [TimetableDay]) -> TimetableEvent {
        TimetableEvent(id: UUID(), title: "페스", posterUrl: nil, dateRange: "", venueName: "홀", days: days)
    }

    func test_currentDay_잘못된_인덱스_안전() {
        let vm = TimetableDetailViewModel(event: event(days: [
            TimetableDay(dayNumber: 1, dateString: "D1", performances: []),
        ]))
        vm.selectDay(at: 99)   // 범위 밖 → 무시
        XCTAssertEqual(vm.state.selectedDayIndex, 0)
        XCTAssertEqual(vm.state.currentDay.dayNumber, 1)
    }

    func test_공연_토글_선택_해제() {
        let p = perf()
        let vm = TimetableDetailViewModel(event: event(days: [
            TimetableDay(dayNumber: 1, dateString: "D1", performances: [p]),
        ]))
        XCTAssertFalse(vm.isSelected(id: p.id))
        vm.togglePerformance(id: p.id)
        XCTAssertTrue(vm.isSelected(id: p.id))
        vm.togglePerformance(id: p.id)
        XCTAssertFalse(vm.isSelected(id: p.id))
    }

    func test_빈_days_currentDay_빈값() {
        let vm = TimetableDetailViewModel(event: event(days: []))
        XCTAssertEqual(vm.state.currentDay.dayNumber, 0, "days 비면 빈 day(크래시 없음)")
        XCTAssertTrue(vm.state.currentDay.performances.isEmpty)
    }
}
