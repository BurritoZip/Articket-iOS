import Foundation

// events 테이블 — timetable_performances는 별도 쿼리로 분리 (FK 조인 미요구)
struct TimetableEventRow: Decodable {
    let id: UUID
    let title: String
    let posterUrl: String?
    let startDate: Date
    let endDate: Date?
    let venues: VenueRef?

    struct VenueRef: Decodable {
        let name: String
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd"
        return f
    }()

    func toTimetableEvent(performances: [TimetablePerformanceRow]) -> TimetableEvent {
        let start = Self.dateFormatter.string(from: startDate)
        let end = endDate.map { Self.dateFormatter.string(from: $0) } ?? start

        let grouped = Dictionary(grouping: performances, by: \.dayNumber)
        let days: [TimetableDay] = grouped.keys.sorted().compactMap { dayNum in
            guard let rows = grouped[dayNum] else { return nil }
            let dateString = rows.first?.dateString ?? ""
            let perfs = rows
                .sorted { $0.startTime < $1.startTime }
                .map { row in
                    Performance(
                        id: row.id,
                        startTime: row.startTime,
                        endTime: row.endTime,
                        artistName: row.artistName,
                        stageName: row.stageName,
                        genre: row.genre
                    )
                }
            return TimetableDay(dayNumber: dayNum, dateString: dateString, performances: perfs)
        }

        return TimetableEvent(
            id: id,
            title: title,
            posterUrl: posterUrl,
            dateRange: "\(start) ~ \(end)",
            venueName: venues?.name ?? "",
            days: days
        )
    }
}

struct TimetablePerformanceRow: Decodable {
    let id: UUID
    let eventId: UUID
    let dayNumber: Int
    let dateString: String
    let startTime: String
    let endTime: String
    let artistName: String
    let stageName: String
    let genre: String
}
