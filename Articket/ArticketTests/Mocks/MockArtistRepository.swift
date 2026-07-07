@testable import Articket

import Foundation

final class MockArtistRepository: ArtistRepositoryProtocol {

    func fetchMyArtists() async -> [Artist] {
        [
            Artist(id: UUID(), name: "백예린", avatarUrl: nil, followersCount: 129_000, upcomingEventCount: 3, isFollowing: true),
            Artist(id: UUID(), name: "검정치마", avatarUrl: nil, followersCount: 87_000, upcomingEventCount: 2, isFollowing: true),
            Artist(id: UUID(), name: "The 1975", avatarUrl: nil, followersCount: 450_000, upcomingEventCount: 1, isFollowing: true),
            Artist(id: UUID(), name: "미노이", avatarUrl: nil, followersCount: 62_000, upcomingEventCount: 4, isFollowing: true),
            Artist(id: UUID(), name: "한로로", avatarUrl: nil, followersCount: 34_000, upcomingEventCount: 2, isFollowing: true),
            Artist(id: UUID(), name: "기리보이", avatarUrl: nil, followersCount: 210_000, upcomingEventCount: 3, isFollowing: true),
            Artist(id: UUID(), name: "윤지영", avatarUrl: nil, followersCount: 28_000, upcomingEventCount: 1, isFollowing: true),
        ]
    }

    func fetchPopularArtists() async -> [PopularArtist] {
        [
            PopularArtist(id: UUID(), name: "The Volunteers", imageUrl: nil, badge: "티켓팅 오픈"),
            PopularArtist(id: UUID(), name: "Oasis", imageUrl: nil, badge: "내한 확정"),
            PopularArtist(id: UUID(), name: "유다빈밴드(YdBB)", imageUrl: nil, badge: "컴백 예정"),
        ]
    }

