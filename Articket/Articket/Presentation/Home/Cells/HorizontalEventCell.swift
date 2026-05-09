import UIKit
import SnapKit

// 새로 시작된 공연 / 곧 종료되는 공연 cell
// Layout: 96×96pt square image on LEFT, [title / date / venue] stacked on RIGHT.
final class HorizontalEventCell: UICollectionViewCell {
    static let reuseIdentifier = "HorizontalEventCell"

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
        label.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)    // #333
        label.numberOfLines = 2
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)    // #999
        return label
    }()

    private let venueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)    // #999
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .white

        let textStack = UIStackView(arrangedSubviews: [titleLabel, dateLabel, venueLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        contentView.addSubview(imageView)
        contentView.addSubview(textStack)

        imageView.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.size.equalTo(96)
        }

        textStack.snp.makeConstraints {
            $0.leading.equalTo(imageView.snp.trailing).offset(12)
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.cancelImageLoad()
        imageView.image = nil
        titleLabel.text = nil
        dateLabel.text = nil
        venueLabel.text = nil
    }

    func configure(with event: Event) {
        titleLabel.text = event.title
        dateLabel.text = event.dateRangeString
        venueLabel.text = event.venueName
        imageView.loadImage(urlString: event.posterUrl)
    }
}
