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
    let ticketCloseDate: Date?
    let ticketProvider: String?
    let organizer: String?
    let noticeText: String?
    let isBanner: Bool
    let hasTimetable: Bool?
    // 스코어링 엔진 컬럼 (옵셔널 — 미산출 시 null)
    let popularityScore: Double?
    let trendingScore: Double?
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
            isInterested: isInterested,
            hasTimetable: hasTimetable ?? false,
            popularityScore: popularityScore,
            trendingScore: trendingScore
        )
    }

    func toConcertDetail(reviews: [ConcertDetailReview] = []) -> ConcertDetail {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        let start = dateFormatter.string(from: startDate)
        let dateRange = "\(start) ~ \(endDate.map { dateFormatter.string(from: $0) } ?? start)"

        let dtFmt: DateFormatter = {
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy.MM.dd HH:mm"
            return fmt
        }()

        let ticketOpenStr  = ticketOpenDate.map  { dtFmt.string(from: $0) } ?? ""
        let ticketCloseStr = ticketCloseDate.map { dtFmt.string(from: $0) } ?? ""

        let artist: Artist = {
            guard let a = artists else {
                return Artist(id: UUID(), name: "", nameEn: nil, avatarUrl: nil,
                              followersCount: 0, upcomingEventCount: 0, isFollowing: false)
            }
            return Artist(id: a.id, name: a.name, nameEn: a.nameEn, avatarUrl: a.avatarUrl,
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
            ticketCloseDate: ticketCloseStr,
            ticketProvider: ticketProvider ?? "",
            organizer: organizer ?? "",
            noticeText: noticeText ?? "",
            artist: artist,
            imageAssetName: posterUrl,
            reviews: reviews,
            hasTimetable: hasTimetable ?? false
        )
    }
}
