import Foundation

/// 예매(`user_bookings`) ↔ 관람 집계의 단일 기준.
///
/// - 예매 현황: 예매됨 + 아직 안 끝남 (`!hasEnded`)
/// - 관람 수/통계/관람작: 예매됨 + 이미 끝남 (`hasEnded`)
/// - 종료 시각: `end_date` 우선, 없으면 `start_date` (다일 공연·단일 공연 공통)
///
/// status `active`/`completed`는 레거시 혼재 가능 — 조회는 날짜로 가르고,
/// 신규 `markBooked`만 `active`를 쓴다. (그릴링 2026-08-06)
enum BookingAttendance {

    /// 공연이 끝났는지. `endDate`가 없으면 `startDate`를 종료일로 본다.
    static func hasEnded(startDate: Date, endDate: Date?, now: Date = Date()) -> Bool {
        let effectiveEnd = endDate ?? startDate
        return effectiveEnd < now
    }

    /// 내 예매 현황에 남을 미래·진행 중 예매인지.
    static func isUpcomingOrOngoing(startDate: Date, endDate: Date?, now: Date = Date()) -> Bool {
        !hasEnded(startDate: startDate, endDate: endDate, now: now)
    }
}
