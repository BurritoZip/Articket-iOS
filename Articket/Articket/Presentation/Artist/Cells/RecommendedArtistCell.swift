import UIKit
import SnapKit

final class RecommendedArtistCell: UICollectionViewCell {
    static let reuseIdentifier = "RecommendedArtistCell"

    var onFollowTapped: ((UUID) -> Void)?
    private var artistId: UUID?

    private let avatarView = ArtistAvatarView(size: 64, showMusicBadge: false)

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .bold)
        l.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
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

    private let followButton = FollowButton()

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

    override func prepareForReuse() {
        super.prepareForReuse()
        onFollowTapped = nil
        artistId = nil
        nameLabel.text = nil
        followersLabel.text = nil
        followersLabel.isHidden = false
        eventCountLabel.text = nil
        avatarView.configure(urlString: nil)
        followButton.setFollowing(false)
    }

    func configure(with artist: Artist) {
        artistId = artist.id
        nameLabel.text = artist.name
        avatarView.configure(urlString: artist.avatarUrl)

        if artist.followersCount > 0 {
            let followers = artist.followersCount >= 1000
                ? String(format: "팔로워 %gK", Double(artist.followersCount) / 1000)
                : "팔로워 \(artist.followersCount)"
            followersLabel.text = followers
            followersLabel.isHidden = false
        } else {
            followersLabel.isHidden = true
        }
        eventCountLabel.text = "공연 \(artist.upcomingEventCount)개"
        followButton.setFollowing(artist.isFollowing)
    }

    @objc private func followTapped() {
        guard let id = artistId else { return }
        onFollowTapped?(id)
    }
}
