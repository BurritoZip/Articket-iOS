import UIKit
import SnapKit

// MARK: - ArtistDetailViewController
// Figma 1:2821 (콘서트 탭), 1:2915 (프로필 탭)

final class ArtistDetailViewController: UIViewController {

    private let viewModel: ArtistDetailViewModel

    // MARK: - Views

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical = true
        return sv
    }()

    private let contentView = UIView()

    private let headerView = ArtistDetailHeaderView()
    private let tabBarView = ArtistTabBarView()

    private let tabContentContainer: UIView = UIView()

    private let backButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        b.tintColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1)
        return b
    }()

    private let concertContent = ConcertTabContentView()
    private let profileContent = ProfileTabContentView()

    private var contentInsetApplied = false

    // MARK: - Init

    init(viewModel: ArtistDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupScrollView()
        setupBackButton()
        bindViewModel()
        render()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !contentInsetApplied {
            contentInsetApplied = true
            scrollView.contentInset.top = view.safeAreaInsets.top + 48
            scrollView.scrollIndicatorInsets.top = scrollView.contentInset.top
        }
    }

    // MARK: - Setup

    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }

        contentView.addSubview(headerView)
        contentView.addSubview(tabBarView)
        contentView.addSubview(tabContentContainer)

        headerView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
        }

        tabBarView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.leading.equalToSuperview().inset(20)
            $0.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(36)
        }

        tabContentContainer.snp.makeConstraints {
            $0.top.equalTo(tabBarView.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }

        tabBarView.onTabSelected = { [weak self] index in
            self?.viewModel.selectTab(index)
        }

        headerView.onFollowTapped = { /* 팔로우 로직 추후 구현 */ }
    }

    private func setupBackButton() {
        view.addSubview(backButton)
        backButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.equalToSuperview().inset(20)
            $0.width.height.equalTo(48)
        }
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
    }

    // MARK: - Bind

    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] in
            self?.render()
        }
    }

    private func render() {
        let state = viewModel.state
        let detail = state.detail

        headerView.configure(with: detail.artist)
        concertContent.configure(detail: detail)
        profileContent.configure(detail: detail)

        tabBarView.selectTab(state.selectedTab, animated: false)
        showTab(state.selectedTab)
    }

    private func showTab(_ index: Int) {
        tabContentContainer.subviews.forEach { $0.removeFromSuperview() }

        let activeView = index == 0 ? concertContent : profileContent
        tabContentContainer.addSubview(activeView)
        activeView.snp.makeConstraints { $0.edges.equalToSuperview() }

        // scrollView가 새 콘텐츠 높이를 재계산하도록
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    // MARK: - Actions

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}
