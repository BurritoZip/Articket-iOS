import UIKit
import SnapKit

// MARK: - CalendarCell
// Figma 1:2669: 월 네비 헤더 + 7열 달력 카드 + 이벤트 칩

final class CalendarCell: UICollectionViewCell {
    static let reuseIdentifier = "CalendarCell"

    var onMonthChanged: ((Int) -> Void)?  // delta: +1 또는 -1

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

    // MARK: Header
    private let prevButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        b.tintColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        return b
    }()

    private let monthLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .medium)
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

    // 7 × 6 = 42 날짜 셀 (UIView)
    private let gridStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.distribution = .fillEqually
        sv.spacing = 4
        return sv
    }()

    private var dayCells: [[DayCell]] = []  // [row][col]

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

        prevButton.snp.makeConstraints { $0.size.equalTo(28) }
        nextButton.snp.makeConstraints { $0.size.equalTo(28) }

        // Weekday labels
        let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
        weekdays.forEach { day in
            let l = UILabel()
            l.text = day
            l.font = .systemFont(ofSize: 11, weight: .medium)
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
                rowStack.addArrangedSubview(cell)
                row.append(cell)
            }
            dayCells.append(row)
            gridStack.addArrangedSubview(rowStack)
        }

        addSubview(cardView)
        cardView.addSubview(weekdayStack)
        cardView.addSubview(gridStack)

        headerStack.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(28)
        }
        cardView.snp.makeConstraints {
            $0.top.equalTo(headerStack.snp.bottom).offset(16)
            $0.leading.trailing.bottom.equalToSuperview()
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

        prevButton.addTarget(self, action: #selector(prevTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
    }

    func configure(year: Int, month: Int, events: [CalendarEvent]) {
        monthLabel.text = "\(year)년 \(month)월"

        // 해당 월의 1일 요일 (0=일, 1=월, ...)
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = 1
        let cal = Calendar.current
        guard let firstDate = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: firstDate) else { return }
        let daysInMonth = range.count
        let startWeekday = cal.component(.weekday, from: firstDate) - 1  // 0-based

        // 이벤트를 날짜별로 분류
        var eventsByDay: [Int: [CalendarEvent]] = [:]
        for event in events {
            let day = cal.component(.day, from: event.date)
            let m = cal.component(.month, from: event.date)
            let y = cal.component(.year, from: event.date)
            if y == year && m == month {
                eventsByDay[day, default: []].append(event)
            }
        }

        // 셀 채우기
        var dayNumber = 1
        for row in 0..<6 {
            for col in 0..<7 {
                let index = row * 7 + col
                let cell = dayCells[row][col]
                if index < startWeekday || dayNumber > daysInMonth {
                    cell.clear()
                } else {
                    let eventsForDay = eventsByDay[dayNumber] ?? []
                    cell.configure(day: dayNumber, events: eventsForDay)
                    dayNumber += 1
                }
            }
        }
    }

    @objc private func prevTapped() { onPrev?() }
    @objc private func nextTapped() { onNext?() }
}

// MARK: - DayCell
// 날짜 숫자 + 최대 3개 이벤트 칩

private final class DayCell: UIView {

    private let dayLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 10, weight: .medium)
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
        addSubview(dayLabel)
        addSubview(chipsStack)

        dayLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(5)
            $0.leading.equalToSuperview().inset(5)
            $0.height.equalTo(15)
        }
        chipsStack.snp.makeConstraints {
            $0.top.equalTo(dayLabel.snp.bottom).offset(2)
            $0.leading.equalToSuperview().inset(3)
            $0.trailing.equalToSuperview().inset(3)
            $0.bottom.lessThanOrEqualToSuperview().inset(1)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func configure(day: Int, events: [CalendarEvent]) {
        dayLabel.text = "\(day)"
        chipsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let visible = events.prefix(3)
        visible.forEach { event in
            chipsStack.addArrangedSubview(makeChip(event: event))
        }
    }

    func clear() {
        dayLabel.text = nil
        chipsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }

    private func makeChip(event: CalendarEvent) -> UIView {
        let chip = UIView()
        chip.layer.cornerRadius = 4
        chip.clipsToBounds = true

        let label = UILabel()
        label.font = .systemFont(ofSize: 7, weight: .medium)
        label.lineBreakMode = .byTruncatingTail

        switch event.color {
        case .green:
            chip.backgroundColor = UIColor(red: 0.863, green: 0.988, blue: 0.906, alpha: 1)
            label.textColor = UIColor(red: 0, green: 0.51, blue: 0.212, alpha: 1)
        case .red:
            chip.backgroundColor = UIColor(red: 1, green: 0.886, blue: 0.886, alpha: 1)
            label.textColor = UIColor(red: 1, green: 0.278, blue: 0.341, alpha: 1)
        case .yellow:
            chip.backgroundColor = UIColor(red: 0.996, green: 0.976, blue: 0.761, alpha: 1)
            label.textColor = UIColor(red: 0.651, green: 0.373, blue: 0, alpha: 1)
        }

        label.text = event.title
        chip.addSubview(label)
        label.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(2)
            $0.leading.trailing.equalToSuperview().inset(4)
        }
        chip.snp.makeConstraints { $0.height.equalTo(16) }
        return chip
    }
}
