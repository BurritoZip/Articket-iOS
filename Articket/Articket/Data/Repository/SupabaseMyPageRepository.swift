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
        async let bookingTask: [BookingDateCountRow] = SupabaseService.shared.fetch(
            table: "user_bookings",
            // 관람 공연 수 = 끝난 예매만 (미래 예매 즉시 카운트 금지)
            query: "select=id,events(start_date,end_date)&status=in.(active,completed)"
        )
        async let followTask: [CountRow] = SupabaseService.shared.fetch(
            table: "user_artist_followings",
            query: "select=artist_id"
        )

        let rows = try await profileTask
        let bookingRows = (try? await bookingTask) ?? []
        let now = Date()
        let bookingCount = bookingRows.filter { row in
            guard let event = row.events else { return false }
            return BookingAttendance.hasEnded(
                startDate: event.startDate, endDate: event.endDate, now: now
            )
        }.count
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

    func fetchMyReviewCount() async throws -> Int {
        guard AuthService.shared.isLoggedIn else { return 0 }
        // RLS 로 현재 유저 후기만 반환됨 (ReviewRepository.fetchMyReviews 와 동일 테이블).
        // id 만 select 해서 행 수만 센다 (bookingCount 패턴과 동일).
        let rows: [CountRow] = (try? await SupabaseService.shared.fetch(
            table: "concert_reviews",
            query: "select=id"
        )) ?? []
        return rows.count
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
        // limit을 크게: booked_at 최근이 미래 예매면 끝난 공연이 잘려 후기/통계가 비는 회귀 방지
        let query = "select=id,events(id,title,poster_url,start_date,end_date,venues(name))&status=in.(active,completed)&order=booked_at.desc&limit=200"
        let rows: [UserBookingRow] = (try? await SupabaseService.shared.fetch(table: "user_bookings", query: query)) ?? []
        let now = Date()
        return rows.compactMap { row -> Event? in
            guard let ref = row.events,
                  BookingAttendance.hasEnded(
                    startDate: ref.startDate, endDate: ref.endDate, now: now
                  ) else { return nil }
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
        guard AuthService.shared.isLoggedIn else { return [] }
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let now = Date()

        let query = "select=id,events(id,title,poster_url,start_date,end_date,venues(name))&status=in.(active,completed)&order=booked_at.desc&limit=500"
        let rows: [UserBookingRow] = (try? await SupabaseService.shared.fetch(table: "user_bookings", query: query)) ?? []

        func toEvent(_ ref: UserBookingRow.EventRef) -> Event {
            Event(id: ref.id, title: ref.title, posterUrl: ref.posterUrl,
                  startDate: ref.startDate, endDate: ref.endDate,
                  venueName: ref.venues?.name ?? "", isInterested: false)
        }

        // 올해 이미 관람한 공연 (end_date ?? start_date < now && 시작일 올해)
        let thisYear = rows.compactMap { row -> Event? in
            guard let ref = row.events,
                  BookingAttendance.hasEnded(
                    startDate: ref.startDate, endDate: ref.endDate, now: now
                  ),
                  calendar.component(.year, from: ref.startDate) == currentYear else { return nil }
            return toEvent(ref)
        }
        if !thisYear.isEmpty { return thisYear }

        // 올해 관람 없으면 전년도
        return rows.compactMap { row -> Event? in
            guard let ref = row.events,
                  BookingAttendance.hasEnded(
                    startDate: ref.startDate, endDate: ref.endDate, now: now
                  ),
                  calendar.component(.year, from: ref.startDate) == currentYear - 1 else { return nil }
            return toEvent(ref)
        }
    }

    func updateAvatar(imageData: Data) async throws -> String {
        guard let userId = AuthService.shared.currentUserId else {
            throw URLError(.userAuthenticationRequired)
        }
        // 오브젝트 키 첫 세그먼트 = 유저 uid → storage RLS (foldername[1] = auth.uid()) 통과.
        // Swift `UUID.uuidString`은 대문자인데 Postgres `auth.uid()::text`는 소문자라
        // 그대로 쓰면 RLS 문자열 비교가 어긋나 403(권한 오류)이 난다 → 반드시 소문자로.
        let path = "\(userId.uuidString.lowercased())/avatar.jpg"
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
