import Foundation

enum ConcertStatus: String, Sendable {
    case onSale = "예매 중"
    case upcoming = "예매 예정"
    case ongoing = "공연 중"       // admin: 공연 기간 중(start<=now<=end). 2026-05 add_ongoing_status
    case ended = "판매종료"
}

/// 예매처 선택지 한 건. 같은 공연이 여러 예매처(인터파크·YES24 등)에서 동시 판매될 때
/// 각 예매처가 하나의 BookingLink. Admin이 events.booking_links(JSONB)로 정제해 내려준다.
/// 배열 순서 = 표시 우선순위.
struct BookingLink: Sendable, Equatable {
    let provider: String   // 예매처 키 (interpark/yes24/melon/yanolja/klook)
    let label: String      // 표시명 (인터파크/YES24/멜론티켓/놀(야놀자)/클룩)
    let url: URL
}

/// 회차 한 건 — 같은 공연·공연장의 특정 날짜 공연. 회차별 예매처가 다를 수 있어 각자 링크를 가진다.
struct ConcertSession: Sendable, Equatable {
    let eventId: UUID
    let startDate: Date
    let dateLabel: String        // 표시용 "2026.08.05"
    let bookingUrl: URL?
    let bookingLinks: [BookingLink]
}

struct ConcertDetailReview: Sendable {
    let id: UUID
    let starCount: Int
    let title: String
    let username: String
    let date: String
    let content: String
}

struct ConcertDetail: Sendable {
    let id: UUID
    let title: String
    /// 서버가 내려준 예매 상태. 로딩 전(placeholder)이거나 서버 값이 미지의 문자열이면 nil —
    /// nil일 때 UI는 상태 배지·안내문을 그리지 않는다. (임의 기본값을 넣으면 로딩 중
    /// '예매 예정'이 실데이터인 척 노출됐다가 '예매 중'으로 튀는 문제가 생김)
    let status: ConcertStatus?
    let genre: String
    let duration: String
    let ageRestriction: String
    let venueName: String
    let address: String
    let phoneNumber: String
    let dateRange: String
    let ticketOpenDate: String
    let ticketCloseDate: String
    let ticketProvider: String
    /// 외부 예매 사이트 URL (없으면 예매하기 버튼 비활성/숨김). 대표 예매처 1곳.
    let bookingUrl: URL?
    /// 예매처 선택지 전체. 2곳 이상이면 예매하기 탭 시 선택 시트를 띄운다.
    /// 비어 있으면 bookingUrl 단일 경로로 폴백.
    let bookingLinks: [BookingLink]
    let organizer: String
    let noticeText: String
    /// 대표 아티스트 (호환용 — 첫 출연자)
    let artist: Artist
    /// 출연 아티스트 전체 (페스티벌/합동공연 다중). 단일 공연은 [artist].
    let lineupArtists: [Artist]
    let imageAssetName: String?
    let reviews: [ConcertDetailReview]
    let hasTimetable: Bool
    /// 회차 목록(자신 포함). 1건이면 단일 공연. 2건+ 이면 상세에서 회차 선택 UI 표시.
    let sessions: [ConcertSession]

    static let placeholder = ConcertDetail(
        id: UUID(), title: "", status: nil,
        genre: "", duration: "", ageRestriction: "",
        venueName: "", address: "", phoneNumber: "",
        dateRange: "", ticketOpenDate: "", ticketCloseDate: "", ticketProvider: "",
        bookingUrl: nil,
        bookingLinks: [],
        organizer: "", noticeText: "",
        artist: Artist(id: UUID(), name: "", nameEn: nil, avatarUrl: nil,
                       followersCount: 0, upcomingEventCount: 0, isFollowing: false),
        lineupArtists: [],
        imageAssetName: nil, reviews: [], hasTimetable: false,
        sessions: []
    )
}
