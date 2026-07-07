import Foundation

enum ConcertStatus: String, Sendable {
    case onSale = "예매 중"
    case upcoming = "예매 예정"
    case ended = "판매종료"
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
    let status: ConcertStatus
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
    /// 외부 예매 사이트 URL (없으면 예매하기 버튼 비활성/숨김)
    let bookingUrl: URL?
    let organizer: String
    let noticeText: String
    /// 대표 아티스트 (호환용 — 첫 출연자)
    let artist: Artist
    /// 출연 아티스트 전체 (페스티벌/합동공연 다중). 단일 공연은 [artist].
    let lineupArtists: [Artist]
    let imageAssetName: String?
    let reviews: [ConcertDetailReview]
    let hasTimetable: Bool

    static let placeholder = ConcertDetail(
        id: UUID(), title: "", status: .upcoming,
        genre: "", duration: "", ageRestriction: "",
        venueName: "", address: "", phoneNumber: "",
        dateRange: "", ticketOpenDate: "", ticketCloseDate: "", ticketProvider: "",
        bookingUrl: nil,
        organizer: "", noticeText: "",
        artist: Artist(id: UUID(), name: "", nameEn: nil, avatarUrl: nil,
                       followersCount: 0, upcomingEventCount: 0, isFollowing: false),
        lineupArtists: [],
        imageAssetName: nil, reviews: [], hasTimetable: false
    )
}
