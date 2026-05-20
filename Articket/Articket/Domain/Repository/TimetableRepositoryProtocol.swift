import Foundation

protocol TimetableRepositoryProtocol: Sendable {
    func fetchTimetable(eventId: UUID) async throws -> [TimetablePerformance]
}
