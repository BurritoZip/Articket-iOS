import UIKit
import SnapKit

final class ReviewsViewController: UIViewController {

    weak var coordinator: ProfileCoordinator?
    private let viewModel: ReviewsViewModel

    private let navigationBar = SimpleNavigationBar(title: "나의 후기")

    private let tableView: UITableView = {
        let tv = UITableView()
        tv.separatorStyle = .none
        tv.backgroundColor = UIColor(hex: "#F9FAFB")
        tv.register(ReviewCell.self, forCellReuseIdentifier: ReviewCell.reuseId)
        return tv
    }()

    private let emptyStateView = EmptyStateView()

    // 로딩은 스피너 대신 리스트 스켈레톤(프로젝트 관례)
    private let skeletonView = ListSkeletonView()

    init(viewModel: ReviewsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#F9FAFB")
        setupLayout()
        bindViewModel()
        viewModel.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func setupLayout() {
        [navigationBar, tableView, emptyStateView, skeletonView].forEach { view.addSubview($0) }

        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(44)
        }
        navigationBar.onBackTapped = { [weak self] in
            self?.dismissOrPop()
        }

        tableView.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        emptyStateView.snp.makeConstraints {
            $0.center.equalTo(tableView)
            $0.leading.trailing.equalToSuperview().inset(40)
        }
        skeletonView.snp.makeConstraints { $0.edges.equalTo(tableView) }

        tableView.dataSource = self
    }

    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] in self?.render() }
        viewModel.onError = { [weak self] msg in
            self?.showErrorAlert(msg, retry: { self?.viewModel.viewDidLoad() })
        }
    }

    private func render() {
        let state = viewModel.state

        if state.isLoading {
            skeletonView.isHidden = false
        } else {
            skeletonView.isHidden = true
            skeletonView.stopShimmer()
        }

        let isEmpty = state.reviews.isEmpty && !state.isLoading
        emptyStateView.isHidden = !isEmpty
        if isEmpty {
            emptyStateView.configure(
                icon: UIImage(systemName: "star"),
                title: "작성한 후기가 없어요",
                subtitle: "관람한 공연의 후기를 남겨보세요"
            )
        }

        tableView.reloadData()
    }
}

extension ReviewsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.state.reviews.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ReviewCell.reuseId, for: indexPath) as! ReviewCell
        cell.configure(with: viewModel.state.reviews[indexPath.row])
        return cell
    }
}

// MARK: - ReviewCell

private final class ReviewCell: UITableViewCell {

    static let reuseId = "ReviewCell"

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 12
        return v
    }()

    private let posterView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 6
        iv.backgroundColor = UIColor(hex: "#E5E7EB")
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .scaled(14, weight: .semibold, textStyle: .subheadline)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(hex: "#121212")
        l.numberOfLines = 2
        return l
    }()

    private let starsLabel: UILabel = {
        let l = UILabel()
        l.font = .scaled(13, textStyle: .footnote)
        l.adjustsFontForContentSizeCategory = true
        return l
    }()

    private let contentLabel: UILabel = {
        let l = UILabel()
        l.font = .scaled(13, textStyle: .footnote)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(hex: "#555555")
        l.numberOfLines = 3
        return l
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .scaled(11, textStyle: .caption1)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(hex: "#AAAAAA")
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(cardView)
        cardView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(6)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        let infoStack = UIStackView(arrangedSubviews: [titleLabel, starsLabel, contentLabel, dateLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 4

        [posterView, infoStack].forEach { cardView.addSubview($0) }

        posterView.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview().inset(12)
            $0.width.equalTo(56)
        }
        infoStack.snp.makeConstraints {
            $0.leading.equalTo(posterView.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().inset(12)
            $0.top.equalToSuperview().offset(12)
            $0.bottom.lessThanOrEqualToSuperview().inset(12)
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with review: ConcertReview) {
        posterView.loadImage(urlString: review.eventPosterUrl)
        titleLabel.text = "[\(review.eventTitle)] \(review.title)"
        starsLabel.text = String(repeating: "★", count: review.starCount) + String(repeating: "☆", count: 5 - review.starCount)
        starsLabel.textColor = UIColor(hex: "#FFCC00")
        contentLabel.text = review.content
        dateLabel.text = "\(review.formattedDate)  \(review.username)"
    }
}
