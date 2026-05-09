import UIKit
import SnapKit

final class MyArtistSectionView: UIView {

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "내 아티스트"
        l.font = .systemFont(ofSize: 20, weight: .bold)
        l.textColor = UIColor(hex: "#333333")
        return l
    }()

    private let scrollView: UIScrollView = {
        let s = UIScrollView()
        s.showsHorizontalScrollIndicator = false
        return s
    }()
    private let stackView: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 16
        s.alignment = .center
        return s
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        addSubview(scrollView)
        scrollView.addSubview(stackView)

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.equalToSuperview().inset(20)
        }
        scrollView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.height.equalTo(112)
        }
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalToSuperview()
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(artists: [Artist]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let leadingSpace = UIView()
        leadingSpace.snp.makeConstraints { $0.width.equalTo(20) }
        stackView.addArrangedSubview(leadingSpace)

        artists.forEach { artist in
            let item = ArtistAvatarItemView()
            item.configure(name: artist.name, urlString: artist.avatarUrl)
            stackView.addArrangedSubview(item)
        }

        let trailingSpace = UIView()
        trailingSpace.snp.makeConstraints { $0.width.equalTo(20) }
        stackView.addArrangedSubview(trailingSpace)
    }
}

// MARK: - ArtistAvatarItemView

private final class ArtistAvatarItemView: UIView {

    private let avatarContainer: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 40
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor(hex: "#121212").cgColor
        v.clipsToBounds = true
        return v
    }()
    private let avatarImage: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(hex: "#E5E7EB")
        return iv
    }()
    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = UIColor(hex: "#333333")
        l.textAlignment = .center
        l.numberOfLines = 1
        return l
    }()
    private let followBadge: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#121212")
        v.layer.cornerRadius = 12
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor.white.cgColor
        v.isUserInteractionEnabled = false
        return v
    }()
    private let plusIcon: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 9, weight: .bold)
        iv.image = UIImage(systemName: "plus", withConfiguration: config)
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(avatarContainer)
        avatarContainer.addSubview(avatarImage)
        addSubview(nameLabel)
        addSubview(followBadge)
        followBadge.addSubview(plusIcon)

        snp.makeConstraints { $0.width.equalTo(80) }
        avatarContainer.snp.makeConstraints {
            $0.top.centerX.equalToSuperview()
            $0.size.equalTo(80)
        }
        avatarImage.snp.makeConstraints { $0.edges.equalToSuperview().inset(2) }
        avatarImage.layer.cornerRadius = 37
        nameLabel.snp.makeConstraints {
            $0.top.equalTo(avatarContainer.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
        // Figma: absolute left-[56px] top-[56px] size-[24px] within 80px container → trailing/bottom aligned
        followBadge.snp.makeConstraints {
            $0.trailing.bottom.equalTo(avatarContainer)
            $0.size.equalTo(24)
        }
        plusIcon.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(10)
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(name: String, urlString: String?) {
        nameLabel.text = name
        avatarImage.loadImage(urlString: urlString)
    }
}
