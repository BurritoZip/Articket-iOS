import Foundation
import Supabase

struct SupabaseConcertDetailRepository: ConcertDetailRepositoryProtocol {

    private let service = SupabaseService.shared

    func fetchConcertDetail(concertId: UUID) async throws -> ConcertDetail {
        let events: [EventRow] = try await service.fetch(
            table: "events",
            query: "select=*,venues(name,address,phone_number),artists(id,name,name_en,avatar_url,followers_count,upcoming_event_count),event_artists(display_order,role,artists(id,name,name_en,avatar_url,followers_count,upcoming_event_count))&id=eq.\(concertId.uuidString)&limit=1"
        )
        guard let row = events.first else { throw SupabaseError.httpError(404) }

        let reviews: [ConcertReviewRow] = (try? await service.fetch(
            table: "concert_reviews",
            query: "select=id,star_count,title,username,created_at&event_id=eq.\(concertId.uuidString)&order=created_at.desc&limit=20"
        )) ?? []

        let sessions = await fetchSiblingSessions(for: row)

        return row.toConcertDetail(
            reviews: reviews.map { $0.toConcertDetailReview() },
            sessions: sessions
        )
    }

    /// 같은 공연장의 다가오는 이벤트를 가져와 회차(seriesKey 일치)만 세션으로 묶는다.
    /// 목록 그룹핑(EventSeriesGrouping)과 동일 키를 써 판정이 일관된다. 회차가 1건뿐이면 [] 반환
    /// (상세는 단일 공연으로 표시). 새 목록성 쿼리이므로 is_hidden 필터 필수.
    private func fetchSiblingSessions(for row: EventRow) async -> [ConcertSession] {
        guard let venueId = row.venueId,
              let selfKey = EventSeriesGrouping.seriesKey(
                  title: row.title, venueName: row.venues?.name ?? "")
        else { return [] }

        let nowISO = ISO8601DateFormatter().string(from: Date())
        let candidates: [EventRow] = (try? await service.fetch(
            table: "events",
            query: "select=id,title,start_date,booking_url,booking_links,venues(name)&venue_id=eq.\(venueId.uuidString)&end_date=gte.\(nowISO)&is_hidden=eq.false&order=start_date.asc"
        )) ?? []

        let group = candidates.filter {
            EventSeriesGrouping.seriesKey(title: $0.title, venueName: $0.venues?.name ?? "") == selfKey
        }
        guard group.count >= 2 else { return [] }

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy.MM.dd"
        return group.map {
            ConcertSession(
                eventId: $0.id,
                startDate: $0.startDate,
                dateLabel: fmt.string(from: $0.startDate),
                bookingUrl: $0.parsedBookingUrl,
                bookingLinks: $0.parsedBookingLinks
            )
        }
    }

    // MARK: - Interest

    func fetchIsInterested(concertId: UUID) async -> Bool {
        guard AuthService.shared.isLoggedIn else { return false }
        let rows: [UserInterestedIdRow] = (try? await service.fetch(
            table: "user_interested_events",
            query: "select=event_id&event_id=eq.\(concertId.uuidString)&limit=1"
        )) ?? []
        return !rows.isEmpty
    }

    func toggleInterested(concertId: UUID, currentlyInterested: Bool) async throws {
        guard let userId = AuthService.shared.currentUserId else { return }
        let client = SupabaseService.shared.client
        if currentlyInterested {
            try await client.from("user_interested_events")
                .delete()
                .eq("event_id", value: concertId.uuidString)
                .execute()
        } else {
            try await client.from("user_interested_events")
                .insert(InterestedEventInsert(userId: userId, eventId: concertId))
                .execute()
        }
    }
}
