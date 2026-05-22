import Foundation

enum InquiryStatus: String, Sendable {
    case pending = "pending"
    case answered = "answered"

    var displayText: String {
        switch self {
        case .pending: return "처리중"
        case .answered: return "답변완료"
        }
    }
}

struct Inquiry: Sendable {
    let id: UUID
    let title: String
    let content: String
    let status: InquiryStatus
    let createdAt: Date
    let answer: String?

    var formattedDate: String { Self.fmt.string(from: createdAt) }

    private static let fmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd"
        return f
    }()
}
