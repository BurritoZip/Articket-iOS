import UIKit
import SnapKit

final class UpcomingEventCell: UICollectionViewCell {
    static let reuseIdentifier = "UpcomingEventCell"

    private let dDayBadge: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .bold)
        label.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)         // #333
        label.backgroundColor = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1) // #e5e7eb
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)         // #333
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let infoLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)         // #333
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 8
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor(red: 0.90, green: 0.91, blue: 0.92, alpha: 1).cgColor

        // Row 1: badge + title side by side
        let badgeRow = UIStackView(arrangedSubviews: [dDayBadge, titleLabel])
        badgeRow.axis = .horizontal
        badgeRow.spacing = 8
        badgeRow.alignment = .center

        // Main stack: badgeRow on top, info below
        let mainStack = UIStackView(arrangedSubviews: [badgeRow, infoLabel])
        mainStack.axis = .vertical
        mainStack.spacing = 8

        contentView.addSubview(mainStack)

        dDayBadge.snp.makeConstraints {
            $0.width.equalTo(40)
            $0.height.equalTo(20)
        }

        mainStack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(16)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func prepareForReuse() {
        super.prepareForReuse()
        dDayBadge.text = nil
        titleLabel.text = nil
        infoLabel.text = nil
    }

    func configure(with event: Event) {
        dDayBadge.text = event.dDayString
        titleLabel.text = event.title
        infoLabel.text = "\(event.dateRangeString)  ·  \(event.venueName)"
    }
}
