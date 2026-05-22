import Foundation

@MainActor
final class HomeViewModel {

    // MARK: - State

    struct State {
        var banners: [Event] = []
        var interestedEvents: [Event] = []
        var upcomingEvents: [Event] = []
        var newlyStartedEvents: [Event] = []
        var soonEndingEvents: [Event] = []
        var isLoading: Bool = false

        var bannerCount: Int { banners.count }

        static let empty = State()
    }

    // MARK: - Properties

    private(set) var state: State = .empty
    var onStateChanged: (() -> Void)?
    var onError: ((String) -> Void)?

    private let fetchHomeEventsUseCase: any FetchHomeEventsUseCaseProtocol

    // MARK: - Init

    init(fetchHomeEventsUseCase: some FetchHomeEventsUseCaseProtocol) {
        self.fetchHomeEventsUseCase = fetchHomeEventsUseCase
    }

    // MARK: - Input

    func viewDidLoad() {
        loadEvents()
    }

    func reload() {
        loadEvents()
    }

    func refreshInterestedEvents() {
        Task {
            guard let result = try? await fetchHomeEventsUseCase.execute() else { return }
            state.interestedEvents = result.interestedEvents
            onStateChanged?()
        }
    }

    private func loadEvents() {
        state.isLoading = true
        onStateChanged?()
        Task {
            do {
                let result = try await fetchHomeEventsUseCase.execute()
                state = State(
                    banners: result.banners,
                    interestedEvents: result.interestedEvents,
                    upcomingEvents: result.upcomingEvents,
                    newlyStartedEvents: result.newlyStartedEvents,
                    soonEndingEvents: result.soonEndingEvents,
                    isLoading: false
                )
            } catch {
                state.isLoading = false
                onError?("공연 정보를 불러오지 못했습니다.")
            }
            onStateChanged?()
        }
    }
}
