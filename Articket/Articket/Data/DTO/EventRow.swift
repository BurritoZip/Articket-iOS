import Foundation

/// 목록성 events 쿼리 공통 필터 — admin soft-hide(events.is_hidden) 존중.
/// admin 이 병합 흡수·불량·미분류·포스터결손 등으로 숨긴 이벤트를 앱 목록에서 제외한다.
/// **새 목록 쿼리를 추가하면 반드시 이 상수를 query 에 포함할 것**(누락 시 숨긴 공연이 노출됨).
/// 단일 상세 조회(by id)·관심목록은 제외(딥링크·유저 의도 보존).
let kVisibleEventsFilter = "&is_hidden=eq.false"

struct EventRow: Decodable {
    let id: UUID
    let title: String
    let artistId: UUID?
    let venueId: UUID?               // events.venue_id — 회차(형제) 매칭용
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
    let bookingLinks: [BookingLinkRow]?  // events.booking_links(JSONB) — 예매처 선택지 [{provider,label,url}]
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

    struct BookingLinkRow: Decodable {
        let provider: String?
        let label: String?
        let url: String?
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
            genre: genre,
            popularityScore: popularityScore,
            trendingScore: trendingScore
        )
    }

    /// events.booking_links(JSONB) → 파싱된 예매처 선택지 (형제 회차·상세 공용)
    var parsedBookingLinks: [BookingLink] {
        (bookingLinks ?? []).compactMap { row in
            guard let provider = row.provider, let label = row.label,
                  let urlStr = row.url, let url = URL(string: urlStr) else { return nil }
            return BookingLink(provider: provider, label: label, url: url)
        }
    }

    var parsedBookingUrl: URL? { bookingUrl.flatMap { URL(string: $0) } }

    func toConcertDetail(
        reviews: [ConcertDetailReview] = [],
        sessions: [ConcertSession] = []
    ) -> ConcertDetail {
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

        // admin status enum: upcoming/on_sale/ongoing/ended (2026-05 ongoing 추가).
        // 미지의 값은 .upcoming으로 뭉개지 않고 nil로 두어 UI에서 배지를 숨긴다.
        let concertStatus: ConcertStatus? = {
            switch status {
            case "on_sale":  return .onSale
            case "upcoming": return .upcoming
            case "ongoing":  return .ongoing
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
            bookingUrl: parsedBookingUrl,
            bookingLinks: parsedBookingLinks,
            organizer: organizer ?? "",
            noticeText: noticeText ?? "",
            artist: artist,
            lineupArtists: lineup,
            imageAssetName: posterUrl,
            reviews: reviews,
            hasTimetable: hasTimetable ?? false,
            sessions: sessions
        )
    }
}
