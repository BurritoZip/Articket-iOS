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
            query: "select=id,display_name,last_visit_date&limit=1"
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
            lastVisitDate: row.lastVisitDate
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
        let query = "select=*,venues(name)&end_date=not.is.null&end_date=lt.\(nowISO)&order=end_date.desc&limit=5"
        let rows: [EventRow] = try await SupabaseService.shared.fetch(table: "events", query: query)
        return rows.map { $0.toEvent() }
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

    private func defaultProfile() -> UserProfile {
        UserProfile(
            displayName: "아티켓 유저",
            email: "",
            initial: "U",
            concertCount: 0,
            followingArtistCount: 0,
            lastVisitDate: nil
        )
    }
}
