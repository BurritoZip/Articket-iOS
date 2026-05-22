import Foundation
import Supabase

struct SupabaseMyPageRepository: MyPageRepositoryProtocol {

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private var nowISO: String { Self.isoFormatter.string(from: Date()) }

    func fetchUserProfile() async throws -> UserProfile {
        async let profileTask: [UserProfileRow] = SupabaseService.shared.fetch(
            table: "user_profiles",
            query: "select=id,display_name,last_visit_date,avatar_url&limit=1"
        )
        async let bookingTask: [CountRow] = SupabaseService.shared.fetch(
            table: "user_bookings",
            query: "select=id"
        )
        async let followTask: [CountRow] = SupabaseService.shared.fetch(
            table: "user_artist_followings",
            query: "select=artist_id"
        )

        let rows = try await profileTask
        let bookingCount = (try? await bookingTask)?.count ?? 0
        let followCount = (try? await followTask)?.count ?? 0

        let email = AuthService.shared.isLoggedIn
            ? (SupabaseService.shared.client.auth.currentSession?.user.email ?? "")
            : ""

        guard let row = rows.first else { return defaultProfile() }
        let name = row.displayName ?? "아티켓 유저"
        return UserProfile(
            displayName: name,
            email: email,
            initial: String(name.first ?? "U"),
            concertCount: bookingCount,
            followingArtistCount: followCount,
            lastVisitDate: row.lastVisitDate,
            avatarUrl: row.avatarUrl
        )
    }

    func updateDisplayName(_ name: String) async throws {
        guard let userId = AuthService.shared.currentUserId else { return }
        struct DisplayNameUpdate: Encodable {
            let displayName: String
            enum CodingKeys: String, CodingKey { case displayName = "display_name" }
        }
        try await SupabaseService.shared.client
            .from("user_profiles")
            .update(DisplayNameUpdate(displayName: name))
            .eq("id", value: userId.uuidString)
            .execute()
    }

    func fetchMyArtists() async throws -> [Artist] {
        let rows: [UserFollowingRow] = try await SupabaseService.shared.fetch(
            table: "user_artist_followings",
            query: "select=artist_id,artists(id,name,avatar_url,followers_count,upcoming_event_count)&limit=20"
        )
        let followed = rows.compactMap { $0.toArtist() }
        if !followed.isEmpty { return followed }

        // 팔로우 목록 없음(비로그인) — 인기 아티스트로 대체
        let popularRows: [ArtistRow] = try await SupabaseService.shared.fetch(
            table: "artists",
            query: "select=id,name,avatar_url,followers_count,upcoming_event_count&order=upcoming_event_count.desc&limit=6"
        )
        return popularRows.map { $0.toArtist() }
    }

    func fetchReviewableShows() async throws -> [Event] {
        guard AuthService.shared.isLoggedIn else { return [] }
        let query = "select=id,events(id,title,poster_url,start_date,end_date,venues(name))&order=booked_at.desc&limit=20"
        let rows: [UserBookingRow] = (try? await SupabaseService.shared.fetch(table: "user_bookings", query: query)) ?? []
        let now = Date()
        return rows.compactMap { row -> Event? in
            guard let ref = row.events,
                  let endDate = ref.endDate, endDate < now else { return nil }
            return Event(
                id: ref.id,
                title: ref.title,
                posterUrl: ref.posterUrl,
                startDate: ref.startDate,
                endDate: ref.endDate,
                venueName: ref.venues?.name ?? "",
                isInterested: false
            )
        }
    }

    func fetchYearlyShows() async throws -> [Event] {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())

        // 데이터가 있는 연도 우선 탐색 (당해 → 전년도)
        for year in [currentYear, currentYear - 1] {
            let yearStart = "\(year)-01-01T00:00:00Z"
            let endBound = year < currentYear ? "\(year + 1)-01-01T00:00:00Z" : nowISO
            let query = "select=*,venues(name)&start_date=gte.\(yearStart)&start_date=lt.\(endBound)&order=start_date.desc&limit=10"
            let rows: [EventRow] = try await SupabaseService.shared.fetch(table: "events", query: query)
            if !rows.isEmpty { return rows.map { $0.toEvent() } }
        }
        return []
    }

    func updateAvatar(imageData: Data) async throws -> String {
        guard let userId = AuthService.shared.currentUserId else {
            throw URLError(.userAuthenticationRequired)
        }
        let path = "avatars/\(userId.uuidString).jpg"
        let url = try await SupabaseService.shared.uploadToStorage(data: imageData, path: path, bucket: "avatars")
        struct AvatarUpdate: Encodable {
            let avatarUrl: String
            enum CodingKeys: String, CodingKey { case avatarUrl = "avatar_url" }
        }
        try await SupabaseService.shared.client
            .from("user_profiles")
            .update(AvatarUpdate(avatarUrl: url))
            .eq("id", value: userId.uuidString)
            .execute()
        return url
    }

    private func defaultProfile() -> UserProfile {
        UserProfile(
            displayName: "아티켓 유저",
            email: "",
            initial: "U",
            concertCount: 0,
            followingArtistCount: 0,
            lastVisitDate: nil,
            avatarUrl: nil
        )
    }
}
