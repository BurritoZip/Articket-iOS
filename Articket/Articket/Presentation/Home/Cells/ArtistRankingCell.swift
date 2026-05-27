import UIKit
import SnapKit

final class ArtistRankingCell: UICollectionViewCell {
    static let reuseIdentifier = "ArtistRankingCell"

    var onToggleExpansion: (() -> Void)?
    var onArtistTapped: (() -> Void)?

    private let rankLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .bold)
        l.textColor = UIColor(red: 0.063, green: 0.094, blue: 0.157, alpha: 1)
        l.textAlignment = .center
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        return l
    }()

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        iv.layer.cornerRadius = 30
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.textColor = UIColor(red: 0.063, green: 0.094, blue: 0.157, alpha: 1)
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        return l
    }()

    private let countLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textColor = UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1)
        return l
    }()

    private let chevronButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        btn.tintColor = UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1)
        return btn
    }()

    private let posterScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.isHidden = true
        sv.isDirectionalLockEnabled = true
        return sv
    }()

    private let posterStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 8
        sv.alignment = .fill
        return sv
    }()

    private let separatorView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.941, green: 0.941, blue: 0.941, alpha: 1)
        return v
    }()

    private var posterScrollHeightConstraint: Constraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(rankLabel)
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(countLabel)
        contentView.addSubview(chevronButton)
        contentView.addSubview(posterScrollView)
        posterScrollView.addSubview(posterStackView)
        contentView.addSubview(separatorView)
        setupLayout()

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        contentView.addGestureRecognizer(tap)
        chevronButton.addTarget(self, action: #selector(chevronTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.cancelImageLoad()
        avatarImageView.image = nil
        nameLabel.text = nil
        countLabel.text = nil
        rankLabel.text = nil
        posterStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        posterScrollView.isHidden = true
        posterScrollHeightConstraint.update(offset: 0)
        onToggleExpansion = nil
        onArtistTapped = nil
    }

    private func setupLayout() {
        rankLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalTo(avatarImageView)
            $0.width.equalTo(24)
        }

        avatarImageView.snp.makeConstraints {
            $0.leading.equalTo(rankLabel.snp.trailing).offset(12)
            $0.top.equalToSuperview().inset(12)
            $0.size.equalTo(60)
        }

        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(avatarImageView.snp.trailing).offset(12)
            $0.top.equalTo(avatarImageView).offset(8)
            $0.trailing.lessThanOrEqualTo(chevronButton.snp.leading).offset(-8)
        }

        countLabel.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.top.equalTo(nameLabel.snp.bottom).offset(4)
        }

        chevronButton.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalTo(avatarImageView)
            $0.size.equalTo(24)
        }

        posterScrollView.snp.makeConstraints {
            $0.top.equalTo(avatarImageView.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            posterScrollHeightConstraint = $0.height.equalTo(0).constraint
        }

        posterStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalToSuperview()
        }

        separatorView.snp.makeConstraints {
            $0.top.equalTo(posterScrollView.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(1)
            $0.bottom.equalToSuperview()
        }
    }

    func configure(with entry: ArtistRankEntry) {
        rankLabel.text = "\(entry.rank)"
        nameLabel.text = entry.name
        countLabel.text = "올해 관람횟수 : \(entry.viewCount)"

        avatarImageView.loadImage(urlString: entry.avatarUrl)

        let isExpanded = entry.isExpanded
        posterScrollView.isHidden = !isExpanded
        posterScrollHeightConstraint.update(offset: isExpanded ? 112 : 0)

        let chevronName = isExpanded ? "chevron.up" : "chevron.down"
        chevronButton.setImage(UIImage(systemName: chevronName), for: .normal)

        if isExpanded {
            buildPosterThumbnails(urls: entry.posterUrls)
        }
    }

    private func buildPosterThumbnails(urls: [String]) {
        posterStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for url in urls {
            let iv = UIImageView()
            iv.contentMode = .scaleAspectFill
            iv.clipsToBounds = true
            iv.layer.cornerRadius = 6
            iv.snp.makeConstraints { $0.width.equalTo(80) }
            iv.loadImage(urlString: url)
            posterStackView.addArrangedSubview(iv)
        }
    }

    @objc private func handleTap() {
        onArtistTapped?()
    }

    @objc private func chevronTapped() {
        onToggleExpansion?()
    }
}
