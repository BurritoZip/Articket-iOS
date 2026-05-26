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
        let homeVM = HomeViewModel(fetchHomeEventsUseCase: useCase)
        let bookingRepository = SupabaseBookingRepository()
        let myUseCase = FetchMyDataUseCase(repository: bookingRepository)
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

    func showConcertDetail(concertId: UUID, imageAssetName: String? = nil) {
        let repo = SupabaseConcertDetailRepository()
        let vm = ConcertDetailViewModel(concertId: concertId, imageAssetName: imageAssetName, repository: repo)
        let vc = ConcertDetailViewController(viewModel: vm)
        vc.coordinator = self
        navigationController.pushViewController(vc, animated: true)
    }

    func showArtistDetail(artistId: UUID) {
        let repo = SupabaseArtistDetailRepository()
        let vm = ArtistDetailViewModel(artistId: artistId, repository: repo)
        let vc = ArtistDetailViewController(viewModel: vm)
        vc.coordinator = self
        navigationController.pushViewController(vc, animated: true)
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
}
