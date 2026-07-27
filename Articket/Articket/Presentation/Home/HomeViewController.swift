import UIKit
import SnapKit

@MainActor
final class HomeViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: HomeViewModel
    private let myViewModel: MyViewModel
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<HomeSection, HomeSectionItem>!

    /// 블록 기반 알림 옵저버 토큰 — deinit에서 해제해 좀비 옵저버·중복 구독을 막는다 (Profile과 동일 패턴)
    private var notificationTokens: [NSObjectProtocol] = []
    private var myCollectionView: UICollectionView!
    private var myDataSource: UICollectionViewDiffableDataSource<MySection, MySectionItem>!
    private var newlyStartedOffset: Int = 0
    private var soonEndingOffset: Int = 0
    private var currentHeroBannerPage: Int = 0
    private var isMyMode: Bool = false
    private var currentHomeSections: [HomeSection] = [.heroBanner, .newlyStarted, .soonEnding]
    private var currentMySections: [MySection] = []

    // MARK: - Hero banner top inset
    private static let navBarHeight: CGFloat = 56
    private static let posterTopGap: CGFloat = 17
    private var posterHeight: CGFloat = 0
    private var isHeaderOpaque = false
    private var heroBannerTopInset: CGFloat = 0

    // MARK: - Blurred hero background
    private let blurredBackgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private var blurredBackgroundHeightConstraint: Constraint!
    private let blurDimOverlay: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        return v
    }()

    private let heroBannerProgressView = HeroBannerProgressView()
    private var heroBannerProgressTopConstraint: Constraint!

    private let skeletonView = HomeSkeletonView()
    private let myModeSkeletonView = MyModeSkeletonView()

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
        button.setTitle("PLAY", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 24, weight: .black)
        button.setTitleColor(UIColor.white.withAlphaComponent(0.55), for: .normal)
        return button
    }()

    private let searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        button.tintColor = .white
        button.accessibilityLabel = "검색"
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
        setupHeroBannerProgress()
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
        (navigationController?.parent as? MainTabBarController)?.setTabBarHidden(false, animated: false)
        // 외부 예매처에 다녀온 직후를 잡기 위해 홈으로 돌아올 때마다 미응답 intent를 다시 조회
        viewModel.refreshBookingIntent()
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

        blurredBackgroundImageView.addSubview(blurDimOverlay)
        blurDimOverlay.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    private func setupHeroBannerProgress() {
        view.addSubview(heroBannerProgressView)
        heroBannerProgressView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(45)
            $0.height.equalTo(2.5)
            heroBannerProgressTopConstraint = $0.top.equalToSuperview().offset(0).constraint
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
                    sections: currentHomeSections,
                    onHeroBannerPageChanged: { [weak self] page in self?.heroBannerPageChanged(to: page) }
                ),
                animated: false
            )
            collectionView.contentOffset = .zero
        }

        let posterWidth = view.bounds.width - HomeCollectionViewLayoutFactory.heroBannerPosterSideMargin * 2
        posterHeight = posterWidth * 1.43
        blurredBackgroundHeightConstraint.update(
            offset: heroBannerTopInset + posterHeight + HomeCollectionViewLayoutFactory.heroBannerProgressAreaHeight
        )
        heroBannerProgressTopConstraint.update(offset: heroBannerTopInset + posterHeight + 20)

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
                sections: currentHomeSections,
                onHeroBannerPageChanged: { [weak self] page in self?.heroBannerPageChanged(to: page) }
            )
        )
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.isDirectionalLockEnabled = true
        collectionView.alwaysBounceVertical = true

        collectionView.register(HeroBannerCell.self, forCellWithReuseIdentifier: HeroBannerCell.reuseIdentifier)
        collectionView.register(BookingPromptCell.self, forCellWithReuseIdentifier: BookingPromptCell.reuseIdentifier)
        collectionView.register(InterestedEventCell.self, forCellWithReuseIdentifier: InterestedEventCell.reuseIdentifier)
        collectionView.register(UpcomingEventCell.self, forCellWithReuseIdentifier: UpcomingEventCell.reuseIdentifier)
        collectionView.register(HorizontalEventCell.self, forCellWithReuseIdentifier: HorizontalEventCell.reuseIdentifier)
        collectionView.register(
            SectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SectionHeaderView.reuseIdentifier
        )

        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .white
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalToSuperview() }

        view.addSubview(skeletonView)
        skeletonView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    // MARK: - Collection View (MY)

    private func setupMyCollectionView() {
        myCollectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: MyCollectionViewLayoutFactory.makeLayout(sections: [])
        )
        myCollectionView.backgroundColor = .white
        myCollectionView.showsVerticalScrollIndicator = false
        myCollectionView.contentInsetAdjustmentBehavior = .never
        myCollectionView.isHidden = true

        myCollectionView.register(MyBookingCell.self, forCellWithReuseIdentifier: MyBookingCell.reuseIdentifier)
        myCollectionView.register(MyBookingEmptyCell.self, forCellWithReuseIdentifier: MyBookingEmptyCell.reuseIdentifier)
        myCollectionView.register(ShortcutCell.self, forCellWithReuseIdentifier: ShortcutCell.reuseIdentifier)
        myCollectionView.register(YearlySubtitleCell.self, forCellWithReuseIdentifier: YearlySubtitleCell.reuseIdentifier)
        myCollectionView.register(YearlyChartCell.self, forCellWithReuseIdentifier: YearlyChartCell.reuseIdentifier)
        myCollectionView.register(YearlyStatRowCell.self, forCellWithReuseIdentifier: YearlyStatRowCell.reuseIdentifier)
        myCollectionView.register(ArtistRankingCell.self, forCellWithReuseIdentifier: ArtistRankingCell.reuseIdentifier)
        myCollectionView.register(StatEventCell.self, forCellWithReuseIdentifier: StatEventCell.reuseIdentifier)
        myCollectionView.register(StatSeeMoreCell.self, forCellWithReuseIdentifier: StatSeeMoreCell.reuseIdentifier)
        myCollectionView.register(StatEmptyCell.self, forCellWithReuseIdentifier: StatEmptyCell.reuseIdentifier)
        myCollectionView.register(
            SectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SectionHeaderView.reuseIdentifier
        )

        view.addSubview(myCollectionView)
        myCollectionView.snp.makeConstraints { $0.edges.equalToSuperview() }

        myModeSkeletonView.isHidden = true
        view.addSubview(myModeSkeletonView)
        myModeSkeletonView.snp.makeConstraints { $0.edges.equalToSuperview() }
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
            $0.size.equalTo(44)
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
            cell.configure(with: event)
            return cell
        case .bannerPlaceholder:
            let cell = cv.dequeueReusableCell(withReuseIdentifier: HeroBannerCell.reuseIdentifier, for: indexPath) as! HeroBannerCell
            cell.configureAsPlaceholder()
            return cell
        case .bookingPrompt(let intent):
            let cell = cv.dequeueReusableCell(withReuseIdentifier: BookingPromptCell.reuseIdentifier, for: indexPath) as! BookingPromptCell
            cell.configure(with: intent)
            cell.onConfirm = { [weak self] in
                AppLog.shared.action("예매확인:네")
                self?.viewModel.confirmBookingIntent()
            }
            cell.onDismiss = { [weak self] in
                AppLog.shared.action("예매확인:아니요")
                self?.viewModel.dismissBookingIntent()
            }
            return cell
        case .recommended(let event):
            let cell = cv.dequeueReusableCell(withReuseIdentifier: InterestedEventCell.reuseIdentifier, for: indexPath) as! InterestedEventCell
            cell.configure(with: event)
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
        guard kind == UICollectionView.elementKindSectionHeader else { return nil }
        // 조건부 섹션 추가 때문에 rawValue 대신 snapshot에서 실제 section 식별자 참조
        let sections = dataSource.snapshot().sectionIdentifiers
        guard indexPath.section < sections.count else { return nil }
        let section = sections[indexPath.section]

        let header = cv.dequeueReusableSupplementaryView(
            ofKind: kind, withReuseIdentifier: SectionHeaderView.reuseIdentifier, for: indexPath
        ) as! SectionHeaderView

        switch section {
        case .recommendations:
            header.configure(title: "회원님을 위한 추천", accessory: .seeMore)
            header.onSeeMoreTapped = { [weak self] in self?.showSeeMore(section: section) }
        case .interestedEvents:
            header.configure(title: "관심 있는 이벤트", accessory: .seeMore)
            header.onSeeMoreTapped = { [weak self] in self?.showSeeMore(section: section) }
        case .upcomingEvents:
            header.configure(title: "오픈 예정", accessory: .seeMore)
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
        case .bookingEmpty:
            return cv.dequeueReusableCell(withReuseIdentifier: MyBookingEmptyCell.reuseIdentifier, for: indexPath)
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
            cell.setSelectedKind(myViewModel.state.selectedStatCard)  // 리로드 후 선택 하이라이트 복원
            cell.onCardTapped = { [weak self] kind in self?.handleStatCardTap(kind) }
            return cell
        case .artistRanking(let entry):
            let cell = cv.dequeueReusableCell(withReuseIdentifier: ArtistRankingCell.reuseIdentifier, for: indexPath) as! ArtistRankingCell
            cell.configure(with: entry)
            let row = indexPath.item
            let artistId = entry.id
            cell.onToggleExpansion = { [weak self] in
                self?.myViewModel.toggleArtistExpansion(at: row)
            }
            cell.onArtistTapped = { [weak self] in
                self?.coordinator?.showArtistDetail(artistId: artistId)
            }
            return cell
        case .statEvent(let event):
            let cell = cv.dequeueReusableCell(withReuseIdentifier: StatEventCell.reuseIdentifier, for: indexPath) as! StatEventCell
            cell.configure(with: event)
            return cell
        case .statSeeMore(let kind):
            let cell = cv.dequeueReusableCell(withReuseIdentifier: StatSeeMoreCell.reuseIdentifier, for: indexPath) as! StatSeeMoreCell
            cell.configure(expanded: kind == .topArtist && myViewModel.state.isStatExpanded)
            return cell
        case .statEmpty(let kind):
            let cell = cv.dequeueReusableCell(withReuseIdentifier: StatEmptyCell.reuseIdentifier, for: indexPath) as! StatEmptyCell
            cell.configure(kind: kind)
            return cell
        }
    }

    private func mySupplementaryView(kind: String, indexPath: IndexPath, in cv: UICollectionView) -> UICollectionReusableView? {
        guard kind == UICollectionView.elementKindSectionHeader else { return nil }

        // 조건부 섹션 추가 때문에 rawValue 대신 snapshot에서 실제 section 식별자 참조
        let sections = myDataSource.snapshot().sectionIdentifiers
        guard indexPath.section < sections.count else { return nil }
        let section = sections[indexPath.section]

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
        case .statDetail:
            return header  // 별도 헤더 없음 — 통계 카드 바로 아래 붙는 스왑 리스트
        }
        return header
    }

    // MARK: - Snapshots

    private func applySnapshot() {
        let state = viewModel.state

        // Build ordered sections list — drives both snapshot and layout index mapping
        var sections: [HomeSection] = [.heroBanner]
        if state.pendingBookingIntent != nil { sections.append(.bookingPrompt) }
        if !state.recommendedEvents.isEmpty { sections.append(.recommendations) }
        if !state.interestedEvents.isEmpty { sections.append(.interestedEvents) }
        if !state.upcomingEvents.isEmpty   { sections.append(.upcomingEvents) }
        if !state.newlyStartedEvents.isEmpty { sections.append(.newlyStarted) }
        if !state.soonEndingEvents.isEmpty   { sections.append(.soonEnding) }

        // Rebuild layout whenever the section set changes (rawValue-based lookup would break otherwise)
        if sections != currentHomeSections {
            currentHomeSections = sections
            newlyStartedOffset = 0
            soonEndingOffset = 0
            collectionView.setCollectionViewLayout(
                HomeCollectionViewLayoutFactory.makeLayout(
                    topInset: heroBannerTopInset,
                    sections: currentHomeSections,
                    onHeroBannerPageChanged: { [weak self] page in self?.heroBannerPageChanged(to: page) }
                ),
                animated: false
            )
        }

        var snapshot = NSDiffableDataSourceSnapshot<HomeSection, HomeSectionItem>()
        snapshot.appendSections(sections)
        // placeholder keeps heroBanner section height intact when real banners are empty
        let bannerItems: [HomeSectionItem] = state.banners.isEmpty
            ? [.bannerPlaceholder]
            : state.banners.map { .banner($0) }
        snapshot.appendItems(bannerItems, toSection: .heroBanner)

        if let intent = state.pendingBookingIntent {
            snapshot.appendItems([.bookingPrompt(intent)], toSection: .bookingPrompt)
        }

        if !state.recommendedEvents.isEmpty {
            snapshot.appendItems(state.recommendedEvents.map { .recommended($0) }, toSection: .recommendations)
        }
        if !state.interestedEvents.isEmpty {
            snapshot.appendItems(state.interestedEvents.map { .interested($0) }, toSection: .interestedEvents)
        }
        // 홈에는 최대 2개만 표시; 더보기에서 전체 목록 확인 가능
        if !state.upcomingEvents.isEmpty {
            snapshot.appendItems(Array(state.upcomingEvents.prefix(2)).map { .upcoming($0) }, toSection: .upcomingEvents)
        }
        if !state.newlyStartedEvents.isEmpty {
            snapshot.appendItems(state.newlyStartedEvents.map { .newlyStarted($0) }, toSection: .newlyStarted)
        }
        if !state.soonEndingEvents.isEmpty {
            snapshot.appendItems(state.soonEndingEvents.map { .soonEnding($0) }, toSection: .soonEnding)
        }

        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func applyMySnapshot() {
        let state = myViewModel.state
        var snapshot = NSDiffableDataSourceSnapshot<MySection, MySectionItem>()

        // 활성 섹션 목록 구성 — 레이아웃 인덱스 매핑에 사용
        var activeSections: [MySection] = []

        // 예매 내역: 항상 섹션 표시 — 비어있을 때는 빈 상태 셀로 안내
        activeSections.append(.myBookings)
        snapshot.appendSections([.myBookings])
        if state.bookings.isEmpty {
            snapshot.appendItems([.bookingEmpty], toSection: .myBookings)
        } else {
            snapshot.appendItems(state.bookings.map { .booking($0) }, toSection: .myBookings)
        }

        // 바로가기: 항상 표시
        activeSections.append(.shortcuts)
        snapshot.appendSections([.shortcuts])
        snapshot.appendItems(ShortcutItem.allCases.map { .shortcut($0) }, toSection: .shortcuts)

        // 올해 통계: 항상 표시 (stats가 없으면 기본값 사용)
        let stats = state.stats ?? MyStats(
            year: Calendar.current.component(.year, from: Date()),
            monthlyViewCounts: Array(repeating: 0, count: 12),
            topMonth: 1, topGenre: "-", topArtist: "-", totalCount: 0
        )
        activeSections.append(.yearlyStats)
        snapshot.appendSections([.yearlyStats])
        snapshot.appendItems([
            .yearlySubtitle(stats),
            .yearlyChart(stats),
            .yearlyStatRow(stats)
        ], toSection: .yearlyStats)

        // 통계 상세: 선택된 카드에 맞춰 스왑되는 리스트 (통계 카드 바로 아래, 항상 표시)
        activeSections.append(.statDetail)
        snapshot.appendSections([.statDetail])
        var statItems: [MySectionItem] = []
        switch state.selectedStatCard {
        case .topArtist:
            let rows = myViewModel.statArtistRows
            statItems = rows.isEmpty ? [.statEmpty(.topArtist)] : rows.map { .artistRanking($0) }
        case .topView, .topGenre:
            let rows = myViewModel.statEventRows
            statItems = rows.isEmpty ? [.statEmpty(state.selectedStatCard)] : rows.map { .statEvent($0) }
        }
        if myViewModel.showsStatSeeMore {
            statItems.append(.statSeeMore(state.selectedStatCard))
        }
        // 같은 공연을 두 번 예매하면 동일한 Event가 중복 생성돼 .statEvent 아이템이 겹치고,
        // NSDiffableDataSource는 중복 식별자에서 크래시난다(빈 카드 탭 시 apply 순간 발생).
        // 순서를 유지하며 중복 아이템을 제거해 방어한다.
        var seenStatItems = Set<MySectionItem>()
        statItems = statItems.filter { seenStatItems.insert($0).inserted }
        snapshot.appendItems(statItems, toSection: .statDetail)

        // 섹션 구성이 바뀐 경우에만 레이아웃 재생성
        if activeSections != currentMySections {
            currentMySections = activeSections
            myCollectionView.setCollectionViewLayout(
                MyCollectionViewLayoutFactory.makeLayout(sections: currentMySections),
                animated: false
            )
        }

        myDataSource.apply(snapshot, animatingDifferences: !state.isLoading)
    }

    // MARK: - Binding

    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] in
            guard let self else { return }
            self.applySnapshot()
            if !self.viewModel.state.isLoading {
                self.collectionView.refreshControl?.endRefreshing()
            }
            if !self.viewModel.state.isLoading && !self.skeletonView.isHidden {
                UIView.animate(withDuration: 0.3) {
                    self.skeletonView.alpha = 0
                } completion: { _ in
                    self.skeletonView.isHidden = true
                    self.skeletonView.stopShimmer()
                }
            }
            let banners = self.viewModel.state.banners
            self.heroBannerProgressView.isHidden = banners.isEmpty
            self.heroBannerProgressView.configure(totalPages: banners.count)
            if let firstBanner = banners.first {
                self.updateBlurredBackground(with: firstBanner)
            }
        }
        viewModel.onError = { [weak self] message in
            self?.collectionView.refreshControl?.endRefreshing()
            self?.showErrorAlert(message, retry: { self?.viewModel.viewDidLoad() })
        }
        viewModel.onBookingIntentResolved = { [weak self] message in
            self?.showToast(message, type: .success)
        }
        viewModel.onLoginRequired = { [weak self] retry in
            self?.showLoginPrompt(then: retry)
        }
        viewModel.onTicketScheduleLoaded = { [weak self] events in
            self?.coordinator?.showEventList(title: "예매 일정", events: events)
        }

        let center = NotificationCenter.default
        notificationTokens.append(center.addObserver(
            forName: .eventInterestedDidChange, object: nil, queue: .main
        ) { [weak self] _ in
            self?.viewModel.refreshInterestedEvents()
        })

        // 외부 예매처는 별도 앱/사파리로 열리므로 복귀 시 viewWillAppear가 안 뜬다 → 포그라운드 복귀도 함께 감시
        notificationTokens.append(center.addObserver(
            forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main
        ) { [weak self] _ in
            self?.viewModel.refreshBookingIntent()
        })

        // 로그인 직후 로컬에 쌓아둔 intent를 서버 기준으로 다시 확인
        notificationTokens.append(center.addObserver(
            forName: .userDidLogin, object: nil, queue: .main
        ) { [weak self] _ in
            self?.viewModel.refreshBookingIntent()
        })
    }

    deinit {
        notificationTokens.forEach { NotificationCenter.default.removeObserver($0) }
    }

    @objc private func handleRefresh() {
        viewModel.reload()
    }

    private func bindMyViewModel() {
        myViewModel.onStateChanged = { [weak self] in
            guard let self else { return }
            self.applyMySnapshot()
            if !self.myViewModel.state.isLoading && !self.myModeSkeletonView.isHidden {
                UIView.animate(withDuration: 0.25) {
                    self.myModeSkeletonView.alpha = 0
                } completion: { _ in
                    self.myModeSkeletonView.isHidden = true
                    self.myModeSkeletonView.stopShimmer()
                }
            }
        }
        myViewModel.onError = { [weak self] message in
            self?.showErrorAlert(message, retry: { self?.myViewModel.viewDidLoad() })
        }
    }


    // MARK: - Hero banner page tracking

    private func heroBannerPageChanged(to page: Int) {
        guard page != currentHeroBannerPage else { return }
        currentHeroBannerPage = page
        heroBannerProgressView.setPage(page)
        let banners = viewModel.state.banners
        guard page < banners.count else { return }
        updateBlurredBackground(with: banners[page])
    }

    // MARK: - Blurred background update

    private func updateBlurredBackground(with event: Event) {
        guard let urlString = event.posterUrl, let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = UIImage(data: data) else { return }
            let blurred = Self.gaussianBlur(image: image, radius: 25)
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                UIView.transition(
                    with: self.blurredBackgroundImageView,
                    duration: 0.4,
                    options: .transitionCrossDissolve
                ) {
                    self.blurredBackgroundImageView.image = blurred
                }
            }
        }.resume()
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
        heroBannerProgressView.isHidden = false
        view.backgroundColor = .white

        // 현재 스크롤 위치 기준으로 헤더 스타일 즉시 복원
        let offsetY = collectionView.contentOffset.y
        let shouldBeOpaque = offsetY > Self.posterTopGap + posterHeight
        isHeaderOpaque = shouldBeOpaque
        applyNowHeaderStyle(opaque: shouldBeOpaque)
    }

    private func switchToMy() {
        isMyMode = true
        isHeaderOpaque = false  // NOW 모드 복귀 시 재계산하도록 초기화
        collectionView.isHidden = true
        myCollectionView.isHidden = false
        blurredBackgroundImageView.isHidden = true
        heroBannerProgressView.isHidden = true
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

        if myViewModel.state.isLoading {
            myModeSkeletonView.isHidden = false
            myModeSkeletonView.alpha = 1
        }
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
        // 선택 카드 변경 → 하단 상세 리스트가 해당 카드로 스왑(제자리 갱신)
        myViewModel.selectStatCard(kind)
    }

    private func showSeeMore(section: HomeSection) {
        let state = viewModel.state
        switch section {
        case .recommendations:
            coordinator?.showEventList(title: "회원님을 위한 추천", events: state.recommendedEvents)
        case .interestedEvents:
            coordinator?.showEventList(title: "관심 있는 이벤트", events: state.interestedEvents)
        case .upcomingEvents:
            coordinator?.showEventList(title: "오픈 예정", events: state.upcomingEvents)
        default:
            break
        }
    }

    private func scrollSection(_ section: HomeSection, forward: Bool) {
        let snapshot = dataSource.snapshot()
        guard let sectionIndex = snapshot.sectionIdentifiers.firstIndex(of: section) else { return }
        let count = snapshot.numberOfItems(inSection: section)
        guard count > 0 else { return }

        let step = HomeCollectionViewLayoutFactory.verticalEventItemsPerPage

        switch section {
        case .newlyStarted:
            newlyStartedOffset = forward
                ? min(newlyStartedOffset + step, count - 1)
                : max(newlyStartedOffset - step, 0)
            collectionView.scrollToItem(
                at: IndexPath(item: newlyStartedOffset, section: sectionIndex),
                at: .centeredHorizontally, animated: true
            )
        case .soonEnding:
            soonEndingOffset = forward
                ? min(soonEndingOffset + step, count - 1)
                : max(soonEndingOffset - step, 0)
            collectionView.scrollToItem(
                at: IndexPath(item: soonEndingOffset, section: sectionIndex),
                at: .centeredHorizontally, animated: true
            )
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

        if offsetY < 0 {
            // Pull-to-refresh: 블러를 상단 고정 + 하단 방향으로 stretch해서 poster와 일체감 유지
            let pull = -offsetY
            let blurH = blurredBackgroundImageView.bounds.height
            if blurH > 0 {
                let scale = (blurH + pull) / blurH
                // scale(1, s).concatenating(translate(0, pull/2)) → 상단 고정, 하단 +pull 확장
                let stretchT = CGAffineTransform(scaleX: 1, y: scale)
                    .concatenating(CGAffineTransform(translationX: 0, y: pull / 2))
                blurredBackgroundImageView.transform = stretchT
            }
            heroBannerProgressView.transform = CGAffineTransform(translationX: 0, y: pull)
        } else {
            // 일반 스크롤: 블러를 콘텐츠와 함께 위로 올려 하단 섹션에 블러가 겹치지 않도록
            let t = CGAffineTransform(translationX: 0, y: -offsetY)
            blurredBackgroundImageView.transform = t
            heroBannerProgressView.transform = t
        }

        if !isMyMode {
            let stickyThreshold = Self.posterTopGap + posterHeight
            let shouldBeOpaque = offsetY > stickyThreshold
            if shouldBeOpaque != isHeaderOpaque {
                isHeaderOpaque = shouldBeOpaque
                applyNowHeaderStyle(opaque: shouldBeOpaque)
            }
        }
    }

    private func applyNowHeaderStyle(opaque: Bool) {
        let darkColor = UIColor(red: 0.063, green: 0.094, blue: 0.157, alpha: 1)
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self else { return }
            self.topHeaderView.backgroundColor = opaque ? .white : .clear
            self.statusBarCoverView.backgroundColor = opaque ? .white : .clear
        }
        nowButton.setTitleColor(opaque ? darkColor : .white, for: .normal)
        myButton.setTitleColor(
            opaque
                ? UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1)
                : UIColor.white.withAlphaComponent(0.55),
            for: .normal
        )
        searchButton.tintColor = opaque ? darkColor : .white
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView === self.collectionView {
            guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
            let event: Event
            switch item {
            case .bannerPlaceholder:
                return
            case .bookingPrompt:
                // 셀 안의 [네]/[아니요] 버튼이 액션을 처리한다. 배너 자체 탭은 무시 —
                // 여기서 상세로 보내면 답을 고르려다 화면이 튀는 오작동이 된다.
                return
            case .banner(let e), .interested(let e), .upcoming(let e),
                 .newlyStarted(let e), .soonEnding(let e), .recommended(let e):
                event = e
            }
            coordinator?.showConcertDetail(concertId: event.id, imageAssetName: event.posterUrl)
        } else if collectionView === myCollectionView {
            guard let item = myDataSource.itemIdentifier(for: indexPath) else { return }
            if case .booking(let booking) = item {
                coordinator?.showConcertDetail(concertId: booking.eventId, imageAssetName: booking.imageAssetName)
            } else if case .shortcut(let shortcut) = item {
                switch shortcut {
                case .timetable:
                    coordinator?.showTimetable()
                case .schedule:
                    viewModel.requestTicketSchedule()
                }
            } else if case .statEvent(let event) = item {
                coordinator?.showConcertDetail(concertId: event.id, imageAssetName: event.posterUrl)
            } else if case .statSeeMore(let kind) = item {
                handleStatSeeMore(kind)
            }
        }
    }

    /// 통계 상세 "더보기" — 최애는 인라인 확장, 이벤트 카드는 전체 리스트로 push
    private func handleStatSeeMore(_ kind: StatCardKind) {
        switch kind {
        case .topArtist:
            myViewModel.toggleStatExpansion()
        case .topView:
            coordinator?.showEventList(title: "\(myViewModel.state.stats?.topMonth ?? 0)월 관람작",
                                       events: myViewModel.statEventsAll)
        case .topGenre:
            let genre = myViewModel.state.stats?.topGenre ?? ""
            coordinator?.showEventList(title: genre.isEmpty ? "선호 장르 관람작" : "\(genre) 관람작",
                                       events: myViewModel.statEventsAll)
        }
    }
}
