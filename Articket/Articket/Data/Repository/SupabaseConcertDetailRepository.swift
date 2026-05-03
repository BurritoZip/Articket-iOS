import Foundation

struct SupabaseConcertDetailRepository: ConcertDetailRepositoryProtocol {

    private let service = SupabaseService.shared

    func fetchConcertDetail(concertId: UUID) async throws -> ConcertDetail {
        let events: [EventRow] = try await service.fetch(
            table: "events",
            query: "select=*,venues(name,address,phone_number),artists(id,name,avatar_url,followers_count,upcoming_event_count)&id=eq.\(concertId.uuidString)&limit=1"
        )
        guard let row = events.first else { throw SupabaseError.httpError(404) }

        let reviews: [ConcertReviewRow] = (try? await service.fetch(
            table: "concert_reviews",
            query: "select=id,star_count,title,username,created_at&event_id=eq.\(concertId.uuidString)&order=created_at.desc&limit=20"
        )) ?? []

        return row.toConcertDetail(reviews: reviews.map { $0.toConcertReview() })
    }
}
