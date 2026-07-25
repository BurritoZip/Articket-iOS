import Foundation

enum MySection: Int, CaseIterable, Sendable {
    case myBookings
    case shortcuts
    case yearlyStats
    case artistRanking
}

enum ShortcutItem: String, CaseIterable, Hashable, Sendable {
    case schedule = "예매 일정"
    case timetable = "타임테이블"

    var iconSystemName: String {
        switch self {
        case .schedule: return "calendar"
        case .timetable: return "tablecells"
        }
    }
}

enum MySectionItem: @preconcurrency Hashable, Sendable {
    case booking(Booking)
    case bookingEmpty
    case shortcut(ShortcutItem)
    case yearlySubtitle(MyStats)
    case yearlyChart(MyStats)
    case yearlyStatRow(MyStats)
    case artistRanking(ArtistRankEntry)
}
