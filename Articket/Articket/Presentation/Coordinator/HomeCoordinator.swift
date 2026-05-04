import UIKit

final class HomeCoordinator: Coordinator {

    let navigationController: UINavigationController

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
        let nav = UINavigationController(rootViewController: vc)
        nav.isNavigationBarHidden = true
        nav.modalPresentationStyle = .fullScreen
        navigationController.present(nav, animated: true)
    }

    func showConcertDetail(concertId: UUID, imageAssetName: String? = nil) {
        let repo = SupabaseConcertDetailRepository()
        let vm = ConcertDetailViewModel(concertId: concertId, imageAssetName: imageAssetName, repository: repo)
        let vc = ConcertDetailViewController(viewModel: vm)
        navigationController.pushViewController(vc, animated: true)
    }

    func showEventList(title: String, events: [Event]) {
        let vc = EventListViewController(title: title, events: events, coordinator: self)
        navigationController.pushViewController(vc, animated: true)
    }
}
