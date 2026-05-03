import UIKit
import SnapKit

final class PopularArtistCell: UICollectionViewCell {
    static let reuseIdentifier = "PopularArtistCell"

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1)
        iv.layer.cornerRadius = 4
        iv.clipsToBounds = true
        return iv
    }()

    private let overlayView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.15)
        return v
    }()

    private let badgeView = BadgePillView()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .bold)
        l.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        l.textAlignment = .center
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.addSubview(overlayView)
        imageView.addSubview(badgeView)
        contentView.addSubview(nameLabel)

        imageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.size.equalTo(128)
        }
        overlayView.snp.makeConstraints { $0.edges.equalToSuperview() }
        badgeView.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(8)
        }
        nameLabel.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func configure(with artist: PopularArtist) {
        badgeView.configure(text: artist.badge)
        nameLabel.text = artist.name
        imageView.loadImage(urlString: artist.imageUrl)
    }
}
