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

        return row.toConcertDetail(reviews: reviews.map { $0.toConcertDetailReview() })
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
