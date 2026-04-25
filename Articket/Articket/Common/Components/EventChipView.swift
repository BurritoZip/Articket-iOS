import UIKit
import SnapKit

// 달력 이벤트 칩 (색상 3종). CalendarCell.DayCell에서 사용.
final class EventChipView: UIView {

    private let label: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 7, weight: .medium)
        l.lineBreakMode = .byTruncatingTail
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 4
        clipsToBounds = true
        addSubview(label)
        label.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(2)
            $0.leading.trailing.equalToSuperview().inset(4)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func configure(title: String, color: CalendarEventColor) {
        label.text = title
        switch color {
        case .green:
            backgroundColor = UIColor(red: 0.863, green: 0.988, blue: 0.906, alpha: 1)
            label.textColor = UIColor(red: 0, green: 0.51, blue: 0.212, alpha: 1)
        case .red:
            backgroundColor = UIColor(red: 1, green: 0.886, blue: 0.886, alpha: 1)
            label.textColor = UIColor(red: 1, green: 0.278, blue: 0.341, alpha: 1)
        case .yellow:
            backgroundColor = UIColor(red: 0.996, green: 0.976, blue: 0.761, alpha: 1)
            label.textColor = UIColor(red: 0.651, green: 0.373, blue: 0, alpha: 1)
        }
    }
}
