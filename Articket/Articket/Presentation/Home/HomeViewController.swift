import UIKit
import SnapKit

@MainActor
final class HomeViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: HomeViewModel
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<HomeSection, HomeSectionItem>!
    private var newlyStartedOffset: Int = 0
    private var soonEndingOffset: Int = 0
    private var currentHeroBannerPage: Int = 0

    // MARK: - Hero banner top inset
    // Nav bar spec (Figma): 11.5pt top padding + 33pt content + 11.5pt bottom padding = 56pt total.
    // Poster starts 17pt below the nav bar bottom → topInset = safeAreaTop + 56 + 17 = safeAreaTop + 73.
    private static let navBarHeight: CGFloat = 56   // 11.5 + 33 + 11.5
    private static let posterTopGap: CGFloat = 17   // gap from nav bar bottom to poster top
    private var heroBannerTopInset: CGFloat = 0

    // MARK: - Blurred hero background
    // Covers: status bar + nav bar + gap + poster + progress area.
    // 60pt white gap below before "관심 있는 이벤트" header.
    private let blurredBackgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private var blurredBackgroundHeightConstraint: Constraint!

    // MARK: - Custom top header (replaces system navigation bar)
    // Total height 56pt (11.5pt top + 33pt content + 11.5pt bottom padding).
    // Stored as a property so scrollViewDidScroll can translate it with the banner.
    private var topHeaderView: UIView!
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

    // MARK: - Init

    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // opaque bar 포함 전체 레이아웃이 y=0(status bar 뒤)부터 시작하도록 강제
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
        view.backgroundColor = .white
        setupBlurredBackground()
        setupCollectionView()
        setupTopHeader()
        collectionView.delegate = self
        configureDataSource()
        bindViewModel()
        viewModel.viewDidLoad()
    }

    // 히어로 어두운 배경 위에서 status bar 텍스트를 흰색으로
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        setNeedsStatusBarAppearanceUpdate()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
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

        // topInset = safeAreaTop + navBar(56) + gap(17)
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

        // Blurred bg covers the full hero area: topInset + poster + progress bar area.
        let posterWidth = view.bounds.width - HomeCollectionViewLayoutFactory.heroBannerPosterSideMargin * 2
        let posterHeight = posterWidth * 1.43
        blurredBackgroundHeightConstraint.update(
            offset: heroBannerTopInset + posterHeight + HomeCollectionViewLayoutFactory.heroBannerProgressAreaHeight
        )
    }

    // MARK: - Collection View

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
        // Disable automatic content inset adjustment so the hero section reaches
        // behind the status bar from the very top of the screen.
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
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    // MARK: - Custom Top Header
    // Floats above the collection view, stays visible over the blurred hero background.
    // Height = navBarHeight (56pt): 11.5pt top + 33pt content + 11.5pt bottom.

    private func setupTopHeader() {
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

    // MARK: - Data Source

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

    // MARK: - Snapshot

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
        // CIAffineClamp extends edge pixels infinitely before blurring,
        // preventing the dark-fade artifact that CIGaussianBlur creates at image boundaries.
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

    // MARK: - Actions

    @objc private func nowTapped() {
        nowButton.setTitleColor(.white, for: .normal)
        myButton.setTitleColor(UIColor.white.withAlphaComponent(0.55), for: .normal)
    }

    @objc private func myTapped() {
        myButton.setTitleColor(.white, for: .normal)
        nowButton.setTitleColor(UIColor.white.withAlphaComponent(0.55), for: .normal)
    }

    @objc private func searchTapped() { /* TODO: push SearchViewController */ }

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

// MARK: - UICollectionViewDelegate (scroll sync)

extension HomeViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        // Clamp to 0: background must not be pushed below y=0 (would expose dark gap behind status bar).
        let bgOffsetY = max(offsetY, 0)
        blurredBackgroundImageView.transform = CGAffineTransform(translationX: 0, y: -bgOffsetY)
        topHeaderView.transform = CGAffineTransform(translationX: 0, y: -offsetY)
    }
}
