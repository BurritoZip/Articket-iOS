import UIKit
import SnapKit

final class TimetableListViewController: UIViewController {

    private let viewModel: TimetableListViewModel
    weak var coordinator: HomeCoordinator?

    // MARK: - UI

    private let sectionTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "공연 선택하기"
        l.font = .scaled(20, weight: .bold, textStyle: .title3)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(hex: "#333333")
        return l
    }()

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        cv.backgroundColor = .white
        cv.showsVerticalScrollIndicator = false
        cv.register(TimetableEventCell.self, forCellWithReuseIdentifier: TimetableEventCell.reuseIdentifier)
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    private let emptyStateView: UIView = {
        let v = UIView()
        v.isHidden = true
        return v
    }()

    private let emptyIconImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "calendar.badge.minus")
        iv.tintColor = UIColor(hex: "#CCCCCC")
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "아직 등록된 타임테이블이 없어요"
        l.font = .scaled(16, weight: .medium, textStyle: .headline)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(hex: "#999999")
        l.textAlignment = .center
        return l
    }()

    private let emptySubLabel: UILabel = {
        let l = UILabel()
        l.font = .scaled(13, weight: .regular, textStyle: .footnote)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(hex: "#CCCCCC")
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    /// 로드 실패 시에만 노출하는 재시도 버튼(빈 상태에선 숨김)
    private let retryButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("다시 시도", for: .normal)
        b.setTitleColor(UIColor(hex: "#374151"), for: .normal)
        b.titleLabel?.font = .scaled(14, weight: .medium, textStyle: .subheadline)
        b.titleLabel?.adjustsFontForContentSizeCategory = true
        b.backgroundColor = UIColor(hex: "#F3F4F6")
        b.layer.cornerRadius = 8
        b.contentEdgeInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20)
        b.isHidden = true
        return b
    }()

    // MARK: - Init

    init(viewModel: TimetableListViewModel, coordinator: HomeCoordinator?) {
        self.viewModel = viewModel
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationItem.title = "타임테이블"
        setupUI()
        bindViewModel()
        viewModel.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
        (navigationController?.parent as? MainTabBarController)?.setTabBarHidden(true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            (navigationController?.parent as? MainTabBarController)?.setTabBarHidden(false)
        }
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        collectionView.contentInset.bottom = view.safeAreaInsets.bottom
        collectionView.verticalScrollIndicatorInsets.bottom = view.safeAreaInsets.bottom
    }

    // MARK: - Setup

    private func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = nil
        appearance.titleTextAttributes = [
            .font: UIFont.scaled(16, weight: .bold, textStyle: .headline),
            .foregroundColor: UIColor(hex: "#121212")
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = UIColor(hex: "#121212")
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    private func setupUI() {
        view.addSubview(sectionTitleLabel)
        view.addSubview(collectionView)
        view.addSubview(emptyStateView)
        emptyStateView.addSubview(emptyIconImageView)
        emptyStateView.addSubview(emptyLabel)
        emptyStateView.addSubview(emptySubLabel)
        emptyStateView.addSubview(retryButton)
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)

        sectionTitleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            $0.leading.equalToSuperview().offset(24)
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(sectionTitleLabel.snp.bottom).offset(20)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        emptyStateView.snp.makeConstraints {
            $0.top.equalTo(sectionTitleLabel.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        emptyIconImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-24)
            $0.size.equalTo(56)
        }

        emptyLabel.snp.makeConstraints {
            $0.top.equalTo(emptyIconImageView.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
        }

        emptySubLabel.snp.makeConstraints {
            $0.top.equalTo(emptyLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview().offset(40)
            $0.trailing.equalToSuperview().inset(40)
        }

        retryButton.snp.makeConstraints {
            $0.top.equalTo(emptySubLabel.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
        }
    }

    @objc private func retryTapped() {
        viewModel.viewDidLoad()
    }

    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] in
            guard let self else { return }
            let isEmpty = self.viewModel.state.events.isEmpty && !self.viewModel.state.isLoading
            self.collectionView.isHidden = isEmpty
            self.sectionTitleLabel.isHidden = isEmpty
            self.emptyStateView.isHidden = !isEmpty
            if let errorMsg = self.viewModel.state.errorMessage {
                self.emptyLabel.text = "데이터를 불러오지 못했어요"
                self.emptySubLabel.text = errorMsg
                self.retryButton.isHidden = false
            } else {
                self.emptyLabel.text = "아직 등록된 타임테이블이 없어요"
                self.emptySubLabel.text = nil
                self.retryButton.isHidden = true
            }
            self.collectionView.reloadData()
        }
    }

    private func makeLayout() -> UICollectionViewLayout {
        let screenWidth = UIScreen.main.bounds.width
        let itemWidth = (screenWidth - 48 - 12) / 2

        let item = NSCollectionLayoutItem(
            layoutSize: .init(widthDimension: .absolute(itemWidth), heightDimension: .estimated(310))
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(310)),
            subitems: [item, item]
        )
        group.interItemSpacing = .fixed(12)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 17
        section.contentInsets = .init(top: 0, leading: 24, bottom: 32, trailing: 24)

        return UICollectionViewCompositionalLayout(section: section)
    }
}

// MARK: - UICollectionViewDataSource

extension TimetableListViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.state.events.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TimetableEventCell.reuseIdentifier,
            for: indexPath
        ) as! TimetableEventCell
        cell.configure(with: viewModel.state.events[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension TimetableListViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let event = viewModel.state.events[indexPath.item]
        coordinator?.showTimetableDetail(event: event)
    }
}
