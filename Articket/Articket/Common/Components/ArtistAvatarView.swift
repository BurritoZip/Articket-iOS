import UIKit
import SnapKit

// 원형 아티스트 이미지 뷰. MyArtistCell(size=80, badge=true 팔로우 하트), RecommendedArtistCell(size=64, badge=false) 공유.
final class ArtistAvatarView: UIView {

    private let ringView = UIView()
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        iv.clipsToBounds = true
        return iv
    }()

    init(size: CGFloat, showMusicBadge: Bool) {
        super.init(frame: .zero)
        clipsToBounds = false

        ringView.layer.cornerRadius = size / 2
        ringView.layer.borderColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1).cgColor
        ringView.layer.borderWidth = 2
        ringView.clipsToBounds = true
        imageView.layer.cornerRadius = (size - 4) / 2

        addSubview(ringView)
        ringView.addSubview(imageView)

        ringView.snp.makeConstraints { $0.edges.equalToSuperview() }
        imageView.snp.makeConstraints { $0.edges.equalToSuperview().inset(2) }

        if showMusicBadge {
            let badge = FollowHeartBadgeView()
            addSubview(badge)
            badge.snp.makeConstraints {
                $0.trailing.bottom.equalToSuperview()
                $0.size.equalTo(24)
            }
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func configure(urlString: String?) {
        imageView.loadImage(urlString: urlString)
    }
}

private final class FollowHeartBadgeView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1)
        layer.cornerRadius = 12
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 2

        // 팔로우한 아티스트 표시 — 하트 (Figma)
        let icon = UIImageView(image: UIImage(systemName: "heart.fill"))
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        addSubview(icon)
        icon.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(12)
        }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }
}
