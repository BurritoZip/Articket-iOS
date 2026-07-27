import UIKit
import SnapKit

// MARK: - Layout Constants

private enum G {
    static let hourH: CGFloat = 56            // Figma: 1시간 = 56pt
    static let minH: CGFloat = 56.0 / 60.0   // 1분 = 0.9333pt
    static let timeColW: CGFloat = 72         // 타임라인 열 너비 (60+12)
    static let stageGap: CGFloat = 8          // 스테이지 간 간격
    static let rightPad: CGFloat = 12         // 그리드 오른쪽 패딩
    static let hMargin: CGFloat = 16          // 좌우 화면 마진
    static let blockPadH: CGFloat = 8         // 블록 좌우 내부 패딩
    static let blockPadV: CGFloat = 4         // 블록 상하 내부 패딩
    static let accentW: CGFloat = 1           // 액센트 보더 너비
    // 스테이지 색상: Figma 기준 (A=#FF8080, B=#121212, C=#FFFD80)
    static let stageColors: [UIColor] = [
        UIColor(hex: "#FF8080"),
        UIColor(hex: "#121212"),
        UIColor(hex: "#FFFD80"),
        UIColor(hex: "#80FFCF"),
        UIColor(hex: "#C77DFF")
    ]
    // 블록 배경: Figma bg-[rgba(18,18,18,0.1)]
    static let blockBg = UIColor(red: 18/255, green: 18/255, blue: 18/255, alpha: 0.1)
}

// MARK: - PerformanceBlockView

private final class PerformanceBlockView: UIView {
    var performance: Performance?
}

// MARK: - TimetableGridViewController

final class TimetableGridViewController: UIViewController {

    // MARK: - State

    private let viewModel: TimetableGridViewModel
    weak var coordinator: HomeCoordinator?
    private var lastLayoutWidth: CGFloat = 0
    private var isSelectionMode = false

    // MARK: - Day Tabs

