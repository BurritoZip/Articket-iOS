@testable import Articket

import Foundation

final class MockTimetableRepository: TimetableRepositoryProtocol {

    static let shared = MockTimetableRepository()
    private init() {}

    func fetchTimetableEvents() async throws -> [TimetableEvent] {
        [seoulJazzFestival, blackSkirts2025, volunteersEncore, endlessSummer]
    }

    // computed property이므로 매번 새 UUID() 생성 방지 — 고정 UUID 사용
    private var seoulJazzFestival: TimetableEvent {
        TimetableEvent(
            id: UUID(uuidString: "11111111-0000-0000-0000-000000000001")!,
            title: "제18회 서울재즈페스티벌 2026",
            posterUrl: nil,
            dateRange: "2026.05.22 ~ 2026.05.24",
            venueName: "올림픽공원",
            days: [
                TimetableDay(dayNumber: 1, dateString: "2026.05.22", performances: [
                    Performance(id: UUID(uuidString: "A1000001-0000-0000-0000-000000000001")!, startTime: "17:00", endTime: "18:00", artistName: "한로로", stageName: "STAGE A", genre: "R&B"),
                    Performance(id: UUID(uuidString: "A1000001-0000-0000-0000-000000000002")!, startTime: "17:30", endTime: "18:20", artistName: "The 1975", stageName: "STAGE B", genre: "Band"),
                    Performance(id: UUID(uuidString: "A1000001-0000-0000-0000-000000000003")!, startTime: "18:00", endTime: "19:00", artistName: "Yerin Baek", stageName: "STAGE A", genre: "R&B"),
                    Performance(id: UUID(uuidString: "A1000001-0000-0000-0000-000000000004")!, startTime: "18:20", endTime: "19:20", artistName: "KC", stageName: "STAGE C", genre: "Hiphop"),
                    Performance(id: UUID(uuidString: "A1000001-0000-0000-0000-000000000005")!, startTime: "19:00", endTime: "20:00", artistName: "The Black Skirts", stageName: "STAGE B", genre: "INDIE"),
                    Performance(id: UUID(uuidString: "A1000001-0000-0000-0000-000000000006")!, startTime: "20:00", endTime: "21:20", artistName: "Post Malone", stageName: "STAGE A", genre: "R&B")
                ]),
                TimetableDay(dayNumber: 2, dateString: "2026.05.23", performances: [
                    Performance(id: UUID(uuidString: "A1000002-0000-0000-0000-000000000001")!, startTime: "17:00", endTime: "18:00", artistName: "Peder Elias", stageName: "STAGE A", genre: "Pop"),
                    Performance(id: UUID(uuidString: "A1000002-0000-0000-0000-000000000002")!, startTime: "17:30", endTime: "18:30", artistName: "Leellamarz", stageName: "STAGE B", genre: "Hiphop"),
                    Performance(id: UUID(uuidString: "A1000002-0000-0000-0000-000000000003")!, startTime: "18:00", endTime: "19:00", artistName: "Lee Young Ji", stageName: "STAGE C", genre: "Hiphop"),
                    Performance(id: UUID(uuidString: "A1000002-0000-0000-0000-000000000004")!, startTime: "19:00", endTime: "20:00", artistName: "Lauv", stageName: "STAGE A", genre: "Pop"),
                    Performance(id: UUID(uuidString: "A1000002-0000-0000-0000-000000000005")!, startTime: "19:30", endTime: "20:30", artistName: "Beenzino", stageName: "STAGE B", genre: "Hiphop"),
                    Performance(id: UUID(uuidString: "A1000002-0000-0000-0000-000000000006")!, startTime: "20:00", endTime: "21:00", artistName: "wave to earth", stageName: "STAGE C", genre: "Indie")
                ]),
                TimetableDay(dayNumber: 3, dateString: "2026.05.24", performances: [
                    Performance(id: UUID(uuidString: "A1000003-0000-0000-0000-000000000001")!, startTime: "17:00", endTime: "18:00", artistName: "meenoi", stageName: "STAGE C", genre: "R&B"),
                    Performance(id: UUID(uuidString: "A1000003-0000-0000-0000-000000000002")!, startTime: "17:30", endTime: "18:20", artistName: "Coogie", stageName: "STAGE B", genre: "Hiphop"),
                    Performance(id: UUID(uuidString: "A1000003-0000-0000-0000-000000000003")!, startTime: "19:00", endTime: "20:00", artistName: "Prep", stageName: "STAGE A", genre: "Pop"),
                    Performance(id: UUID(uuidString: "A1000003-0000-0000-0000-000000000004")!, startTime: "19:30", endTime: "20:30", artistName: "HANRORO", stageName: "STAGE C", genre: "R&B"),
                    Performance(id: UUID(uuidString: "A1000003-0000-0000-0000-000000000005")!, startTime: "20:00", endTime: "21:00", artistName: "검정치마", stageName: "STAGE A", genre: "INDIE"),
                    Performance(id: UUID(uuidString: "A1000003-0000-0000-0000-000000000006")!, startTime: "20:30", endTime: "21:30", artistName: "Epik High", stageName: "STAGE B", genre: "Hiphop")
                ])
            ]
        )
    }

