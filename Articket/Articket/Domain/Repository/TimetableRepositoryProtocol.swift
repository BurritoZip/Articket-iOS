import Foundation

protocol TimetableRepositoryProtocol {
    func fetchTimetableEvents() async throws -> [TimetableEvent]
}
