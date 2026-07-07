import Foundation

/// 예매 링크 미연결 등 예매 관련 이슈를 백엔드에 기록 — Admin 콘솔에서 확인.
protocol BookingIssueReporting: Sendable {
    /// booking_url 이 없는 공연에서 사용자가 예매하기를 시도했을 때 기록
    func reportMissingBookingLink(eventId: UUID, eventTitle: String) async
}
