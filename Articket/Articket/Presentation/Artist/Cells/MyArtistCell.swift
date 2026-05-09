import UIKit
import SnapKit

final class MyArtistCell: UICollectionViewCell {
    static let reuseIdentifier = "MyArtistCell"

    private let avatarView = ArtistAvatarView(size: 80, showMusicBadge: true)

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        l.textAlignment = .center
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)

        avatarView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.size.equalTo(80)
        }
        nameLabel.snp.makeConstraints {
            $0.top.equalTo(avatarView.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarView.configure(urlString: nil)
        nameLabel.text = nil
    }

    func configure(with artist: Artist) {
        nameLabel.text = artist.name
        avatarView.configure(urlString: artist.avatarUrl)
    }
}
