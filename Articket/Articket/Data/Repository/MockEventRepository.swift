import Foundation

final class MockEventRepository: EventRepositoryProtocol {

    func fetchBannerEvents() async -> [Event] {
        [
            event("Yerin Baek 2025 Live", days: 5, duration: 4, venue: "SFACTORY 성수",
                  image: "Events/Banners/banner_yerin_baek"),
            event("2025 아이유 콘서트", days: 20, duration: 3, venue: "올림픽공원 체조경기장",
                  image: "Events/Banners/banner_iu"),
            event("The Black Skirts Tour", days: 35, duration: 2, venue: "예스24 라이브홀",
                  image: "Events/Banners/banner_black_skirts"),
        ]
    }

    func fetchInterestedEvents() async -> [Event] {
        [
            event("2025 검정치마 단독공연", days: 2, duration: 2, venue: "올림픽공원 올림픽홀",
                  interested: true, image: "Events/Interested/poster_black_skirts"),
            event("The Volunteers Tour", days: 10, duration: 2, venue: "블루스퀘어 마스터카드홀",
                  interested: true, image: "Events/Interested/poster_volunteers"),
            event("10cm 단독공연", days: 15, duration: 1, venue: "예스24 라이브홀",
                  interested: true, image: "Events/Interested/poster_10cm"),
            event("잔나비 콘서트", days: 30, duration: 3, venue: "올림픽공원 체조경기장",
                  interested: true, image: "Events/Interested/poster_jannabi"),
        ]
    }

    func fetchUpcomingEvents() async -> [Event] {
        [
            event("백예린 2025 Live [wanna see you danc...]", days: 5,  duration: 3, venue: "에스팩토리"),
            event("2025 Heize Concert [Heize City: LOVE...]", days: 41, duration: 3, venue: "영화라이브홀"),
            event("10cm 10주년 콘서트",  days: 60, duration: 2, venue: "올림픽공원 올림픽홀"),
            event("선우정아 단독공연",    days: 75, duration: 1, venue: "예스24 라이브홀"),
        ]
    }

    func fetchNewlyStartedEvents() async -> [Event] {
        [
            event("지소쿠리클럽 연말 단독 콘서트: Into the Wild", daysAgo: 5, duration: 2,
                  venue: "예스24 한드로크홀", image: "Events/NewlyStarted/newly_jisokkuri"),
            event("2025 데이먼스 이어 단독공연: Lunar Cycle System", daysAgo: 10, duration: 9,
                  venue: "예스24 라이브홀", image: "Events/NewlyStarted/newly_demons"),
            event("CHUU 2ND TINY-CON: 첫 눈이 오면 그때 가서 만나", daysAgo: 3, duration: 2,
                  venue: "신한카드 SOL페이 스퀘어 라이브홀", image: "Events/NewlyStarted/newly_chuu"),
            event("요네즈 켄시 내한공연", daysAgo: 1, duration: 5,
                  venue: "KSPO DOME", image: "Events/NewlyStarted/newly_yonezu"),
        ]
    }

    func fetchSoonEndingEvents() async -> [Event] {
        [
            event("2025 윤지영 단독공연: 시지프 신화 [THE MYTH OF SISYPHUS]", days: 1, duration: 0,
                  venue: "노들섬 라이브하우스", image: "Events/SoonEnding/ending_yun_jiyoung"),
            event("한로로 4TH 단독콘서트: 자몽살 구름탕", days: 2, duration: 1,
                  venue: "고려대학교 화정체육관", image: "Events/SoonEnding/ending_hanroro"),
            event("2025 Bye Bye Badman 단독 공연 'Bad Timing'", days: 3, duration: 0,
                  venue: "KT&G 상상마당 홍대 라이브홀", image: "Events/SoonEnding/ending_bad_timing"),
            event("소란 단독공연", days: 5, duration: 1,
                  venue: "예스24 라이브홀", image: "Events/SoonEnding/ending_soran"),
        ]
    }

    // MARK: - Private

    private func event(
        _ title: String,
        days: Int = 0,
        daysAgo: Int = 0,
        duration: Int = 1,
        venue: String,
        interested: Bool = false,
        image: String? = nil
    ) -> Event {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let start = daysAgo > 0
            ? cal.date(byAdding: .day, value: -daysAgo, to: today) ?? today
            : cal.date(byAdding: .day, value: days, to: today) ?? today
        let end = cal.date(byAdding: .day, value: duration, to: start) ?? start
        return Event(
            id: UUID(),
            title: title,
            imageAssetName: image,
            startDate: start,
            endDate: end,
            venueName: venue,
            isInterested: interested
        )
    }
}
