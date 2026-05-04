import Foundation

struct SupabaseArtistRepository: ArtistRepositoryProtocol {

    private let service = SupabaseService.shared

    func fetchMyArtists() async throws -> [Artist] {
        // 로그인 전 빈 배열 반환 — 인증 구현 후 user_artist_followings 조인으로 교체
        []
    }

    func fetchPopularArtists() async throws -> [PopularArtist] {
        let rows: [ArtistRow] = try await service.fetch(
            table: "artists",
            query: "select=id,name,avatar_url,followers_count,upcoming_event_count&order=followers_count.desc&limit=5"
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
            let bookingStatus: BookingStatus = {
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
            query: "select=id,name,avatar_url,followers_count,upcoming_event_count&order=upcoming_event_count.desc&limit=5"
        )
        return rows.map { $0.toArtist(isFollowing: false) }
    }
}
