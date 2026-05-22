import UIKit

protocol AuthCoordinatorDelegate: AnyObject {
    func authCoordinatorDidAuthenticate()
}

final class AuthCoordinator {
    private let window: UIWindow
    weak var delegate: AuthCoordinatorDelegate?

    init(window: UIWindow, delegate: AuthCoordinatorDelegate) {
        self.window = window
        self.delegate = delegate
    }

    func start() {
        let vc = AuthViewController()
        vc.onSignInSuccess = { [weak self] in
            self?.delegate?.authCoordinatorDidAuthenticate()
        }
        window.rootViewController = vc
        window.makeKeyAndVisible()
    }
}
