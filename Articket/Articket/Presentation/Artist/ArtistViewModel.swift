import Foundation

@MainActor
final class ArtistViewModel {
    struct State {
        var myArtists: [Artist] = []
        var popularArtists: [PopularArtist] = []
        var calendarYear: Int = Calendar.current.component(.year, from: Date())
        var calendarMonth: Int = Calendar.current.component(.month, from: Date())
        var calendarEvents: [CalendarEvent] = []
        var recommendedArtists: [Artist] = []
    }

    private(set) var state: State = .init()
    var onStateChanged: (() -> Void)?

    private let useCase: FetchArtistDataUseCase

    init(useCase: FetchArtistDataUseCase) {
        self.useCase = useCase
    }

    func viewDidLoad() {
        let result = useCase.execute()
        state.myArtists = result.myArtists
        state.popularArtists = result.popularArtists
        state.recommendedArtists = result.recommendedArtists
        state.calendarEvents = useCase.fetchCalendarEvents(year: state.calendarYear, month: state.calendarMonth)
        onStateChanged?()
    }

    func changeMonth(by delta: Int) {
        var month = state.calendarMonth + delta
        var year = state.calendarYear
        if month > 12 { month = 1; year += 1 }
        if month < 1  { month = 12; year -= 1 }
        state.calendarMonth = month
        state.calendarYear = year
        state.calendarEvents = useCase.fetchCalendarEvents(year: year, month: month)
        onStateChanged?()
    }

    func toggleFollow(artistId: UUID) {
        if let idx = state.myArtists.firstIndex(where: { $0.id == artistId }) {
            state.myArtists[idx].isFollowing.toggle()
        }
        if let idx = state.recommendedArtists.firstIndex(where: { $0.id == artistId }) {
            state.recommendedArtists[idx].isFollowing.toggle()
        }
        onStateChanged?()
    }
}
