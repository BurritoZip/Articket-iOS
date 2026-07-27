import Foundation
@testable import Articket

// 여러 테스트에서 공유하는 구성 가능한 리포지토리 스텁. 네트워크 무의존.
// (RemediationLogicTests의 private 스텁과 이름이 겹치지 않도록 Test* 접두사 사용)

final class TestMyPageRepo: MyPageRepositoryProtocol, @unchecked Sendable {
    var reviewableShows: [Event] = []
    var yearlyShows: [Event] = []
    var myArtists: [Artist] = []
    var avatarError: Error?
    private(set) var didUpdateName = false

    func fetchUserProfile() async throws -> UserProfile {
        UserProfile(displayName: "", email: "", initial: "U",
                    concertCount: 0, followingArtistCount: 0, lastVisitDate: nil, avatarUrl: nil)
    }
    func fetchMyArtists() async throws -> [Artist] { myArtists }
    func fetchReviewableShows() async throws -> [Event] { reviewableShows }
    func fetchYearlyShows() async throws -> [Event] { yearlyShows }
    func updateDisplayName(_ name: String) async throws { didUpdateName = true }
    func updateAvatar(imageData: Data) async throws -> String {
        if let avatarError { throw avatarError }
        return "https://cdn/avatar.jpg"
    }
}

final class TestBookingRepo: BookingRepositoryProtocol, @unchecked Sendable {
    var bookings: [Booking] = []
    var stats: MyStats = MyStats(year: 2026, monthlyViewCounts: Array(repeating: 0, count: 12),
                                 topMonth: 1, topGenre: "", topArtist: "", totalCount: 0)
    var rankings: [ArtistRankEntry] = []
    var pendingIntent: BookingIntent?
    private(set) var resolved: [(eventId: UUID, outcome: BookingIntentOutcome)] = []

    func fetchMyBookings() async throws -> [Booking] { bookings }
    func fetchCancelledBookings() async throws -> [Booking] { [] }
    func fetchMyStats() async throws -> MyStats { stats }
    func fetchArtistRankings() async throws -> [ArtistRankEntry] { rankings }
    func markBooked(eventId: UUID) async throws {}
    func isBooked(eventId: UUID) async throws -> Bool { false }
    func recordBookingIntent(eventId: UUID, eventTitle: String, posterUrl: String?) async {}
    func fetchPendingBookingIntent() async -> BookingIntent? { pendingIntent }
    func resolveBookingIntent(eventId: UUID, outcome: BookingIntentOutcome) async throws {
        resolved.append((eventId, outcome))
        // 해소되면 다음 조회에서 사라지도록
        if pendingIntent?.eventId == eventId { pendingIntent = nil }
    }
}

final class TestReviewRepo: ReviewRepositoryProtocol, @unchecked Sendable {
    var writeError: Error?
    private(set) var writeCount = 0
    private(set) var lastWrite: (eventId: UUID, title: String, star: Int, content: String)?

    func fetchMyReviews() async throws -> [ConcertReview] { [] }
    func writeReview(eventId: UUID, title: String, starCount: Int, content: String) async throws {
        if let writeError { throw writeError }
        writeCount += 1
        lastWrite = (eventId, title, starCount, content)
    }
}

// MARK: - 엔티티 빌더

enum TestFixtures {
    static func event(id: UUID = UUID(), title: String = "공연", venue: String = "홀",
                      start: Date = Date(), genre: String? = nil) -> Event {
        Event(id: id, title: title, posterUrl: "https://img/\(title).jpg",
              startDate: start, endDate: nil, venueName: venue, isInterested: false, genre: genre)
    }

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var c = DateComponents(); c.year = year; c.month = month; c.day = day
        return Calendar.current.date(from: c)!
    }

    static func ranking(_ rank: Int, name: String) -> ArtistRankEntry {
        ArtistRankEntry(id: UUID(), rank: rank, name: name, viewCount: rank,
                        avatarUrl: nil, posterUrls: [], isExpanded: false)
    }
}
