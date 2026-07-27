import UIKit
import SnapKit

// MARK: - CalendarCell
// Figma 1:2669: 월 네비 헤더 + 7열 달력 카드 + 이벤트 칩
// Figma 1:2730: 날짜 선택 상태 + 이벤트 카드 목록

final class CalendarCell: UICollectionViewCell {
    static let reuseIdentifier = "CalendarCell"

    var onMonthChanged: ((Int) -> Void)?
    var onDaySelected: ((Int) -> Void)? {
        didSet { calendarView.onDaySelected = onDaySelected }
    }

    private let calendarView = EventCalendarView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(calendarView)
        calendarView.snp.makeConstraints { $0.edges.equalToSuperview() }
        calendarView.onPrev = { [weak self] in self?.onMonthChanged?(-1) }
        calendarView.onNext = { [weak self] in self?.onMonthChanged?(+1) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func configure(year: Int, month: Int, events: [CalendarEvent]) {
        calendarView.configure(year: year, month: month, events: events)
    }
}

// MARK: - EventCalendarView

final class EventCalendarView: UIView {

    var onPrev: (() -> Void)?
    var onNext: (() -> Void)?
    var onDaySelected: ((Int) -> Void)?

    private var selectedDay: Int?
    private var eventsByDay: [Int: [CalendarEvent]] = [:]

    // MARK: Header
    private let prevButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        b.tintColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        return b
    }()

    private let monthLabel: UILabel = {
        let l = UILabel()
        l.font = .scaled(16, weight: .medium, textStyle: .headline, maxSize: 20)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        return l
    }()

    private let nextButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        b.tintColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        return b
    }()

    private let headerStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.alignment = .center
        sv.distribution = .equalSpacing
        return sv
    }()

    // MARK: Calendar card
    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 4
        v.layer.borderColor = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1).cgColor
        v.layer.borderWidth = 1
        return v
    }()

    private let weekdayStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        return sv
    }()

    private let gridStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.distribution = .fillEqually
        sv.spacing = 4
        return sv
    }()

    private var dayCells: [[DayCell]] = []

    // MARK: Events container (shown below calendar card when a day is selected)
    private let eventsContainer: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 12
        return sv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    private func setupViews() {
        // Header
        headerStack.addArrangedSubview(prevButton)
        headerStack.addArrangedSubview(monthLabel)
        headerStack.addArrangedSubview(nextButton)
        addSubview(headerStack)

        prevButton.snp.makeConstraints { $0.size.equalTo(44) }
        nextButton.snp.makeConstraints { $0.size.equalTo(44) }

        // Weekday labels
        let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
        weekdays.forEach { day in
            let l = UILabel()
            l.text = day
            l.font = .scaled(11, weight: .medium, textStyle: .caption1, maxSize: 14)
            l.adjustsFontForContentSizeCategory = true
            l.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
            l.textAlignment = .center
            weekdayStack.addArrangedSubview(l)
        }

        // 6 rows × 7 cols
        for _ in 0..<6 {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 0
            var row: [DayCell] = []
            for _ in 0..<7 {
                let cell = DayCell()
                cell.onTapped = { [weak self] day in self?.selectDay(day) }
                rowStack.addArrangedSubview(cell)
                row.append(cell)
            }
            dayCells.append(row)
            gridStack.addArrangedSubview(rowStack)
        }

        addSubview(cardView)
        cardView.addSubview(weekdayStack)
        cardView.addSubview(gridStack)
        addSubview(eventsContainer)

        headerStack.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(28)
        }
        cardView.snp.makeConstraints {
            $0.top.equalTo(headerStack.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(336)
        }
        weekdayStack.snp.makeConstraints {
            $0.top.equalToSuperview().inset(12)
            $0.leading.trailing.equalToSuperview().inset(12)
            $0.height.equalTo(24)
        }
        gridStack.snp.makeConstraints {
            $0.top.equalTo(weekdayStack.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(12)
            $0.bottom.equalToSuperview().inset(12)
        }
        eventsContainer.snp.makeConstraints {
            $0.top.equalTo(cardView.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }

        prevButton.addTarget(self, action: #selector(prevTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
    }

    func configure(year: Int, month: Int, events: [CalendarEvent]) {
        monthLabel.text = "\(year)년 \(month)월"

        selectedDay = nil
        eventsContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // 이벤트를 날짜별로 분류
        var byDay: [Int: [CalendarEvent]] = [:]
        let cal = Calendar.current
        for event in events {
            let day = cal.component(.day, from: event.date)
            let m = cal.component(.month, from: event.date)
            let y = cal.component(.year, from: event.date)
            if y == year && m == month {
                byDay[day, default: []].append(event)
            }
        }
        eventsByDay = byDay

        // 해당 월의 1일 요일
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = 1
        guard let firstDate = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: firstDate) else { return }
        let daysInMonth = range.count
        let startWeekday = cal.component(.weekday, from: firstDate) - 1

        var dayNumber = 1
        for row in 0..<6 {
            for col in 0..<7 {
                let index = row * 7 + col
                let cell = dayCells[row][col]
                if index < startWeekday || dayNumber > daysInMonth {
                    cell.clear()
                } else {
                    cell.configure(day: dayNumber, events: eventsByDay[dayNumber] ?? [])
                    dayNumber += 1
                }
            }
        }
    }

    private func selectDay(_ day: Int) {
        selectedDay = day

        for row in dayCells {
            for cell in row {
                cell.setSelected(cell.currentDay == day)
            }
        }

        eventsContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let events = eventsByDay[day] ?? []
        guard !events.isEmpty else {
            onDaySelected?(day)
            return
        }

        let displayCount = min(2, events.count)
        for event in events.prefix(displayCount) {
            let card = CalendarEventCardView()
            card.configure(with: event)
            eventsContainer.addArrangedSubview(card)
        }

        if events.count > displayCount {
            let remaining = events.count - displayCount
            let moreButton = UIButton(type: .system)
            moreButton.setTitle("더보기 (\(remaining)개)", for: .normal)
            moreButton.setTitleColor(UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1), for: .normal)
            moreButton.titleLabel?.font = .scaled(13, weight: .medium, textStyle: .footnote)
            moreButton.titleLabel?.adjustsFontForContentSizeCategory = true
            moreButton.backgroundColor = UIColor(red: 0.953, green: 0.957, blue: 0.965, alpha: 1)
            moreButton.layer.cornerRadius = 4
            moreButton.snp.makeConstraints { $0.height.equalTo(40) }

            let allEvents = events
            moreButton.addAction(UIAction { [weak self, weak moreButton] _ in
                guard let self, let moreButton else { return }
                let insertIndex = self.eventsContainer.arrangedSubviews.firstIndex(of: moreButton) ?? self.eventsContainer.arrangedSubviews.count
                moreButton.removeFromSuperview()
                for (i, event) in allEvents.dropFirst(displayCount).enumerated() {
                    let card = CalendarEventCardView()
                    card.configure(with: event)
                    self.eventsContainer.insertArrangedSubview(card, at: insertIndex + i)
                }
                self.onDaySelected?(day)
            }, for: .touchUpInside)

            eventsContainer.addArrangedSubview(moreButton)
        }

        onDaySelected?(day)
    }

    @objc private func prevTapped() { onPrev?() }
    @objc private func nextTapped() { onNext?() }
}

