import Foundation
import UserNotifications

// MARK: - TicketOpenNotifier
// 티켓 오픈 시각에 로컬 알림을 예약/해제한다. 서버 푸시(APNs) 없이 온디바이스로 완결 —
// 기기 로컬이라 기기 교체 시 따라가지 않지만 "티켓 오픈 리마인더" 용도엔 충분.

enum TicketOpenNotifier {

    private static func identifier(_ eventId: UUID) -> String { "ticketopen-\(eventId.uuidString)" }

    /// 이 공연에 예약된 알림이 있는지
    static func isScheduled(eventId: UUID) async -> Bool {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return requests.contains { $0.identifier == identifier(eventId) }
    }

    /// 예약 해제
    static func cancel(eventId: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier(eventId)])
    }

    /// 알림 토글.
    /// - 반환 `true`: 새로 설정됨 / `false`: 해제됨 / `nil`: 설정 불가(권한 거부·과거 시각)
    static func toggle(eventId: UUID, title: String, date: Date) async -> Bool? {
        if await isScheduled(eventId: eventId) {
            cancel(eventId: eventId)
            return false
        }

        // 이미 지난 시각이면 예약 의미 없음
        guard date > Date() else { return nil }

        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else { return nil }

        let content = UNMutableNotificationContent()
        content.title = "티켓 오픈 알림"
        content.body = "\(title) 티켓팅이 곧 열려요!"
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: identifier(eventId), content: content, trigger: trigger)
        do {
            try await center.add(request)
            return true
        } catch {
            return nil
        }
    }
}
