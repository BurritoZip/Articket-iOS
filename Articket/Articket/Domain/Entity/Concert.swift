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
    let organizer: String
    let noticeText: String
    let artist: Artist
    let imageAssetName: String?
    let reviews: [ConcertDetailReview]
    let hasTimetable: Bool

    static let placeholder = ConcertDetail(
        id: UUID(), title: "", status: .upcoming,
        genre: "", duration: "", ageRestriction: "",
        venueName: "", address: "", phoneNumber: "",
        dateRange: "", ticketOpenDate: "", ticketCloseDate: "", ticketProvider: "",
        organizer: "", noticeText: "",
        artist: Artist(id: UUID(), name: "", avatarUrl: nil,
                       followersCount: 0, upcomingEventCount: 0, isFollowing: false),
        imageAssetName: nil, reviews: [], hasTimetable: false
    )
}
