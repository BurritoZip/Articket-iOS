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
    private let recommendationUseCase: any FetchArtistRecommendationsUseCaseProtocol

    init(
        useCase: FetchArtistDataUseCase,
        recommendationUseCase: any FetchArtistRecommendationsUseCaseProtocol
    ) {
        self.useCase = useCase
        self.recommendationUseCase = recommendationUseCase
    }

    func viewDidLoad() {
        state.isLoading = true
        onStateChanged?()
        Task {
            do {
                // 내 아티스트/캘린더는 기존 소스(Supabase), 인기/추천은 별도 추천 API.
                // 추천 API는 선택적 섹션 — 미배포/장애로 실패해도 화면 전체를 막지 않도록
                // 비throwing(try?)으로 격리한다. 핵심 데이터만 try await 묶음에 둔다.
                async let result = useCase.execute()
                async let calEvents = useCase.fetchCalendarEvents(year: state.calendarYear, month: state.calendarMonth)
                async let follows = useCase.fetchFollowedArtistIds()
                async let recsOptional = fetchRecommendationsSafely()

                let (r, events, followedIds, rec) = try await (result, calEvents, follows, recsOptional)
                state.myArtists = r.myArtists
                state.calendarEvents = events

                // 인기 아티스트: 추천 API 응답이 있으면 우선 사용(rank 배지),
                // 미배포/실패로 비면 Supabase 인기 목록으로 폴백(useCase.execute가 이미 조회함).
                if let rec, !rec.popular.isEmpty {
                    state.popularArtists = rec.popular.enumerated().map { idx, item in
                        PopularArtist(
                            id: item.id,
                            name: item.name,
                            imageUrl: item.avatarUrl,
                            badge: "\(item.rank ?? idx + 1)"
                        )
                    }
                } else {
                    state.popularArtists = r.popularArtists
                }

                // 추천(For You): 추천 API 우선, 실패/빈 응답 시 Supabase 추천으로 폴백.
                // 팔로워수·인지도는 운영 지표라 추천 응답에 없음 → 0/nil 로 둔다(셀 미표시).
                if let rec, !rec.forYou.isEmpty {
                    state.recommendedArtists = rec.forYou.map { item in
                        Artist(
                            id: item.id,
                            name: item.name,
                            nameEn: nil,
                            avatarUrl: item.avatarUrl,
                            followersCount: 0,
                            upcomingEventCount: item.upcomingEventCount ?? 0,
                            isFollowing: followedIds.contains(item.id),
                            popularityScore: nil,
                            trendingScore: nil
                        )
                    }
                } else {
                    state.recommendedArtists = r.recommendedArtists.map { artist in
                        var a = artist
                        a.isFollowing = followedIds.contains(artist.id)
                        return a
                    }
                }
            } catch {
                onError?("아티스트 정보를 불러오지 못했습니다.")
            }
            state.isLoading = false
            onStateChanged?()
        }
    }

    /// 추천 API 호출을 비throwing으로 래핑 — 실패 시 nil 반환해 나머지 로딩을 막지 않는다.
    private func fetchRecommendationsSafely() async -> ArtistRecommendationsResult? {
        try? await recommendationUseCase.execute(popularLimit: 20, forYouLimit: 20)
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
        // 롤백용 이전 팔로워 수 캡처
        let prevMyCount = state.myArtists.first(where: { $0.id == artistId })?.followersCount
        let prevRecCount = state.recommendedArtists.first(where: { $0.id == artistId })?.followersCount
        let delta = wasFollowing ? -1 : 1
        if let idx = state.myArtists.firstIndex(where: { $0.id == artistId }) {
            state.myArtists[idx].isFollowing.toggle()
            state.myArtists[idx].followersCount = max(0, state.myArtists[idx].followersCount + delta)
        }
        if let idx = state.recommendedArtists.firstIndex(where: { $0.id == artistId }) {
            state.recommendedArtists[idx].isFollowing.toggle()
            state.recommendedArtists[idx].followersCount = max(0, state.recommendedArtists[idx].followersCount + delta)
        }
        onStateChanged?()
        Task {
            do {
                try await useCase.toggleFollow(artistId: artistId, currentlyFollowing: wasFollowing)
                NotificationCenter.default.post(name: .artistFollowDidChange, object: artistId)
            } catch {
                // 롤백 (isFollowing + followersCount)
                if let idx = state.myArtists.firstIndex(where: { $0.id == artistId }) {
                    state.myArtists[idx].isFollowing = wasFollowing
                    if let prev = prevMyCount { state.myArtists[idx].followersCount = prev }
                }
                if let idx = state.recommendedArtists.firstIndex(where: { $0.id == artistId }) {
                    state.recommendedArtists[idx].isFollowing = wasFollowing
                    if let prev = prevRecCount { state.recommendedArtists[idx].followersCount = prev }
                }
                onStateChanged?()
                onError?("팔로우 처리에 실패했습니다.")
            }
        }
    }
}
