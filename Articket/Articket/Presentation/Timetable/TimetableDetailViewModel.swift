import Foundation

@MainActor
final class TimetableDetailViewModel {

    struct State {
        var event: TimetableEvent
        var selectedDayIndex: Int = 0
        var selectedPerformanceIds: Set<UUID> = []

        var currentDay: TimetableDay {
            event.days[selectedDayIndex]
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
