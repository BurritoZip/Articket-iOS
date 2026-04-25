import UIKit

final class MyCoordinator: Coordinator {

    let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let vc = UIViewController()
        vc.view.backgroundColor = .white
        navigationController.setViewControllers([vc], animated: false)
    }
}
