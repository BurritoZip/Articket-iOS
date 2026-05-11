import UIKit
import SnapKit

final class SearchResultViewController: UIViewController {

    private let keyword: String
    private let repository: any EventRepositoryProtocol
    weak var coordinator: HomeCoordinator?

    private var events: [Event] = []

    // MARK: - UI

    private let statusBarCoverView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        return v
    }()

    private let topHeaderView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        return v
    }()

    private let backButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        b.tintColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1)
        return b
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18, weight: .bold)
        l.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        return l
    }()

    private let tableView: UITableView = {
        let tv = UITableView()
        tv.separatorStyle = .none
        tv.backgroundColor = .white
        tv.showsVerticalScrollIndicator = false
        return tv
    }()

    private let emptyView: UIView = {
        let v = UIView()
        v.isHidden = true
        return v
    }()

    private let emptyImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        iv.tintColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .medium)
        l.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        l.textAlignment = .center
        l.numberOfLines = 2
        return l
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let a = UIActivityIndicatorView(style: .medium)
        a.hidesWhenStopped = true
        return a
    }()

    // MARK: - Init

    init(keyword: String, repository: any EventRepositoryProtocol = SupabaseEventRepository(), coordinator: HomeCoordinator? = nil) {
        self.keyword = keyword
        self.repository = repository
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: false)
        titleLabel.text = "\"\(keyword)\" 검색 결과"
        setupLayout()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SearchResultCell.self, forCellReuseIdentifier: SearchResultCell.reuseId)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        fetchResults()
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(statusBarCoverView)
        view.addSubview(topHeaderView)
        topHeaderView.addSubview(backButton)
        topHeaderView.addSubview(titleLabel)
        view.addSubview(tableView)
        view.addSubview(emptyView)
        emptyView.addSubview(emptyImageView)
        emptyView.addSubview(emptyLabel)
        view.addSubview(loadingIndicator)

        statusBarCoverView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        topHeaderView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(52)
        }
        backButton.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(44)
        }
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(backButton.snp.trailing).offset(4)
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().inset(20)
        }
        tableView.snp.makeConstraints {
            $0.top.equalTo(topHeaderView.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        emptyView.snp.makeConstraints {
            $0.center.equalTo(tableView)
            $0.width.equalTo(240)
        }
        emptyImageView.snp.makeConstraints {
            $0.top.centerX.equalToSuperview()
            $0.size.equalTo(48)
        }
        emptyLabel.snp.makeConstraints {
            $0.top.equalTo(emptyImageView.snp.bottom).offset(16)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        loadingIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    // MARK: - Data

    private func fetchResults() {
        loadingIndicator.startAnimating()
        emptyView.isHidden = true
        Task {
            do {
                let result = try await repository.searchEvents(keyword: keyword)
                events = result
                tableView.reloadData()
                let hasResults = !result.isEmpty
                emptyView.isHidden = hasResults
                if !hasResults {
                    emptyLabel.text = "'\(keyword)'에 해당하는\n공연이 없습니다"
                }
            } catch {
                emptyView.isHidden = false
                emptyLabel.text = "검색 중 오류가 발생했습니다\n잠시 후 다시 시도해주세요"
            }
            loadingIndicator.stopAnimating()
        }
    }

    // MARK: - Actions

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITableViewDataSource

extension SearchResultViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        events.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultCell.reuseId, for: indexPath) as! SearchResultCell
        cell.configure(with: events[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate

extension SearchResultViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let event = events[indexPath.row]
        coordinator?.showConcertDetail(concertId: event.id)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        88
    }
}

// MARK: - Cell

private final class SearchResultCell: UITableViewCell {

    static let reuseId = "SearchResultCell"

    private let posterView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor = UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1)
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.textColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1)
        l.numberOfLines = 2
        return l
    }()

    private let venueLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        return l
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .white
        selectionStyle = .none

        contentView.addSubview(posterView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(venueLabel)
        contentView.addSubview(dateLabel)

        posterView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(56)
            $0.height.equalTo(64)
        }
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(posterView).offset(4)
            $0.leading.equalTo(posterView.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().inset(20)
        }
        venueLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.leading.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(20)
        }
        dateLabel.snp.makeConstraints {
            $0.top.equalTo(venueLabel.snp.bottom).offset(2)
            $0.leading.equalTo(titleLabel)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with event: Event) {
        titleLabel.text = event.title
        venueLabel.text = event.venueName

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy.MM.dd"
        let start = fmt.string(from: event.startDate)
        if let end = event.endDate, end != event.startDate {
            dateLabel.text = "\(start) ~ \(fmt.string(from: end))"
        } else {
            dateLabel.text = start
        }

        if let url = event.posterUrl {
            posterView.loadImage(from: url)
        } else {
            posterView.image = nil
        }
    }
}
