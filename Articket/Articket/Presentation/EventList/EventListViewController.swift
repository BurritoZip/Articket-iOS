import UIKit
import SnapKit

final class EventListViewController: UIViewController {

    private let listTitle: String
    private let events: [Event]

    // 공연 상세 라우팅만 필요 → 프로토콜로 받아 Home/Profile/Artist 코디네이터 재사용
    weak var coordinator: ArtistDetailCoordinatorProtocol?

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

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "공연 정보가 없습니다"
        l.font = .systemFont(ofSize: 15, weight: .medium)
        l.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        l.textAlignment = .center
        l.isHidden = true
        return l
    }()

    // MARK: - Init

    init(title: String, events: [Event], coordinator: ArtistDetailCoordinatorProtocol?) {
        self.listTitle = title
        self.events = events
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupViews()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(EventListCell.self, forCellReuseIdentifier: EventListCell.reuseIdentifier)
        emptyLabel.isHidden = !events.isEmpty
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.contentInset.bottom = view.safeAreaInsets.bottom
    }

    // MARK: - Setup

    private func setupViews() {
        view.addSubview(statusBarCoverView)
        view.addSubview(topHeaderView)
        topHeaderView.addSubview(backButton)
        topHeaderView.addSubview(titleLabel)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)

        let border = UIView()
        border.backgroundColor = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1)
        topHeaderView.addSubview(border)

        statusBarCoverView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.top)
        }

        topHeaderView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(56)
        }

        backButton.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(44)
        }

        titleLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        border.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }

        tableView.snp.makeConstraints {
            $0.top.equalTo(topHeaderView.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        emptyLabel.snp.makeConstraints {
            $0.center.equalTo(tableView)
        }

        titleLabel.text = listTitle
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITableViewDataSource

extension EventListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        events.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: EventListCell.reuseIdentifier, for: indexPath) as! EventListCell
        cell.configure(with: events[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate

extension EventListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 96 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let event = events[indexPath.row]
        coordinator?.showConcertDetail(concertId: event.id, imageAssetName: event.posterUrl)
    }
}

// MARK: - EventListCell

private final class EventListCell: UITableViewCell {
    static let reuseIdentifier = "EventListCell"

    private let posterImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        iv.layer.cornerRadius = 4
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .bold)
        l.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        l.numberOfLines = 2
        return l
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        return l
    }()

    private let venueLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        l.lineBreakMode = .byTruncatingTail
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .white

        let textStack = UIStackView(arrangedSubviews: [titleLabel, dateLabel, venueLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        contentView.addSubview(posterImageView)
        contentView.addSubview(textStack)

        posterImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(72)
        }

        textStack.snp.makeConstraints {
            $0.leading.equalTo(posterImageView.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func prepareForReuse() {
        super.prepareForReuse()
        posterImageView.cancelImageLoad()
        posterImageView.image = nil
        titleLabel.text = nil
        dateLabel.text = nil
        venueLabel.text = nil
    }

    func configure(with event: Event) {
        titleLabel.text = event.title
        dateLabel.text = event.dateRangeString
        venueLabel.text = event.venueName
        posterImageView.loadImage(urlString: event.posterUrl)
    }
}
