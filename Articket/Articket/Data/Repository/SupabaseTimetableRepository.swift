import Foundation

struct SupabaseTimetableRepository: TimetableRepositoryProtocol {
    private let service = SupabaseService.shared

    func fetchTimetable(eventId: UUID) async throws -> [TimetablePerformance] {
        let rows: [TimetablePerformanceRow] = try await service.fetch(
            table: "timetable_performances",
            query: "select=id,event_id,artist_id,day_number,date_string,start_time,end_time,artist_name,stage_name,genre&event_id=eq.\(eventId.uuidString)&order=day_number.asc,start_time.asc&limit=300"
        )
        return rows.map { $0.toTimetablePerformance() }
    }
}
