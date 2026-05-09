import Foundation

// MARK: - User Bookings

struct UserBookingRow: Decodable {
    let id: UUID
    let seat: String
    let deliveryType: String
    let bookedAt: Date
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
            imageAssetName: events?.posterUrl
        )
    }
}

// MARK: - User Profile

struct UserProfileRow: Decodable {
    let id: UUID
    let displayName: String?
    let lastVisitDate: Date?
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
