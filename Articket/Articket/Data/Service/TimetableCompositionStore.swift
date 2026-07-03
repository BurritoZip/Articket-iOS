import Foundation

/// 사용자가 구성한 타임테이블(선택한 공연 + 직접 추가한 공연)을 이벤트별로 영속화.
/// Grid(편집) → Detail(리스트) → LockscreenGuide(카드) 가 모두 이 저장소를 공유해서
/// 한 화면에서 바꾼 구성이 다른 화면에 즉시 반영되도록 한다.
enum TimetableCompositionStore {

    private static let selectedKey = "TimetableSelectedPerformances"   // [eventId: [perfId]]
    private static let addedKey    = "TimetableAddedPerformances"      // [eventId: [Performance]]

    // MARK: - Selected performance ids

    static func selectedIds(eventId: UUID) -> Set<UUID> {
        let all = loadSelectedMap()
        let ids = all[eventId.uuidString] ?? []
        return Set(ids.compactMap { UUID(uuidString: $0) })
    }

    static func setSelectedIds(_ ids: Set<UUID>, eventId: UUID) {
        var all = loadSelectedMap()
        all[eventId.uuidString] = ids.map { $0.uuidString }
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: selectedKey)
        }
    }

    // MARK: - User-added performances

    static func added(eventId: UUID) -> [Performance] {
        let all = loadAddedMap()
        return all[eventId.uuidString] ?? []
    }

    static func setAdded(_ performances: [Performance], eventId: UUID) {
        var all = loadAddedMap()
        all[eventId.uuidString] = performances
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: addedKey)
        }
    }

    // MARK: - Private

    private static func loadSelectedMap() -> [String: [String]] {
        guard let data = UserDefaults.standard.data(forKey: selectedKey),
              let decoded = try? JSONDecoder().decode([String: [String]].self, from: data)
        else { return [:] }
        return decoded
    }

    private static func loadAddedMap() -> [String: [Performance]] {
        guard let data = UserDefaults.standard.data(forKey: addedKey),
              let decoded = try? JSONDecoder().decode([String: [Performance]].self, from: data)
        else { return [:] }
        return decoded
    }
}
