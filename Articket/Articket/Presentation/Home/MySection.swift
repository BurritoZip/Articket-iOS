import Foundation

enum MySection: Int, CaseIterable, Sendable {
    case myBookings
    case shortcuts
    case yearlyStats
    case artistRanking
}

enum ShortcutItem: String, CaseIterable, Hashable, Sendable {
    case myTickets = "내 티켓"
    case schedule = "예매 일정"
    case seat = "좌석확인"

    var iconSystemName: String {
        switch self {
        case .myTickets: return "ticket"
        case .schedule: return "calendar"
        case .seat: return "chair.lounge"
        }
    }
}

enum MySectionItem: @preconcurrency Hashable, Sendable {
    case booking(Booking)
    case shortcut(ShortcutItem)
    case yearlySubtitle(MyStats)
    case yearlyChart(MyStats)
    case yearlyStatRow(MyStats)
    case artistRanking(ArtistRankEntry)
}
