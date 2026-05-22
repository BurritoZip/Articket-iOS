import UIKit
import SnapKit

final class MyReviewsViewController: UIViewController {

    weak var coordinator: MyCoordinator?
    private let viewModel: MyReviewsViewModel

    private let navigationBar = SimpleNavigationBar(title: "나의 후기")

    private let tableView: UITableView = {
        let tv = UITableView()
        tv.separatorStyle = .none
        tv.backgroundColor = UIColor(hex: "#F9FAFB")
        tv.register(ReviewCell.self, forCellReuseIdentifier: ReviewCell.reuseId)
        return tv
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "작성한 후기가 없습니다."
        l.font = .systemFont(ofSize: 15)
        l.textColor = UIColor(hex: "#999999")
        l.textAlignment = .center
        return l
    }()

    init(viewModel: MyReviewsViewModel) {
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
        [navigationBar, tableView, emptyLabel].forEach { view.addSubview($0) }

        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(44)
        }
        navigationBar.onBackTapped = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }

        tableView.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        emptyLabel.snp.makeConstraints { $0.center.equalTo(tableView) }

        tableView.dataSource = self
    }

    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] in self?.render() }
        viewModel.onError = { [weak self] msg in
            let alert = UIAlertController(title: "오류", message: msg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            self?.present(alert, animated: true)
        }
    }

    private func render() {
        emptyLabel.isHidden = !viewModel.state.reviews.isEmpty
        tableView.reloadData()
    }
}

extension MyReviewsViewController: UITableViewDataSource {
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
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.textColor = UIColor(hex: "#121212")
        l.numberOfLines = 2
        return l
    }()

    private let starsLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        return l
    }()

    private let contentLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = UIColor(hex: "#555555")
        l.numberOfLines = 3
        return l
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11)
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
