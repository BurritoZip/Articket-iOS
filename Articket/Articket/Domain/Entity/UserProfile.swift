import Foundation

struct UserProfile: Sendable {
    let displayName: String
    let email: String
    let initial: String
    let concertCount: Int
    let followingArtistCount: Int
    let lastVisitDate: Date?
    let avatarUrl: String?

    var lastVisitDateString: String {
        guard let date = lastVisitDate else { return "-" }
        return Self.formatter.string(from: date)
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM.dd"
        return f
    }()
}
