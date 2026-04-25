import UIKit

final class HomeCoordinator: Coordinator {

    private(set) var rootViewController: UIViewController!

    func start() {
        let repository = MockEventRepository()
        let useCase = FetchHomeEventsUseCase(repository: repository)
        let homeVM = HomeViewModel(fetchHomeEventsUseCase: useCase)
        let bookingRepository = MockBookingRepository()
        let myUseCase = FetchMyDataUseCase(repository: bookingRepository)
        let myVM = MyViewModel(fetchMyDataUseCase: myUseCase)
        let vc = HomeViewController(viewModel: homeVM, myViewModel: myVM)
        vc.coordinator = self
        rootViewController = vc
    }

    func showSearch() {
        let vm = SearchViewModel()
        let vc = SearchViewController(viewModel: vm)
        let nav = UINavigationController(rootViewController: vc)
        nav.isNavigationBarHidden = true
        nav.modalPresentationStyle = .fullScreen
        rootViewController.present(nav, animated: true)
    }
}
