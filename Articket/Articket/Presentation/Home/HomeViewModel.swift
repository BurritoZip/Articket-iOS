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
        /// 외부 예매처에 다녀왔지만 아직 예매 여부를 답하지 않은 건 (최신 1건만 노출)
        var pendingBookingIntent: BookingIntent?
        var isLoading: Bool = false

        var bannerCount: Int { banners.count }

        static let empty = State()
    }

    // MARK: - Properties

    private(set) var state: State = .empty
    var onStateChanged: (() -> Void)?
    var onError: ((String) -> Void)?
    /// 비로그인 상태에서 '예매했다'고 답한 경우 — 로그인 후 원래 액션을 재실행한다
    var onLoginRequired: ((@escaping () -> Void) -> Void)?
    /// CTA 응답 결과 안내 (토스트)
    var onBookingIntentResolved: ((String) -> Void)?
    /// 바로가기 "예매 일정" — 티켓 오픈 임박순 리스트 로드 완료 (상위 VC가 EventList로 라우팅)
    var onTicketScheduleLoaded: (([Event]) -> Void)?

    private let fetchHomeEventsUseCase: any FetchHomeEventsUseCaseProtocol
    private let fetchRecommendationsUseCase: any FetchRecommendationsUseCaseProtocol
    private let bookingRepository: any BookingRepositoryProtocol
    private let eventRepository: any EventRepositoryProtocol

    // MARK: - Init

    init(
        fetchHomeEventsUseCase: some FetchHomeEventsUseCaseProtocol,
        fetchRecommendationsUseCase: some FetchRecommendationsUseCaseProtocol,
        bookingRepository: any BookingRepositoryProtocol = SupabaseBookingRepository(),
        eventRepository: any EventRepositoryProtocol = SupabaseEventRepository()
    ) {
        self.fetchHomeEventsUseCase = fetchHomeEventsUseCase
        self.fetchRecommendationsUseCase = fetchRecommendationsUseCase
        self.bookingRepository = bookingRepository
        self.eventRepository = eventRepository
    }

    /// 바로가기 "예매 일정" 탭 — 티켓 오픈 임박 공연 조회 후 콜백
    func requestTicketSchedule() {
        Task {
            let events = (try? await eventRepository.fetchTicketOpenSchedule()) ?? []
            onTicketScheduleLoaded?(events)
        }
    }

    // MARK: - Input

    func viewDidLoad() {
        loadEvents()
        refreshBookingIntent()
    }

    func reload() {
        loadEvents()
        refreshBookingIntent()
    }

    // MARK: - 예매 확인 CTA

    /// 외부 예매처에서 돌아온 직후를 잡아야 하므로 홈 진입/포그라운드 복귀마다 다시 조회한다
    func refreshBookingIntent() {
        Task {
            let intent = await bookingRepository.fetchPendingBookingIntent()
            guard state.pendingBookingIntent != intent else { return }
            state.pendingBookingIntent = intent
            onStateChanged?()
        }
    }

    func confirmBookingIntent() {
        guard let intent = state.pendingBookingIntent else { return }
        // 예매 확정은 user_bookings에 기록이 남는 개인 데이터 → 로그인 필요
        guard AuthService.shared.isLoggedIn else {
            onLoginRequired? { [weak self] in self?.confirmBookingIntent() }
            return
        }
        // 응답 즉시 배너를 걷어 두 번 눌리는 것을 막는다 (실패 시 되돌림)
        state.pendingBookingIntent = nil
        onStateChanged?()
        Task {
            do {
                try await bookingRepository.resolveBookingIntent(eventId: intent.eventId, outcome: .booked)
                onBookingIntentResolved?("예매 완료로 기록했어요")
                refreshBookingIntent()
            } catch {
                state.pendingBookingIntent = intent
                onStateChanged?()
                onError?("예매 기록에 실패했어요. 잠시 후 다시 시도해주세요.")
            }
        }
    }

    func dismissBookingIntent() {
        guard let intent = state.pendingBookingIntent else { return }
        state.pendingBookingIntent = nil
        onStateChanged?()
        Task {
            // 'skipped'는 개인 기록이 남지 않으므로 로그인 없이도 처리된다 (로컬 삭제로 충분)
            try? await bookingRepository.resolveBookingIntent(eventId: intent.eventId, outcome: .skipped)
            refreshBookingIntent()
        }
    }

    func refreshInterestedEvents() {
        Task {
            guard let result = try? await fetchHomeEventsUseCase.execute() else { return }
            state.interestedEvents = Self.dedupedById(result.interestedEvents)
            onStateChanged?()
        }
    }

    /// 같은 event.id가 중복되면 diffable 스냅샷 apply 시 "duplicate identifiers" 크래시가 발생하므로
    /// 첫 등장만 남겨 id 기준 유일화한다. (관심공연 하트 재클릭 크래시 방어)
    private static func dedupedById(_ events: [Event]) -> [Event] {
        var seen = Set<UUID>()
        return events.filter { seen.insert($0.id).inserted }
    }

    private func loadEvents() {
        state.isLoading = true
        onStateChanged?()
        Task {
            do {
                let result = try await fetchHomeEventsUseCase.execute()
                state = State(
                    banners: result.banners,
                    interestedEvents: Self.dedupedById(result.interestedEvents),
                    upcomingEvents: result.upcomingEvents,
                    newlyStartedEvents: result.newlyStartedEvents,
                    soonEndingEvents: result.soonEndingEvents,
                    recommendedEvents: state.recommendedEvents,
                    isLoading: false
                )
                onStateChanged?()
            } catch {
                state.isLoading = false
                onError?("공연 정보를 불러오지 못했어요")
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
