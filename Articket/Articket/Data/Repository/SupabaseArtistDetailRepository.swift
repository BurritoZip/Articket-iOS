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
        // 회차 접기 — 상세 탭에서도 Day1/Day2 중복 제목이 나란히 안 뜨게
        let groupedIds = Set(
            EventSeriesGrouping.group(upcomingRows.map { $0.toEvent() }).map(\.id)
        )
        let upcomingConcerts = upcomingRows
            .filter { groupedIds.contains($0.id) }
            .map { $0.toUpcomingConcert() }

        return artistRow.toArtistDetail(
            upcomingTicketing: upcomingTicketing,
            upcomingConcerts: upcomingConcerts,
            pastConcerts: pastConcerts.map { $0.toPastConcert() },
            musicVideos: musicVideos.map { $0.toMusicVideo() },
            albums: albums.map { $0.toAlbumItem() }
        )
    }

    private func fetchUpcomingEventRows(artistId: UUID) async -> [EventRow] {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        let now = isoFormatter.string(from: Date())

        // 포스터 없는 카드는 목록에 올리지 않음 (홈 배너와 동일 방어)
        async let directRows: [EventRow] = (try? service.fetch(
            table: "events",
            query: "select=*,venues(name)&artist_id=eq.\(artistId.uuidString)&start_date=gte.\(now)&poster_url=not.is.null&is_hidden=eq.false&order=start_date.asc"
        )) ?? []
        async let lineupRows: [EventRow] = (try? service.fetch(
            table: "events",
            query: "select=*,venues(name),event_artists!inner(artist_id)&event_artists.artist_id=eq.\(artistId.uuidString)&start_date=gte.\(now)&poster_url=not.is.null&is_hidden=eq.false&order=start_date.asc"
        )) ?? []

        let (direct, lineup) = await (directRows, lineupRows)
        var seen = Set<UUID>()
        return (direct + lineup)
            .filter { seen.insert($0.id).inserted }
            .sorted { $0.startDate < $1.startDate }
    }

    func fetchUpcomingEvents(artistId: UUID) async throws -> [Event] {
        let rows = await fetchUpcomingEventRows(artistId: artistId)
        // 회차(Day1/Day2) 대표 1건으로 접어 중복 제목 노출을 줄인다
        return EventSeriesGrouping.group(rows.map { $0.toEvent() })
    }

    /// 다가오는 **티켓팅 오픈** — 공연 시작일이 아니라 ticket_open_date 기준.
    /// (이전: start_date 최솟값 + D-Day도 공연일 → 오픈일이 계속 틀리게 보임)
    private func fetchUpcomingTicketing(artistId: UUID) async throws -> UpcomingTicketing? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        let now = isoFormatter.string(from: Date())

        let baseFilter = "ticket_open_date=not.is.null&ticket_open_date=gte.\(now)\(kVisibleEventsFilter)&order=ticket_open_date.asc&limit=5"

        async let directRows: [EventRow] = (try? await service.fetch(
            table: "events",
            query: "select=*,venues(name)&artist_id=eq.\(artistId.uuidString)&\(baseFilter)"
        )) ?? []
        async let lineupRows: [EventRow] = (try? await service.fetch(
            table: "events",
            query: "select=*,venues(name),event_artists!inner(artist_id)&event_artists.artist_id=eq.\(artistId.uuidString)&\(baseFilter)"
        )) ?? []

        let (direct, lineup) = await (directRows, lineupRows)
        var seen = Set<UUID>()
        let merged = (direct + lineup)
            .filter { seen.insert($0.id).inserted }
            .sorted { ($0.ticketOpenDate ?? .distantFuture) < ($1.ticketOpenDate ?? .distantFuture) }

        guard let event = merged.first, let openDate = event.ticketOpenDate else { return nil }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let openDay = calendar.startOfDay(for: openDate)
        let days = calendar.dateComponents([.day], from: today, to: openDay).day ?? 0
        let dDay = days == 0 ? "D-0" : "D-\(days)"

        let ticketOpen = "\(KSTDateFormat.dateTime.string(from: openDate)) · \(event.ticketProvider ?? "")"
        let startStr = KSTDateFormat.day.string(from: event.startDate)
        let endStr = event.endDate.map { KSTDateFormat.day.string(from: $0) } ?? startStr

        return UpcomingTicketing(
            id: event.id,
            dDay: dDay,
            concertTitle: event.title,
            ticketOpenInfo: ticketOpen,
            dateVenueInfo: "\(startStr) ~ \(endStr) · \(event.venues?.name ?? "")",
            ticketOpenDate: openDate
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
