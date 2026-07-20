import Foundation

// MARK: - BookingIntentLocalStore
// 비로그인 상태에서 '예매하기'를 누른 기록을 로컬에 보관한다.
//
// 예매하기는 로그인 없이 쓸 수 있는 공개 기능이라, 서버에만 기록하면 비로그인 사용자는
// 확인 CTA 자체를 못 본다. 그래서 일단 UserDefaults에 쌓아두고 홈에서 그대로 노출하며,
// 사용자가 '예'로 답해 로그인하는 시점에 서버로 승격(promote)한다.

struct BookingIntentLocalStore {

    static let shared = BookingIntentLocalStore()

    private let key = "booking_intents_local"
    private let defaults = UserDefaults.standard

    private struct Entry: Codable {
        let eventId: UUID
        let eventTitle: String
        let posterUrl: String?
        let attemptedAt: Date
    }

    // MARK: - Read

    /// 만료되지 않은 기록만, 최신순
    func pendingIntents() -> [BookingIntent] {
        load()
            .map { BookingIntent(eventId: $0.eventId, eventTitle: $0.eventTitle,
                                 posterUrl: $0.posterUrl, attemptedAt: $0.attemptedAt) }
            .filter { !$0.isExpired }
            .sorted { $0.attemptedAt > $1.attemptedAt }
    }

    // MARK: - Write

    func record(eventId: UUID, eventTitle: String, posterUrl: String?) {
        var entries = load().filter { $0.eventId != eventId }   // 같은 공연 재시도는 최신 시각으로 갱신
        entries.append(Entry(eventId: eventId, eventTitle: eventTitle,
                             posterUrl: posterUrl, attemptedAt: Date()))
        // 만료분은 쓰기 시점에 함께 정리 — 별도 청소 트리거 없이 크기가 유지된다
        let now = Date()
        save(entries.filter { now.timeIntervalSince($0.attemptedAt) <= BookingIntent.expiry })
    }

    func remove(eventId: UUID) {
        save(load().filter { $0.eventId != eventId })
    }

    func removeAll() {
        defaults.removeObject(forKey: key)
    }

    // MARK: - Persistence

    private func load() -> [Entry] {
        guard let data = defaults.data(forKey: key),
              let entries = try? JSONDecoder().decode([Entry].self, from: data) else { return [] }
        return entries
    }

    private func save(_ entries: [Entry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: key)
    }
}
