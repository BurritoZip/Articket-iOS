import Foundation

struct TimetablePerformanceRow: Decodable {
    let id: UUID
    let eventId: UUID
    let artistId: UUID?
    let dayNumber: Int
    let dateString: String
    let startTime: String
    let endTime: String
    let artistName: String
    let stageName: String
    let genre: String?

    func toTimetablePerformance() -> TimetablePerformance {
        TimetablePerformance(
            id: id,
            eventId: eventId,
            artistId: artistId,
            dayNumber: dayNumber,
            dateString: dateString,
            startTime: startTime,
            endTime: endTime,
            artistName: artistName,
            stageName: stageName,
            genre: genre ?? ""
        )
    }
}
