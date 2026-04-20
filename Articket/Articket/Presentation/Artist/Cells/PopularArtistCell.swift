import UIKit
import SnapKit

// MARK: - PopularArtistCell
// Figma 1:212: 128x128pt 이미지 + 좌상단 배지 + 하단 아티스트명

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

    // 흰색 오버레이 15% opacity
    private let overlayView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.15)
        return v
    }()

    // 좌상단 배지: "티켓팅 오픈" 등
    private let badgeLabel: BadgePillLabel = {
        let l = BadgePillLabel()
        l.font = .systemFont(ofSize: 10, weight: .bold)
        l.textColor = .white
        l.backgroundColor = UIColor(white: 0, alpha: 0.8)
        l.layer.cornerRadius = 100
        l.clipsToBounds = true
        return l
    }()

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
        imageView.addSubview(badgeLabel)
        contentView.addSubview(nameLabel)

        imageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.size.equalTo(128)
        }
        overlayView.snp.makeConstraints { $0.edges.equalToSuperview() }
        badgeLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(8)
        }
        nameLabel.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func configure(with artist: PopularArtist) {
        badgeLabel.text = artist.badge
        nameLabel.text = artist.name
    }
}

// MARK: - BadgePillLabel
// px:8 py:4 패딩, radius:100

private final class BadgePillLabel: UILabel {
    private let insets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let base = super.intrinsicContentSize
        return CGSize(width: base.width + insets.left + insets.right,
                      height: base.height + insets.top + insets.bottom)
    }
}
