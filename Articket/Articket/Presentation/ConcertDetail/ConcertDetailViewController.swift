import UIKit
import SnapKit

// MARK: - ConcertDetailViewController
// Figma 1:1652

final class ConcertDetailViewController: UIViewController {

    weak var coordinator: ConcertDetailCoordinatorProtocol?
    private let viewModel: ConcertDetailViewModel

    // MARK: - Views

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical = true
        sv.contentInsetAdjustmentBehavior = .never
        return sv
    }()

    private let contentView = UIView()

    private let heroImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        return iv
    }()

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        v.clipsToBounds = true
        return v
    }()

    private let concertHeaderView = ConcertDetailHeaderView()
    private let bookingView = ConcertBookingView()
    private let tabBarView = ConcertTabBarView()
    private let tabContentContainer = UIView()
    private let infoTabView = ConcertInfoTabView()
    private let salesInfoTabView = SalesInfoTabView()
    private let reviewTabView = ReviewTabView()

    private let backButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        b.tintColor = .white
        return b
    }()

    private let skeletonView = ConcertDetailSkeletonView()

    // MARK: - Init

    init(viewModel: ConcertDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupScrollView()
        setupSkeletonView()   // backButton보다 먼저 붙여 뒤로가기 버튼이 스켈레톤 위에 남도록
        setupBackButton()
        bindViewModel()
        viewModel.viewDidLoad()
        render()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        // safeAreaInsets.bottom = 기기 홈 인디케이터 + additionalSafeAreaInsets(커스텀탭바 60pt)
        // UITabBarController가 아니므로 tabBarController?.tabBar는 nil — 중복 가산 금지
        let bottomInset = view.safeAreaInsets.bottom
        scrollView.contentInset.bottom = bottomInset
        scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
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

        contentView.addSubview(heroImageView)
        heroImageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(400)
        }

        contentView.addSubview(cardView)
        cardView.snp.makeConstraints {
            $0.top.equalTo(heroImageView.snp.bottom).offset(-24)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        let cardStack = UIStackView(arrangedSubviews: [concertHeaderView, bookingView])
        cardStack.axis = .vertical
        cardStack.spacing = 0

        cardView.addSubview(cardStack)
        cardStack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)  // 카드 자체 패딩 20pt + header 내부 inset 10pt = 제목 상단 30pt
            $0.leading.trailing.equalToSuperview()
        }

        cardView.addSubview(tabBarView)
        tabBarView.snp.makeConstraints {
            $0.top.equalTo(cardStack.snp.bottom).offset(32)  // 섹션 py-bottom 10pt + outer gap 32pt = 42pt
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(36)
        }

        cardView.addSubview(tabContentContainer)
        tabContentContainer.snp.makeConstraints {
            $0.top.equalTo(tabBarView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }

        tabBarView.onTabSelected = { [weak self] index in
            self?.viewModel.selectTab(index)
        }

        concertHeaderView.onHeartTapped = { [weak self] in
            self?.viewModel.toggleInterested()
        }
        concertHeaderView.onShareTapped = { [weak self] in
            self?.presentShare()
        }
        infoTabView.onArtistTapped = { [weak self] artistId in
            self?.coordinator?.showArtistDetail(artistId: artistId)
        }
        infoTabView.onMapTapped = { [weak self] in
            self?.openMap()
        }
        bookingView.onBookingTapped = { [weak self] in
            self?.viewModel.requestBooking()
        }
        reviewTabView.onWriteReviewTapped = { [weak self] in
            self?.showToast("후기 작성은 준비 중이에요", type: .info)
        }
    }

    private func setupSkeletonView() {
        view.addSubview(skeletonView)
        skeletonView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    private func setupBackButton() {
        view.addSubview(backButton)
        backButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(4)
            $0.leading.equalToSuperview().inset(12)
            $0.size.equalTo(44)
        }
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
    }

    // MARK: - Bind

    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] in
            guard let self else { return }
            self.render()
            self.dismissSkeletonIfLoaded()
        }
        viewModel.onError = { [weak self] message in
            guard let self else { return }
            self.showToast(message, type: .error)
            // 실패 시에도 스켈레톤을 걷어야 사용자가 뒤로 나가거나 재시도할 수 있다
            self.dismissSkeletonIfLoaded()
        }
        viewModel.onLoginRequired = { [weak self] retry in
            self?.showLoginPrompt(then: retry)
        }
        viewModel.onInterestToggled = { [weak self] isInterested in
            let message = isInterested ? "관심 공연에 추가했어요" : "관심 공연에서 삭제했어요"
            let type: ToastType = isInterested ? .success : .info
            self?.showToast(message, type: type)
        }
        viewModel.onOpenBooking = { url in
            UIApplication.shared.open(url)
        }
    }

    private func dismissSkeletonIfLoaded() {
        guard !viewModel.state.isLoading, !skeletonView.isHidden else { return }
        UIView.animate(withDuration: 0.25) {
            self.skeletonView.alpha = 0
        } completion: { _ in
            self.skeletonView.isHidden = true
            self.skeletonView.stopShimmer()
        }
    }

    private func render() {
        let state = viewModel.state
        let detail = state.detail

        heroImageView.loadImage(urlString: state.heroImageAssetName)

        concertHeaderView.configure(with: detail)
        bookingView.configure(with: detail)
        tabBarView.selectTab(state.selectedTab, animated: false)
        showTab(state.selectedTab)

        concertHeaderView.setInterested(state.isInterested)
    }

    private func showTab(_ index: Int) {
        tabContentContainer.subviews.forEach { $0.removeFromSuperview() }

        let detail = viewModel.state.detail
        let activeView: UIView
        switch index {
        case 0:
            infoTabView.configure(with: detail, followedArtistIds: viewModel.state.followedArtistIds)
            activeView = infoTabView
        case 1:
            salesInfoTabView.configure(with: detail)
            activeView = salesInfoTabView
        case 2:
            reviewTabView.configure(with: detail)
            activeView = reviewTabView
        default:
            activeView = makePlaceholderView(for: index)
        }

        tabContentContainer.addSubview(activeView)
        activeView.snp.makeConstraints { $0.edges.equalToSuperview() }

        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    // MARK: - Actions

    @objc private func backTapped() {
        if navigationController?.viewControllers.count ?? 0 > 1 {
            navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    private func presentShare() {
        let detail = viewModel.state.detail
        let text = "\(detail.title) — \(detail.venueName) · \(detail.dateRange)"
        let vc = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        vc.popoverPresentationController?.sourceView = view
        present(vc, animated: true)
    }

    // MARK: - Helpers

    private func openMap() {
        let detail = viewModel.state.detail
        Task {
            do {
                try await VenueMapOpener.open(venueName: detail.venueName, address: detail.address)
            } catch VenueMapOpener.Failure.noQuery {
                showToast("공연장 주소 정보가 아직 없어요", type: .info)
            } catch {
                showToast("지도에서 위치를 찾지 못했어요", type: .error)
            }
        }
    }

    private func makePlaceholderView(for tab: Int) -> UIView {
        let v = UIView()
        let label = UILabel()
        label.text = tab == 1 ? "판매정보 준비중" : "후기 준비중"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        label.textAlignment = .center
        v.addSubview(label)
        label.snp.makeConstraints { $0.center.equalToSuperview() }
        v.snp.makeConstraints { $0.height.equalTo(120) }
        return v
    }
}
