import Foundation

struct Event: Hashable, Sendable {
    let id: UUID
    let title: String
    let imageAssetName: String?   // local asset name; nil → placeholder
    let startDate: Date
    let endDate: Date
    let venueName: String
    let isInterested: Bool

    // MARK: - Computed

    var dDayString: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.startOfDay(for: startDate)
        if today > start { return "진행중" }
        let days = calendar.dateComponents([.day], from: today, to: start).day ?? 0
        return days == 0 ? "D-0" : "D-\(days)"
    }

    var dateRangeString: String {
        "\(Self.dateFormatter.string(from: startDate)) - \(Self.dateFormatter.string(from: endDate))"
    }

    private static let dateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy.MM.dd"
        return fmt
    }()
}
