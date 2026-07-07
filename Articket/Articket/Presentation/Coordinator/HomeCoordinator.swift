import UIKit

final class HomeCoordinator: Coordinator, SearchCoordinatorProtocol, ArtistDetailCoordinatorProtocol, ConcertDetailCoordinatorProtocol {

    let navigationController: UINavigationController
    private weak var searchNavigationController: UINavigationController?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let repository = SupabaseEventRepository()
        let useCase = FetchHomeEventsUseCase(repository: repository)
        let recUseCase = FetchRecommendationsUseCase(repository: SupabaseRecommendationRepository())
        let homeVM = HomeViewModel(
            fetchHomeEventsUseCase: useCase,
            fetchRecommendationsUseCase: recUseCase
        )
        let bookingRepository = SupabaseBookingRepository()
        let myUseCase = FetchMyDataUseCase(repository: bookingRepository)
        let myVM = MyViewModel(fetchMyDataUseCase: myUseCase)
        let vc = HomeViewController(viewModel: homeVM, myViewModel: myVM)
        vc.coordinator = self
        navigationController.setViewControllers([vc], animated: false)

        #if DEBUG
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.debugShowTimetableGrid()
        }
        #endif
    }

    func showSearch() {
        let vm = SearchViewModel()
        let vc = SearchViewController(viewModel: vm)
        vc.coordinator = self
        let nav = UINavigationController(rootViewController: vc)
        nav.isNavigationBarHidden = true
        nav.modalPresentationStyle = .fullScreen
        searchNavigationController = nav
        navigationController.present(nav, animated: true)
    }

    func showSearchResult(keyword: String) {
        let vc = SearchResultViewController(keyword: keyword, coordinator: self)
        searchNavigationController?.pushViewController(vc, animated: true)
    }

    /// 검색 모달이 떠 있으면 그 위(searchNavigationController)에, 아니면 홈 탭 스택에 push.
    /// (검색 결과 → 상세 진입 시 상세가 모달 뒤로 가려지던 문제 해결)
    private var activeNavigationController: UINavigationController {
        if let searchNav = searchNavigationController, searchNav.presentingViewController != nil {
            return searchNav
        }
        return navigationController
    }

    func showConcertDetail(concertId: UUID, imageAssetName: String? = nil) {
        let repo = SupabaseConcertDetailRepository()
        let vm = ConcertDetailViewModel(concertId: concertId, imageAssetName: imageAssetName, repository: repo)
        let vc = ConcertDetailViewController(viewModel: vm)
        vc.coordinator = self
        activeNavigationController.pushViewController(vc, animated: true)
    }

    func showArtistDetail(artistId: UUID) {
        let repo = SupabaseArtistDetailRepository()
        let vm = ArtistDetailViewModel(artistId: artistId, repository: repo)
        let vc = ArtistDetailViewController(viewModel: vm)
        vc.coordinator = self
        activeNavigationController.pushViewController(vc, animated: true)
    }

    func showEventList(title: String, events: [Event]) {
        let vc = EventListViewController(title: title, events: events, coordinator: self)
        navigationController.pushViewController(vc, animated: true)
    }

    func showTimetable() {
        let repository = SupabaseTimetableRepository()
        let vm = TimetableListViewModel(repository: repository)
        let vc = TimetableListViewController(viewModel: vm, coordinator: self)
        navigationController.pushViewController(vc, animated: true)
    }

    func showTimetableDetail(event: TimetableEvent) {
        let vm = TimetableDetailViewModel(event: event)
        let vc = TimetableDetailViewController(viewModel: vm, coordinator: self)
        navigationController.pushViewController(vc, animated: true)
    }

    func showTimetableLockscreenGuide(event: TimetableEvent, selectedPerformanceIds: Set<UUID>) {
        let vc = TimetableLockscreenGuideViewController(event: event, selectedPerformanceIds: selectedPerformanceIds)
        navigationController.pushViewController(vc, animated: true)
    }

    func showTimetableGrid(event: TimetableEvent, selectedPerformanceIds: Set<UUID>) {
        let vm = TimetableGridViewModel(event: event, selectedPerformanceIds: selectedPerformanceIds)
        let vc = TimetableGridViewController(viewModel: vm, coordinator: self)
        navigationController.pushViewController(vc, animated: true)
    }

    // MARK: - DEBUG: 타임테이블 그리드 직행 (테스트용 — 배포 전 제거)
    #if DEBUG
    func debugShowTimetableGrid() {
        let p1 = Performance(id: UUID(), startTime: "11:00", endTime: "12:00", artistName: "백예린", stageName: "COOL", genre: "인디")
        let p2 = Performance(id: UUID(), startTime: "12:30", endTime: "14:00", artistName: "검정치마", stageName: "COOL", genre: "록")
        let p3 = Performance(id: UUID(), startTime: "15:00", endTime: "16:30", artistName: "Lauv", stageName: "COOL", genre: "팝")
        let p4 = Performance(id: UUID(), startTime: "11:30", endTime: "13:00", artistName: "프로미스나인", stageName: "FRESH", genre: "케이팝")
        let p5 = Performance(id: UUID(), startTime: "14:00", endTime: "15:00", artistName: "The 1975", stageName: "FRESH", genre: "록")
        let p6 = Performance(id: UUID(), startTime: "16:00", endTime: "17:30", artistName: "Post Malone", stageName: "FRESH", genre: "힙합")
        let mockDay = TimetableDay(dayNumber: 1, dateString: "07.05(토)", performances: [p1, p2, p3, p4, p5, p6])
        let mockEvent = TimetableEvent(
            id: UUID(),
            title: "제18회 서울재즈페스티벌 2026",
            posterUrl: nil,
            dateRange: "2026.07.05 - 2026.07.06",
            venueName: "올림픽공원 88잔디마당",
            days: [mockDay]
        )
        // 전체 선택된 상태로 표시
        let allIds: Set<UUID> = [p1.id, p2.id, p3.id, p4.id, p5.id, p6.id]
        showTimetableGrid(event: mockEvent, selectedPerformanceIds: allIds)
    }
    #endif
}
