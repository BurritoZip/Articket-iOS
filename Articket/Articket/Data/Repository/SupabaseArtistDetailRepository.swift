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

        // 예정된 공연(미래 전체)도 상세와 함께 로드 — 직접 출연 + 라인업 병합.
        async let upcomingRows: [EventRow] = fetchUpcomingEventRows(artistId: artistId)

        let (pastConcerts, albums, musicVideos) = try await (pastConcertRows, albumRows, musicVideoRows)

        let upcomingTicketing: UpcomingTicketing? = try await fetchUpcomingTicketing(artistId: artistId)
        let upcomingConcerts = await upcomingRows.map { $0.toUpcomingConcert() }

        return artistRow.toArtistDetail(
            upcomingTicketing: upcomingTicketing,
            upcomingConcerts: upcomingConcerts,
            pastConcerts: pastConcerts.map { $0.toPastConcert() },
            musicVideos: musicVideos.map { $0.toMusicVideo() },
            albums: albums.map { $0.toAlbumItem() }
        )
    }

    func fetchUpcomingEvents(artistId: UUID) async throws -> [Event] {
        let rows = await fetchUpcomingEventRows(artistId: artistId)
        return rows.map { $0.toEvent() }
    }

    /// 미래 예정 공연 EventRow 를 (1) 직접 artist_id + (2) 다중출연 event_artists 라인업 두 경로로
    /// 조회해 event id 기준 병합·정렬한다. 페스티벌/합동공연(artist_id NULL)도 라인업으로 잡기 위함.
    /// 캘린더(SupabaseArtistRepository.fetchCalendarEvents)와 동일한 "출연 아티스트 팔로우" 규칙.
    private func fetchUpcomingEventRows(artistId: UUID) async -> [EventRow] {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        let now = isoFormatter.string(from: Date())

        async let directRows: [EventRow] = (try? service.fetch(
            table: "events",
            query: "select=*,venues(name)&artist_id=eq.\(artistId.uuidString)&start_date=gte.\(now)&is_hidden=eq.false&order=start_date.asc"
        )) ?? []
        async let lineupRows: [EventRow] = (try? service.fetch(
            table: "events",
            query: "select=*,venues(name),event_artists!inner(artist_id)&event_artists.artist_id=eq.\(artistId.uuidString)&start_date=gte.\(now)&is_hidden=eq.false&order=start_date.asc"
        )) ?? []

        let (direct, lineup) = await (directRows, lineupRows)
        var seen = Set<UUID>()
        return (direct + lineup)
            .filter { seen.insert($0.id).inserted }
            .sorted { $0.startDate < $1.startDate }
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
            dateVenueInfo: "\(fmt.string(from: event.startDate)) ~ \(event.endDate.map { fmt.string(from: $0) } ?? "") · \(event.venues?.name ?? "")",
            ticketOpenDate: event.ticketOpenDate
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
