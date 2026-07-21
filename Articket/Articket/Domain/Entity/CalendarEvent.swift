import Foundation

enum CalendarEventColor: Sendable {
    case green
    case red
    case yellow
}

enum TicketSaleStatus: Hashable, Sendable {
    case onSale
    case upcoming
    case ongoing
    case ended

    var label: String {
        switch self {
        case .onSale:   return "예매 중"
        case .upcoming: return "예매 예정"
        case .ongoing:  return "공연 중"
        case .ended:    return "예매 종료"
        }
    }
}

struct CalendarEvent: Hashable, Sendable {
    let id: UUID
    let date: Date
    let title: String
    let color: CalendarEventColor

    let concertTitle: String
    let concertDate: String
    let venueName: String
    let bookingPlatform: String
    let ticketOpenDate: String
    let ticketPrices: [String]
    let bookingStatus: TicketSaleStatus
    let eventCategory: String
}
