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
        var recommendedEvents: [Event] = []
        var isLoading: Bool = false

        var bannerCount: Int { banners.count }

        static let empty = State()
    }

    // MARK: - Properties

    private(set) var state: State = .empty
    var onStateChanged: (() -> Void)?
    var onError: ((String) -> Void)?

    private let fetchHomeEventsUseCase: any FetchHomeEventsUseCaseProtocol
    private let fetchRecommendationsUseCase: any FetchRecommendationsUseCaseProtocol

    // MARK: - Init

    init(
        fetchHomeEventsUseCase: some FetchHomeEventsUseCaseProtocol,
        fetchRecommendationsUseCase: some FetchRecommendationsUseCaseProtocol
    ) {
        self.fetchHomeEventsUseCase = fetchHomeEventsUseCase
        self.fetchRecommendationsUseCase = fetchRecommendationsUseCase
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
                    recommendedEvents: state.recommendedEvents,
                    isLoading: false
                )
                onStateChanged?()
            } catch {
                state.isLoading = false
                onError?("공연 정보를 불러오지 못했습니다.")
                onStateChanged?()
                return
            }
            // 추천은 부가 콘텐츠 — 홈 표시를 막지 않고 도착 시 갱신
            let recommended = await loadRecommendations()
            state.recommendedEvents = recommended
            onStateChanged?()
        }
    }

    /// 추천: 미로그인/실패 시 빈 배열(섹션 숨김)
    private func loadRecommendations() async -> [Event] {
        (try? await fetchRecommendationsUseCase.execute(limit: 10, offset: 0))?.items ?? []
    }
}
