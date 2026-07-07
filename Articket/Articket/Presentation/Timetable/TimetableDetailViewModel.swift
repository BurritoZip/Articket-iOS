import Foundation

@MainActor
final class TimetableDetailViewModel {

    struct State {
        var event: TimetableEvent
        var selectedDayIndex: Int = 0
        var selectedPerformanceIds: Set<UUID> = []

        var currentDay: TimetableDay {
            // days가 비었거나 인덱스 범위 밖이면 빈 day 반환 (인덱스 크래시 방지)
            guard event.days.indices.contains(selectedDayIndex) else {
                return TimetableDay(dayNumber: 0, dateString: "", performances: [])
            }
            return event.days[selectedDayIndex]
        }
    }

    private(set) var state: State
    var onStateChanged: (() -> Void)?

    init(event: TimetableEvent) {
        self.state = State(event: event)
        state.selectedPerformanceIds = TimetableCompositionStore.selectedIds(eventId: event.id)
    }

    /// 그리드에서 편집 후 돌아왔을 때 최신 구성 반영 (VC viewWillAppear 에서 호출)
    func reload() {
        state.selectedPerformanceIds = TimetableCompositionStore.selectedIds(eventId: state.event.id)
        onStateChanged?()
    }

    func selectDay(at index: Int) {
        guard index < state.event.days.count else { return }
        state.selectedDayIndex = index
        onStateChanged?()
    }

    func togglePerformance(id: UUID) {
        if state.selectedPerformanceIds.contains(id) {
            state.selectedPerformanceIds.remove(id)
        } else {
            state.selectedPerformanceIds.insert(id)
        }
        TimetableCompositionStore.setSelectedIds(state.selectedPerformanceIds, eventId: state.event.id)
        onStateChanged?()
    }

    func isSelected(id: UUID) -> Bool {
        state.selectedPerformanceIds.contains(id)
    }
}
