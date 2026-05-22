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
        var isLoading: Bool = false
    }

    private(set) var state: State = .init()
    var onStateChanged: (() -> Void)?
    var onError: ((String) -> Void)?
    var onLoginRequired: ((@escaping () -> Void) -> Void)?

    private let useCase: FetchArtistDataUseCase

    init(useCase: FetchArtistDataUseCase) {
        self.useCase = useCase
    }

    func viewDidLoad() {
        state.isLoading = true
        onStateChanged?()
        Task {
            do {
                async let result = useCase.execute()
                async let calEvents = useCase.fetchCalendarEvents(year: state.calendarYear, month: state.calendarMonth)
                let (r, events) = try await (result, calEvents)
                state.myArtists = r.myArtists
                state.popularArtists = r.popularArtists
                state.recommendedArtists = r.recommendedArtists
                state.calendarEvents = events
            } catch {
                onError?("아티스트 정보를 불러오지 못했습니다.")
            }
            state.isLoading = false
            onStateChanged?()
        }
    }

    func refreshFollowStates() {
        Task {
            async let fetchResult = useCase.execute()
            
            async let fetchedFollowIds = useCase.fetchFollowedArtistIds()
            let followedIds = await fetchedFollowIds
            if let result = try? await fetchResult {
                state.myArtists = result.myArtists
            }
            for idx in state.recommendedArtists.indices {
                state.recommendedArtists[idx].isFollowing = followedIds.contains(state.recommendedArtists[idx].id)
            }
            onStateChanged?()
        }
    }

    func changeMonth(by delta: Int) {
        var month = state.calendarMonth + delta
        var year = state.calendarYear
        if month > 12 { month = 1; year += 1 }
        if month < 1  { month = 12; year -= 1 }
        state.calendarMonth = month
        state.calendarYear = year
        Task {
            do {
                state.calendarEvents = try await useCase.fetchCalendarEvents(year: year, month: month)
            } catch {
                onError?("캘린더 정보를 불러오지 못했습니다.")
            }
            onStateChanged?()
        }
    }

    func toggleFollow(artistId: UUID) {
        guard AuthService.shared.isLoggedIn else {
            onLoginRequired? { [weak self] in self?.toggleFollow(artistId: artistId) }
            return
        }
        let inMyList = state.myArtists.first(where: { $0.id == artistId })?.isFollowing
        let inRecommended = state.recommendedArtists.first(where: { $0.id == artistId })?.isFollowing
        let wasFollowing: Bool = inMyList ?? inRecommended ?? false
        if let idx = state.myArtists.firstIndex(where: { $0.id == artistId }) {
            state.myArtists[idx].isFollowing.toggle()
        }
        if let idx = state.recommendedArtists.firstIndex(where: { $0.id == artistId }) {
            state.recommendedArtists[idx].isFollowing.toggle()
        }
        onStateChanged?()
        Task {
            do {
                try await useCase.toggleFollow(artistId: artistId, currentlyFollowing: wasFollowing)
                NotificationCenter.default.post(name: .artistFollowDidChange, object: artistId)
            } catch {
                // 롤백
                if let idx = state.myArtists.firstIndex(where: { $0.id == artistId }) {
                    state.myArtists[idx].isFollowing = wasFollowing
                }
                if let idx = state.recommendedArtists.firstIndex(where: { $0.id == artistId }) {
                    state.recommendedArtists[idx].isFollowing = wasFollowing
                }
                onStateChanged?()
                onError?("팔로우 처리에 실패했습니다.")
            }
        }
    }
}
