import Foundation
import Supabase

struct SupabaseArtistDetailRepository: ArtistDetailRepositoryProtocol {

    private let service = SupabaseService.shared

    func fetchArtistDetail(artistId: UUID) async throws -> ArtistDetail {
        let artists: [ArtistRow] = try await service.fetch(
            table: "artists",
            query: "select=*&id=eq.\(artistId.uuidString)&limit=1"
        )
        guard let artistRow = artists.first else { throw SupabaseError.httpError(404) }

        async let pastConcertRows: [PastConcertRow] = (try? service.fetch(
            table: "artist_past_concerts",
            query: "select=*&artist_id=eq.\(artistId.uuidString)&order=sort_order.asc"
        )) ?? []

        async let albumRows: [AlbumRow] = (try? service.fetch(
            table: "artist_albums",
            query: "select=*&artist_id=eq.\(artistId.uuidString)&order=sort_order.asc"
        )) ?? []

        async let musicVideoRows: [MusicVideoRow] = (try? service.fetch(
            table: "artist_music_videos",
            query: "select=*&artist_id=eq.\(artistId.uuidString)&order=sort_order.asc"
        )) ?? []

        let (pastConcerts, albums, musicVideos) = try await (pastConcertRows, albumRows, musicVideoRows)

        let upcomingTicketing: UpcomingTicketing? = try await fetchUpcomingTicketing(artistId: artistId)

        return artistRow.toArtistDetail(
            upcomingTicketing: upcomingTicketing,
            pastConcerts: pastConcerts.map { $0.toPastConcert() },
            musicVideos: musicVideos.map { $0.toMusicVideo() },
            albums: albums.map { $0.toAlbumItem() }
        )
    }

    func fetchUpcomingEvents(artistId: UUID) async throws -> [Event] {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        let now = isoFormatter.string(from: Date())

        // fetchUpcomingTicketing과 동일 조건이나 limit 없이 전체. is_hidden 제외(admin soft-hide 존중).
        let rows: [EventRow] = (try? await service.fetch(
            table: "events",
            query: "select=*,venues(name)&artist_id=eq.\(artistId.uuidString)&start_date=gte.\(now)&is_hidden=eq.false&order=start_date.asc"
        )) ?? []
        return rows.map { $0.toEvent() }
    }

    private func fetchUpcomingTicketing(artistId: UUID) async throws -> UpcomingTicketing? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        let now = isoFormatter.string(from: Date())

        let events: [EventRow] = (try? await service.fetch(
            table: "events",
            query: "select=*,venues(name)&artist_id=eq.\(artistId.uuidString)&start_date=gte.\(now)\(kVisibleEventsFilter)&order=start_date.asc&limit=1"
        )) ?? []

        guard let event = events.first else { return nil }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.startOfDay(for: event.startDate)
        let days = calendar.dateComponents([.day], from: today, to: start).day ?? 0
        let dDay = days == 0 ? "D-0" : "D-\(days)"

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy.MM.dd"
        let ticketOpen = event.ticketOpenDate.map { d -> String in
            let f = DateFormatter()
            f.dateFormat = "yyyy.MM.dd HH:mm"
            return "\(f.string(from: d)) · \(event.ticketProvider ?? "")"
        } ?? ""

        return UpcomingTicketing(
            id: event.id,
            dDay: dDay,
            concertTitle: event.title,
            ticketOpenInfo: ticketOpen,
            dateVenueInfo: "\(fmt.string(from: event.startDate)) ~ \(event.endDate.map { fmt.string(from: $0) } ?? "") · \(event.venues?.name ?? "")"
        )
    }

    // MARK: - Follow

    func fetchIsFollowing(artistId: UUID) async -> Bool {
        guard AuthService.shared.isLoggedIn else { return false }
        let rows: [UserFollowingIdRow] = (try? await service.fetch(
            table: "user_artist_followings",
            query: "select=artist_id&artist_id=eq.\(artistId.uuidString)&limit=1"
        )) ?? []
        return !rows.isEmpty
    }

    func toggleFollow(artistId: UUID, currentlyFollowing: Bool) async throws {
        guard let userId = AuthService.shared.currentUserId else { return }
        let client = SupabaseService.shared.client
        if currentlyFollowing {
            try await client.from("user_artist_followings")
                .delete()
                .eq("artist_id", value: artistId.uuidString)
                .execute()
        } else {
            try await client.from("user_artist_followings")
                .insert(ArtistFollowInsert(userId: userId, artistId: artistId))
                .execute()
        }
    }
}
