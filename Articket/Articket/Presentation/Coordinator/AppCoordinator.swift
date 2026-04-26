import UIKit

final class AppCoordinator {

    private let tabBarController: MainTabBarController
    private var homeCoordinator: HomeCoordinator!
    private var artistCoordinator: ArtistCoordinator!
    private var myCoordinator: MyCoordinator!

    init(tabBarController: MainTabBarController) {
        self.tabBarController = tabBarController
    }

    func start() {
        let homeNav = makeNav()
        homeCoordinator = HomeCoordinator(navigationController: homeNav)
        homeCoordinator.start()

        let artistNav = makeNav()
        artistCoordinator = ArtistCoordinator(navigationController: artistNav)
        artistCoordinator.start()

        let myNav = makeNav()
        myCoordinator = MyCoordinator(navigationController: myNav)
        myCoordinator.start()

        tabBarController.configure(tabs: [
            homeNav,
            artistNav,
            myNav
        ])
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
