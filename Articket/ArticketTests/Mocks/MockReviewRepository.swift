@testable import Articket

import Foundation

final class MockReviewRepository: ReviewRepositoryProtocol {

    func fetchMyReviews() async throws -> [ConcertReview] { [] }

    func writeReview(eventId: UUID, title: String, starCount: Int, content: String) async throws {}
}