    private let dayTabScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.bounces = false
        return sv
    }()

    private let dayTabStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        return sv
    }()

    private let dayTabIndicator: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#121212")
        return v
    }()

    private let dayTabBorder: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#E5E7EB")
        return v
    }()

    private var dayTabButtons: [UIButton] = []

    // MARK: - Stage Header (sticky)

    private let stageHeaderView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        return v
    }()

    // MARK: - Grid

    private let gridScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.alwaysBounceVertical = true
        sv.showsHorizontalScrollIndicator = false
        return sv
    }()

    private let gridContentView = UIView()

    // MARK: - Bottom Selection Panel (972:6209)
    // 별도 시트가 아니라 VC 내에서 위로 슬라이드

    private let dimView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.15)
        v.alpha = 0
        return v
    }()

    private let selectionPanel: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.15
        v.layer.shadowOffset = CGSize(width: 0, height: -1)
        v.layer.shadowRadius = 12
        return v
    }()

    private let selectionTableView: UITableView = {
        let tv = UITableView()
        tv.separatorStyle = .singleLine
        tv.separatorColor = UIColor(hex: "#E5E7EB")
        tv.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        tv.backgroundColor = .white
        tv.showsVerticalScrollIndicator = false
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 72
        return tv
    }()

    private var selectionPanelBottomConstraint: Constraint?
    private var selectionPerformances: [Performance] = []

    // MARK: - Add Form Panel (989:4861)
    // 직접 추가 폼: 그리드 위 바텀시트 인라인

    private let addPanel: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.15
        v.layer.shadowOffset = CGSize(width: 0, height: -1)
        v.layer.shadowRadius = 12
        return v
    }()

    private let nameField: UITextField = {
        let tf = UITextField()
        tf.font = .scaled(16, weight: .medium, textStyle: .headline)
        tf.adjustsFontForContentSizeCategory = true
        tf.textColor = .tcInk
        tf.attributedPlaceholder = NSAttributedString(
            string: "가수명",
            attributes: [
                .foregroundColor: UIColor.tcPlaceholder,
                .font: UIFont.scaled(16, weight: .medium, textStyle: .headline)
            ]
        )
        tf.clearButtonMode = .whileEditing
        return tf
    }()

    private let stageButton = DropdownButton()

    private let timeButton = DropdownButton()

    /// "시간 및 장소 추가" — 현재 입력(가수명+스테이지+시간)을 한 슬롯으로 즉시 추가하고
    /// 가수명은 유지·시간만 리셋해 같은 가수의 다른 무대/시간을 연달아 담게 한다(Figma 989).
    private let addSlotButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("시간 및 장소 추가", for: .normal)
        b.setTitleColor(.tcInk, for: .normal)
        b.titleLabel?.font = .scaled(14, weight: .medium, textStyle: .subheadline)
        b.titleLabel?.adjustsFontForContentSizeCategory = true
        return b
    }()

    private var addPanelBottomConstraint: Constraint?
    private var selectedStageName = "STAGE A"
    private var selectedStartMin = 690   // 11:30
    private var selectedEndMin = 750     // 12:30
    /// 현재 폼 행이 아직 커밋 안 된 변경분을 가졌는지 — 완료 시 중복 추가 방지용
    private var formDirty = false
    private var editingPerformanceId: UUID?
    private var isAddFormMode = false

    // MARK: - Init

    init(viewModel: TimetableGridViewModel, coordinator: HomeCoordinator?) {
        self.viewModel = viewModel
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNav()
        setupDayTabs()
        setupStageHeader()
        setupGridScrollView()
        setupSelectionPanel()
        setupAddPanel()
        bindViewModel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let w = view.bounds.width
        guard w > 0, w != lastLayoutWidth else { return }
        lastLayoutWidth = w
        buildGrid()
        updateIndicator(animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyNavAppearance()
        (navigationController?.parent as? MainTabBarController)?.setTabBarHidden(true)
    }

    // MARK: - Navigation Setup

    private func applyNavAppearance() {
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

    private func setupNav() {
        setNormalNavMode()
    }

    /// iOS 26 Liquid Glass shared background 제거 — Figma는 플랫 아이콘/버튼
    private func flat(_ item: UIBarButtonItem) -> UIBarButtonItem {
        if #available(iOS 26.0, *) { item.hidesSharedBackground = true }
        return item
    }

    private func makeFlatBackButton() -> UIBarButtonItem {
        flat(UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        ))
    }

    private func setNormalNavMode() {
        title = "타임테이블"
        navigationItem.leftBarButtonItem = makeFlatBackButton()

        let addBtn = flat(UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addButtonTapped)
        ))
        let shareBtn = flat(UIBarButtonItem(
            image: UIImage(named: "ic_share")?.withRenderingMode(.alwaysTemplate),
            style: .plain,
            target: self,
            action: #selector(shareButtonTapped)
        ))
        navigationItem.rightBarButtonItems = [shareBtn, addBtn]
    }

    private func setSelectionNavMode() {
        title = nil

        let closeBtn = flat(UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeSelectionTapped)
        ))
        navigationItem.leftBarButtonItem = closeBtn

        // "직접 추가" pill — 디자인 시스템 PillButton 사용
        let pillBtn = PillButton(title: "직접 추가", style: .outline)
        pillBtn.addTarget(self, action: #selector(directAddTapped), for: .touchUpInside)
        pillBtn.sizeToFit()

        navigationItem.rightBarButtonItems = [flat(UIBarButtonItem(customView: pillBtn))]
    }

    // MARK: - Day Tabs Setup

    private func setupDayTabs() {
        view.addSubview(dayTabScrollView)
        dayTabScrollView.addSubview(dayTabStack)
        dayTabScrollView.addSubview(dayTabIndicator)
        view.addSubview(dayTabBorder)

        dayTabScrollView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(36)
        }
        dayTabBorder.snp.makeConstraints {
            $0.top.equalTo(dayTabScrollView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(1)
        }
        dayTabStack.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(36)
            $0.width.equalTo(dayTabScrollView.snp.width)
        }

        let days = viewModel.state.event.days
        for (i, day) in days.enumerated() {
            let btn = UIButton(type: .custom)
            btn.tag = i
            btn.setTitle("DAY \(day.dayNumber)", for: .normal)
            btn.titleLabel?.font = .scaled(14, weight: .semibold, textStyle: .subheadline)
            btn.titleLabel?.adjustsFontForContentSizeCategory = true
            btn.setTitleColor(UIColor(hex: "#666666"), for: .normal)
            btn.setTitleColor(UIColor(hex: "#121212"), for: .selected)
            btn.isSelected = (i == 0)
            btn.addTarget(self, action: #selector(dayTabTapped(_:)), for: .touchUpInside)
            dayTabStack.addArrangedSubview(btn)
            dayTabButtons.append(btn)
        }
    }

    private let stageHeaderBorderLine: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#E5E7EB")
        return v
    }()

    private func setupStageHeader() {
        view.addSubview(stageHeaderView)
        view.addSubview(stageHeaderBorderLine)
        stageHeaderView.snp.makeConstraints {
            $0.top.equalTo(dayTabBorder.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(35)
        }
        stageHeaderBorderLine.snp.makeConstraints {
            $0.top.equalTo(stageHeaderView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(1)
        }
    }

    private func setupGridScrollView() {
        view.addSubview(gridScrollView)
        gridScrollView.snp.makeConstraints {
            $0.top.equalTo(stageHeaderBorderLine.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        gridScrollView.addSubview(gridContentView)
    }

    private func setupSelectionPanel() {
        view.addSubview(dimView)
        view.addSubview(selectionPanel)

        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }

        let panelH: CGFloat = 360
        selectionPanel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(panelH)
            selectionPanelBottomConstraint = $0.bottom.equalToSuperview().offset(panelH).constraint
        }

        selectionTableView.register(GridPanelCell.self, forCellReuseIdentifier: GridPanelCell.reuseIdentifier)
        selectionTableView.dataSource = self
        selectionTableView.delegate = self
        selectionPanel.addSubview(selectionTableView)
        selectionTableView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        // 패널 숨긴 상태로 시작
        dimView.isHidden = true
        selectionPanel.isHidden = true
    }

    // MARK: - Add Form Panel Setup

    private func setupAddPanel() {
        view.addSubview(addPanel)

        let panelH: CGFloat = 300
        addPanel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(panelH)
            addPanelBottomConstraint = $0.bottom.equalToSuperview().offset(panelH).constraint
        }

        // 가수명 필드 + 밑줄
        let nameUnderline = makeUnderline()
        addPanel.addSubview(nameField)
        addPanel.addSubview(nameUnderline)

        // STAGE 드롭다운 + 시간 드롭다운 (한 행)
        let optionUnderline = makeUnderline()
        addPanel.addSubview(stageButton)
        addPanel.addSubview(timeButton)
        addPanel.addSubview(optionUnderline)

        nameField.snp.makeConstraints {
            $0.top.equalToSuperview().offset(28)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(28)
        }
        nameUnderline.snp.makeConstraints {
            $0.top.equalTo(nameField.snp.bottom).offset(10)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(1)
        }

        stageButton.snp.makeConstraints {
            $0.top.equalTo(nameUnderline.snp.bottom).offset(20)
            $0.leading.equalToSuperview().offset(20)
            $0.height.equalTo(28)
        }
        timeButton.snp.makeConstraints {
            $0.centerY.equalTo(stageButton)
            $0.leading.equalTo(stageButton.snp.trailing).offset(24)
        }
        optionUnderline.snp.makeConstraints {
            $0.top.equalTo(stageButton.snp.bottom).offset(10)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(1)
        }

        // "시간 및 장소 추가" 버튼 (Figma 989 — 입력 아래 다크 액션)
        addPanel.addSubview(addSlotButton)
        addSlotButton.snp.makeConstraints {
            $0.top.equalTo(optionUnderline.snp.bottom).offset(20)
            $0.leading.equalToSuperview().offset(20)
        }
        addSlotButton.addTarget(self, action: #selector(addSlotTapped), for: .touchUpInside)
        nameField.addTarget(self, action: #selector(formFieldChanged), for: .editingChanged)

        addPanel.isHidden = true
    }

    @objc private func formFieldChanged() { formDirty = true }

    private func makeUnderline() -> UIView {
        let v = UIView()
        v.backgroundColor = .tcFieldBorder
        return v
    }

    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] in
            guard let self else { return }
            self.buildGrid()
            self.updateIndicator(animated: true)
            self.dayTabButtons.enumerated().forEach { i, btn in
                btn.isSelected = (i == self.viewModel.state.selectedDayIndex)
            }
            if self.isSelectionMode {
                self.selectionPerformances = self.viewModel.state.allServerPerformances
                self.selectionTableView.reloadData()
            }
        }
    }

    // MARK: - Grid Builder

    private func buildGrid() {
        gridContentView.subviews.forEach { $0.removeFromSuperview() }
        stageHeaderView.subviews.compactMap { $0 as? UILabel }.forEach { $0.removeFromSuperview() }

        let state = viewModel.state
        let stages = state.stageNames
        let stageCount = max(stages.count, 1)
        let startHour = state.startHour
        let endHour = state.endHour
        let screenW = view.bounds.width
        // 각 스테이지 열 너비 계산 (Figma 공식)
        let stageW = (screenW - G.hMargin * 2 - G.timeColW - G.stageGap * CGFloat(stageCount - 1) - G.rightPad) / CGFloat(stageCount)
        let contentH = CGFloat((endHour - startHour) * 60) * G.minH + 20

        // 스테이지 헤더 레이블 (Figma: text-[#121212], text-[12px], SemiBold)
        for (i, stage) in stages.enumerated() {
            let lbl = UILabel()
            lbl.text = stage
            lbl.font = .scaled(12, weight: .semibold, textStyle: .caption1, maxSize: 15)
            lbl.adjustsFontForContentSizeCategory = true
            lbl.textColor = UIColor(hex: "#121212")
            lbl.textAlignment = .left
            stageHeaderView.addSubview(lbl)
            let xBase = G.hMargin + G.timeColW + CGFloat(i) * (stageW + G.stageGap)
            lbl.frame = CGRect(x: xBase, y: 12, width: stageW, height: 15)
        }

        // 그리드 컨텐츠 영역
        gridContentView.snp.remakeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(screenW)
            $0.height.equalTo(contentH)
        }

        // 시간 레이블 + 가로 구분선
        for i in 0...(endHour - startHour) {
            let hour = startHour + i
            let y = CGFloat(i * 60) * G.minH

            // 시간 레이블 (Figma: pl-12, w-32, text-[#121212], text-[11px], Medium)
            let tLbl = UILabel()
            tLbl.text = String(format: "%02d:00", hour)
            tLbl.font = .scaled(11, weight: .medium, textStyle: .caption1, maxSize: 14)
            tLbl.adjustsFontForContentSizeCategory = true
            tLbl.textColor = UIColor(hex: "#121212")
            tLbl.textAlignment = .left
            gridContentView.addSubview(tLbl)
            tLbl.frame = CGRect(x: G.hMargin + 12, y: y, width: 32, height: 16)

            // 구분선
            let sep = UIView()
            sep.backgroundColor = UIColor(hex: "#E5E7EB")
            gridContentView.addSubview(sep)
            sep.frame = CGRect(x: G.hMargin + G.timeColW, y: y, width: screenW - G.hMargin * 2 - G.timeColW - G.rightPad, height: 0.5)
        }

        // 퍼포먼스 블록
        for (sIdx, stage) in stages.enumerated() {
            let perfs = state.allPerformances.filter { $0.stageName == stage }
            let xBase = G.hMargin + G.timeColW + CGFloat(sIdx) * (stageW + G.stageGap)
            let accentColor = G.stageColors[sIdx % G.stageColors.count]

            for perf in perfs {
                let sMin = minsFromTime(perf.startTime)
                let eMin = minsFromTime(perf.endTime)
                let relY = CGFloat(sMin - startHour * 60) * G.minH
                let blockH = max(CGFloat(eMin - sMin) * G.minH, 18)
                let block = makeBlock(perf, color: accentColor, frame: CGRect(x: xBase, y: relY, width: stageW, height: blockH))
                gridContentView.addSubview(block)
            }
        }
    }

    private func makeBlock(_ perf: Performance, color: UIColor, frame: CGRect) -> PerformanceBlockView {
        let v = PerformanceBlockView(frame: frame)
        v.performance = perf
        // Figma: bg-[rgba(18,18,18,0.1)], border-l 1pt
        v.backgroundColor = G.blockBg
        v.isUserInteractionEnabled = true

        // 왼쪽 액센트 바 (Figma: border-l border-solid)
        let bar = UIView(frame: CGRect(x: 0, y: 0, width: G.accentW, height: frame.height))
        bar.backgroundColor = color
        v.addSubview(bar)

        // 아티스트명 (Figma: top, text-[11px] Medium #121212, w-[70px])
        let nLbl = UILabel()
        nLbl.text = perf.artistName
        nLbl.font = .scaled(11, weight: .medium, textStyle: .caption1, maxSize: 14)
        nLbl.adjustsFontForContentSizeCategory = true
        nLbl.textColor = UIColor(hex: "#121212")
        nLbl.numberOfLines = 1
        nLbl.lineBreakMode = .byTruncatingTail
        v.addSubview(nLbl)
        let contentX = G.accentW + G.blockPadH
        let contentW = frame.width - G.accentW - G.blockPadH * 2
        nLbl.frame = CGRect(x: contentX, y: G.blockPadV, width: contentW, height: 16)

        // 시간 표시 (Figma: bottom, text-[10px] Medium #121212, text-right)
        if frame.height >= 22 {
            let dur = minsFromTime(perf.endTime) - minsFromTime(perf.startTime)
            let dLbl = UILabel()
            dLbl.text = "\(dur)'"
            dLbl.font = .scaled(10, weight: .medium, textStyle: .caption2, maxSize: 12)
            dLbl.adjustsFontForContentSizeCategory = true
            dLbl.textColor = UIColor(hex: "#121212")
            dLbl.textAlignment = .right
            v.addSubview(dLbl)
            dLbl.frame = CGRect(x: contentX, y: frame.height - G.blockPadV - 15, width: contentW, height: 15)
        }

        v.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(blockTapped(_:))))
        return v
    }

    private func minsFromTime(_ t: String) -> Int {
        let p = t.split(separator: ":")
        return (Int(p.first ?? "0") ?? 0) * 60 + (p.count > 1 ? Int(p[1]) ?? 0 : 0)
    }

    // MARK: - Day Tab Indicator

    private func updateIndicator(animated: Bool) {
        let idx = viewModel.state.selectedDayIndex
        guard !dayTabButtons.isEmpty, view.bounds.width > 0 else { return }
        let btnW = view.bounds.width / CGFloat(dayTabButtons.count)
        let f = CGRect(x: CGFloat(idx) * btnW, y: 34, width: btnW, height: 2)
        if animated {
            UIView.animate(withDuration: 0.2) { self.dayTabIndicator.frame = f }
        } else {
            dayTabIndicator.frame = f
        }
    }

    // MARK: - Selection Panel

    private func showSelectionPanel() {
        isSelectionMode = true
        selectionPerformances = viewModel.state.allServerPerformances
        selectionTableView.reloadData()

        dimView.isHidden = false
        selectionPanel.isHidden = false
        view.layoutIfNeeded()

        selectionPanelBottomConstraint?.update(offset: 0)
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.88, initialSpringVelocity: 0) {
            self.dimView.alpha = 1
            self.view.layoutIfNeeded()
        }
        setSelectionNavMode()
    }

    private func hideSelectionPanel() {
        isSelectionMode = false
        let panelH: CGFloat = 360
        selectionPanelBottomConstraint?.update(offset: panelH)
        UIView.animate(withDuration: 0.28) {
            self.dimView.alpha = 0
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.dimView.isHidden = true
            self.selectionPanel.isHidden = true
        }
        setNormalNavMode()
    }

    // MARK: - Add Form Panel

    private func setAddFormNavMode() {
        title = nil

        let closeBtn = flat(UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeAddFormTapped)
        ))
        navigationItem.leftBarButtonItem = closeBtn

        // "완료" pill — 디자인 시스템 PillButton 사용
        let pillBtn = PillButton(title: "완료", style: .outline)
        pillBtn.addTarget(self, action: #selector(addFormDoneTapped), for: .touchUpInside)
        pillBtn.sizeToFit()

        navigationItem.rightBarButtonItems = [flat(UIBarButtonItem(customView: pillBtn))]
    }

    private func showAddForm(prefill perf: Performance? = nil) {
        // 선택 패널이 떠 있으면 내림
        if isSelectionMode { hideSelectionPanel() }

        isAddFormMode = true
        editingPerformanceId = perf?.id

        // 초기값
        let stages = viewModel.state.stageNames
        if let perf {
            nameField.text = perf.artistName
            selectedStageName = perf.stageName
            selectedStartMin = minsFromTime(perf.startTime)
            selectedEndMin = minsFromTime(perf.endTime)
        } else {
            nameField.text = ""
            selectedStageName = stages.first ?? "STAGE A"
            selectedStartMin = 690
            selectedEndMin = 750
        }
        // 편집 진입은 기존 값이 곧 커밋 대상이므로 dirty=true, 신규는 사용자 입력 전까지 false
        formDirty = (perf != nil)
        rebuildStageMenu()
        rebuildTimeMenu()
        updateStageButtonTitle()
        updateTimeButtonTitle()

        dimView.isHidden = false
        addPanel.isHidden = false
        view.layoutIfNeeded()

        addPanelBottomConstraint?.update(offset: 0)
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.88, initialSpringVelocity: 0) {
            self.dimView.alpha = 1
            self.view.layoutIfNeeded()
        }
        setAddFormNavMode()
    }

    private func hideAddForm() {
        isAddFormMode = false
        editingPerformanceId = nil
        nameField.resignFirstResponder()
        let panelH: CGFloat = 300
        addPanelBottomConstraint?.update(offset: panelH)
        UIView.animate(withDuration: 0.28) {
            self.dimView.alpha = 0
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.dimView.isHidden = true
            self.addPanel.isHidden = true
        }
        setNormalNavMode()
    }

    // MARK: - Add Form Dropdowns

    private func rebuildStageMenu() {
        let stages = viewModel.state.stageNames
        let actions = stages.map { name in
            UIAction(title: name, state: name == selectedStageName ? .on : .off) { [weak self] _ in
                self?.selectedStageName = name
                self?.formDirty = true
                self?.updateStageButtonTitle()
                self?.rebuildStageMenu()
            }
        }
        stageButton.menu = UIMenu(children: actions)
    }

    private func rebuildTimeMenu() {
        // 11:00 ~ 22:30, 30분 간격 시작, 기본 60분 길이
        var actions: [UIAction] = []
        for start in stride(from: 660, through: 1350, by: 30) {
            let end = start + 60
            let label = "\(timeString(start)) - \(timeString(end))"
            let isOn = start == selectedStartMin && end == selectedEndMin
            actions.append(UIAction(title: label, state: isOn ? .on : .off) { [weak self] _ in
                self?.selectedStartMin = start
                self?.selectedEndMin = end
                self?.formDirty = true
                self?.updateTimeButtonTitle()
                self?.rebuildTimeMenu()
            })
        }
        timeButton.menu = UIMenu(children: actions)
    }

    private func updateStageButtonTitle() {
        stageButton.setValue(selectedStageName)
    }

    private func updateTimeButtonTitle() {
        timeButton.setValue("\(timeString(selectedStartMin)) - \(timeString(selectedEndMin))")
    }

    private func timeString(_ mins: Int) -> String {
        String(format: "%02d:%02d", mins / 60, mins % 60)
    }

    // MARK: - Actions

    @objc private func dayTabTapped(_ sender: UIButton) {
        viewModel.selectDay(at: sender.tag)
    }

    @objc private func blockTapped(_ sender: UITapGestureRecognizer) {
        guard let block = sender.view as? PerformanceBlockView,
              let perf = block.performance else { return }
        let sheet = PerformanceActionSheetViewController(performance: perf)
        sheet.onDelete = { [weak self] in self?.viewModel.deletePerformance(id: perf.id) }
        sheet.onEdit = { [weak self] in self?.showAddForm(prefill: perf) }
        if let pc = sheet.sheetPresentationController {
            pc.detents = [.custom(identifier: .init("sm")) { _ in 280 }]
            pc.prefersGrabberVisible = true
        }
        sheet.modalPresentationStyle = .pageSheet
        present(sheet, animated: true)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func addButtonTapped() {
        showSelectionPanel()
    }

    @objc private func closeSelectionTapped() {
        hideSelectionPanel()
    }

    @objc private func directAddTapped() {
        showAddForm()
    }

    @objc private func closeAddFormTapped() {
        hideAddForm()
    }

    /// 현재 폼 입력을 한 슬롯으로 커밋. 성공 시 true. (편집 모드면 기존 항목 교체 후 add로 전환)
    @discardableResult
    private func commitCurrentForm(focusNameIfEmpty: Bool = true) -> Bool {
        let name = (nameField.text ?? "").trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else {
            if focusNameIfEmpty { nameField.becomeFirstResponder() }
            return false
        }
        guard selectedEndMin > selectedStartMin else { return false }

        if let id = editingPerformanceId {
            viewModel.deletePerformance(id: id)
            editingPerformanceId = nil   // 첫 커밋 후엔 추가 모드로 전환(연속 추가 대비)
        }
        let perf = Performance(
            id: UUID(),
            startTime: timeString(selectedStartMin),
            endTime: timeString(selectedEndMin),
            artistName: name,
            stageName: selectedStageName,
            genre: ""
        )
        viewModel.addUserPerformance(perf)
        formDirty = false
        return true
    }

    /// "시간 및 장소 추가" — 현재 슬롯을 담고 폼은 유지(가수명 유지·시간만 다음 칸으로) → 같은 가수 연속 추가
    @objc private func addSlotTapped() {
        guard commitCurrentForm() else { return }
        // 다음 슬롯 기본값: 방금 끝난 시간부터 60분 (겹치지 않게)
        let nextStart = min(selectedEndMin, 1350)
        selectedStartMin = nextStart
        selectedEndMin = nextStart + 60
        updateTimeButtonTitle()
        rebuildTimeMenu()
        Haptics.impact()
        nameField.becomeFirstResponder()
    }

    @objc private func addFormDoneTapped() {
        // 아직 커밋 안 된 현재 입력이 있으면 담고, 없으면 그냥 닫는다(시간 및 장소 추가로 이미 담긴 경우)
        if formDirty { _ = commitCurrentForm() }
        hideAddForm()
    }

    @objc private func shareButtonTapped() {
        // 직접 push 대신 coordinator 위임 (라우팅 일원화)
        coordinator?.showTimetableLockscreenGuide(
            event: viewModel.state.event,
            selectedPerformanceIds: viewModel.state.selectedPerformanceIds
        )
    }
}

// MARK: - UITableViewDataSource

extension TimetableGridViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        selectionPerformances.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: GridPanelCell.reuseIdentifier,
            for: indexPath
        ) as! GridPanelCell
        let perf = selectionPerformances[indexPath.row]
        cell.configure(
            with: perf,
            subtitle: viewModel.subtitleString(of: perf),
            isSelected: viewModel.isSelected(id: perf.id)
        )
        cell.onToggle = { [weak self] in
            guard let self else { return }
            self.viewModel.togglePerformance(id: perf.id)
            self.selectionPerformances = self.viewModel.state.allServerPerformances
            tableView.reloadRows(at: [indexPath], with: .none)
            self.buildGrid()
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension TimetableGridViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
