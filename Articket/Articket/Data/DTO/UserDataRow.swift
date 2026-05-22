import Foundation

// MARK: - User Bookings

struct UserBookingRow: Decodable {
    let id: UUID
    let seat: String
    let deliveryType: String
    let bookedAt: Date
    let status: String?
    let events: EventRef?

    struct EventRef: Decodable {
        let id: UUID
        let title: String
        let posterUrl: String?
        let startDate: Date
        let endDate: Date?
        let venues: VenueRef?

        struct VenueRef: Decodable {
            let name: String
        }
    }

    func toBooking() -> Booking {
        Booking(
            id: id,
            title: events?.title ?? "",
            venueName: events?.venues?.name ?? "",
            date: events?.startDate ?? bookedAt,
            seat: seat,
            deliveryType: deliveryType == "delivery" ? .delivery : .onsite,
            imageAssetName: events?.posterUrl,
            status: BookingStatus(rawValue: status ?? "active") ?? .active
        )
    }
}

// MARK: - User Profile

struct UserProfileRow: Decodable {
    let id: UUID
    let displayName: String?
    let lastVisitDate: Date?
    let avatarUrl: String?
}

// MARK: - User Artist Following

struct UserFollowingRow: Decodable {
    let artistId: UUID
    let artists: ArtistRef?

    struct ArtistRef: Decodable {
        let id: UUID
        let name: String
        let avatarUrl: String?
        let followersCount: Int
        let upcomingEventCount: Int
    }

    func toArtist() -> Artist? {
        guard let a = artists else { return nil }
        return Artist(
            id: a.id,
            name: a.name,
            avatarUrl: a.avatarUrl,
            followersCount: a.followersCount,
            upcomingEventCount: a.upcomingEventCount,
            isFollowing: true
        )
    }
}

// MARK: - Booking Stats (user_bookings JOIN events — 사용자 실관람 통계 전용)

struct BookingStatsRow: Decodable {
    let id: UUID
    let events: EventStatsRef?

    struct EventStatsRef: Decodable {
        let startDate: Date
        let genre: String?
    }
}

// MARK: - Event Stats (legacy — 현재 미사용, 삭제 후보)

struct EventStatsRow: Decodable {
    let id: UUID
    let startDate: Date
    let genre: String?
}

// MARK: - User Interested Events

struct InterestedEventRow: Decodable {
    let eventId: UUID
    let events: EventRef?

    struct EventRef: Decodable {
        let id: UUID
        let title: String
        let posterUrl: String?
        let startDate: Date
        let endDate: Date?
        let venues: VenueRef?

        struct VenueRef: Decodable {
            let name: String
        }
    }

    func toEvent() -> Event? {
        guard let e = events else { return nil }
        return Event(
            id: e.id,
            title: e.title,
            posterUrl: e.posterUrl,
            startDate: e.startDate,
            endDate: e.endDate,
            venueName: e.venues?.name ?? "",
            isInterested: true
        )
    }
}

// MARK: - Booking Artist (user_bookings JOIN events JOIN artists — 아티스트 관람 랭킹용)

struct BookingArtistRow: Decodable {
    let events: EventRef?

    struct EventRef: Decodable {
        let artists: ArtistRef?

        struct ArtistRef: Decodable {
            let id: UUID
            let name: String
            let avatarUrl: String?
        }
    }
}

// MARK: - User Artist Following ID only (팔로우 여부 확인용)

struct UserFollowingIdRow: Decodable {
    let artistId: UUID
}

// MARK: - User Interested Event ID only (관심 여부 확인용)

struct UserInterestedIdRow: Decodable {
    let eventId: UUID
}

// MARK: - Count-only row (단순 개수 집계용 — array.count로 사용)

struct CountRow: Decodable {
    private enum CodingKeys: CodingKey {}
    init(from decoder: Decoder) throws {}
}

// MARK: - User Profile Insert/Upsert

struct UserProfileUpsert: Encodable {
    let id: UUID
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        if let name = displayName { try container.encode(name, forKey: .displayName) }
    }
}

// MARK: - User Artist Following Insert

struct ArtistFollowInsert: Encodable {
    let userId: UUID
    let artistId: UUID

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case artistId = "artist_id"
    }
}

// MARK: - User Interested Event Insert

struct InterestedEventInsert: Encodable {
    let userId: UUID
    let eventId: UUID

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case eventId = "event_id"
    }
}

// MARK: - Concert Reviews

struct ReviewRow: Decodable {
    let id: UUID
    let title: String
    let starCount: Int
    let content: String
    let username: String
    let createdAt: Date
    let events: EventRef?

    struct EventRef: Decodable {
        let id: UUID
        let title: String
        let posterUrl: String?
    }

    func toReview() -> ConcertReview? {
        guard let e = events else { return nil }
        return ConcertReview(
            id: id,
            eventId: e.id,
            eventTitle: e.title,
            eventPosterUrl: e.posterUrl,
            title: title,
            starCount: starCount,
            content: content,
            username: username,
            createdAt: createdAt
        )
    }
}

struct ReviewInsert: Encodable {
    let userId: UUID
    let eventId: UUID
    let title: String
    let starCount: Int
    let content: String
    let username: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case eventId = "event_id"
        case title
        case starCount = "star_count"
        case content
        case username
    }
}

// MARK: - Inquiries

struct InquiryRow: Decodable {
    let id: UUID
    let title: String
    let content: String
    let status: String
    let createdAt: Date
    let answer: String?

    func toInquiry() -> Inquiry {
        Inquiry(
            id: id,
            title: title,
            content: content,
            status: InquiryStatus(rawValue: status) ?? .pending,
            createdAt: createdAt,
            answer: answer
        )
    }
}

struct InquiryInsert: Encodable {
    let userId: UUID
    let title: String
    let content: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case title
        case content
    }
}
