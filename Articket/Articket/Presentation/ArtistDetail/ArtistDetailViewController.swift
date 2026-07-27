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
        b.accessibilityLabel = "뒤로"
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
            AppLog.shared.action("팔로우토글")
            self?.viewModel.toggleFollow()
        }

        concertContent.onConcertTapped = { [weak self] concertId, imageAssetName in
            self?.coordinator?.showConcertDetail(concertId: concertId, imageAssetName: imageAssetName)
        }
        concertContent.onMoreTapped = { [weak self] in
            self?.viewModel.requestUpcomingList()
        }
        concertContent.onAlarmTapped = { [weak self] ticketing in
            guard let self else { return }
            guard let date = ticketing.ticketOpenDate else {
                self.showToast("티켓 오픈 일정이 아직 미정이에요", type: .info)
                return
            }
            Task {
                let result = await TicketOpenNotifier.toggle(
                    eventId: ticketing.id, title: ticketing.concertTitle, date: date
                )
                switch result {
                case .some(true):  self.showToast("티켓 오픈 알림을 설정했어요", type: .success)
                case .some(false): self.showToast("티켓 오픈 알림을 해제했어요", type: .info)
                case .none:        self.showToast("알림을 설정할 수 없어요 (권한 또는 지난 일정)", type: .error)
                }
            }
        }
        profileContent.onMusicVideoTapped = { [weak self] video in
            guard let self else { return }
            YouTubeSearchOpener.open(query: "\(self.viewModel.state.detail.artist.name) \(video.title)")
        }
        profileContent.onAlbumTapped = { [weak self] album in
            guard let self else { return }
            YouTubeSearchOpener.open(query: "\(self.viewModel.state.detail.artist.name) \(album.title)")
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
            Haptics.impact()
            let message = isFollowing ? "팔로우했어요" : "팔로우를 취소했어요"
            let type: ToastType = isFollowing ? .success : .info
            self?.showToast(message, type: type)
        }
        viewModel.onUpcomingListLoaded = { [weak self] events in
            self?.coordinator?.showEventList(title: "다가오는 티켓팅", events: events)
        }
    }

    // showLoginPrompt(then:)은 UIViewController+ErrorAlert.swift의 공용 extension 사용

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
