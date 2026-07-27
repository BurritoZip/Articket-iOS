import UIKit
import SnapKit

final class TimetableDetailViewController: UIViewController {

    private let viewModel: TimetableDetailViewModel
    weak var coordinator: HomeCoordinator?

    // MARK: - UI

    private let venueLabel: UILabel = {
        let l = UILabel()
        l.font = .scaled(12, weight: .regular, textStyle: .caption1)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(hex: "#767676")
        return l
    }()

    private let concertTitleLabel: UILabel = {
        let l = UILabel()
        l.font = .scaled(14, weight: .semibold, textStyle: .subheadline)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(hex: "#121212")
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        return l
    }()

    private let dayTabScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.bounces = false
        return sv
    }()

    private let dayTabStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 12
        sv.alignment = .fill
        return sv
    }()

    private let tableView: UITableView = {
        let tv = UITableView()
        tv.separatorStyle = .singleLine
        tv.separatorColor = UIColor(hex: "#E5E7EB")
        tv.separatorInset = .zero
        tv.backgroundColor = .white
        tv.showsVerticalScrollIndicator = false
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 72
        return tv
    }()

    private let makeButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("내 타임테이블 만들기", for: .normal)
        b.titleLabel?.font = .scaled(16, weight: .bold, textStyle: .headline)
        b.titleLabel?.adjustsFontForContentSizeCategory = true
        b.setTitleColor(UIColor(hex: "#121212"), for: .normal)
        b.tintColor = UIColor(hex: "#121212")
        b.layer.borderColor = UIColor(hex: "#121212").cgColor
        b.layer.borderWidth = 1
        b.layer.cornerRadius = 8
        if let image = UIImage(named: "ic_timetable") {
            b.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
            b.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
            b.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        }
        return b
    }()

    private let bottomBarView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        return v
    }()

    // 날짜 탭 레이블을 별도 배열로 관리 — btn.subviews 탐색 방식은 iOS 버전별 내부 구조 변화로 불안정
    private var dayButtons: [UIButton] = []
    private var dayTitleLabels: [UILabel] = []
    private var dayDateLabels: [UILabel] = []

    // MARK: - Init

    init(viewModel: TimetableDetailViewModel, coordinator: HomeCoordinator?) {
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
        setupDayTabs()
        bindViewModel()
        updateDaySelection(index: 0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
        (navigationController?.parent as? MainTabBarController)?.setTabBarHidden(true)
        viewModel.reload()   // 그리드 편집 후 복귀 시 최신 선택 반영
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
        let event = viewModel.state.event
        venueLabel.text = event.venueName
        concertTitleLabel.text = event.title

        view.addSubview(venueLabel)
        view.addSubview(concertTitleLabel)
        view.addSubview(dayTabScrollView)
        dayTabScrollView.addSubview(dayTabStack)
        view.addSubview(tableView)
        view.addSubview(bottomBarView)
        bottomBarView.addSubview(makeButton)

        venueLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.equalToSuperview().offset(20)
        }

        // Figma: gap between venueName and concertTitle = 4pt
        concertTitleLabel.snp.makeConstraints {
            $0.top.equalTo(venueLabel.snp.bottom).offset(4)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().inset(20)
        }

        // Figma: dayTabs top=176 → concertTitle.bottom(≈152) + 24pt
        dayTabScrollView.snp.makeConstraints {
            $0.top.equalTo(concertTitleLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(60)
        }

        // height.equalTo(dayTabScrollView) 필수: UIScrollView content 높이를 frame 높이로 고정 → 수직 스크롤 방지
        dayTabStack.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(dayTabScrollView.snp.height)
        }

        bottomBarView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
        }

        // makeButton.bottom → safeArea 기준: 홈 인디케이터 영역 침범 방지
        makeButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(48)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(12)
        }

        tableView.snp.makeConstraints {
            $0.top.equalTo(dayTabScrollView.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(bottomBarView.snp.top)
        }

        tableView.register(PerformanceCell.self, forCellReuseIdentifier: PerformanceCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self

        makeButton.addTarget(self, action: #selector(makeTimetableTapped), for: .touchUpInside)
    }

    private func setupDayTabs() {
        let event = viewModel.state.event
        let leadingPad = UIView()
        leadingPad.snp.makeConstraints { $0.width.equalTo(20) }
        dayTabStack.addArrangedSubview(leadingPad)

        for (i, day) in event.days.enumerated() {
            let (btn, titleLbl, dateLbl) = makeDayButton(dayNumber: day.dayNumber, dateString: day.dateString, index: i)
            dayButtons.append(btn)
            dayTitleLabels.append(titleLbl)
            dayDateLabels.append(dateLbl)
            dayTabStack.addArrangedSubview(btn)
        }

        let trailingPad = UIView()
        trailingPad.snp.makeConstraints { $0.width.equalTo(20) }
        dayTabStack.addArrangedSubview(trailingPad)
    }

    private func makeDayButton(dayNumber: Int, dateString: String, index: Int) -> (UIButton, UILabel, UILabel) {
        let btn = UIButton(type: .custom)
        btn.tag = index
        btn.layer.cornerRadius = 8
        btn.layer.borderWidth = 1

        let dayLabel = UILabel()
        dayLabel.text = "DAY \(dayNumber)"
        dayLabel.font = .scaled(14, weight: .bold, textStyle: .subheadline)
        dayLabel.adjustsFontForContentSizeCategory = true
        dayLabel.textAlignment = .center

        let dateLabel = UILabel()
        dateLabel.text = dateString
        dateLabel.font = .scaled(12, weight: .regular, textStyle: .caption1)
        dateLabel.adjustsFontForContentSizeCategory = true
        dateLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [dayLabel, dateLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .center
        stack.isUserInteractionEnabled = false

        btn.addSubview(stack)
        stack.snp.makeConstraints { $0.center.equalToSuperview() }

        btn.snp.makeConstraints {
            $0.width.equalTo(160)
            $0.height.equalTo(60)
        }

        btn.addTarget(self, action: #selector(dayTabTapped(_:)), for: .touchUpInside)
        return (btn, dayLabel, dateLabel)
    }

    private func updateDaySelection(index: Int) {
        for i in 0..<dayButtons.count {
            let btn = dayButtons[i]
            let dayLabel = dayTitleLabels[i]
            let dateLabel = dayDateLabels[i]
            let isSelected = i == index

            if isSelected {
                btn.backgroundColor = UIColor(hex: "#121212")
                btn.layer.borderColor = UIColor(hex: "#121212").cgColor
                dayLabel.textColor = .white
                dateLabel.textColor = .white
            } else {
                btn.backgroundColor = .white
                btn.layer.borderColor = UIColor(hex: "#999999").cgColor
                dayLabel.textColor = UIColor(hex: "#121212")
                dateLabel.textColor = UIColor(hex: "#767676")
            }
        }
    }

    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] in
            guard let self else { return }
            self.updateDaySelection(index: self.viewModel.state.selectedDayIndex)
            self.tableView.reloadData()
        }
    }

    // MARK: - Actions

    @objc private func dayTabTapped(_ sender: UIButton) {
        viewModel.selectDay(at: sender.tag)
    }

    @objc private func makeTimetableTapped() {
        coordinator?.showTimetableGrid(
            event: viewModel.state.event,
            selectedPerformanceIds: viewModel.state.selectedPerformanceIds
        )
    }
}

// MARK: - UITableViewDataSource

extension TimetableDetailViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.state.currentDay.performances.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: PerformanceCell.reuseIdentifier,
            for: indexPath
        ) as! PerformanceCell
        let perf = viewModel.state.currentDay.performances[indexPath.row]
        cell.configure(with: perf, isSelected: viewModel.isSelected(id: perf.id))
        cell.onToggle = { [weak self] in
            self?.viewModel.togglePerformance(id: perf.id)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension TimetableDetailViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}

    // 첫 번째 행 상단 구분선 (Figma: border-t on first row)
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#E5E7EB")
        return v
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1.0 / UIScreen.main.scale
    }
}
