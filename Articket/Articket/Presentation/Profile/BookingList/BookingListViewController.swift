import UIKit
import SnapKit

final class BookingListViewController: UIViewController {

    weak var coordinator: ProfileCoordinator?
    private let viewModel: BookingListViewModel

    // MARK: - Views

    private let navigationBar = SimpleNavigationBar(title: "예매내역")

    private let segmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: BookingListViewModel.Tab.allCases.map { $0.title })
        sc.selectedSegmentIndex = 0
        sc.backgroundColor = UIColor(hex: "#F3F4F6")
        sc.selectedSegmentTintColor = .white
        return sc
    }()

    private let tableView: UITableView = {
        let tv = UITableView()
        tv.separatorStyle = .none
        tv.backgroundColor = UIColor(hex: "#F9FAFB")
        tv.register(BookingCell.self, forCellReuseIdentifier: BookingCell.reuseId)
        return tv
    }()

    private let emptyStateView = EmptyStateView()

    private let loadingIndicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.hidesWhenStopped = true
        v.color = UIColor(hex: "#6B7280")
        return v
    }()

    // MARK: - Init

    init(viewModel: BookingListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

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

    // MARK: - Setup

    private func setupLayout() {
        [navigationBar, segmentedControl, tableView, emptyStateView, loadingIndicator].forEach { view.addSubview($0) }

        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(44)
        }
        navigationBar.onBackTapped = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }

        segmentedControl.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(36)
        }

        tableView.snp.makeConstraints {
            $0.top.equalTo(segmentedControl.snp.bottom).offset(12)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        emptyStateView.snp.makeConstraints {
            $0.center.equalTo(tableView)
            $0.leading.trailing.equalToSuperview().inset(40)
        }

        loadingIndicator.snp.makeConstraints {
            $0.center.equalTo(tableView)
        }

        segmentedControl.addTarget(self, action: #selector(tabChanged), for: .valueChanged)
        segmentedControl.selectedSegmentIndex = viewModel.state.selectedTab.rawValue

        tableView.dataSource = self
        tableView.delegate = self
    }

    // MARK: - Bind

    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] in self?.render() }
        viewModel.onError = { [weak self] msg in
            self?.showErrorAlert(msg, retry: { self?.viewModel.viewDidLoad() })
        }
    }

    private func render() {
        let state = viewModel.state
        let bookings = viewModel.currentBookings

        if state.isLoading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }

        let isEmpty = bookings.isEmpty && !state.isLoading
        emptyStateView.isHidden = !isEmpty
        if isEmpty {
            let isActive = state.selectedTab == .active
            emptyStateView.configure(
                icon: UIImage(systemName: "ticket"),
                title: isActive ? "예매한 공연이 없습니다" : "취소한 예매가 없습니다",
                subtitle: isActive ? "공연을 예매하고 내역을 확인해보세요" : nil
            )
        }

        tableView.reloadData()
    }

    @objc private func tabChanged() {
        let tab = BookingListViewModel.Tab(rawValue: segmentedControl.selectedSegmentIndex) ?? .active
        viewModel.selectTab(tab)
    }
}

// MARK: - UITableViewDataSource

extension BookingListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.currentBookings.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BookingCell.reuseId, for: indexPath) as! BookingCell
        cell.configure(with: viewModel.currentBookings[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate

extension BookingListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 100 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let booking = viewModel.currentBookings[indexPath.row]
        coordinator?.showConcertDetail(concertId: booking.eventId, imageAssetName: booking.imageAssetName)
    }
}

// MARK: - BookingCell

private final class BookingCell: UITableViewCell {

    static let reuseId = "BookingCell"

    private let posterView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor = UIColor(hex: "#E5E7EB")
        return iv
    }()

    private let dDayLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .bold)
        l.textColor = UIColor(hex: "#121212")
        l.backgroundColor = UIColor(hex: "#F3F4F6")
        l.layer.cornerRadius = 4
        l.clipsToBounds = true
        l.textAlignment = .center
        return l
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.textColor = UIColor(hex: "#121212")
        l.numberOfLines = 2
        return l
    }()

    private let venueLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = UIColor(hex: "#767676")
        return l
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = UIColor(hex: "#767676")
        return l
    }()

    private let seatLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11)
        l.textColor = UIColor(hex: "#999999")
        return l
    }()

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 12
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        setupLayout()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupLayout() {
        contentView.addSubview(cardView)
        cardView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(6)
            $0.bottom.equalToSuperview().inset(6)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        let infoStack = UIStackView(arrangedSubviews: [dDayLabel, titleLabel, venueLabel, dateLabel, seatLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 2
        infoStack.alignment = .leading

        [posterView, infoStack].forEach { cardView.addSubview($0) }

        posterView.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview().inset(12)
            $0.width.equalTo(56)
        }
        dDayLabel.snp.makeConstraints { $0.width.greaterThanOrEqualTo(36); $0.height.equalTo(18) }

        infoStack.snp.makeConstraints {
            $0.leading.equalTo(posterView.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
        }
    }

    func configure(with booking: Booking) {
        posterView.loadImage(urlString: booking.imageAssetName)
        dDayLabel.text = " \(booking.dDayString) "
        titleLabel.text = booking.title
        venueLabel.text = booking.venueName
        dateLabel.text = booking.formattedDate
        seatLabel.text = booking.seat
        dDayLabel.isHidden = booking.status == .cancelled
    }
}
