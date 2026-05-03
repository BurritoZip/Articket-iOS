import UIKit
import SnapKit

final class InterestedEventCell: UICollectionViewCell {
    static let reuseIdentifier = "InterestedEventCell"

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .tcSurface
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1) // #333333
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .tcTextSecondary
        return label
    }()

    private let venueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .tcTextSecondary
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        let textStack = UIStackView(arrangedSubviews: [titleLabel, dateLabel, venueLabel])
        textStack.axis = .vertical
        textStack.spacing = 1

        contentView.addSubview(imageView)
        contentView.addSubview(textStack)

        imageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(imageView.snp.width).multipliedBy(1.41)
        }

        textStack.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func configure(with event: Event) {
        titleLabel.text = event.title
        dateLabel.text = event.dateRangeString
        venueLabel.text = event.venueName
        imageView.loadImage(urlString: event.posterUrl)
    }
}
