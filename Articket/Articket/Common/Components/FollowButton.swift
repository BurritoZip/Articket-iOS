import UIKit

// 팔로우/팔로잉 전환 버튼. RecommendedArtistCell에서 사용.
final class FollowButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        var config = UIButton.Configuration.filled()
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12)
        configuration = config
        layer.cornerRadius = 100
        clipsToBounds = true
        setFollowing(false)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func setFollowing(_ isFollowing: Bool) {
        var config = configuration ?? UIButton.Configuration.filled()
        config.baseBackgroundColor = isFollowing
            ? UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1)
            : UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        config.baseForegroundColor = isFollowing
            ? UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
            : .white
        var titleAttr = AttributedString(isFollowing ? "팔로잉" : "팔로우")
        titleAttr.font = .systemFont(ofSize: 11, weight: .medium)
        config.attributedTitle = titleAttr
        configuration = config
    }
}
