import Foundation

final class MockTimetableRepository: TimetableRepositoryProtocol {
    func fetchTimetable(eventId: UUID) async -> [TimetablePerformance] {
        [
            TimetablePerformance(
                id: UUID(), eventId: eventId, artistId: nil, dayNumber: 1,
                dateString: "2025.11.01", startTime: "13:00", endTime: "13:40",
                artistName: "한로로", stageName: "GREEN STAGE", genre: "인디"
            ),
            TimetablePerformance(
                id: UUID(), eventId: eventId, artistId: nil, dayNumber: 1,
                dateString: "2025.11.01", startTime: "14:00", endTime: "14:50",
                artistName: "검정치마", stageName: "GREEN STAGE", genre: "록"
            ),
            TimetablePerformance(
                id: UUID(), eventId: eventId, artistId: nil, dayNumber: 2,
                dateString: "2025.11.02", startTime: "15:00", endTime: "15:50",
                artistName: "백예린", stageName: "BLUE STAGE", genre: "팝"
            ),
        ]
    }
}
