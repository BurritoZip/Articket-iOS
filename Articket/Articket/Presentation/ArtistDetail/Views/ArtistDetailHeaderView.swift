import UIKit
import SnapKit

// MARK: - ArtistDetailHeaderView
// Figma 1:2822 — avatar + name + follow + stats

final class ArtistDetailHeaderView: UIView {

    var onFollowTapped: (() -> Void)?

    // MARK: Avatar

    private let avatarContainer: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 54
        v.layer.borderColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1).cgColor
        v.layer.borderWidth = 2
        v.clipsToBounds = true
        return v
    }()

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1)
        iv.layer.cornerRadius = 50
        iv.clipsToBounds = true
        return iv
    }()

    // MARK: Name

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 20, weight: .bold)
        l.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        return l
    }()

    // MARK: Follow Button

    private let followButton: UIButton = {
        let b = UIButton(type: .system)
        let icon = UIImage(systemName: "person.badge.plus")
        b.setImage(icon, for: .normal)
        b.setTitle("팔로우", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        b.tintColor = .white
        b.backgroundColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1)
        b.layer.cornerRadius = 16
        b.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
        return b
    }()

    // MARK: Stats

    private let statsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 24
        sv.alignment = .center
        return sv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    private func setupViews() {
        let outerStack = UIStackView()
        outerStack.axis = .vertical
        outerStack.alignment = .center
        outerStack.spacing = 12

        avatarContainer.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(100) }
        avatarContainer.snp.makeConstraints { $0.size.equalTo(108) }

        followButton.snp.makeConstraints { $0.width.equalTo(100); $0.height.equalTo(32) }

        outerStack.addArrangedSubview(avatarContainer)
        outerStack.addArrangedSubview(nameLabel)
        outerStack.addArrangedSubview(followButton)
        outerStack.addArrangedSubview(statsStack)

        addSubview(outerStack)
        outerStack.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(24)
            $0.centerX.equalToSuperview()
        }

        followButton.addTarget(self, action: #selector(followTapped), for: .touchUpInside)
    }

    func configure(with artist: Artist) {
        nameLabel.text = artist.name
        avatarImageView.loadImage(urlString: artist.avatarUrl)

        statsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        statsStack.addArrangedSubview(StatItemView(value: formatted(artist.followersCount), label: "팔로워"))
        statsStack.addArrangedSubview(StatItemView(value: "\(artist.upcomingEventCount)", label: "공연"))
    }

    private func formatted(_ count: Int) -> String {
        switch count {
        case 1_000_000...: return String(format: "%.1fM", Double(count) / 1_000_000)
        case 1_000...: return String(format: "%.1fK", Double(count) / 1_000)
        default: return "\(count)"
        }
    }

    @objc private func followTapped() { onFollowTapped?() }
}

// MARK: - StatItemView

private final class StatItemView: UIView {

    init(value: String, label: String) {
        super.init(frame: .zero)

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 16, weight: .bold)
        valueLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        valueLabel.textAlignment = .center

        let labelLabel = UILabel()
        labelLabel.text = label
        labelLabel.font = .systemFont(ofSize: 12, weight: .regular)
        labelLabel.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        labelLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [valueLabel, labelLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 0

        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }
}
