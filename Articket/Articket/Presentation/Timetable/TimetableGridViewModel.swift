import Foundation

private func totalMinutes(_ timeString: String) -> Int {
    let parts = timeString.split(separator: ":")
    let h = Int(parts.first ?? "0") ?? 0
    let m = parts.count > 1 ? (Int(parts[1]) ?? 0) : 0
    return h * 60 + m
}

@MainActor
final class TimetableGridViewModel {

    struct State {
        var event: TimetableEvent
        var selectedDayIndex: Int = 0
        var selectedPerformanceIds: Set<UUID>
        var userAddedPerformances: [Performance] = []

        var currentDay: TimetableDay {
            // days가 비었거나 인덱스 범위 밖이면 빈 day 반환 (인덱스 크래시 방지)
            guard event.days.indices.contains(selectedDayIndex) else {
                return TimetableDay(dayNumber: 0, dateString: "", performances: [])
            }
            return event.days[selectedDayIndex]
        }

        // 그리드에는 선택된 서버 공연 + 직접 추가 공연만 표시
        var allPerformances: [Performance] {
            let selected = currentDay.performances.filter { selectedPerformanceIds.contains($0.id) }
            return selected + userAddedPerformances
        }

        // + 버튼 시트에서 전체 서버 공연 목록 표시용
        var allServerPerformances: [Performance] { currentDay.performances }

        var stageNames: [String] {
            var seen = Set<String>()
            var ordered: [String] = []
            for p in allPerformances {
                if seen.insert(p.stageName).inserted { ordered.append(p.stageName) }
            }
            return ordered.isEmpty ? ["STAGE A"] : ordered
        }

        var startHour: Int {
            allPerformances.compactMap { Int($0.startTime.prefix(2)) }.min() ?? 11
        }

        var endHour: Int {
            let hours = allPerformances.compactMap { Int($0.endTime.prefix(2)) }
            return (hours.max() ?? 22) + 1
        }
    }

    private(set) var state: State
    var onStateChanged: (() -> Void)?

    init(event: TimetableEvent, selectedPerformanceIds: Set<UUID>) {
        var selected = selectedPerformanceIds
        let savedAdded = TimetableCompositionStore.added(eventId: event.id)
        // 직접 추가 공연은 항상 선택 상태로 복원
        savedAdded.forEach { selected.insert($0.id) }
        self.state = State(
            event: event,
            selectedPerformanceIds: selected,
            userAddedPerformances: savedAdded
        )
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
        persist()
        onStateChanged?()
    }

    func isSelected(id: UUID) -> Bool {
        state.selectedPerformanceIds.contains(id)
    }

    func addUserPerformance(_ performance: Performance) {
        state.userAddedPerformances.append(performance)
        state.selectedPerformanceIds.insert(performance.id)
        persist()
        onStateChanged?()
    }

    func deletePerformance(id: UUID) {
        state.selectedPerformanceIds.remove(id)
        state.userAddedPerformances.removeAll { $0.id == id }
        persist()
        onStateChanged?()
    }

    /// 선택/추가 구성을 공유 저장소에 저장 → Detail·Lockscreen 이 즉시 반영
    private func persist() {
        TimetableCompositionStore.setSelectedIds(state.selectedPerformanceIds, eventId: state.event.id)
        TimetableCompositionStore.setAdded(state.userAddedPerformances, eventId: state.event.id)
    }

    func performance(atHour hour: Int, stage: String) -> Performance? {
        state.allPerformances.first { p in
            guard p.stageName == stage else { return false }
            let start = totalMinutes(p.startTime)
            let end = totalMinutes(p.endTime)
            let slotStart = hour * 60
            let slotEnd = (hour + 1) * 60
            return start < slotEnd && end > slotStart
        }
    }

    func isFirstHour(_ hour: Int, of performance: Performance) -> Bool {
        (Int(performance.startTime.prefix(2)) ?? hour) == hour
    }

    func durationString(of performance: Performance) -> String {
        let dur = totalMinutes(performance.endTime) - totalMinutes(performance.startTime)
        return "\(performance.startTime) - \(performance.endTime) (\(dur)')"
    }

    func subtitleString(of performance: Performance) -> String {
        let dur = totalMinutes(performance.endTime) - totalMinutes(performance.startTime)
        return "\(performance.stageName) · \(dur)분 · \(performance.startTime) ~ \(performance.endTime)"
    }
}
