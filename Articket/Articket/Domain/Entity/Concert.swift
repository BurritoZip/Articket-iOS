import Foundation

enum ConcertStatus: String, Sendable {
    case onSale = "예매 중"
    case upcoming = "예매 예정"
    case ended = "판매종료"
}

struct ConcertReview: Sendable {
    let id: UUID
    let starCount: Int     // 1–5
    let title: String
    let username: String   // "bogyu****"
    let date: String       // "2025.11.26"
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
    let ticketProvider: String
    let noticeText: String
    let artist: Artist
    let imageAssetName: String?
    let reviews: [ConcertReview]

    static let placeholder = ConcertDetail(
        id: UUID(), title: "", status: .upcoming,
        genre: "", duration: "", ageRestriction: "",
        venueName: "", address: "", phoneNumber: "",
        dateRange: "", ticketOpenDate: "", ticketProvider: "",
        noticeText: "",
        artist: Artist(id: UUID(), name: "", avatarUrl: nil,
                       followersCount: 0, upcomingEventCount: 0, isFollowing: false),
        imageAssetName: nil, reviews: []
    )
}
