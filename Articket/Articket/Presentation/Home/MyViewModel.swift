import Foundation

@MainActor
final class MyViewModel {

    struct State {
        var bookings: [Booking] = []
        var stats: MyStats? = nil
        var artistRankings: [ArtistRankEntry] = []
    }

    private let fetchMyDataUseCase: FetchMyDataUseCase
    private(set) var state: State = .init()
    var onStateChanged: (() -> Void)?

    init(fetchMyDataUseCase: FetchMyDataUseCase) {
        self.fetchMyDataUseCase = fetchMyDataUseCase
    }

    func viewDidLoad() {
        let result = fetchMyDataUseCase.execute()
        state.bookings = result.bookings
        state.stats = result.stats
        state.artistRankings = result.artistRankings
        onStateChanged?()
    }

    func toggleArtistExpansion(at index: Int) {
        guard index < state.artistRankings.count else { return }
        state.artistRankings[index].isExpanded.toggle()
        onStateChanged?()
    }
}
