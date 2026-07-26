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

    // MARK: - 예매 의사 확인 CTA

    private struct IntentUpsert: Encodable {
        let userId: UUID
        let eventId: UUID
        let attemptedAt: String
        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case eventId = "event_id"
            case attemptedAt = "attempted_at"
        }
    }

    /// 응답 반영용. 비로그인 중 쌓인 건은 서버에 행이 없을 수 있어 update가 아닌 upsert로 넣는다.
    /// attempted_at은 싣지 않는다 — 충돌 시 UPDATE는 실린 컬럼만 갱신하므로 최초 시도 시각이 보존된다.
    private struct IntentResolve: Encodable {
        let userId: UUID
        let eventId: UUID
        let outcome: String
        let resolvedAt: String
        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case eventId = "event_id"
            case outcome
            case resolvedAt = "resolved_at"
        }
    }

    func recordBookingIntent(eventId: UUID, eventTitle: String, posterUrl: String?) async {
        // 비로그인이면 로컬에 보관 — 예매하기는 공개 기능이라 로그인 강제 없이 CTA를 띄운다
        guard let userId = AuthService.shared.currentUserId else {
            BookingIntentLocalStore.shared.record(eventId: eventId, eventTitle: eventTitle, posterUrl: posterUrl)
            return
        }
        let payload = IntentUpsert(
            userId: userId,
            eventId: eventId,
            attemptedAt: Self.isoFormatter.string(from: Date())
        )
        do {
            // 같은 공연 재시도는 시각만 갱신 (PK = user_id + event_id)
            try await SupabaseService.shared.client
                .from("booking_intents")
                .upsert(payload, onConflict: "user_id,event_id")
                .execute()
        } catch {
            // 기록 실패가 예매 링크 오픈을 막아선 안 된다 — 로컬로 폴백해 CTA는 살린다
            BookingIntentLocalStore.shared.record(eventId: eventId, eventTitle: eventTitle, posterUrl: posterUrl)
        }
    }

    func fetchPendingBookingIntent() async -> BookingIntent? {
        // 로컬 기록이 있으면 우선 노출 — 비로그인 중 남긴 건이 로그인 후에도 유실되지 않게 한다
        if let local = BookingIntentLocalStore.shared.pendingIntents().first {
            return local
        }
        guard AuthService.shared.isLoggedIn else { return nil }

        let query = "select=event_id,attempted_at,events(title,poster_url)"
            + "&outcome=is.null&order=attempted_at.desc&limit=1"
        do {
            let rows: [BookingIntentRow] = try await SupabaseService.shared.fetch(
                table: "booking_intents",
                query: query
            )
            guard let intent = rows.first?.toBookingIntent(), !intent.isExpired else { return nil }
            // 상세 화면에서 이미 '예매 완료'로 표시한 공연이면 되묻지 않는다
            if (try? await isBooked(eventId: intent.eventId)) == true {
                try? await resolveBookingIntent(eventId: intent.eventId, outcome: .booked)
                return nil
            }
            return intent
        } catch {
            return nil
        }
    }

    func resolveBookingIntent(eventId: UUID, outcome: BookingIntentOutcome) async throws {
        // 로컬 기록은 응답과 동시에 제거 (로그인 여부와 무관)
        BookingIntentLocalStore.shared.remove(eventId: eventId)

        guard let userId = AuthService.shared.currentUserId else {
            // 비로그인 상태의 'skipped'는 로컬 삭제로 충분. 'booked'는 로그인 후 처리돼야 하므로
            // 호출부(ViewModel)가 로그인 유도 뒤 재호출한다.
            if outcome == .booked { throw URLError(.userAuthenticationRequired) }
            return
        }

        if outcome == .booked {
            // 확정 시에만 user_bookings에 기록 — 통계·마이페이지가 이 테이블을 집계하기 때문
            if (try? await isBooked(eventId: eventId)) != true {
                try await markBooked(eventId: eventId)
            }
        }

        let payload = IntentResolve(
            userId: userId,
            eventId: eventId,
            outcome: outcome.rawValue,
            resolvedAt: Self.isoFormatter.string(from: Date())
        )
        try await SupabaseService.shared.client
            .from("booking_intents")
            .upsert(payload, onConflict: "user_id,event_id")
            .execute()
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

        return countMap
            .sorted { $0.value.count > $1.value.count }
            .prefix(5)
            .enumerated()
            .map { index, element in
                // id는 실제 아티스트 UUID를 쓴다. 매 조회마다 UUID()로 새로 만들면
                // diffable 식별자가 계속 바뀌어 리로드마다 셀이 통째로 재생성된다.
                ArtistRankEntry(
                    id: element.key,
                    rank: index + 1,
                    name: element.value.name,
                    viewCount: element.value.count,
                    avatarUrl: element.value.url,
                    posterUrls: [],
                    isExpanded: false
                )
            }
    }
}
