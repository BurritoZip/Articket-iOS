import UIKit
import SnapKit

// MARK: - RecommendedArtistCell
// Figma 1:2678: 64pt circle + 이름/팔로워/공연수 + "팔로우" 버튼
// 전체: white bg, border 1pt #e5e7eb, radius 4, height 90pt

final class RecommendedArtistCell: UICollectionViewCell {
    static let reuseIdentifier = "RecommendedArtistCell"

    var onFollowTapped: ((UUID) -> Void)?
    private var artistId: UUID?

    private let avatarView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1)
        iv.layer.cornerRadius = 32
        iv.clipsToBounds = true
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .bold)
        l.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        return l
    }()

    private let followersLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        return l
    }()

    private let eventCountLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1)
        return l
    }()

    private let infoStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 12
        sv.alignment = .center
        return sv
    }()

    private let followButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12)
        var titleAttr = AttributedString("팔로우")
        titleAttr.font = .systemFont(ofSize: 11, weight: .medium)
        config.attributedTitle = titleAttr
        let b = UIButton(configuration: config)
        b.layer.cornerRadius = 100
        b.clipsToBounds = true
        return b
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 4
        contentView.layer.borderColor = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1).cgColor
        contentView.layer.borderWidth = 1

        infoStack.addArrangedSubview(followersLabel)
        infoStack.addArrangedSubview(eventCountLabel)

        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(infoStack)
        contentView.addSubview(followButton)

        avatarView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(17)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(64)
        }
        nameLabel.snp.makeConstraints {
            $0.top.equalTo(avatarView).offset(6)
            $0.leading.equalTo(avatarView.snp.trailing).offset(16)
            $0.trailing.lessThanOrEqualTo(followButton.snp.leading).offset(-12)
        }
        infoStack.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(4)
            $0.leading.equalTo(nameLabel)
        }
        followButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(17)
            $0.centerY.equalToSuperview()
        }

        followButton.addTarget(self, action: #selector(followTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func configure(with artist: Artist) {
        artistId = artist.id
        nameLabel.text = artist.name

        let followers = artist.followersCount >= 1000
            ? String(format: "팔로워 %gK", Double(artist.followersCount) / 1000)
            : "팔로워 \(artist.followersCount)"
        followersLabel.text = followers
        eventCountLabel.text = "공연 \(artist.upcomingEventCount)개"

        var config = followButton.configuration ?? UIButton.Configuration.filled()
        config.baseBackgroundColor = artist.isFollowing
            ? UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1)
            : UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        config.baseForegroundColor = artist.isFollowing
            ? UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
            : .white
        var titleAttr = AttributedString(artist.isFollowing ? "팔로잉" : "팔로우")
        titleAttr.font = .systemFont(ofSize: 11, weight: .medium)
        config.attributedTitle = titleAttr
        followButton.configuration = config
    }

    @objc private func followTapped() {
        guard let id = artistId else { return }
        onFollowTapped?(id)
    }
}
