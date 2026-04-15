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

        var bannerCount: Int { banners.count }

        static let empty = State()
    }

    // MARK: - Properties

    private(set) var state: State = .empty
    var onStateChanged: (() -> Void)?

    private let fetchHomeEventsUseCase: any FetchHomeEventsUseCaseProtocol

    // MARK: - Init

    init(fetchHomeEventsUseCase: some FetchHomeEventsUseCaseProtocol) {
        self.fetchHomeEventsUseCase = fetchHomeEventsUseCase
    }

    // MARK: - Input

    func viewDidLoad() {
        let result = fetchHomeEventsUseCase.execute()
        state = State(
            banners: result.banners,
            interestedEvents: result.interestedEvents,
            upcomingEvents: result.upcomingEvents,
            newlyStartedEvents: result.newlyStartedEvents,
            soonEndingEvents: result.soonEndingEvents
        )
        onStateChanged?()
    }
}
