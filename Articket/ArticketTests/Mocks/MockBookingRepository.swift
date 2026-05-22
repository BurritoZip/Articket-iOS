@testable import Articket

import Foundation

final class MockBookingRepository: BookingRepositoryProtocol {

    func fetchMyBookings() async throws -> [Booking] {
        let calendar = Calendar.current
        let today = Date()
        return [
            Booking(
                id: UUID(),
                title: "백예린 UNIT LIVE [STRINGS]",
                venueName: "올림픽공원 올림픽홀",
                date: calendar.date(byAdding: .day, value: 7, to: today)!,
                seat: "1층 A구역 15열 20번",
                deliveryType: .delivery,
                imageAssetName: "poster_yerin_baek",
                status: .active
            ),
            Booking(
                id: UUID(),
                title: "검정치마 [THANKS FOR THE MEMORIES]",
                venueName: "예스24 라이브홀",
                date: calendar.date(byAdding: .day, value: 14, to: today)!,
                seat: "1층 B구역 8열 5번",
                deliveryType: .onsite,
                imageAssetName: "poster_black_skirts",
                status: .active
            )
        ]
    }

    func fetchCancelledBookings() async throws -> [Booking] {
        let calendar = Calendar.current
        let today = Date()
        return [
            Booking(
                id: UUID(),
                title: "소란 CONCERT [봄의 소란]",
                venueName: "홍익대 대학로 아트센터",
                date: calendar.date(byAdding: .day, value: -10, to: today)!,
                seat: "2층 C구역 3열 12번",
                deliveryType: .delivery,
                imageAssetName: nil,
                status: .cancelled
            )
        ]
    }

    func fetchMyStats() async throws -> MyStats {
        let counts = [1, 3, 2, 4, 2, 5, 3, 4, 3, 2, 1, 0]
        let topMonth = (counts.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0) + 1
        return MyStats(
            year: 2025,
            monthlyViewCounts: counts,
            topMonth: topMonth,
            topGenre: "인디",
            topArtist: "백예린",
            totalCount: counts.reduce(0, +)
        )
    }

    func fetchArtistRankings() async throws -> [ArtistRankEntry] {
        [
            ArtistRankEntry(id: UUID(), rank: 1, name: "백예린", viewCount: 5, avatarUrl: nil, posterUrls: [], isExpanded: false),
            ArtistRankEntry(id: UUID(), rank: 2, name: "검정치마", viewCount: 4, avatarUrl: nil, posterUrls: [], isExpanded: false),
            ArtistRankEntry(id: UUID(), rank: 3, name: "소란", viewCount: 3, avatarUrl: nil, posterUrls: [], isExpanded: false),
            ArtistRankEntry(id: UUID(), rank: 4, name: "츄", viewCount: 3, avatarUrl: nil, posterUrls: [], isExpanded: false),
            ArtistRankEntry(id: UUID(), rank: 5, name: "혁오", viewCount: 2, avatarUrl: nil, posterUrls: [], isExpanded: false)
        ]
    }
}