// MARK: - DayCell
// 날짜 숫자 + 최대 3개 이벤트 칩 + 선택 시 셀 테두리 표시 (Figma 1:5867)

private final class DayCell: UIView {

    var onTapped: ((Int) -> Void)?
    private(set) var currentDay: Int = 0

    private let dayLabel: UILabel = {
        let l = UILabel()
        l.font = .scaled(10, weight: .medium, textStyle: .caption2, maxSize: 13)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        return l
    }()

    private let chipsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 2
        return sv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        addSubview(dayLabel)
        addSubview(chipsStack)
        isUserInteractionEnabled = true

        dayLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(5)
            $0.leading.equalToSuperview().inset(5)
            $0.height.equalTo(15)
        }
        chipsStack.snp.makeConstraints {
            $0.top.equalTo(dayLabel.snp.bottom).offset(2)
            $0.leading.equalToSuperview().inset(3)
            $0.trailing.equalToSuperview().inset(3)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func configure(day: Int, events: [CalendarEvent]) {
        currentDay = day
        dayLabel.text = "\(day)"
        chipsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        events.prefix(3).forEach { event in
            let chip = EventChipView()
            chip.configure(title: event.title, color: event.color)
            chip.snp.makeConstraints { $0.height.equalTo(16) }
            chipsStack.addArrangedSubview(chip)
        }
    }

    func clear() {
        currentDay = 0
        dayLabel.text = nil
        chipsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        setSelected(false)
    }

    func setSelected(_ selected: Bool) {
        if selected {
            layer.borderColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 0.8).cgColor
            layer.borderWidth = 1
            layer.cornerRadius = 8
            dayLabel.font = .scaled(10, weight: .bold, textStyle: .caption2, maxSize: 13)
        } else {
            layer.borderWidth = 0
            layer.cornerRadius = 0
            dayLabel.font = .scaled(10, weight: .medium, textStyle: .caption2, maxSize: 13)
        }
    }

    @objc private func handleTap() {
        guard currentDay > 0 else { return }
        onTapped?(currentDay)
    }
}
