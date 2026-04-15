import UIKit
import SnapKit

final class MainTabBarController: UITabBarController {

    private let customTabBar = CustomTabBarView(items: [
        .init(title: "Home",   image: UIImage(named: "ic_home_thin"),   selectedImage: UIImage(named: "ic_home_filled")),
        .init(title: "Artist", image: UIImage(named: "ic_artist_thin"), selectedImage: nil),
        .init(title: "My",     image: UIImage(named: "ic_my_thin"),     selectedImage: UIImage(named: "ic_my_filled")),
    ])

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupCustomTabBar()
    }

    // MARK: - Tabs

    private func setupTabs() {
        let repository = MockEventRepository()
        let useCase = FetchHomeEventsUseCase(repository: repository)
        let homeViewModel = HomeViewModel(fetchHomeEventsUseCase: useCase)
        let homeVC = HomeViewController(viewModel: homeViewModel)

        let homeNav   = UINavigationController(rootViewController: homeVC)
        let artistNav = UINavigationController(rootViewController: blankVC())
        let myNav     = UINavigationController(rootViewController: blankVC())

        // System tab bar items are hidden; we use customTabBar for visuals.
        // Tab bar items need a title/image so UITabBarController tracks them,
        // but we set them to empty to avoid visual duplication.
        [homeNav, artistNav, myNav].forEach {
            $0.tabBarItem = UITabBarItem(title: nil, image: nil, tag: 0)
        }

        viewControllers = [homeNav, artistNav, myNav]
    }

    private func blankVC() -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .white
        return vc
    }

    // MARK: - Custom Tab Bar

    private func setupCustomTabBar() {
        // Hide the system tab bar.
        tabBar.isHidden = true

        view.addSubview(customTabBar)

        customTabBar.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
        }

        // Push child view controller content above the 60pt tab bar content area.
        additionalSafeAreaInsets.bottom = CustomTabBarView.contentHeight

        customTabBar.onTabSelected = { [weak self] index in
            self?.selectedIndex = index
        }
    }
}
