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
        let myUseCase = FetchMyDataUseCase(repository: bookingRepository,
                                          myPageRepository: SupabaseMyPageRepository())
        let myVM = MyViewModel(fetchMyDataUseCase: myUseCase)
        let vc = HomeViewController(viewModel: homeVM, myViewModel: myVM)
        vc.coordinator = self
        navigationController.setViewControllers([vc], animated: false)
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

    /// 공연 상세에서 후기 작성 — 해당 공연 preselect (ConcertDetailCoordinatorProtocol)
    func showWriteReview(preselectedEventId: UUID) {
        let vm = WriteReviewViewModel(
            myPageRepository: SupabaseMyPageRepository(),
            reviewRepository: SupabaseReviewRepository(),
            preselectedEventId: preselectedEventId
        )
        navigationController.pushViewController(WriteReviewViewController(viewModel: vm), animated: true)
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

}
