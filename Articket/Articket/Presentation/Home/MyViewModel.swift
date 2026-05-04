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
            } catch { }
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
