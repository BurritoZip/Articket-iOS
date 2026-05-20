import Foundation

struct SupabaseTimetableRepository: TimetableRepositoryProtocol {

    private let service = SupabaseService.shared

    func fetchTimetableEvents() async throws -> [TimetableEvent] {
        print("[Timetable] ① 이벤트 조회 시작 (has_timetable=true)")

        let eventRows: [TimetableEventRow] = try await service.fetch(
            table: "events",
            query: "select=id,title,poster_url,start_date,end_date,venues(name)&has_timetable=eq.true&order=start_date.asc"
        )
        print("[Timetable] ② 이벤트 조회 완료 — \(eventRows.count)건")
        for row in eventRows {
            print("[Timetable]   • \(row.title) (id: \(row.id))")
        }

        guard !eventRows.isEmpty else {
            print("[Timetable] ③ has_timetable=true 이벤트 없음 → 빈 배열 반환")
            return []
        }

        let ids = eventRows.map { $0.id.uuidString.lowercased() }.joined(separator: ",")
        print("[Timetable] ③ 공연 조회 시작 — event_id in (\(ids))")

        let perfRows: [TimetablePerformanceRow] = try await service.fetch(
            table: "timetable_performances",
            query: "select=*&event_id=in.(\(ids))&order=day_number.asc,start_time.asc"
        )
        print("[Timetable] ④ 공연 조회 완료 — \(perfRows.count)건")
        for perf in perfRows {
            print("[Timetable]   • DAY\(perf.dayNumber) \(perf.startTime)~\(perf.endTime) \(perf.artistName) @ \(perf.stageName)")
        }

        let byEvent = Dictionary(grouping: perfRows, by: \.eventId)
        let result = eventRows.map { eventRow in
            eventRow.toTimetableEvent(performances: byEvent[eventRow.id] ?? [])
        }
        print("[Timetable] ⑤ 변환 완료 — TimetableEvent \(result.count)건, 총 Day 수: \(result.flatMap(\.days).count)")
        return result
    }
}
