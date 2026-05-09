import UIKit
import SnapKit

final class MainTabBarController: UIViewController {

    private let customTabBar = CustomTabBarView(items: [
        .init(title: "Home",   image: UIImage(named: "ic_home_thin"),   selectedImage: UIImage(named: "ic_home_filled")),
        .init(title: "Artist", image: UIImage(named: "ic_artist_thin"), selectedImage: nil),
        .init(title: "My",     image: UIImage(named: "ic_my_thin"),     selectedImage: UIImage(named: "ic_my_filled")),
    ])

    private var tabs: [UIViewController] = []
    private var currentIndex: Int = -1

    override func viewDidLoad() {
        super.viewDidLoad()
        // 히어로 배너 로딩 전 status bar 영역이 어둡게 보이도록
        view.backgroundColor = UIColor(red: 18/255, green: 18/255, blue: 18/255, alpha: 1)
        setupCustomTabBar()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        let deviceBottom = view.window?.safeAreaInsets.bottom ?? 0
        customTabBar.updateBottomInset(deviceBottom)
    }

    // status bar 스타일을 현재 탭 child에 위임
    override var childForStatusBarStyle: UIViewController? {
        guard tabs.indices.contains(currentIndex) else { return nil }
        return tabs[currentIndex]
    }

    // MARK: - Tabs

    func configure(tabs: [UIViewController]) {
        self.tabs = tabs
        transition(to: 0)
    }

    // MARK: - Custom Tab Bar

    private func setupCustomTabBar() {
        view.addSubview(customTabBar)
        customTabBar.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
        }
        additionalSafeAreaInsets.bottom = CustomTabBarView.contentHeight

        customTabBar.onTabSelected = { [weak self] index in
            self?.transition(to: index)
        }
    }

    // MARK: - Tab Switching

    private func transition(to index: Int) {
        guard tabs.indices.contains(index) else { return }

        // 같은 탭 재탭: 네비게이션 스택을 루트까지 팝
        if index == currentIndex {
            if let nav = tabs[currentIndex] as? UINavigationController {
                nav.popToRootViewController(animated: true)
            }
            return
        }

        if tabs.indices.contains(currentIndex) {
            let outgoing = tabs[currentIndex]
            outgoing.willMove(toParent: nil)
            outgoing.view.removeFromSuperview()
            outgoing.removeFromParent()
        }

        let incoming = tabs[index]
        addChild(incoming)
        view.insertSubview(incoming.view, belowSubview: customTabBar)
        incoming.view.snp.remakeConstraints { $0.edges.equalToSuperview() }
        incoming.didMove(toParent: self)

        currentIndex = index
        customTabBar.setSelectedIndex(index)
        setNeedsStatusBarAppearanceUpdate()
    }
}