    private var blackSkirts2025: TimetableEvent {
        TimetableEvent(
            id: UUID(uuidString: "11111111-0000-0000-0000-000000000002")!,
            title: "2025 검정치마 단독공연 \"SONGS TO BRING YOU HOME\"",
            posterUrl: nil,
            dateRange: "2025.02.07 ~ 2025.02.09",
            venueName: "올림픽공원 올림픽홀",
            days: [
                TimetableDay(dayNumber: 1, dateString: "2025.02.07", performances: [
                    Performance(id: UUID(uuidString: "B1000001-0000-0000-0000-000000000001")!, startTime: "18:00", endTime: "19:00", artistName: "Opening Act", stageName: "STAGE A", genre: "INDIE"),
                    Performance(id: UUID(uuidString: "B1000001-0000-0000-0000-000000000002")!, startTime: "19:00", endTime: "21:30", artistName: "검정치마", stageName: "STAGE A", genre: "INDIE")
                ]),
                TimetableDay(dayNumber: 2, dateString: "2025.02.08", performances: [
                    Performance(id: UUID(uuidString: "B1000002-0000-0000-0000-000000000001")!, startTime: "18:00", endTime: "19:00", artistName: "Opening Act", stageName: "STAGE A", genre: "INDIE"),
                    Performance(id: UUID(uuidString: "B1000002-0000-0000-0000-000000000002")!, startTime: "19:00", endTime: "21:30", artistName: "검정치마", stageName: "STAGE A", genre: "INDIE")
                ]),
                TimetableDay(dayNumber: 3, dateString: "2025.02.09", performances: [
                    Performance(id: UUID(uuidString: "B1000003-0000-0000-0000-000000000001")!, startTime: "18:00", endTime: "19:00", artistName: "Opening Act", stageName: "STAGE A", genre: "INDIE"),
                    Performance(id: UUID(uuidString: "B1000003-0000-0000-0000-000000000002")!, startTime: "19:00", endTime: "21:30", artistName: "검정치마", stageName: "STAGE A", genre: "INDIE")
                ])
            ]
        )
    }

    private var volunteersEncore: TimetableEvent {
        TimetableEvent(
            id: UUID(uuidString: "11111111-0000-0000-0000-000000000003")!,
            title: "THE VOLUNTEERS TOUR 2024 ENCORE CONCERT [Bye, Summer]",
            posterUrl: nil,
            dateRange: "2024.10.12 ~ 2024.10.13",
            venueName: "블루스퀘어 마스터카드홀",
            days: [
                TimetableDay(dayNumber: 1, dateString: "2024.10.12", performances: [
                    Performance(id: UUID(uuidString: "C1000001-0000-0000-0000-000000000001")!, startTime: "17:30", endTime: "18:30", artistName: "Opening Act", stageName: "STAGE A", genre: "Indie"),
                    Performance(id: UUID(uuidString: "C1000001-0000-0000-0000-000000000002")!, startTime: "19:00", endTime: "21:00", artistName: "The Volunteers", stageName: "STAGE A", genre: "Indie")
                ]),
                TimetableDay(dayNumber: 2, dateString: "2024.10.13", performances: [
                    Performance(id: UUID(uuidString: "C1000002-0000-0000-0000-000000000001")!, startTime: "17:30", endTime: "18:30", artistName: "Opening Act", stageName: "STAGE A", genre: "Indie"),
                    Performance(id: UUID(uuidString: "C1000002-0000-0000-0000-000000000002")!, startTime: "19:00", endTime: "21:00", artistName: "The Volunteers", stageName: "STAGE A", genre: "Indie")
                ])
            ]
        )
    }

    private var endlessSummer: TimetableEvent {
        TimetableEvent(
            id: UUID(uuidString: "11111111-0000-0000-0000-000000000004")!,
            title: "ENDLESS SUMMER : 2023 검정치마 앵콜 공연 \"HOME\"",
            posterUrl: nil,
            dateRange: "2023.08.25 ~ 2023.08.26",
            venueName: "블루스퀘어 마스터카드홀",
            days: [
                TimetableDay(dayNumber: 1, dateString: "2023.08.25", performances: [
                    Performance(id: UUID(uuidString: "D1000001-0000-0000-0000-000000000001")!, startTime: "18:00", endTime: "19:00", artistName: "Opening Act", stageName: "STAGE A", genre: "INDIE"),
                    Performance(id: UUID(uuidString: "D1000001-0000-0000-0000-000000000002")!, startTime: "19:00", endTime: "21:30", artistName: "검정치마", stageName: "STAGE A", genre: "INDIE")
                ]),
                TimetableDay(dayNumber: 2, dateString: "2023.08.26", performances: [
                    Performance(id: UUID(uuidString: "D1000002-0000-0000-0000-000000000001")!, startTime: "18:00", endTime: "19:00", artistName: "Opening Act", stageName: "STAGE A", genre: "INDIE"),
                    Performance(id: UUID(uuidString: "D1000002-0000-0000-0000-000000000002")!, startTime: "19:00", endTime: "21:30", artistName: "검정치마", stageName: "STAGE A", genre: "INDIE")
                ])
            ]
        )
    }
}
