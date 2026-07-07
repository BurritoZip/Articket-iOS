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

    // MARK: - Booked 표시 (예매 완료 CTA)

    private struct BookingInsert: Encodable {
        let userId: UUID
        let eventId: UUID
        let status: String
        let bookedAt: String
        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case eventId = "event_id"
            case status
            case bookedAt = "booked_at"
        }
    }

    private struct BookedIdRow: Decodable { let id: UUID }

    func markBooked(eventId: UUID) async throws {
        guard let userId = AuthService.shared.currentUserId else {
            throw URLError(.userAuthenticationRequired)
        }
        let insert = BookingInsert(
            userId: userId,
            eventId: eventId,
            status: BookingStatus.completed.rawValue,
            bookedAt: Self.isoFormatter.string(from: Date())
        )
        try await SupabaseService.shared.client
            .from("user_bookings")
            .insert(insert)
            .execute()
    }

    func isBooked(eventId: UUID) async throws -> Bool {
        guard AuthService.shared.isLoggedIn else { return false }
        // RLS가 본인 행으로 스코프. active/completed면 이미 예매된 것으로 간주.
        let rows: [BookedIdRow] = try await SupabaseService.shared.fetch(
            table: "user_bookings",
            query: "select=id&event_id=eq.\(eventId.uuidString)&status=in.(active,completed)&limit=1"
        )
        return !rows.isEmpty
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
