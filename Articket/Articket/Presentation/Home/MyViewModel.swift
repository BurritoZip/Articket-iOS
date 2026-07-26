import Foundation

@MainActor
final class MyViewModel {

    struct State {
        var bookings: [Booking] = []
        var stats: MyStats? = nil
        var artistRankings: [ArtistRankEntry] = []
        var yearlyShows: [Event] = []
        var isLoading: Bool = false
        /// 통계 카드 중 선택된 것 — 하단 상세 리스트가 이 카드에 맞게 스왑
        var selectedStatCard: StatCardKind = .topArtist
        /// 최애 상세를 top3 → 전체로 인라인 확장했는지 (최애 "더보기" 토글)
        var isStatExpanded: Bool = false
    }

    /// 상세 리스트 상단 노출 개수 (더보기 전)
    private static let statTopCount = 3

    /// 선택 카드의 아티스트 랭킹 행 (최애 전용). 확장 시 전체, 아니면 top3.
    var statArtistRows: [ArtistRankEntry] {
        state.selectedStatCard == .topArtist
            ? (state.isStatExpanded ? state.artistRankings : Array(state.artistRankings.prefix(Self.statTopCount)))
            : []
    }

    /// 선택 카드(최다관람/선호장르)의 관람작 필터 결과 전체
    var statEventsAll: [Event] {
        guard let stats = state.stats else { return [] }
        switch state.selectedStatCard {
        case .topView:
            let cal = Calendar.current
            return state.yearlyShows.filter { cal.component(.month, from: $0.startDate) == stats.topMonth }
        case .topGenre:
            return state.yearlyShows.filter { $0.genre == stats.topGenre }
        case .topArtist:
            return []
        }
    }

    /// 상세 리스트에 노출할 관람작 top3
    var statEventRows: [Event] { Array(statEventsAll.prefix(Self.statTopCount)) }

    /// 더보기/접기 행 노출 여부 — top3 초과일 때. 최애는 확장 상태와 무관하게
    /// 항상 노출(라벨이 더보기↔접기 토글). 이벤트는 초과분이 있을 때만(더보기=EventList).
    var showsStatSeeMore: Bool {
        state.selectedStatCard == .topArtist
            ? state.artistRankings.count > Self.statTopCount
            : (statEventsAll.count > Self.statTopCount)
    }

    private let fetchMyDataUseCase: FetchMyDataUseCase
    private(set) var state: State = .init()
    var onStateChanged: (() -> Void)?
    var onError: ((String) -> Void)?

    init(fetchMyDataUseCase: FetchMyDataUseCase) {
        self.fetchMyDataUseCase = fetchMyDataUseCase
    }

    func viewDidLoad() {
        state.isLoading = true
        onStateChanged?()
        Task {
            do {
                let result = try await fetchMyDataUseCase.execute()
                state.bookings = result.bookings
                state.stats = result.stats
                state.artistRankings = result.artistRankings
                state.yearlyShows = result.yearlyShows
            } catch {
                onError?("MY 데이터를 불러오지 못했습니다.")
            }
            state.isLoading = false
            onStateChanged?()
        }
    }

    func toggleArtistExpansion(at index: Int) {
        guard index < state.artistRankings.count else { return }
        state.artistRankings[index].isExpanded.toggle()
        onStateChanged?()
    }

    /// 통계 카드 선택 — 하단 상세 리스트를 해당 카드로 스왑 (확장 상태 초기화)
    func selectStatCard(_ kind: StatCardKind) {
        guard kind != state.selectedStatCard else { return }
        state.selectedStatCard = kind
        state.isStatExpanded = false
        onStateChanged?()
    }

    /// 최애 상세 "더보기" — top3 ↔ 전체 인라인 토글
    func toggleStatExpansion() {
        state.isStatExpanded.toggle()
        onStateChanged?()
    }
}
