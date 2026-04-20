import UIKit
import SnapKit

final class ArtistViewController: UIViewController {

    private let viewModel: ArtistViewModel

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
        return b
    }()

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<ArtistSection, ArtistSectionItem>!

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
            $0.trailing.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(28)
        }

        // border-b 적용
        let border = UIView()
        border.backgroundColor = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1)
        topHeaderView.addSubview(border)
        border.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }
    }

    private func setupCollectionView() {
        let layout = ArtistCollectionViewLayoutFactory.makeLayout()
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
            cell.configure(year: year, month: month, events: viewModel.state.calendarEvents)
            cell.onMonthChanged = { [weak self] delta in self?.viewModel.changeMonth(by: delta) }
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

        guard let section = ArtistSection(rawValue: indexPath.section) else { return header }
        switch section {
        case .myArtists:          header.configure(title: "내 아티스트", accessory: .none)
        case .popularArtists:     header.configure(title: "인기 아티스트", accessory: .none)
        case .calendar:           header.configure(title: "공연 캘린더", accessory: .none)
        case .recommendedArtists: header.configure(title: "당신이 좋아할 만한 아티스트", accessory: .none)
        }
        return header
    }

    // MARK: - Bind

    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] in
            self?.applySnapshot()
        }
    }

    private func applySnapshot() {
        let state = viewModel.state
        var snapshot = NSDiffableDataSourceSnapshot<ArtistSection, ArtistSectionItem>()
        snapshot.appendSections(ArtistSection.allCases)

        snapshot.appendItems(state.myArtists.map { .myArtist($0) }, toSection: .myArtists)
        snapshot.appendItems(state.popularArtists.map { .popularArtist($0) }, toSection: .popularArtists)
        snapshot.appendItems([.calendar(year: state.calendarYear, month: state.calendarMonth)], toSection: .calendar)
        snapshot.appendItems(state.recommendedArtists.map { .recommendedArtist($0) }, toSection: .recommendedArtists)

        dataSource.apply(snapshot, animatingDifferences: false)
    }
}
