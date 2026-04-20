import Foundation

enum CalendarEventColor: Sendable {
    case green
    case red
    case yellow
}

struct CalendarEvent: Hashable, Sendable {
    let id: UUID
    let date: Date
    let title: String
    let color: CalendarEventColor
}
