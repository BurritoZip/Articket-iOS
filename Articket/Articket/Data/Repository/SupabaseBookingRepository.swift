import Foundation
import Supabase

struct SupabaseBookingRepository: BookingRepositoryProtocol {

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    func fetchMyBookings() async throws -> [Booking] {
        let query = "select=id,seat,delivery_type,booked_at,status,events(id,title,poster_url,start_date,end_date,venues(name))&status=eq.active&order=booked_at.desc&limit=50"
        let rows: [UserBookingRow] = try await SupabaseService.shared.fetch(table: "user_bookings", query: query)
        return rows.map { $0.toBooking() }
    }

    func fetchCancelledBookings() async throws -> [Booking] {
        let query = "select=id,seat,delivery_type,booked_at,status,events(id,title,poster_url,start_date,end_date,venues(name))&status=eq.cancelled&order=booked_at.desc&limit=50"
        let rows: [UserBookingRow] = try await SupabaseService.shared.fetch(table: "user_bookings", query: query)
        return rows.map { $0.toBooking() }
    }

    func fetchMyStats() async throws -> MyStats {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())

        // user_bookings 기반 실관람 통계만 계산
        // auth 미구현으로 빈 테이블이면 zero stats 반환 (events 테이블 전체 집계 금지)
        let yearStart = "\(currentYear)-01-01T00:00:00Z"
        let query = "select=id,events(start_date,genre)&events.start_date=gte.\(yearStart)"
        let rows: [BookingStatsRow] = try await SupabaseService.shared.fetch(
            table: "user_bookings",
            query: query
        )

        guard !rows.isEmpty else {
            return MyStats(
                year: currentYear,
                monthlyViewCounts: Array(repeating: 0, count: 12),
                topMonth: 1,
                topGenre: "",
                topArtist: "",
                totalCount: 0
            )
        }

        var monthlyCounts = Array(repeating: 0, count: 12)
        var genreMap: [String: Int] = [:]
        for row in rows {
            guard let event = row.events else { continue }
            let month = calendar.component(.month, from: event.startDate)
            monthlyCounts[month - 1] += 1
            if let genre = event.genre { genreMap[genre, default: 0] += 1 }
        }
        let topMonthIndex = monthlyCounts.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0
        let topGenre = genreMap.max(by: { $0.value < $1.value })?.key ?? ""
        return MyStats(
            year: currentYear,
            monthlyViewCounts: monthlyCounts,
            topMonth: topMonthIndex + 1,
            topGenre: topGenre,
            topArtist: "",
            totalCount: monthlyCounts.reduce(0, +)
        )
    }

    func fetchArtistRankings() async throws -> [ArtistRankEntry] {
        guard AuthService.shared.isLoggedIn else { return [] }
        let rows: [BookingArtistRow] = try await SupabaseService.shared.fetch(
            table: "user_bookings",
            query: "select=events(artists(id,name,avatar_url))&limit=200"
        )

        var countMap: [UUID: (name: String, url: String?, count: Int)] = [:]
        for row in rows {
            guard let artistRef = row.events?.artists else { continue }
            countMap[artistRef.id, default: (artistRef.name, artistRef.avatarUrl, 0)].count += 1
        }

        return countMap.values
            .sorted { $0.count > $1.count }
            .prefix(5)
            .enumerated()
            .map { index, entry in
                ArtistRankEntry(
                    id: UUID(),
                    rank: index + 1,
                    name: entry.name,
                    viewCount: entry.count,
                    avatarUrl: entry.url,
                    posterUrls: [],
                    isExpanded: false
                )
            }
    }
}
