import UIKit
import SnapKit

final class ProfileViewController: UIViewController {

    weak var coordinator: ProfileCoordinator?

    private let viewModel: ProfilePageViewModel

    // MARK: - Subviews

    private let scrollView: UIScrollView = {
        let s = UIScrollView()
        s.showsVerticalScrollIndicator = false
        return s
    }()
    private let refreshControl = UIRefreshControl()
    private let contentStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        return s
    }()

    private let profileHeaderView = ProfileHeaderView()

    private let artistDivider = DividerView()
    private let artistSectionView = ProfileArtistSectionView()

    private let reviewDivider = DividerView()
    private let reviewPromptView = ProfileReviewPromptView()
    private var reviewWrapper: UIView?

    private let yearlyDivider = DividerView()
    private let yearlyShowSectionView = ProfileYearlyShowSectionView()
    private var yearlyWrapper: UIView?

    private let menuDivider = DividerView()
    private let menuSectionView = ProfileMenuSectionView()
    private let myPageSkeletonView = MyPageSkeletonView()

    private let guestContainerView: UIView = {
        let v = UIView()
        v.isHidden = true
        return v
    }()
    private let guestIconImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "person.circle"))
        iv.tintColor = UIColor(hex: "#9CA3AF")
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    private let guestTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "로그인이 필요합니다"
        l.font = .scaled(18, weight: .semibold, textStyle: .headline)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(hex: "#111827")
        l.textAlignment = .center
        return l
    }()
    private let guestSubtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "내 정보를 확인하려면 로그인해 주세요."
        l.font = .scaled(14, textStyle: .subheadline)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(hex: "#6B7280")
        l.textAlignment = .center
        return l
    }()
    private let guestLoginButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("로그인하기", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .scaled(16, weight: .semibold, textStyle: .headline)
        b.titleLabel?.adjustsFontForContentSizeCategory = true
        b.backgroundColor = UIColor(hex: "#111827")
        b.layer.cornerRadius = 8
        return b
    }()

    private var hasLoadedData = false

    // MARK: - Init

    init(viewModel: ProfilePageViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#F9FAFB")
        setupLayout()
        bindViewModel()
        setupNotifications()
        updateLoginState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        (navigationController?.parent as? MainTabBarController)?.setTabBarHidden(false, animated: false)
        updateLoginState()
        // 다른 화면(아티스트 상세 등)에서 팔로우를 바꾸고 이 탭으로 돌아오면
        // 팔로우 알림이 이미 지나갔을 수 있다. 진입할 때마다 '내 아티스트'만 다시 불러
        // "다른 곳 갔다 와야 갱신되는" 문제를 없앤다. (이미 로드된 경우에만 — 최초 로드는 위에서 처리)
        if AuthService.shared.isLoggedIn && hasLoadedData {
            viewModel.refreshMyArtists()
        }
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        scrollView.contentInset.bottom = view.safeAreaInsets.bottom
        scrollView.verticalScrollIndicatorInsets.bottom = view.safeAreaInsets.bottom
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        scrollView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)

        scrollView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        contentStack.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }

        // Figma: status bar 44pt + white bar 28pt = top-[72px]. safeArea가 status bar 처리하므로 28pt 추가
        let topSpacer = UIView()
        contentStack.addArrangedSubview(topSpacer)
        topSpacer.snp.makeConstraints { $0.height.equalTo(28) }

        contentStack.addArrangedSubview(profileHeaderView)

        // Figma outer container gap-[36px] 적용
        let artistWrapper = paddedWrapper(view: artistSectionView, top: 36, bottom: 36)
        contentStack.addArrangedSubview(artistWrapper)

        contentStack.addArrangedSubview(artistDivider)

        let rw = paddedWrapper(view: reviewPromptView, top: 36, bottom: 36)
        reviewWrapper = rw
        contentStack.addArrangedSubview(rw)

        contentStack.addArrangedSubview(reviewDivider)

        let yw = paddedWrapper(view: yearlyShowSectionView, top: 36, bottom: 36)
        yearlyWrapper = yw
        contentStack.addArrangedSubview(yw)

        contentStack.addArrangedSubview(yearlyDivider)

        contentStack.addArrangedSubview(paddedWrapper(view: menuSectionView, top: 36, bottom: 0))

        view.addSubview(myPageSkeletonView)
        myPageSkeletonView.snp.makeConstraints { $0.edges.equalToSuperview() }

        view.addSubview(guestContainerView)
        guestContainerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        guestContainerView.addSubview(guestIconImageView)
        guestContainerView.addSubview(guestTitleLabel)
        guestContainerView.addSubview(guestSubtitleLabel)
        guestContainerView.addSubview(guestLoginButton)

        guestIconImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-60)
            $0.size.equalTo(64)
        }
        guestTitleLabel.snp.makeConstraints {
            $0.top.equalTo(guestIconImageView.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
        }
        guestSubtitleLabel.snp.makeConstraints {
            $0.top.equalTo(guestTitleLabel.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
        }
        guestLoginButton.snp.makeConstraints {
            $0.top.equalTo(guestSubtitleLabel.snp.bottom).offset(24)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(160)
            $0.height.equalTo(48)
        }
        guestLoginButton.addTarget(self, action: #selector(guestLoginTapped), for: .touchUpInside)
    }

    private func paddedWrapper(view: UIView, top: CGFloat = 0, bottom: CGFloat = 0) -> UIView {
        let wrapper = UIView()
        wrapper.addSubview(view)
        view.snp.makeConstraints {
            $0.top.equalToSuperview().offset(top)
            $0.bottom.equalToSuperview().inset(bottom)
            $0.leading.trailing.equalToSuperview()
        }
        return wrapper
    }

    // MARK: - Binding

    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] in
            guard let self else { return }
            if !viewModel.state.isLoading && !myPageSkeletonView.isHidden {
                UIView.animate(withDuration: 0.25) {
                    self.myPageSkeletonView.alpha = 0
                } completion: { _ in
                    self.myPageSkeletonView.isHidden = true
                    self.myPageSkeletonView.stopShimmer()
                }
            }
            self.applyState()
        }
        viewModel.onError = { [weak self] message in
            self?.showErrorAlert(message, retry: { self?.viewModel.viewDidLoad() })
        }
        artistSectionView.onArtistTapped = { [weak self] artistId in
            self?.coordinator?.showArtistDetail(artistId: artistId)
        }
        yearlyShowSectionView.onShowTapped = { [weak self] event in
            self?.coordinator?.showConcertDetail(concertId: event.id, imageAssetName: event.posterUrl)
        }
        yearlyShowSectionView.onSeeMoreTapped = { [weak self] in
            guard let self else { return }
            self.coordinator?.showEventList(title: "올해 본 공연", events: self.viewModel.state.yearlyShows)
        }

        menuSectionView.onMenuTapped = { [weak self] item in
            self?.handleMenuTap(item)
        }

        menuSectionView.onLogoutTapped = { [weak self] in
            self?.confirmLogout()
        }
    }

    private func handleMenuTap(_ item: MyMenuItem) {
        switch item {
        case .bookingHistory:
            coordinator?.showBookingList(initialTab: .active)
        case .writeReview:
            coordinator?.showWriteReview(currentProfile: viewModel.state.userProfile)
        case .cancelHistory:
            coordinator?.showBookingList(initialTab: .cancelled)
        case .myReviews:
            coordinator?.showReviews()
        case .inquiry:
            coordinator?.showInquiry()
        case .editProfile:
            coordinator?.showEditProfile(currentProfile: viewModel.state.userProfile) { [weak self] in
                self?.viewModel.viewDidLoad()
            }
        case .customerService:
            openSupportMail()
        }
    }

    // 블록 기반 옵저버는 토큰을 보관해 deinit에서 해제 (VC 재생성 시 중복 구독 방지)
    private var notificationTokens: [NSObjectProtocol] = []

    private func setupNotifications() {
        let center = NotificationCenter.default
        notificationTokens.append(center.addObserver(
            forName: .userDidLogin, object: nil, queue: .main
        ) { [weak self] _ in
            self?.hasLoadedData = false
            self?.updateLoginState()
        })
        notificationTokens.append(center.addObserver(
            forName: .userDidLogout, object: nil, queue: .main
        ) { [weak self] _ in
            self?.hasLoadedData = false
            self?.updateLoginState()
        })
        notificationTokens.append(center.addObserver(
            forName: .artistFollowDidChange, object: nil, queue: .main
        ) { [weak self] _ in
            self?.viewModel.refreshMyArtists()
        })
    }

    deinit {
        notificationTokens.forEach { NotificationCenter.default.removeObserver($0) }
    }

    private func updateLoginState() {
        let isLoggedIn = AuthService.shared.isLoggedIn
        scrollView.isHidden = !isLoggedIn
        guestContainerView.isHidden = isLoggedIn

        if isLoggedIn && !hasLoadedData {
            hasLoadedData = true
            myPageSkeletonView.isHidden = false
            myPageSkeletonView.alpha = 1
            viewModel.viewDidLoad()
        } else if !isLoggedIn {
            myPageSkeletonView.isHidden = true
        }
    }

    @objc private func handleRefresh() {
        guard AuthService.shared.isLoggedIn else {
            refreshControl.endRefreshing()
            return
        }
        // 전체 재로딩(스켈레톤 대신 새로고침 스피너). 완료 시 endRefreshing.
        viewModel.refresh { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }

    @objc private func guestLoginTapped() {
        guard let scene = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate,
              let appCoordinator = scene.appCoordinator else { return }
        appCoordinator.presentLogin(from: self) { [weak self] in
            // userDidLogin notification이 데이터 로드 처리
            _ = self
        }
    }

    private func confirmLogout() {
        let alert = UIAlertController(title: "로그아웃", message: "로그아웃 하시겠습니까?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "로그아웃", style: .destructive) { [weak self] _ in
            Task { @MainActor in
                do {
                    try await AuthService.shared.signOut()
                    NotificationCenter.default.post(name: .userDidLogout, object: nil)
                } catch {
                    // 로그아웃 실패 시 세션 유지 — UI 전환하지 않고 에러 안내
                    let err = UIAlertController(title: "로그아웃 실패", message: "잠시 후 다시 시도해주세요.", preferredStyle: .alert)
                    err.addAction(UIAlertAction(title: "확인", style: .default))
                    self?.present(err, animated: true)
                }
            }
        })
        present(alert, animated: true)
    }

    /// 고객센터 — 지원 이메일로 메일 작성 화면 오픈. 메일 앱이 없으면 주소를 알림으로 안내.
    private func openSupportMail() {
        let address = "articket2026@gmail.com"
        let subject = "[Articket] 문의".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "mailto:\(address)?subject=\(subject)") else { return }
        UIApplication.shared.open(url) { [weak self] success in
            guard !success else { return }
            let alert = UIAlertController(
                title: "메일 앱을 열 수 없어요",
                message: "\(address) 로 문의해 주세요.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            self?.present(alert, animated: true)
        }
    }

    private func applyState() {
        let profile = viewModel.state.userProfile ?? UserProfile(
            displayName: "게스트",
            email: "",
            initial: "G",
            concertCount: 0,
            followingArtistCount: 0,
            lastVisitDate: nil,
            avatarUrl: nil
        )
        profileHeaderView.configure(with: profile)
        artistSectionView.configure(artists: viewModel.state.myArtists)

        let hasReviewable = !viewModel.state.reviewableShows.isEmpty
        reviewWrapper?.isHidden = !hasReviewable
        reviewDivider.isHidden = !hasReviewable
        if let firstShow = viewModel.state.reviewableShows.first {
            reviewPromptView.configure(show: firstShow)
            reviewPromptView.onWriteTapped = { [weak self] in
                self?.coordinator?.showWriteReview(currentProfile: self?.viewModel.state.userProfile)
            }
        }

        let hasYearly = !viewModel.state.yearlyShows.isEmpty
        yearlyWrapper?.isHidden = !hasYearly
        yearlyDivider.isHidden = !hasYearly
        yearlyShowSectionView.configure(shows: viewModel.state.yearlyShows)

        // Figma 메뉴 뱃지 — 후기 작성(미작성 관람 공연 수), 나의 후기(작성한 후기 수)
        menuSectionView.setBadges([
            .writeReview: .count(viewModel.state.reviewableShows.count),
            .myReviews: .count(viewModel.state.reviewCount)
        ])
    }
}

// MARK: - DividerView

private final class DividerView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(hex: "#F3F4F6")
        snp.makeConstraints { $0.height.equalTo(8) }
    }
    required init?(coder: NSCoder) { fatalError() }
}
