import Foundation

struct TimetableEvent: Hashable, Sendable {
    let id: UUID
    let title: String
    let posterUrl: String?
    let dateRange: String
    let venueName: String
    let days: [TimetableDay]
}

struct TimetableDay: Hashable, Sendable {
    let dayNumber: Int
    let dateString: String
    var performances: [Performance]
}

struct Performance: Hashable, Sendable, Codable {
    let id: UUID
    let startTime: String
    let endTime: String
    let artistName: String
    let stageName: String
    let genre: String
}
