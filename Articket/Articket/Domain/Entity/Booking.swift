import Foundation

enum DeliveryType: Hashable, Sendable {
    case delivery
    case onsite
}

enum BookingStatus: String, Sendable {
    case active = "active"
    case cancelled = "cancelled"
    case completed = "completed"
}

struct Booking: Hashable, Sendable {
    let id: UUID          // user_bookings 행 id
    let eventId: UUID     // 공연(events) id — 예매 셀 탭 시 공연 상세 진입에 사용
    let title: String
    let venueName: String
    let date: Date
    let seat: String
    let deliveryType: DeliveryType
    let imageAssetName: String?
    let status: BookingStatus

    var dDayString: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let eventDay = calendar.startOfDay(for: date)
        if today > eventDay { return "진행중" }
        let days = calendar.dateComponents([.day], from: today, to: eventDay).day ?? 0
        return days == 0 ? "D-0" : "D-\(days)"
    }

    var formattedDate: String {
        Self.dateFormatter.string(from: date)
    }

    private static let dateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy.MM.dd"
        return fmt
    }()
}
