import Foundation

enum MySection: Int, CaseIterable, Sendable {
    case myBookings
    case shortcuts
    case yearlyStats
    case statDetail   // 선택된 통계 카드에 맞춰 스왑되는 하단 상세 리스트
}

enum ShortcutItem: String, CaseIterable, Hashable, Sendable {
    case schedule = "예매 일정"
    case timetable = "타임테이블"

    var iconSystemName: String {
        switch self {
        case .schedule: return "calendar"
        case .timetable: return "tablecells"
        }
    }
}

enum MySectionItem: @preconcurrency Hashable, Sendable {
    case booking(Booking)
    case bookingEmpty
    case shortcut(ShortcutItem)
    case yearlySubtitle(MyStats)
    case yearlyChart(MyStats)
    case yearlyStatRow(MyStats)
    // statDetail 섹션 아이템 (선택 카드에 따라 스왑)
    case artistRanking(ArtistRankEntry)         // 최애: 아티스트 랭킹 행
    case statEvent(Event)                        // 최다관람/선호장르: 관람작 행
    case statSeeMore(StatCardKind)               // "더보기" 행 (최애=인라인확장 / 이벤트=EventList)
    case statEmpty(StatCardKind)                 // 해당 카드 데이터 0건 안내
}
