@testable import Articket

import Foundation

final class MockMyPageRepository: MyPageRepositoryProtocol {

    func fetchUserProfile() async -> UserProfile {
        UserProfile(
            displayName: "보규님",
            email: "bogyu@example.com",
            initial: "규",
            concertCount: 22,
            followingArtistCount: 7,
            lastVisitDate: makeDate(year: 2025, month: 11, day: 26),
            avatarUrl: nil
        )
    }

    func fetchMyArtists() async -> [Artist] {
        [
            Artist(id: UUID(), name: "백예린", nameEn: nil, avatarUrl: nil, followersCount: 0, upcomingEventCount: 0, isFollowing: true),
            Artist(id: UUID(), name: "검정치마", nameEn: nil, avatarUrl: nil, followersCount: 0, upcomingEventCount: 0, isFollowing: true),
            Artist(id: UUID(), name: "The 1975", nameEn: nil, avatarUrl: nil, followersCount: 0, upcomingEventCount: 0, isFollowing: true),
            Artist(id: UUID(), name: "미노이", nameEn: nil, avatarUrl: nil, followersCount: 0, upcomingEventCount: 0, isFollowing: true),
            Artist(id: UUID(), name: "한로로", nameEn: nil, avatarUrl: nil, followersCount: 0, upcomingEventCount: 0, isFollowing: true),
            Artist(id: UUID(), name: "기리보이", nameEn: nil, avatarUrl: nil, followersCount: 0, upcomingEventCount: 0, isFollowing: true),
        ]
    }

    func fetchReviewableShows() async -> [Event] {
        [
            Event(
                id: UUID(),
                title: "백예린 2025 Live [wanna see you dance again]",
                imageAssetName: nil,
                startDate: makeDate(year: 2025, month: 11, day: 20),
                endDate: makeDate(year: 2025, month: 11, day: 23),
                venueName: "에스펙토리 성수",
                isInterested: false
            )
        ]
    }

    func updateDisplayName(_ name: String) async throws {}
    func updateAvatar(imageData: Data) async throws -> String { return "" }

    func fetchYearlyShows() async -> [Event] {
        [
            Event(
                id: UUID(),
                title: "백예린 2025 Live [wanna see you dance again]",
                imageAssetName: nil,
                startDate: makeDate(year: 2025, month: 11, day: 20),
                endDate: makeDate(year: 2025, month: 11, day: 23),
                venueName: "에스펙토리 성수",
                isInterested: false
            ),
            Event(
                id: UUID(),
                title: "백예린 단독콘서트 Flash and Core",
                imageAssetName: nil,
                startDate: makeDate(year: 2025, month: 10, day: 25),
                endDate: makeDate(year: 2025, month: 10, day: 26),
                venueName: "인천 인스파이어 아레나",
                isInterested: false
            ),
            Event(
                id: UUID(),
                title: "검정치마 단독공연 \"LAST DANCE\"",
                imageAssetName: nil,
                startDate: makeDate(year: 2025, month: 5, day: 2),
                endDate: makeDate(year: 2025, month: 5, day: 11),
                venueName: "장충체육관",
                isInterested: false
            ),
            Event(
                id: UUID(),
                title: "HANRORO 3RD SOLO CONCERT '발아(發芽)'",
                imageAssetName: nil,
                startDate: makeDate(year: 2025, month: 1, day: 11),
                endDate: makeDate(year: 2025, month: 1, day: 12),
                venueName: "예스24 라이브홀",
                isInterested: false
            ),
        ]
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }
}
