import UIKit
import SnapKit

final class SearchResultViewController: UIViewController {

    private enum Scope: Int { case event = 0, artist = 1 }

    private let keyword: String
    private let repository: any EventRepositoryProtocol
    private let artistRepository: any ArtistRepositoryProtocol
    weak var coordinator: (any SearchCoordinatorProtocol)?

    private var events: [Event] = []
    private var artists: [Artist] = []
    private var scope: Scope = .event
    private var didLoadArtists = false

    // MARK: - UI

    private let navigationBar = SimpleNavigationBar(title: "")

    private let scopeControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["공연", "아티스트"])
        sc.selectedSegmentIndex = 0
        return sc
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

    /// 검색 실패(네트워크 등) 시에만 노출하는 재시도 버튼. 결과 없음 상태에선 숨긴다.
    private let retryButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("다시 시도", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        b.backgroundColor = UIColor(hex: "#121212")
        b.layer.cornerRadius = 10
        b.contentEdgeInsets = UIEdgeInsets(top: 10, left: 24, bottom: 10, right: 24)
        b.isHidden = true
        return b
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let a = UIActivityIndicatorView(style: .medium)
        a.hidesWhenStopped = true
        return a
    }()

    // MARK: - Init

    init(keyword: String,
         coordinator: (any SearchCoordinatorProtocol)? = nil,
         repository: any EventRepositoryProtocol = SupabaseEventRepository(),
         artistRepository: any ArtistRepositoryProtocol = SupabaseArtistRepository()) {
        self.keyword = keyword
        self.repository = repository
        self.artistRepository = artistRepository
        super.init(nibName: nil, bundle: nil)
        self.coordinator = coordinator
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationBar.setTitle("\"\(keyword)\" 검색 결과")
        setupLayout()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SearchResultCell.self, forCellReuseIdentifier: SearchResultCell.reuseId)
        tableView.register(ArtistResultCell.self, forCellReuseIdentifier: ArtistResultCell.reuseId)
        scopeControl.addTarget(self, action: #selector(scopeChanged), for: .valueChanged)
        fetchResults()
    }

    @objc private func scopeChanged() {
        scope = Scope(rawValue: scopeControl.selectedSegmentIndex) ?? .event
        switch scope {
        case .event:
            tableView.reloadData()
            updateEmptyState()
        case .artist:
            if didLoadArtists {
                tableView.reloadData()
                updateEmptyState()
            } else {
                fetchArtists()
            }
        }
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(navigationBar)
        view.addSubview(scopeControl)
        view.addSubview(tableView)
        view.addSubview(emptyView)
        // 이미지·문구·재시도를 세로 스택으로 묶어, 재시도 버튼 숨김 시 빈 공간 없이 collapse
        let emptyStack = UIStackView(arrangedSubviews: [emptyImageView, emptyLabel, retryButton])
        emptyStack.axis = .vertical
        emptyStack.alignment = .center
        emptyStack.spacing = 16
        emptyView.addSubview(emptyStack)
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        view.addSubview(loadingIndicator)

        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(44)
        }
        navigationBar.onBackTapped = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        scopeControl.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        tableView.snp.makeConstraints {
            $0.top.equalTo(scopeControl.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        emptyView.snp.makeConstraints {
            $0.center.equalTo(tableView)
            $0.width.equalTo(240)
        }
        emptyStack.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        emptyImageView.snp.makeConstraints {
            $0.size.equalTo(48)
        }
        emptyLabel.snp.makeConstraints {
            $0.width.equalTo(emptyView)
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
                events = EventSeriesGrouping.group(try await repository.searchEvents(keyword: keyword))
                if scope == .event { tableView.reloadData() }
                updateEmptyState()
            } catch {
                showSearchError()
            }
            loadingIndicator.stopAnimating()
        }
    }

    private func fetchArtists() {
        loadingIndicator.startAnimating()
        emptyView.isHidden = true
        Task {
            do {
                artists = try await artistRepository.searchArtists(keyword: keyword)
                didLoadArtists = true
                if scope == .artist { tableView.reloadData() }
                updateEmptyState()
            } catch {
                showSearchError()
            }
            loadingIndicator.stopAnimating()
        }
    }

    /// 현재 선택된 탭 기준 빈 상태 표시
    private func updateEmptyState() {
        let isEmpty: Bool
        switch scope {
        case .event:  isEmpty = events.isEmpty
        case .artist: isEmpty = didLoadArtists && artists.isEmpty
        }
        emptyView.isHidden = !isEmpty
        if isEmpty {
            // 결과 없음: 재시도 버튼 숨김. "아티스트이/공연이" 조사 오류를 피하려 조사 의존 없는 문구 사용.
            retryButton.isHidden = true
            emptyImageView.isHidden = false
            emptyLabel.text = "'\(keyword)' 검색 결과가 없어요\n다른 키워드로 찾아보세요"
        }
    }

    /// 검색 실패(네트워크 등) 공통 처리 — 재시도 버튼과 함께 노출
    private func showSearchError() {
        emptyView.isHidden = false
        emptyImageView.isHidden = false
        emptyLabel.text = "검색이 원활하지 않아요\n잠시 후 다시 시도해 주세요"
        retryButton.isHidden = false
    }

    @objc private func retryTapped() {
        retryButton.isHidden = true
        emptyView.isHidden = true
        switch scope {
        case .event:  fetchResults()
        case .artist: fetchArtists()
        }
    }

}

// MARK: - UITableViewDataSource

extension SearchResultViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        scope == .event ? events.count : artists.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch scope {
        case .event:
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultCell.reuseId, for: indexPath) as! SearchResultCell
            cell.configure(with: events[indexPath.row])
            return cell
        case .artist:
            let cell = tableView.dequeueReusableCell(withIdentifier: ArtistResultCell.reuseId, for: indexPath) as! ArtistResultCell
            cell.configure(with: artists[indexPath.row])
            return cell
        }
    }
}

// MARK: - UITableViewDelegate

extension SearchResultViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch scope {
        case .event:
            let event = events[indexPath.row]
            coordinator?.showConcertDetail(concertId: event.id, imageAssetName: event.posterUrl)
        case .artist:
            let artist = artists[indexPath.row]
            coordinator?.showArtistDetail(artistId: artist.id)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        scope == .event ? 88 : 72
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

        if let badge = event.sessionBadge {
            dateLabel.text = "\(badge)  \(event.sessionDatesSummary)"
        } else {
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy.MM.dd"
            let start = fmt.string(from: event.startDate)
            if let end = event.endDate, end != event.startDate {
                dateLabel.text = "\(start) ~ \(fmt.string(from: end))"
            } else {
                dateLabel.text = start
            }
        }

        if let url = event.posterUrl {
            posterView.loadImage(urlString: url)
        } else {
            posterView.image = nil
        }
    }
}

// MARK: - Artist Cell

private final class ArtistResultCell: UITableViewCell {

    static let reuseId = "ArtistResultCell"

    private let avatarView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 24
        iv.backgroundColor = UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1)
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.textColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1)
        return l
    }()

    private let followersLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .white
        selectionStyle = .none

        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(followersLabel)

        avatarView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(48)
        }
        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(avatarView.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(avatarView.snp.centerY).offset(-1)
        }
        followersLabel.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.top.equalTo(avatarView.snp.centerY).offset(3)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with artist: Artist) {
        nameLabel.text = artist.name
        followersLabel.text = "팔로워 \(artist.followersCount.formatted())"
        if let url = artist.avatarUrl {
            avatarView.loadImage(urlString: url)
        } else {
            avatarView.image = nil
        }
    }
}
