import Foundation
import Supabase

struct SupabaseArtistRepository: ArtistRepositoryProtocol {

    private let service = SupabaseService.shared

    func fetchMyArtists() async throws -> [Artist] {
        guard AuthService.shared.isLoggedIn else { return [] }
        let rows: [UserFollowingRow] = try await service.fetch(
            table: "user_artist_followings",
            query: "select=artist_id,artists(id,name,avatar_url,followers_count,upcoming_event_count)&limit=30"
        )
        return rows.compactMap { $0.toArtist() }
    }

    func fetchFollowedArtistIds() async -> Set<UUID> {
        guard AuthService.shared.isLoggedIn else { return [] }
        let rows: [UserFollowingIdRow] = (try? await service.fetch(
            table: "user_artist_followings",
            query: "select=artist_id&limit=200"
        )) ?? []
        return Set(rows.map { $0.artistId })
    }

    func fetchPopularArtists() async throws -> [PopularArtist] {
        let rows: [ArtistRow] = try await service.fetch(
            table: "artists",
            query: "select=id,name,avatar_url,followers_count,upcoming_event_count&order=birth_date.desc.nullslast,followers_count.desc&limit=5"
        )
        return rows.map { row in
            let badge: String = {
                if row.upcomingEventCount > 0 { return "티켓팅 오픈" }
                return "팔로워 급상승"
            }()
            return PopularArtist(id: row.id, name: row.name, imageUrl: row.avatarUrl, badge: badge)
        }
    }

    func fetchCalendarEvents(year: Int, month: Int) async throws -> [CalendarEvent] {
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = 1
        let cal = Calendar.current
        guard let firstDay = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: firstDay),
              let lastDay = cal.date(byAdding: .day, value: range.count - 1, to: firstDay)
        else { return [] }

        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime]
        let firstISO = fmt.string(from: firstDay)
        let lastISO  = fmt.string(from: lastDay)

        let rows: [EventRow] = try await service.fetch(
            table: "events",
            query: "select=*,venues(name)&start_date=lte.\(lastISO)&end_date=gte.\(firstISO)&order=start_date.asc&limit=60"
        )

        var events: [CalendarEvent] = []
        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy.MM.dd"

        for row in rows {
            let color: CalendarEventColor = {
                switch row.status {
                case "on_sale":  return .green
                case "upcoming": return .yellow
                default:         return .red
                }
            }()
            let bookingStatus: TicketSaleStatus = {
                switch row.status {
                case "on_sale":  return .onSale
                case "upcoming": return .upcoming
                default:         return .ended
                }
            }()
            let dateRange = "\(dateFmt.string(from: row.startDate)) ~ \(row.endDate.map { dateFmt.string(from: $0) } ?? dateFmt.string(from: row.startDate))"

            // 해당 월에 속하는 날짜마다 CalendarEvent 생성
            let startClamped = max(row.startDate, firstDay)
            let endClamped   = min(row.endDate ?? row.startDate, lastDay)
            var cursor = startClamped
            while cursor <= endClamped {
                if cal.component(.month, from: cursor) == month {
                    events.append(CalendarEvent(
                        id: row.id,
                        date: cursor,
                        title: row.title,
                        color: color,
                        concertTitle: row.title,
                        concertDate: dateRange,
                        venueName: row.venues?.name ?? "",
                        bookingPlatform: row.ticketProvider ?? "",
                        ticketOpenDate: "",
                        ticketPrices: [],
                        bookingStatus: bookingStatus,
                        eventCategory: row.genre ?? ""
                    ))
                }
                guard let next = cal.date(byAdding: .day, value: 1, to: cursor) else { break }
                cursor = next
            }
        }
        return events
    }

    func fetchRecommendedArtists() async throws -> [Artist] {
        let rows: [ArtistRow] = try await service.fetch(
            table: "artists",
            query: "select=id,name,avatar_url,followers_count,upcoming_event_count&order=birth_date.desc.nullslast,followers_count.desc&limit=5"
        )
        return rows.map { $0.toArtist(isFollowing: false) }
    }

    func searchArtists(keyword: String) async throws -> [Artist] {
        let encoded = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? keyword
        let rows: [ArtistRow] = try await service.fetch(
            table: "artists",
            query: "select=id,name,name_en,avatar_url,followers_count,upcoming_event_count&name=ilike.*\(encoded)*&order=followers_count.desc&limit=30"
        )
        return rows.map { $0.toArtist(isFollowing: false) }
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