    func fetchCalendarEvents(year: Int, month: Int) async -> [CalendarEvent] {
        var components = DateComponents()
        components.year = year
        components.month = month
        let cal = Calendar.current

        func date(_ day: Int) -> Date {
            components.day = day
            return cal.date(from: components) ?? Date()
        }

        return [
            CalendarEvent(
                id: UUID(), date: date(1), title: "부산락페스티벌", color: .green,
                concertTitle: "2025 부산락페스티벌",
                concertDate: "2025년 11월 1~2일 (토~일)",
                venueName: "을숙도야외공연장", bookingPlatform: "인터파크 티켓",
                ticketOpenDate: "10.01 (수) 10:00",
                ticketPrices: ["1일권 75,000원", "2일권 130,000원"],
                bookingStatus: .onSale, eventCategory: "페스티벌"
            ),
            CalendarEvent(
                id: UUID(), date: date(2), title: "부산락페스티벌", color: .green,
                concertTitle: "2025 부산락페스티벌",
                concertDate: "2025년 11월 1~2일 (토~일)",
                venueName: "을숙도야외공연장", bookingPlatform: "인터파크 티켓",
                ticketOpenDate: "10.01 (수) 10:00",
                ticketPrices: ["1일권 75,000원", "2일권 130,000원"],
                bookingStatus: .onSale, eventCategory: "페스티벌"
            ),
            CalendarEvent(
                id: UUID(), date: date(5), title: "헤이즈", color: .red,
                concertTitle: "Heize 2025 Concert : Still, Here",
                concertDate: "2025년 11월 5일 (수)",
                venueName: "올림픽홀", bookingPlatform: "YES24 라이브",
                ticketOpenDate: "10.15 (수) 20:00",
                ticketPrices: ["VIP 150,000원", "R석 110,000원", "S석 88,000원"],
                bookingStatus: .onSale, eventCategory: "국내공연"
            ),
            CalendarEvent(
                id: UUID(), date: date(8), title: "기리보이", color: .red,
                concertTitle: "기리보이 단독 공연 2025",
                concertDate: "2025년 11월 8~9일 (토~일)",
                venueName: "Yes24 라이브홀", bookingPlatform: "YES24 라이브",
                ticketOpenDate: "10.08 (수) 20:00",
                ticketPrices: ["전석 77,000원"],
                bookingStatus: .onSale, eventCategory: "국내공연"
            ),
            CalendarEvent(
                id: UUID(), date: date(9), title: "기리보이", color: .red,
                concertTitle: "기리보이 단독 공연 2025",
                concertDate: "2025년 11월 8~9일 (토~일)",
                venueName: "Yes24 라이브홀", bookingPlatform: "YES24 라이브",
                ticketOpenDate: "10.08 (수) 20:00",
                ticketPrices: ["전석 77,000원"],
                bookingStatus: .onSale, eventCategory: "국내공연"
            ),
            CalendarEvent(
                id: UUID(), date: date(10), title: "One ok Rock", color: .yellow,
                concertTitle: "ONE OK ROCK DETOX Asia Tour 2026 in Korea",
                concertDate: "2025년 11월 22~23일 (금~토)",
                venueName: "고척스카이돔", bookingPlatform: "티켓링크",
                ticketOpenDate: "10.12 (화) 18:00",
                ticketPrices: ["전석 165,000원"],
                bookingStatus: .ended, eventCategory: "내한공연"
            ),
            CalendarEvent(
                id: UUID(), date: date(10), title: "부산락페스티벌", color: .green,
                concertTitle: "2025 부산락페스티벌",
                concertDate: "2025년 11월 1~2일 (토~일)",
                venueName: "을숙도야외공연장", bookingPlatform: "인터파크 티켓",
                ticketOpenDate: "10.01 (수) 10:00",
                ticketPrices: ["1일권 75,000원", "2일권 130,000원"],
                bookingStatus: .onSale, eventCategory: "페스티벌"
            ),
            CalendarEvent(
                id: UUID(), date: date(14), title: "원더리벳", color: .green,
                concertTitle: "WONDERLIVET 2025",
                concertDate: "2025년 11월 22~24일 (금~일)",
                venueName: "KSPO DOME", bookingPlatform: "멜론티켓",
                ticketOpenDate: "11.08 (금) 20:00",
                ticketPrices: ["3일권 329,000원", "2일권 229,000원", "1일권 143,000원"],
                bookingStatus: .onSale, eventCategory: "페스티벌"
            ),
            CalendarEvent(
                id: UUID(), date: date(14), title: "피에타", color: .red,
                concertTitle: "피에타 정규 2집 발매 기념 공연",
                concertDate: "2025년 11월 14일 (금)",
                venueName: "프리즘홀", bookingPlatform: "인터파크 티켓",
                ticketOpenDate: "10.07 (화) 20:00",
                ticketPrices: ["전석 44,000원"],
                bookingStatus: .upcoming, eventCategory: "국내공연"
            ),
            CalendarEvent(
                id: UUID(), date: date(20), title: "백예린", color: .red,
                concertTitle: "Yerin Baek 2025 Live : wanna see you dance again",
                concertDate: "2025년 11월 22~24일 (금~일)",
                venueName: "에스펙토리 성수", bookingPlatform: "NOL 티켓",
                ticketOpenDate: "11.12 (화) 19:00",
                ticketPrices: ["전석 110,000원"],
                bookingStatus: .upcoming, eventCategory: "국내공연"
            ),
            CalendarEvent(
                id: UUID(), date: date(27), title: "데이먼스이어", color: .red,
                concertTitle: "데이먼스이어 연말 콘서트",
                concertDate: "2025년 11월 27일 (목)",
                venueName: "Yes24 라이브홀", bookingPlatform: "YES24 라이브",
                ticketOpenDate: "10.25 (토) 14:00",
                ticketPrices: ["전석 66,000원"],
                bookingStatus: .upcoming, eventCategory: "국내공연"
            ),
        ]
    }

    func fetchRecommendedArtists() async -> [Artist] {
        [
            Artist(id: UUID(), name: "Post Malone",   avatarUrl: nil, followersCount: 920_000, upcomingEventCount: 3, isFollowing: false),
            Artist(id: UUID(), name: "윤하",           avatarUrl: nil, followersCount: 129_000, upcomingEventCount: 8, isFollowing: false),
            Artist(id: UUID(), name: "Yonezu Kenshi", avatarUrl: nil, followersCount: 605_000, upcomingEventCount: 5, isFollowing: false),
        ]
    }

    func fetchFollowedArtistIds() async -> Set<UUID> { [] }

    func toggleFollow(artistId: UUID, currentlyFollowing: Bool) async throws {}

    func searchArtists(keyword: String) async throws -> [Artist] {
        let all = await fetchRecommendedArtists()
        return all.filter { $0.name.localizedCaseInsensitiveContains(keyword) }
    }
}
