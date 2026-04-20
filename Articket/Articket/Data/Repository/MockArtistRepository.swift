import Foundation

final class MockArtistRepository: ArtistRepositoryProtocol {

    func fetchMyArtists() -> [Artist] {
        [
            Artist(id: UUID(), name: "백예린", avatarAssetName: nil, followersCount: 129_000, upcomingEventCount: 3, isFollowing: true),
            Artist(id: UUID(), name: "검정치마", avatarAssetName: nil, followersCount: 87_000, upcomingEventCount: 2, isFollowing: true),
            Artist(id: UUID(), name: "The 1975", avatarAssetName: nil, followersCount: 450_000, upcomingEventCount: 1, isFollowing: true),
            Artist(id: UUID(), name: "미노이", avatarAssetName: nil, followersCount: 62_000, upcomingEventCount: 4, isFollowing: true),
            Artist(id: UUID(), name: "한로로", avatarAssetName: nil, followersCount: 34_000, upcomingEventCount: 2, isFollowing: true),
            Artist(id: UUID(), name: "기리보이", avatarAssetName: nil, followersCount: 210_000, upcomingEventCount: 3, isFollowing: true),
            Artist(id: UUID(), name: "윤지영", avatarAssetName: nil, followersCount: 28_000, upcomingEventCount: 1, isFollowing: true),
        ]
    }

    func fetchPopularArtists() -> [PopularArtist] {
        [
            PopularArtist(id: UUID(), name: "The Volunteers", imageAssetName: nil, badge: "티켓팅 오픈"),
            PopularArtist(id: UUID(), name: "Oasis", imageAssetName: nil, badge: "내한 확정"),
            PopularArtist(id: UUID(), name: "유다빈밴드(YdBB)", imageAssetName: nil, badge: "컴백 예정"),
        ]
    }

    func fetchCalendarEvents(year: Int, month: Int) -> [CalendarEvent] {
        var components = DateComponents()
        components.year = year
        components.month = month
        let cal = Calendar.current

        func date(_ day: Int) -> Date {
            components.day = day
            return cal.date(from: components) ?? Date()
        }

        return [
            CalendarEvent(id: UUID(), date: date(1),  title: "부산락페스티벌", color: .green),
            CalendarEvent(id: UUID(), date: date(2),  title: "부산락페스티벌", color: .green),
            CalendarEvent(id: UUID(), date: date(5),  title: "헤이즈",         color: .red),
            CalendarEvent(id: UUID(), date: date(8),  title: "기리보이",        color: .red),
            CalendarEvent(id: UUID(), date: date(9),  title: "기리보이",        color: .red),
            CalendarEvent(id: UUID(), date: date(10), title: "One of Rock",    color: .yellow),
            CalendarEvent(id: UUID(), date: date(10), title: "부산락페스티벌", color: .green),
            CalendarEvent(id: UUID(), date: date(14), title: "원더리벳",        color: .green),
            CalendarEvent(id: UUID(), date: date(14), title: "피에타",          color: .red),
            CalendarEvent(id: UUID(), date: date(20), title: "백예린",          color: .red),
            CalendarEvent(id: UUID(), date: date(27), title: "데이먼스이어",    color: .red),
        ]
    }

    func fetchRecommendedArtists() -> [Artist] {
        [
            Artist(id: UUID(), name: "Post Malone",   avatarAssetName: nil, followersCount: 920_000, upcomingEventCount: 3, isFollowing: false),
            Artist(id: UUID(), name: "윤하",           avatarAssetName: nil, followersCount: 129_000, upcomingEventCount: 8, isFollowing: false),
            Artist(id: UUID(), name: "Yonezu Kenshi", avatarAssetName: nil, followersCount: 605_000, upcomingEventCount: 5, isFollowing: false),
        ]
    }
}
