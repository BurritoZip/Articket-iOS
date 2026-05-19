import Foundation

private let kSelectedPerformancesKey = "TimetableSelectedPerformances"

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
        loadSavedSelections()
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
        saveSelections()
        onStateChanged?()
    }

    func isSelected(id: UUID) -> Bool {
        state.selectedPerformanceIds.contains(id)
    }

    private func saveSelections() {
        var all = loadAllSaved()
        all[state.event.id.uuidString] = state.selectedPerformanceIds.map { $0.uuidString }
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: kSelectedPerformancesKey)
        }
    }

    private func loadSavedSelections() {
        let all = loadAllSaved()
        let ids = all[state.event.id.uuidString] ?? []
        state.selectedPerformanceIds = Set(ids.compactMap { UUID(uuidString: $0) })
    }

    private func loadAllSaved() -> [String: [String]] {
        guard let data = UserDefaults.standard.data(forKey: kSelectedPerformancesKey),
              let decoded = try? JSONDecoder().decode([String: [String]].self, from: data)
        else { return [:] }
        return decoded
    }
}
