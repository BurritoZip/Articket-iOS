import Foundation

/// 회차 공연 묶기 — 같은 공연·공연장의 다른 날짜(회차)를 대표 1건으로 접는다.
///
/// 판정 키: 정규화 제목(Day/일차/회차 마커 제거) + 공연장명. 날짜가 2개 이상 다를 때만 회차로 접고,
/// 대표는 가장 이른 시작일. 전국투어(공연장 다름)는 키가 갈려 각자 유지된다.
/// 목록 계층(FetchHomeEventsUseCase / 검색 / 더보기)에서 [Event] 에 적용한다.
enum EventSeriesGrouping {

    /// 회차 판정 키. 공연장명이 없으면 nil(그룹핑 대상 제외 — 서로 다른 공연이 뭉치는 것 방지).
    static func seriesKey(_ e: Event) -> String? {
        seriesKey(title: e.title, venueName: e.venueName)
    }

    /// 제목·공연장 문자열 기반 키 (EventRow/상세 형제 매칭 공용).
    static func seriesKey(title: String, venueName: String) -> String? {
        let venue = venueName.replacingOccurrences(
            of: "\\s", with: "", options: .regularExpression
        ).lowercased()
        if venue.isEmpty { return nil }

        var t = title.lowercased()
        for pattern in [
            "day\\s*\\d+",        // Day 1, day2
            "\\d+\\s*일\\s*차",   // 1일차, 2 일 차
            "\\d+\\s*회\\s*차",   // 1회차
            "[\\[(]\\s*\\d+\\s*차\\s*[\\])]", // [1차]
        ] {
            t = t.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }
        t = t.replacingOccurrences(of: "[^a-z0-9가-힣]", with: "", options: .regularExpression)
        if t.count < 4 { return nil } // 너무 짧으면 오매칭 위험 — 그룹핑 안 함
        return "\(t)|\(venue)"
    }

    /// 같은 회차끼리 접어 대표 1건 + 회차 정보를 담은 배열 반환. 원래 등장 순서 보존.
    static func group(_ events: [Event]) -> [Event] {
        var buckets: [String: [Event]] = [:]

        // 자리 보존을 위해 각 위치를 (key?, event)로 훑는다
        var sequence: [(key: String?, event: Event)] = []
        for e in events {
            let k = seriesKey(e)
            sequence.append((k, e))
            if let k { buckets[k, default: []].append(e) }
        }

        var emitted = Set<String>()
        var result: [Event] = []
        for (k, e) in sequence {
            guard let k else { result.append(e); continue } // 키 없음 → 그대로
            if emitted.contains(k) { continue }             // 이미 대표로 방출됨
            emitted.insert(k)
            let g = buckets[k]!.sorted { $0.startDate < $1.startDate }
            let distinctDays = Set(g.map {
                Calendar.current.startOfDay(for: $0.startDate)
            })
            if g.count > 1, distinctDays.count > 1 {
                // 회차 — 대표(가장 이른) + 회차 정보
                result.append(g.first!.withSessionInfo(
                    count: g.count, startDates: g.map { $0.startDate }
                ))
            } else {
                // 회차 아님(중복이거나 단일) — 원본 순서의 첫 등장 그대로
                result.append(e)
            }
        }
        return result
    }
}
