import UIKit
import SnapKit

@MainActor
final class HomeViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: HomeViewModel
    private let myViewModel: MyViewModel
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<HomeSection, HomeSectionItem>!
    private var myCollectionView: UICollectionView!
    private var myDataSource: UICollectionViewDiffableDataSource<MySection, MySectionItem>!
    private var newlyStartedOffset: Int = 0
    private var soonEndingOffset: Int = 0
    private var currentHeroBannerPage: Int = 0
    private var isMyMode: Bool = false

    // MARK: - Hero banner top inset
    private static let navBarHeight: CGFloat = 56
    private static let posterTopGap: CGFloat = 17
    private var heroBannerTopInset: CGFloat = 0

    // MARK: - Blurred hero background
    private let blurredBackgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private var blurredBackgroundHeightConstraint: Constraint!

    // MARK: - Custom top header
    private var topHeaderView: UIView!
    // MY 모드에서 status bar 영역(safeArea 위)을 흰색으로 채우는 뷰.
    // NOW 모드에서는 clear — blurredBackground가 status bar까지 커버.
    private let statusBarCoverView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()
    private let nowButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("NOW", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 24, weight: .black)
        button.setTitleColor(.white, for: .normal)
        return button
    }()

    private let myButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("MY", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 24, weight: .black)
        button.setTitleColor(UIColor.white.withAlphaComponent(0.55), for: .normal)
        return button
    }()

    private let searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        button.tintColor = .white
        return button
    }()

    weak var coordinator: HomeCoordinator?

    // MARK: - Init

    init(viewModel: HomeViewModel, myViewModel: MyViewModel) {
        self.viewModel = viewModel
        self.myViewModel = myViewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
        view.backgroundColor = .white
        setupBlurredBackground()
        setupCollectionView()
        setupMyCollectionView()
        setupTopHeader()
        collectionView.delegate = self
        myCollectionView.delegate = self
        configureDataSource()
        configureMyDataSource()
        bindViewModel()
        bindMyViewModel()
        viewModel.viewDidLoad()
        myViewModel.viewDidLoad()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        setNeedsStatusBarAppearanceUpdate()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    // MARK: - Blurred Background Setup

    private func setupBlurredBackground() {
        blurredBackgroundImageView.backgroundColor = UIColor(red: 18/255, green: 18/255, blue: 18/255, alpha: 1)
        view.addSubview(blurredBackgroundImageView)
        blurredBackgroundImageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            blurredBackgroundHeightConstraint = $0.height.equalTo(400).constraint
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let newTopInset = view.safeAreaInsets.top + Self.navBarHeight + Self.posterTopGap
        if abs(newTopInset - heroBannerTopInset) > 0.5 {
            heroBannerTopInset = newTopInset
            collectionView.setCollectionViewLayout(
                HomeCollectionViewLayoutFactory.makeLayout(
                    topInset: heroBannerTopInset,
                    onHeroBannerPageChanged: { [weak self] page in self?.heroBannerPageChanged(to: page) }
                ),
                animated: false
            )
            collectionView.contentOffset = .zero
        }

        let posterWidth = view.bounds.width - HomeCollectionViewLayoutFactory.heroBannerPosterSideMargin * 2
        let posterHeight = posterWidth * 1.43
        blurredBackgroundHeightConstraint.update(
            offset: heroBannerTopInset + posterHeight + HomeCollectionViewLayoutFactory.heroBannerProgressAreaHeight
        )

        // contentInsetAdjustmentBehavior = .never이므로 탭바 높이를 수동 보정
        // view.safeAreaInsets.bottom = 기기 홈 인디케이터 + additionalSafeAreaInsets.bottom(60pt 탭바)
        let bottomInset = view.safeAreaInsets.bottom
        if collectionView.contentInset.bottom != bottomInset {
            collectionView.contentInset.bottom = bottomInset
            collectionView.verticalScrollIndicatorInsets.bottom = bottomInset
        }
    }

    // MARK: - Collection View (NOW)

    private func setupCollectionView() {
        collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: HomeCollectionViewLayoutFactory.makeLayout(
                topInset: 0,
                onHeroBannerPageChanged: { [weak self] page in self?.heroBannerPageChanged(to: page) }
            )
        )
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInsetAdjustmentBehavior = .never

        collectionView.register(HeroBannerCell.self, forCellWithReuseIdentifier: HeroBannerCell.reuseIdentifier)
        collectionView.register(InterestedEventCell.self, forCellWithReuseIdentifier: InterestedEventCell.reuseIdentifier)
        collectionView.register(UpcomingEventCell.self, forCellWithReuseIdentifier: UpcomingEventCell.reuseIdentifier)
        collectionView.register(HorizontalEventCell.self, forCellWithReuseIdentifier: HorizontalEventCell.reuseIdentifier)
        collectionView.register(
            SectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SectionHeaderView.reuseIdentifier
        )

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    // MARK: - Collection View (MY)

    private func setupMyCollectionView() {
        myCollectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: MyCollectionViewLayoutFactory.makeLayout()
        )
        myCollectionView.backgroundColor = .white
        myCollectionView.showsVerticalScrollIndicator = false
        myCollectionView.contentInsetAdjustmentBehavior = .never
        myCollectionView.isHidden = true

        myCollectionView.register(MyBookingCell.self, forCellWithReuseIdentifier: MyBookingCell.reuseIdentifier)
        myCollectionView.register(ShortcutCell.self, forCellWithReuseIdentifier: ShortcutCell.reuseIdentifier)
        myCollectionView.register(YearlySubtitleCell.self, forCellWithReuseIdentifier: YearlySubtitleCell.reuseIdentifier)
        myCollectionView.register(YearlyChartCell.self, forCellWithReuseIdentifier: YearlyChartCell.reuseIdentifier)
        myCollectionView.register(YearlyStatRowCell.self, forCellWithReuseIdentifier: YearlyStatRowCell.reuseIdentifier)
        myCollectionView.register(ArtistRankingCell.self, forCellWithReuseIdentifier: ArtistRankingCell.reuseIdentifier)
        myCollectionView.register(
            SectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SectionHeaderView.reuseIdentifier
        )

        view.addSubview(myCollectionView)
        myCollectionView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    // MARK: - Custom Top Header

    private func setupTopHeader() {
        // statusBarCoverView: safeArea 위 status bar 영역 채움
        view.addSubview(statusBarCoverView)
        statusBarCoverView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.top)
        }

        let headerView = UIView()
        topHeaderView = headerView
        view.addSubview(headerView)

        headerView.addSubview(nowButton)
        headerView.addSubview(myButton)
        headerView.addSubview(searchButton)

        headerView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(Self.navBarHeight)
        }

        nowButton.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
        }

        myButton.snp.makeConstraints {
            $0.leading.equalTo(nowButton.snp.trailing).offset(12)
            $0.centerY.equalToSuperview()
        }

        searchButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
        }

        nowButton.addTarget(self, action: #selector(nowTapped), for: .touchUpInside)
        myButton.addTarget(self, action: #selector(myTapped), for: .touchUpInside)
        searchButton.addTarget(self, action: #selector(searchTapped), for: .touchUpInside)
    }

    // MARK: - Data Source (NOW)

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { [weak self] cv, indexPath, item in
            self?.cell(for: item, at: indexPath, in: cv)
        }
        dataSource.supplementaryViewProvider = { [weak self] cv, kind, indexPath in
            self?.supplementaryView(kind: kind, indexPath: indexPath, in: cv)
        }
    }

    private func cell(for item: HomeSectionItem, at indexPath: IndexPath, in cv: UICollectionView) -> UICollectionViewCell {
        switch item {
        case .banner(let event):
            let cell = cv.dequeueReusableCell(withReuseIdentifier: HeroBannerCell.reuseIdentifier, for: indexPath) as! HeroBannerCell
            cell.configure(with: event, pageIndex: indexPath.item, totalPages: viewModel.state.bannerCount)
            return cell
        case .interested(let event):
            let cell = cv.dequeueReusableCell(withReuseIdentifier: InterestedEventCell.reuseIdentifier, for: indexPath) as! InterestedEventCell
            cell.configure(with: event)
            return cell
        case .upcoming(let event):
            let cell = cv.dequeueReusableCell(withReuseIdentifier: UpcomingEventCell.reuseIdentifier, for: indexPath) as! UpcomingEventCell
            cell.configure(with: event)
            return cell
        case .newlyStarted(let event), .soonEnding(let event):
            let cell = cv.dequeueReusableCell(withReuseIdentifier: HorizontalEventCell.reuseIdentifier, for: indexPath) as! HorizontalEventCell
            cell.configure(with: event)
            return cell
        }
    }

    private func supplementaryView(kind: String, indexPath: IndexPath, in cv: UICollectionView) -> UICollectionReusableView? {
        guard kind == UICollectionView.elementKindSectionHeader,
              let section = HomeSection(rawValue: indexPath.section) else { return nil }

        let header = cv.dequeueReusableSupplementaryView(
            ofKind: kind, withReuseIdentifier: SectionHeaderView.reuseIdentifier, for: indexPath
        ) as! SectionHeaderView

        switch section {
        case .interestedEvents:
            header.configure(title: "관심 있는 이벤트", accessory: .seeMore)
            header.onSeeMoreTapped = { [weak self] in self?.showSeeMore(section: section) }
        case .upcomingEvents:
            header.configure(title: "다가오는 이벤트", accessory: .seeMore)
            header.onSeeMoreTapped = { [weak self] in self?.showSeeMore(section: section) }
        case .newlyStarted:
            header.configure(title: "새로 시작된 공연", accessory: .arrows)
            header.onLeftArrowTapped  = { [weak self] in self?.scrollSection(.newlyStarted, forward: false) }
            header.onRightArrowTapped = { [weak self] in self?.scrollSection(.newlyStarted, forward: true) }
        case .soonEnding:
            header.configure(title: "곧 종료되는 공연", accessory: .arrows)
            header.onLeftArrowTapped  = { [weak self] in self?.scrollSection(.soonEnding, forward: false) }
            header.onRightArrowTapped = { [weak self] in self?.scrollSection(.soonEnding, forward: true) }
        default:
            break
        }
        return header
    }

    // MARK: - Data Source (MY)

    private func configureMyDataSource() {
        myDataSource = UICollectionViewDiffableDataSource(collectionView: myCollectionView) { [weak self] cv, indexPath, item in
            self?.myCell(for: item, at: indexPath, in: cv)
        }
        myDataSource.supplementaryViewProvider = { [weak self] cv, kind, indexPath in
            self?.mySupplementaryView(kind: kind, indexPath: indexPath, in: cv)
        }
    }

    private func myCell(for item: MySectionItem, at indexPath: IndexPath, in cv: UICollectionView) -> UICollectionViewCell {
        switch item {
        case .booking(let booking):
            let cell = cv.dequeueReusableCell(withReuseIdentifier: MyBookingCell.reuseIdentifier, for: indexPath) as! MyBookingCell
            cell.configure(with: booking)
            return cell
        case .shortcut(let shortcut):
            let cell = cv.dequeueReusableCell(withReuseIdentifier: ShortcutCell.reuseIdentifier, for: indexPath) as! ShortcutCell
            cell.configure(with: shortcut)
            return cell
        case .yearlySubtitle(let stats):
            let cell = cv.dequeueReusableCell(withReuseIdentifier: YearlySubtitleCell.reuseIdentifier, for: indexPath) as! YearlySubtitleCell
            cell.configure(with: stats)
            return cell
        case .yearlyChart(let stats):
            let cell = cv.dequeueReusableCell(withReuseIdentifier: YearlyChartCell.reuseIdentifier, for: indexPath) as! YearlyChartCell
            cell.configure(with: stats)
            return cell
        case .yearlyStatRow(let stats):
            let cell = cv.dequeueReusableCell(withReuseIdentifier: YearlyStatRowCell.reuseIdentifier, for: indexPath) as! YearlyStatRowCell
            cell.configure(with: stats)
            cell.onCardTapped = { [weak self] kind in self?.handleStatCardTap(kind) }
            return cell
        case .artistRanking(let entry):
            let cell = cv.dequeueReusableCell(withReuseIdentifier: ArtistRankingCell.reuseIdentifier, for: indexPath) as! ArtistRankingCell
            cell.configure(with: entry)
            let row = indexPath.item
            cell.onToggleExpansion = { [weak self] in
                self?.myViewModel.toggleArtistExpansion(at: row)
            }
            return cell
        }
    }

    private func mySupplementaryView(kind: String, indexPath: IndexPath, in cv: UICollectionView) -> UICollectionReusableView? {
        guard kind == UICollectionView.elementKindSectionHeader,
              let section = MySection(rawValue: indexPath.section) else { return nil }

        let header = cv.dequeueReusableSupplementaryView(
            ofKind: kind, withReuseIdentifier: SectionHeaderView.reuseIdentifier, for: indexPath
        ) as! SectionHeaderView

        switch section {
        case .myBookings:
            header.configure(title: "내 예매 현황", accessory: .none)
        case .shortcuts:
            header.configure(title: "바로가기", accessory: .none)
        case .yearlyStats:
            header.configure(title: "올해 본 공연", accessory: .none)
        case .artistRanking:
            header.configure(title: "아티스트 랭킹", accessory: .none)
        }
        return header
    }

    // MARK: - Snapshots

    private func applySnapshot() {
        let state = viewModel.state
        var snapshot = NSDiffableDataSourceSnapshot<HomeSection, HomeSectionItem>()
        snapshot.appendSections(HomeSection.allCases)
        snapshot.appendItems(state.banners.map { .banner($0) },                  toSection: .heroBanner)
        snapshot.appendItems(state.interestedEvents.map { .interested($0) },     toSection: .interestedEvents)
        snapshot.appendItems(state.upcomingEvents.map { .upcoming($0) },         toSection: .upcomingEvents)
        snapshot.appendItems(state.newlyStartedEvents.map { .newlyStarted($0) }, toSection: .newlyStarted)
        snapshot.appendItems(state.soonEndingEvents.map { .soonEnding($0) },     toSection: .soonEnding)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func applyMySnapshot() {
        let state = myViewModel.state
        var snapshot = NSDiffableDataSourceSnapshot<MySection, MySectionItem>()
        snapshot.appendSections(MySection.allCases)
        snapshot.appendItems(state.bookings.map { .booking($0) }, toSection: .myBookings)
        snapshot.appendItems(ShortcutItem.allCases.map { .shortcut($0) }, toSection: .shortcuts)
        if let stats = state.stats {
            snapshot.appendItems([
                .yearlySubtitle(stats),
                .yearlyChart(stats),
                .yearlyStatRow(stats)
            ], toSection: .yearlyStats)
        }
        snapshot.appendItems(state.artistRankings.map { .artistRanking($0) }, toSection: .artistRanking)
        myDataSource.apply(snapshot, animatingDifferences: true)
    }

    // MARK: - Binding

    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] in
            guard let self else { return }
            self.applySnapshot()
            if let firstBanner = self.viewModel.state.banners.first {
                self.updateBlurredBackground(with: firstBanner)
            }
        }
    }

    private func bindMyViewModel() {
        myViewModel.onStateChanged = { [weak self] in
            self?.applyMySnapshot()
        }
    }

    // MARK: - Hero banner page tracking

    private func heroBannerPageChanged(to page: Int) {
        guard page != currentHeroBannerPage else { return }
        currentHeroBannerPage = page
        let banners = viewModel.state.banners
        guard page < banners.count else { return }
        updateBlurredBackground(with: banners[page])
    }

    // MARK: - Blurred background update

    private func updateBlurredBackground(with event: Event) {
        guard let imageName = event.imageAssetName,
              let image = UIImage(named: imageName) else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let blurred = Self.gaussianBlur(image: image, radius: 25)
            DispatchQueue.main.async {
                UIView.transition(
                    with: self!.blurredBackgroundImageView,
                    duration: 0.4,
                    options: .transitionCrossDissolve
                ) {
                    self?.blurredBackgroundImageView.image = blurred
                }
            }
        }
    }

    private nonisolated static func gaussianBlur(image: UIImage, radius: CGFloat) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        let clamp = CIFilter(name: "CIAffineClamp")
        clamp?.setValue(ciImage, forKey: kCIInputImageKey)
        clamp?.setValue(CGAffineTransform.identity, forKey: "inputTransform")
        guard let clamped = clamp?.outputImage else { return nil }
        let blur = CIFilter(name: "CIGaussianBlur")
        blur?.setValue(clamped, forKey: kCIInputImageKey)
        blur?.setValue(radius, forKey: kCIInputRadiusKey)
        guard let output = blur?.outputImage else { return nil }
        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let cgImage = context.createCGImage(output, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    // MARK: - Mode switching

    private func switchToNow() {
        isMyMode = false
        collectionView.isHidden = false
        myCollectionView.isHidden = true
        blurredBackgroundImageView.isHidden = false
        view.backgroundColor = .white
        topHeaderView.backgroundColor = .clear
        statusBarCoverView.backgroundColor = .clear
        nowButton.setTitleColor(.white, for: .normal)
        myButton.setTitleColor(UIColor.white.withAlphaComponent(0.55), for: .normal)
        searchButton.tintColor = .white
    }

    private func switchToMy() {
        isMyMode = true
        collectionView.isHidden = true
        myCollectionView.isHidden = false
        blurredBackgroundImageView.isHidden = true
        view.backgroundColor = .white
        topHeaderView.backgroundColor = .white
        statusBarCoverView.backgroundColor = .white
        let activeColor = UIColor(red: 0.063, green: 0.094, blue: 0.157, alpha: 1)
        let inactiveColor = UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1)
        myButton.setTitleColor(activeColor, for: .normal)
        nowButton.setTitleColor(inactiveColor, for: .normal)
        searchButton.tintColor = activeColor

        // 상단 inset: status bar + navBar
        let topInset = view.safeAreaInsets.top + Self.navBarHeight
        // 하단 inset: additionalSafeAreaInsets(탭바 60pt) + 기기 홈 인디케이터
        let bottomInset = view.safeAreaInsets.bottom
        myCollectionView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: bottomInset, right: 0)
        myCollectionView.verticalScrollIndicatorInsets = UIEdgeInsets(top: topInset, left: 0, bottom: bottomInset, right: 0)
        myCollectionView.contentOffset = CGPoint(x: 0, y: -topInset)
    }

    // MARK: - Actions

    @objc private func nowTapped() {
        guard isMyMode else { return }
        switchToNow()
    }

    @objc private func myTapped() {
        guard !isMyMode else { return }
        switchToMy()
    }

    @objc private func searchTapped() {
        coordinator?.showSearch()
    }

    private func handleStatCardTap(_ kind: StatCardKind) {
        switch kind {
        case .topArtist:
            let sectionIndex = MySection.artistRanking.rawValue
            let snapshot = myDataSource.snapshot()
            guard snapshot.numberOfItems(inSection: .artistRanking) > 0 else { return }
            myCollectionView.scrollToItem(
                at: IndexPath(item: 0, section: sectionIndex), at: .top, animated: true
            )
        case .topView, .topGenre:
            break  // TODO: 관람 랭킹 / 장르 랭킹 화면 구현
        }
    }

    private func showSeeMore(section: HomeSection) { /* TODO: push EventListViewController */ }

    private func scrollSection(_ section: HomeSection, forward: Bool) {
        let sectionIndex = section.rawValue
        let snapshot = dataSource.snapshot()
        let count = snapshot.numberOfItems(inSection: section)
        guard count > 0 else { return }

        switch (section, forward) {
        case (.newlyStarted, true):
            newlyStartedOffset = min(newlyStartedOffset + 1, count - 1)
            collectionView.scrollToItem(at: IndexPath(item: newlyStartedOffset, section: sectionIndex), at: .top, animated: true)
        case (.newlyStarted, false):
            newlyStartedOffset = max(newlyStartedOffset - 1, 0)
            collectionView.scrollToItem(at: IndexPath(item: newlyStartedOffset, section: sectionIndex), at: .top, animated: true)
        case (.soonEnding, true):
            soonEndingOffset = min(soonEndingOffset + 1, count - 1)
            collectionView.scrollToItem(at: IndexPath(item: soonEndingOffset, section: sectionIndex), at: .top, animated: true)
        case (.soonEnding, false):
            soonEndingOffset = max(soonEndingOffset - 1, 0)
            collectionView.scrollToItem(at: IndexPath(item: soonEndingOffset, section: sectionIndex), at: .top, animated: true)
        default:
            break
        }
    }
}

// MARK: - UICollectionViewDelegate

extension HomeViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === collectionView else { return }
        let offsetY = scrollView.contentOffset.y
        let bgOffsetY = max(offsetY, 0)
        blurredBackgroundImageView.transform = CGAffineTransform(translationX: 0, y: -bgOffsetY)
        topHeaderView.transform = CGAffineTransform(translationX: 0, y: -offsetY)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView === self.collectionView {
            guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
            let event: Event
            switch item {
            case .banner(let e), .interested(let e), .upcoming(let e),
                 .newlyStarted(let e), .soonEnding(let e):
                event = e
            }
            coordinator?.showConcertDetail(concertId: event.id, imageAssetName: event.imageAssetName)
        } else if collectionView === myCollectionView {
            guard let item = myDataSource.itemIdentifier(for: indexPath) else { return }
            if case .booking(let booking) = item {
                coordinator?.showConcertDetail(concertId: booking.id, imageAssetName: booking.imageAssetName)
            }
        }
    }
}
