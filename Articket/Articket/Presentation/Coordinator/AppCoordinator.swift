import UIKit

final class AppCoordinator {

    private let window: UIWindow
    private var homeCoordinator: HomeCoordinator!
    private var artistCoordinator: ArtistCoordinator!
    private var myCoordinator: MyCoordinator!

    init(window: UIWindow) {
        self.window = window
    }

    func start() {
        showMainApp(animated: false)
        Task { await AuthService.shared.validateSession() }
    }

    // MARK: - Modal Login

    func presentLogin(from vc: UIViewController, completion: @escaping () -> Void) {
        let authVC = AuthViewController()
        authVC.onSignInSuccess = { [weak vc] in
            vc?.dismiss(animated: true, completion: completion)
        }
        let nav = UINavigationController(rootViewController: authVC)
        nav.modalPresentationStyle = .pageSheet
        vc.present(nav, animated: true)
    }

    // MARK: - Main App

    private func showMainApp(animated: Bool) {
        let tabBar = MainTabBarController()
        setupTabs(tabBar: tabBar)

        if animated {
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
                self.window.rootViewController = tabBar
            }
        } else {
            window.rootViewController = tabBar
            window.makeKeyAndVisible()
        }
    }

    private func setupTabs(tabBar: MainTabBarController) {
        let homeNav = makeNav()
        homeCoordinator = HomeCoordinator(navigationController: homeNav)
        homeCoordinator.start()

        let artistNav = makeNav()
        artistCoordinator = ArtistCoordinator(navigationController: artistNav)
        artistCoordinator.start()

        let myNav = makeNav()
        myCoordinator = MyCoordinator(navigationController: myNav)
        myCoordinator.start()

        tabBar.configure(tabs: [homeNav, artistNav, myNav])
    }

    private func makeNav() -> UINavigationController {
        let nav = UINavigationController()
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        nav.navigationBar.standardAppearance = appearance
        nav.navigationBar.scrollEdgeAppearance = appearance
        nav.view.backgroundColor = .white
        return nav
    }
}
