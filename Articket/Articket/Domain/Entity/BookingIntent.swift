import Foundation

/// 외부 예매처로 나간 기록. 복귀 후 홈에서 "예매하셨나요?"로 되묻기 위한 최소 정보.
/// Hashable — Home의 diffable 스냅샷 아이템으로 직접 쓰인다
struct BookingIntent: Sendable, Hashable {
    let eventId: UUID
    let eventTitle: String
    let posterUrl: String?
    let attemptedAt: Date

    /// 미응답 intent가 유효한 기간 — 지난 건은 조회에서 제외한다.
    /// 오래된 질문이 홈 상단에 계속 남아 거슬리는 것을 막기 위함.
    static let expiry: TimeInterval = 7 * 24 * 60 * 60

    var isExpired: Bool {
        Date().timeIntervalSince(attemptedAt) > Self.expiry
    }
}

/// 사용자가 CTA에 답한 결과
enum BookingIntentOutcome: String, Sendable {
    case booked
    case skipped
}
