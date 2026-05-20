import Foundation

struct TimetablePerformance: Hashable, Sendable {
    let id: UUID
    let eventId: UUID
    let artistId: UUID?
    let dayNumber: Int
    let dateString: String
    let startTime: String
    let endTime: String
    let artistName: String
    let stageName: String
    let genre: String

    var timeRangeString: String {
        endTime.isEmpty ? startTime : "\(startTime) - \(endTime)"
    }
}

struct TimetableDay: Hashable, Sendable {
    let dayNumber: Int
    let dateString: String
    let performances: [TimetablePerformance]
}
