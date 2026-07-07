import UIKit
import SnapKit

// MARK: - ArtistDetailViewController
// Figma 1:2821 (콘서트 탭), 1:2915 (프로필 탭)

final class ArtistDetailViewController: UIViewController {

    weak var coordinator: ArtistDetailCoordinatorProtocol?
    private let viewModel: ArtistDetailViewModel

    // MARK: - Views

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical = true
        sv.contentInsetAdjustmentBehavior = .never
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

    private let skeletonView = ArtistDetailSkeletonView()

    private var contentInsetApplied = false  // top inset 1회 초기화용

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
        setupSkeletonView()
        setupBackButton()
        bindViewModel()
        viewModel.viewDidLoad()
        render()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !contentInsetApplied, view.safeAreaInsets.top > 0 {
            contentInsetApplied = true
            let topInset = view.safeAreaInsets.top + 48
            let bottomInset = view.safeAreaInsets.bottom
            scrollView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: bottomInset, right: 0)
            scrollView.scrollIndicatorInsets = UIEdgeInsets(top: topInset, left: 0, bottom: bottomInset, right: 0)
            scrollView.contentOffset = CGPoint(x: 0, y: -topInset)
        }
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        guard contentInsetApplied else { return }
        let bottomInset = view.safeAreaInsets.bottom
        scrollView.contentInset.bottom = bottomInset
        scrollView.scrollIndicatorInsets.bottom = bottomInset
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

        headerView.onFollowTapped = { [weak self] in
            self?.viewModel.toggleFollow()
        }

        concertContent.onConcertTapped = { [weak self] concertId, imageAssetName in
            self?.coordinator?.showConcertDetail(concertId: concertId, imageAssetName: imageAssetName)
        }
        concertContent.onMoreTapped = { [weak self] in
            self?.showComingSoon()
        }
        concertContent.onAlarmTapped = { [weak self] in
            self?.showComingSoon()
        }
        profileContent.onMusicVideoTapped = { [weak self] in
            self?.showComingSoon()
        }
    }

    private func setupSkeletonView() {
        view.addSubview(skeletonView)
        skeletonView.snp.makeConstraints { $0.edges.equalToSuperview() }
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
            guard let self else { return }
            self.render()
            if !self.viewModel.state.isLoading && !self.skeletonView.isHidden {
                UIView.animate(withDuration: 0.25) {
                    self.skeletonView.alpha = 0
                } completion: { _ in
                    self.skeletonView.isHidden = true
                    self.skeletonView.stopShimmer()
                }
            }
        }
        viewModel.onError = { [weak self] message in
            self?.showToast(message, type: .error)
        }
        viewModel.onLoginRequired = { [weak self] retry in
            self?.showLoginPrompt(then: retry)
        }
        viewModel.onFollowToggled = { [weak self] isFollowing in
            let message = isFollowing ? "팔로우했어요" : "팔로우를 취소했어요"
            let type: ToastType = isFollowing ? .success : .info
            self?.showToast(message, type: type)
        }
    }

    private func showLoginPrompt(then action: @escaping () -> Void) {
        let alert = UIAlertController(title: "로그인 필요", message: "이 기능을 사용하려면 로그인이 필요합니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "로그인", style: .default) { [weak self] _ in
            guard let self else { return }
            guard let scene = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate,
                  let appCoordinator = scene.appCoordinator else { return }
            appCoordinator.presentLogin(from: self, completion: action)
        })
        present(alert, animated: true)
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

    private func showComingSoon() {
        let alert = UIAlertController(title: nil, message: "서비스 준비 중입니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
