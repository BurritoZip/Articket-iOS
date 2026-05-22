import Foundation

struct ConcertReview: Sendable {
    let id: UUID
    let eventId: UUID
    let eventTitle: String
    let eventPosterUrl: String?
    let title: String
    let starCount: Int
    let content: String
    let username: String
    let createdAt: Date

    var formattedDate: String { Self.fmt.string(from: createdAt) }

    private static let fmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd"
        return f
    }()
}
