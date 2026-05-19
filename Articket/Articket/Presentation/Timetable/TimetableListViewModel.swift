import Foundation

@MainActor
final class TimetableListViewModel {

    struct State {
        var events: [TimetableEvent] = []
        var isLoading: Bool = false
        var errorMessage: String? = nil
    }

    private(set) var state = State()
    var onStateChanged: (() -> Void)?

    private let repository: TimetableRepositoryProtocol

    init(repository: TimetableRepositoryProtocol) {
        self.repository = repository
    }

    func viewDidLoad() {
        state.isLoading = true
        state.errorMessage = nil
        onStateChanged?()
        Task {
            do {
                let events = try await repository.fetchTimetableEvents()
                state.events = events
                state.errorMessage = nil
            } catch {
                print("[Timetable] 이벤트 로드 실패:", error)
                state.errorMessage = error.localizedDescription
            }
            state.isLoading = false
            onStateChanged?()
        }
    }
}
