import UIKit

final class MyCoordinator: Coordinator {

    let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let repository = MockMyPageRepository()
        let useCase = FetchMyPageDataUseCase(repository: repository)
        let viewModel = MyPageViewModel(useCase: useCase)
        let vc = MyViewController(viewModel: viewModel)
        vc.coordinator = self
        navigationController.setViewControllers([vc], animated: false)
    }

    func showConcertDetail(concertId: UUID, imageAssetName: String? = nil) {
        let repo = MockConcertDetailRepository()
        let vm = ConcertDetailViewModel(concertId: concertId, imageAssetName: imageAssetName, repository: repo)
        let vc = ConcertDetailViewController(viewModel: vm)
        navigationController.pushViewController(vc, animated: true)
    }
}
