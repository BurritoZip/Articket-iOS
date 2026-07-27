import UIKit
import SnapKit

final class TimetableEventCell: UICollectionViewCell {

    static let reuseIdentifier = "TimetableEventCell"

    private let posterImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .tcSurface
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .scaled(14, weight: .bold, textStyle: .subheadline)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = .tcTextPrimary
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        return l
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .scaled(12, weight: .regular, textStyle: .caption1)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(hex: "#999999")
        return l
    }()

    private let venueLabel: UILabel = {
        let l = UILabel()
        l.font = .scaled(12, weight: .medium, textStyle: .caption1)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(hex: "#999999")
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        contentView.addSubview(posterImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(venueLabel)

        posterImageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(233)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(posterImageView.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
        }

        dateLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(2)
            $0.leading.trailing.equalToSuperview()
        }

        venueLabel.snp.makeConstraints {
            $0.top.equalTo(dateLabel.snp.bottom).offset(2)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().inset(8)
        }
    }

    func configure(with event: TimetableEvent) {
        titleLabel.text = event.title
        dateLabel.text = event.dateRange
        venueLabel.text = event.venueName

        if let url = event.posterUrl {
            posterImageView.loadPoster(urlString: url)
        } else {
            posterImageView.image = nil
            posterImageView.backgroundColor = .tcSurface
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        posterImageView.image = nil
        posterImageView.backgroundColor = .tcSurface
    }
}
