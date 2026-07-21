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
            query: "select=id,name,avatar_url,followers_count,upcoming_event_count,country&order=birth_date.desc.nullslast,followers_count.desc&limit=5"
        )
        return rows.map { row in
            // country 기반 뱃지 (Figma): 해외 아티스트+공연예정 → 내한 확정, 국내+공연예정 → 티켓팅 오픈, 공연예정 없음 → 컴백 예정
            let isForeign: Bool = {
                guard let c = row.country, !c.isEmpty else { return false }  // null/미상 → 국내로 간주
                return !c.contains("한국")  // "대한민국"·"한국" 포함 시 국내
            }()
            let badge: String = {
                if row.upcomingEventCount > 0 {
                    return isForeign ? "내한 확정" : "티켓팅 오픈"
                }
                return "컴백 예정"
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
                case "on_sale", "ongoing": return .green   // 예매중·공연중 = 활성
                case "upcoming":           return .yellow
                default:                   return .red
                }
            }()
            // admin status enum(upcoming/on_sale/ongoing/ended) 전부 매핑.
            // 과거 ongoing이 default로 떨어져 "예매 종료"로 잘못 표시되던 버그 수정.
            let bookingStatus: TicketSaleStatus = {
                switch row.status {
                case "on_sale":  return .onSale
                case "upcoming": return .upcoming
                case "ongoing":  return .ongoing
                default:         return .ended
                }
            }()
            let dateRange = "\(dateFmt.string(from: row.startDate)) ~ \(row.endDate.map { dateFmt.string(from: $0) } ?? dateFmt.string(from: row.startDate))"

            func appendEvent(on date: Date) {
                events.append(CalendarEvent(
                    id: row.id,
                    date: date,
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

            // 비정상적으로 긴 기간(잘못된 end_date 또는 시즌권/장기축제)은 캘린더를 도배하므로
            // 시작일 하나만 표시한다. 정상 범위(≤7일, 주말 페스티벌 등)만 날짜별로 확장.
            let spanDays = cal.dateComponents([.day], from: row.startDate,
                                              to: row.endDate ?? row.startDate).day ?? 0
            if spanDays > 7 {
                if row.startDate >= firstDay && row.startDate <= lastDay,
                   cal.component(.month, from: row.startDate) == month {
                    appendEvent(on: row.startDate)
                }
            } else {
                // 해당 월에 속하는 날짜마다 CalendarEvent 생성
                let startClamped = max(row.startDate, firstDay)
                let endClamped   = min(row.endDate ?? row.startDate, lastDay)
                var cursor = startClamped
                while cursor <= endClamped {
                    if cal.component(.month, from: cursor) == month {
                        appendEvent(on: cursor)
                    }
                    guard let next = cal.date(byAdding: .day, value: 1, to: cursor) else { break }
                    cursor = next
                }
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
