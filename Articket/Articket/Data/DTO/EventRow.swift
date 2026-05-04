import Foundation

struct EventRow: Decodable {
    let id: UUID
    let title: String
    let artistId: UUID?
    let posterUrl: String?
    let startDate: Date
    let endDate: Date?
    let status: String
    let genre: String?
    let duration: String?
    let ageRestriction: String?
    let ticketOpenDate: Date?
    let ticketProvider: String?
    let noticeText: String?
    let isBanner: Bool
    let venues: VenueRef?
    let artists: ArtistRef?

    struct VenueRef: Decodable {
        let name: String
        let address: String?
        let phoneNumber: String?
    }

    struct ArtistRef: Decodable {
        let id: UUID
        let name: String
        let avatarUrl: String?
        let followersCount: Int
        let upcomingEventCount: Int
    }

    func toEvent(isInterested: Bool = false) -> Event {
        Event(
            id: id,
            title: title,
            imageAssetName: nil,
            posterUrl: posterUrl,
            startDate: startDate,
            endDate: endDate,
            venueName: venues?.name ?? "",
            isInterested: isInterested
        )
    }

    func toConcertDetail(reviews: [ConcertReview] = []) -> ConcertDetail {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        let start = dateFormatter.string(from: startDate)
        let dateRange = "\(start) ~ \(endDate.map { dateFormatter.string(from: $0) } ?? start)"

        let ticketOpenStr: String = {
            guard let d = ticketOpenDate else { return "" }
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy.MM.dd HH:mm"
            return fmt.string(from: d)
        }()

        let artist: Artist = {
            guard let a = artists else {
                return Artist(id: UUID(), name: "", avatarUrl: nil,
                              followersCount: 0, upcomingEventCount: 0, isFollowing: false)
            }
            return Artist(id: a.id, name: a.name, avatarUrl: a.avatarUrl,
                          followersCount: a.followersCount,
                          upcomingEventCount: a.upcomingEventCount,
                          isFollowing: false)
        }()

        let concertStatus: ConcertStatus = {
            switch status {
            case "on_sale": return .onSale
            case "ended":   return .ended
            default:        return .upcoming
            }
        }()

        return ConcertDetail(
            id: id,
            title: title,
            status: concertStatus,
            genre: genre ?? "",
            duration: duration ?? "",
            ageRestriction: ageRestriction ?? "",
            venueName: venues?.name ?? "",
            address: venues?.address ?? "",
            phoneNumber: venues?.phoneNumber ?? "",
            dateRange: dateRange,
            ticketOpenDate: ticketOpenStr,
            ticketProvider: ticketProvider ?? "",
            noticeText: noticeText ?? "",
            artist: artist,
            imageAssetName: posterUrl,
            reviews: reviews
        )
    }
}
