import UIKit

final class AppCoordinator: AuthCoordinatorDelegate {

    private let window: UIWindow
    private var authCoordinator: AuthCoordinator?
    private var homeCoordinator: HomeCoordinator!
    private var artistCoordinator: ArtistCoordinator!
    private var myCoordinator: MyCoordinator!

    init(window: UIWindow) {
        self.window = window
    }

    func start() {
        if AuthService.shared.isLoggedIn {
            showMainApp(animated: false)
        } else {
            showAuth()
        }
    }

    // MARK: - Auth Flow

    private func showAuth() {
        let coord = AuthCoordinator(window: window, delegate: self)
        authCoordinator = coord
        coord.start()
    }

    func authCoordinatorDidAuthenticate() {
        authCoordinator = nil
        showMainApp(animated: true)
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
