import UIKit
import SnapKit

final class ArtistViewController: UIViewController {

    private let viewModel: ArtistViewModel

    /// 블록 기반 알림 옵저버 토큰 — deinit에서 해제해 좀비 옵저버·중복 구독을 막는다 (Profile과 동일 패턴)
    private var notificationTokens: [NSObjectProtocol] = []
    weak var coordinator: ArtistCoordinator?

    // MARK: - Views

    private let statusBarCoverView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        return v
    }()

    private let topHeaderView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.borderColor = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1).cgColor
        v.layer.borderWidth = 0
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "My Artists"
        l.font = .systemFont(ofSize: 20, weight: .bold)
        l.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        return l
    }()

    private let searchButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        b.tintColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1)
        b.accessibilityLabel = "검색"
        return b
    }()

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<ArtistSection, ArtistSectionItem>!
    private let artistSkeletonView = ArtistSkeletonView()

    // MARK: - Init

    init(viewModel: ArtistViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupViews()
        setupCollectionView()
        configureDataSource()
        bindViewModel()
        viewModel.viewDidLoad()
        collectionView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (navigationController?.parent as? MainTabBarController)?.setTabBarHidden(false, animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.contentInset.bottom = view.safeAreaInsets.bottom
    }

    // MARK: - Setup

    private func setupViews() {
        view.addSubview(statusBarCoverView)
        view.addSubview(topHeaderView)
        topHeaderView.addSubview(titleLabel)
        topHeaderView.addSubview(searchButton)

        statusBarCoverView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        topHeaderView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(56)
        }
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
        }
        searchButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(44)
        }

        // border-b 적용
        let border = UIView()
        border.backgroundColor = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1)
        topHeaderView.addSubview(border)
        border.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }

        searchButton.addTarget(self, action: #selector(searchTapped), for: .touchUpInside)
    }

    private func setupCollectionView() {
        let layout = ArtistCollectionViewLayoutFactory.makeLayout { [weak self] index in
            self?.dataSource.sectionIdentifier(for: index)
        }
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.showsVerticalScrollIndicator = false

        collectionView.register(MyArtistCell.self, forCellWithReuseIdentifier: MyArtistCell.reuseIdentifier)
        collectionView.register(PopularArtistCell.self, forCellWithReuseIdentifier: PopularArtistCell.reuseIdentifier)
        collectionView.register(CalendarCell.self, forCellWithReuseIdentifier: CalendarCell.reuseIdentifier)
        collectionView.register(RecommendedArtistCell.self, forCellWithReuseIdentifier: RecommendedArtistCell.reuseIdentifier)
        collectionView.register(
            SectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SectionHeaderView.reuseIdentifier
        )

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints {
            $0.top.equalTo(topHeaderView.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        view.insertSubview(artistSkeletonView, belowSubview: topHeaderView)
        artistSkeletonView.snp.makeConstraints {
            $0.top.equalTo(topHeaderView.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<ArtistSection, ArtistSectionItem>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, item in
            self?.cell(for: item, at: indexPath, in: collectionView)
        }

        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            self?.headerView(for: indexPath, in: collectionView)
        }
    }

    private func cell(for item: ArtistSectionItem, at indexPath: IndexPath, in cv: UICollectionView) -> UICollectionViewCell {
        switch item {
        case .myArtist(let artist):
            let cell = cv.dequeueReusableCell(withReuseIdentifier: MyArtistCell.reuseIdentifier, for: indexPath) as! MyArtistCell
            cell.configure(with: artist)
            return cell

        case .popularArtist(let artist):
            let cell = cv.dequeueReusableCell(withReuseIdentifier: PopularArtistCell.reuseIdentifier, for: indexPath) as! PopularArtistCell
            cell.configure(with: artist)
            return cell

        case .calendar(let year, let month):
            let cell = cv.dequeueReusableCell(withReuseIdentifier: CalendarCell.reuseIdentifier, for: indexPath) as! CalendarCell
            cell.onMonthChanged = { [weak self] delta in self?.viewModel.changeMonth(by: delta) }
            cell.onDaySelected = { [weak self] _ in
                guard let self else { return }
                // 셀은 estimated 높이 self-sizing이라 더보기로 커졌다가 다른(짧은) 날을 고르면
                // performBatchUpdates(nil)만으로는 캐시된 큰 높이가 안 줄어 이전 날 내용과
                // 겹쳐 보인다. 레이아웃을 명시적으로 무효화해 높이를 매번 다시 측정하게 한다.
                self.collectionView.collectionViewLayout.invalidateLayout()
            }
            cell.configure(year: year, month: month, events: viewModel.state.calendarEvents)
            return cell

        case .recommendedArtist(let artist):
            let cell = cv.dequeueReusableCell(withReuseIdentifier: RecommendedArtistCell.reuseIdentifier, for: indexPath) as! RecommendedArtistCell
            cell.configure(with: artist)
            cell.onFollowTapped = { [weak self] id in self?.viewModel.toggleFollow(artistId: id) }
            return cell
        }
    }

    private func headerView(for indexPath: IndexPath, in cv: UICollectionView) -> UICollectionReusableView {
        let header = cv.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SectionHeaderView.reuseIdentifier,
            for: indexPath
        ) as! SectionHeaderView

        guard let section = dataSource.sectionIdentifier(for: indexPath.section) else { return header }
        switch section {
        case .myArtists:
            break
        case .popularArtists:
            header.configure(
                title: "인기 아티스트",
                accessory: .none,
                icon: UIImage(named: "ic_popular_artist")?.withRenderingMode(.alwaysTemplate)
            )
        case .calendar:
            header.configure(
                title: "공연 캘린더",
                accessory: .none,
                icon: UIImage(named: "ic_callender")?.withRenderingMode(.alwaysTemplate)
            )
        case .recommendedArtists:
            header.configure(
                title: "당신이 좋아할 만한 아티스트",
                accessory: .none,
                icon: UIImage(named: "ic_like_artist")?.withRenderingMode(.alwaysTemplate),
                fontSize: 18
            )
        }
        return header
    }

    // MARK: - Bind

    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] in
            guard let self else { return }
            if !viewModel.state.isLoading && !artistSkeletonView.isHidden {
                UIView.animate(withDuration: 0.25) {
                    self.artistSkeletonView.alpha = 0
                } completion: { _ in
                    self.artistSkeletonView.isHidden = true
                    self.artistSkeletonView.stopShimmer()
                }
            }
            self.applySnapshot()
        }
        viewModel.onError = { [weak self] message in
            self?.showErrorAlert(message, retry: { self?.viewModel.viewDidLoad() })
        }
        viewModel.onLoginRequired = { [weak self] retry in
            self?.showLoginPrompt(then: retry)
        }
        viewModel.onFollowToggled = { [weak self] isFollowing in
            Haptics.impact()
            let message = isFollowing ? "팔로우했어요" : "팔로우를 취소했어요"
            self?.showToast(message, type: isFollowing ? .success : .info)
        }
        notificationTokens.append(NotificationCenter.default.addObserver(
            forName: .artistFollowDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.viewModel.refreshFollowStates()
        })
    }

    deinit {
        notificationTokens.forEach { NotificationCenter.default.removeObserver($0) }
    }

    // showLoginPrompt(then:)은 UIViewController+ErrorAlert.swift의 공용 extension 사용

    // MARK: - Actions

    @objc private func searchTapped() {
        coordinator?.showSearch()
    }

    private func applySnapshot() {
        let state = viewModel.state
        var snapshot = NSDiffableDataSourceSnapshot<ArtistSection, ArtistSectionItem>()

        // 빈 섹션은 헤더만 덩그러니 남으므로 제외 (비로그인 = 추천/내 아티스트 없음 → 인기만)
        if !state.myArtists.isEmpty {
            snapshot.appendSections([.myArtists])
            snapshot.appendItems(state.myArtists.map { .myArtist($0) }, toSection: .myArtists)
        }
        if !state.popularArtists.isEmpty {
            snapshot.appendSections([.popularArtists])
            snapshot.appendItems(state.popularArtists.map { .popularArtist($0) }, toSection: .popularArtists)
        }
        snapshot.appendSections([.calendar])
        snapshot.appendItems([.calendar(year: state.calendarYear, month: state.calendarMonth)], toSection: .calendar)
        if !state.recommendedArtists.isEmpty {
            snapshot.appendSections([.recommendedArtists])
            // 하단 추천 아티스트 리스트는 최대 3명만 노출
            snapshot.appendItems(state.recommendedArtists.prefix(3).map { .recommendedArtist($0) }, toSection: .recommendedArtists)
        }

        dataSource.apply(snapshot, animatingDifferences: !viewModel.state.isLoading) { [weak self] in
            guard let self else { return }
            // reconfigure 는 또 한 번 apply 를 호출한다. apply 완료 콜백 안에서 바로 부르면
            // diffable 이 아직 apply 큐를 벗어나기 전이라 재진입 apply 로 크래시
            // (BUG_IN_CLIENT_OF_DIFFABLE_DATA_SOURCE...REENTRANTLY). 다음 런루프로 미뤄 재진입 차단.
            DispatchQueue.main.async {
                // 캘린더 아이템 식별자는 .calendar(year, month) 라 이벤트만 바뀌면 diffable 이
                // "변경 없음"으로 보고 셀을 재구성하지 않는다 → 비동기로 로드된 이벤트가 반영 안 됨.
                // 이벤트 로드/변경 후 캘린더 아이템을 명시적으로 reconfigure 해 셀을 갱신한다.
                self.reconfigureCalendarItem()
                // 캘린더 셀은 .estimated 자체 크기라 월/이벤트가 바뀌면 높이 재측정이 필요하다.
                self.collectionView.performBatchUpdates(nil)
            }
        }
    }

    // 캘린더에 실제 반영된 (연/월/이벤트) 서명 — 변경 시에만 reconfigure 해
    // 불필요한 셀 재구성(날짜 선택 초기화)을 피한다.
    private var lastCalendarSignature: Int?

    private func reconfigureCalendarItem() {
        let state = viewModel.state
        var hasher = Hasher()
        hasher.combine(state.calendarYear)
        hasher.combine(state.calendarMonth)
        hasher.combine(state.calendarEvents)
        let signature = hasher.finalize()
        guard signature != lastCalendarSignature else { return }

        var snapshot = dataSource.snapshot()
        let item = ArtistSectionItem.calendar(year: state.calendarYear, month: state.calendarMonth)
        guard snapshot.indexOfItem(item) != nil else { return }
        lastCalendarSignature = signature
        snapshot.reconfigureItems([item])
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - UICollectionViewDelegate

extension ArtistViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .myArtist(let artist), .recommendedArtist(let artist):
            coordinator?.showArtistDetail(artistId: artist.id)
        case .popularArtist(let artist):
            coordinator?.showArtistDetail(artistId: artist.id)
        default:
            break
        }
    }
}
