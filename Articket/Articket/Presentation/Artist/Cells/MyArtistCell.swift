import UIKit
import SnapKit

// MARK: - MyArtistCell
// Figma 1:195: 80pt 원형 아바타 + 2pt #121212 border + 우하단 24pt 음표 배지 + 12pt 이름

final class MyArtistCell: UICollectionViewCell {
    static let reuseIdentifier = "MyArtistCell"

    private let avatarContainer: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 40
        v.layer.borderColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1).cgColor
        v.layer.borderWidth = 2
        v.clipsToBounds = true
        return v
    }()

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 38
        return iv
    }()

    // 우하단 배지: 음표 아이콘 24pt
    private let badgeView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1)
        v.layer.cornerRadius = 12
        v.layer.borderColor = UIColor.white.cgColor
        v.layer.borderWidth = 2
        return v
    }()

    private let badgeIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "music.note"))
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        l.textAlignment = .center
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(avatarContainer)
        avatarContainer.addSubview(avatarImageView)
        contentView.addSubview(badgeView)
        badgeView.addSubview(badgeIcon)
        contentView.addSubview(nameLabel)

        avatarContainer.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.size.equalTo(80)
        }
        avatarImageView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(2)
        }
        badgeView.snp.makeConstraints {
            $0.trailing.bottom.equalTo(avatarContainer)
            $0.size.equalTo(24)
        }
        badgeIcon.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(12)
        }
        nameLabel.snp.makeConstraints {
            $0.top.equalTo(avatarContainer.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func configure(with artist: Artist) {
        nameLabel.text = artist.name
    }
}
