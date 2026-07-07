import Foundation
import Supabase
import PostgREST

/// event_booking_link_issues 테이블에 이슈를 insert. 실패해도 사용자 흐름을 막지 않도록 조용히 무시.
struct SupabaseBookingIssueReporter: BookingIssueReporting {

    private struct IssueInsert: Encodable {
        let eventId: UUID
        let eventTitle: String
        let reason: String
        let platform: String
        let appUserId: UUID?
        enum CodingKeys: String, CodingKey {
            case eventId = "event_id"
            case eventTitle = "event_title"
            case reason
            case platform
            case appUserId = "app_user_id"
        }
    }

    func reportMissingBookingLink(eventId: UUID, eventTitle: String) async {
        let insert = IssueInsert(
            eventId: eventId,
            eventTitle: eventTitle,
            reason: "missing_booking_url",
            platform: "ios",
            appUserId: AuthService.shared.currentUserId
        )
        // 텔레메트리 성격 — 실패는 무시(예매 흐름/UX 영향 없음)
        try? await SupabaseService.shared.client
            .from("event_booking_link_issues")
            .insert(insert)
            .execute()
    }
}
