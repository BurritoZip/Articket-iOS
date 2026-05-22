import Foundation
import Supabase

struct SupabaseReviewRepository: ReviewRepositoryProtocol {

    func fetchMyReviews() async throws -> [ConcertReview] {
        guard AuthService.shared.isLoggedIn else { return [] }
        let rows: [ReviewRow] = try await SupabaseService.shared.fetch(
            table: "concert_reviews",
            query: "select=id,title,star_count,content,username,created_at,events(id,title,poster_url)&order=created_at.desc&limit=50"
        )
        return rows.compactMap { $0.toReview() }
    }

    func writeReview(eventId: UUID, title: String, starCount: Int, content: String) async throws {
        guard let userId = AuthService.shared.currentUserId else {
            throw ReviewError.notLoggedIn
        }
        // username: 표시명 우선, 없으면 이메일 사용
        let username = SupabaseService.shared.client.auth.currentSession?.user.email ?? "아티켓 유저"
        try await SupabaseService.shared.client
            .from("concert_reviews")
            .insert(ReviewInsert(
                userId: userId,
                eventId: eventId,
                title: title,
                starCount: starCount,
                content: content,
                username: username
            ))
            .execute()
    }
}

enum ReviewError: Error {
    case notLoggedIn
}
