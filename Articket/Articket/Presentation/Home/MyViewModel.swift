import Foundation

@MainActor
final class MyViewModel {

    struct State {
        var bookings: [Booking] = []
        var stats: MyStats? = nil
        var artistRankings: [ArtistRankEntry] = []
        var isLoading: Bool = false
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
}
