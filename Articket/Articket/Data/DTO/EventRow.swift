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
    let bookingUrl: String?          // events.booking_url — 예매하기 버튼이 여는 외부 예매 사이트 URL
    let organizer: String?
    let noticeText: String?
    let isBanner: Bool
    let hasTimetable: Bool?
    // 스코어링 엔진 컬럼 (옵셔널 — 미산출 시 null)
    let popularityScore: Double?
    let trendingScore: Double?
    let venues: VenueRef?
    let artists: ArtistRef?
    // event_artists 조인 (다중 출연 — 페스티벌/합동공연). 없으면 단일 artists로 폴백.
    let eventArtists: [EventArtistRef]?

    struct VenueRef: Decodable {
        let name: String
        let address: String?
        let phoneNumber: String?
    }

    struct ArtistRef: Decodable {
        let id: UUID
        let name: String
        let nameEn: String?
        let avatarUrl: String?
        let followersCount: Int
        let upcomingEventCount: Int
    }

    struct EventArtistRef: Decodable {
        let displayOrder: Int?
        let role: String?
        let artists: ArtistRef? // 중첩 조인된 artists 행
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

        func toArtist(_ a: ArtistRef) -> Artist {
            Artist(id: a.id, name: a.name, nameEn: a.nameEn, avatarUrl: a.avatarUrl,
                   followersCount: a.followersCount,
                   upcomingEventCount: a.upcomingEventCount, isFollowing: false)
        }

        // 다중 출연 우선(display_order 정렬), 없으면 단일 artists 폴백
        let lineup: [Artist] = {
            let multi = (eventArtists ?? [])
                .sorted { ($0.displayOrder ?? 0) < ($1.displayOrder ?? 0) }
                .compactMap { $0.artists }
                .map(toArtist)
            if !multi.isEmpty { return multi }
            if let a = artists { return [toArtist(a)] }
            return []
        }()

        let artist: Artist = lineup.first
            ?? Artist(id: UUID(), name: "", nameEn: nil, avatarUrl: nil,
                      followersCount: 0, upcomingEventCount: 0, isFollowing: false)

        // 미지의 status 문자열을 .upcoming으로 뭉개면 '예매 예정'이 잘못 표기된다 → nil로 두고 UI에서 숨김
        let concertStatus: ConcertStatus? = {
            switch status {
            case "on_sale":  return .onSale
            case "upcoming": return .upcoming
            case "ended":    return .ended
            default:         return nil
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
            bookingUrl: bookingUrl.flatMap { URL(string: $0) },
            organizer: organizer ?? "",
            noticeText: noticeText ?? "",
            artist: artist,
            lineupArtists: lineup,
            imageAssetName: posterUrl,
            reviews: reviews,
            hasTimetable: hasTimetable ?? false
        )
    }
}
