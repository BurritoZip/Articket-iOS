import UIKit
import SnapKit

final class SectionHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "SectionHeaderView"

    enum AccessoryKind {
        case seeMore
        case arrows
        case none
    }

    var onSeeMoreTapped: (() -> Void)?
    var onLeftArrowTapped: (() -> Void)?
    var onRightArrowTapped: (() -> Void)?

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = UIColor(red: 0.063, green: 0.094, blue: 0.157, alpha: 1)
        iv.isHidden = true
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = UIColor(red: 0.063, green: 0.094, blue: 0.157, alpha: 1)
        return label
    }()

    private let titleStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 6
        sv.alignment = .center
        return sv
    }()

    private let seeMoreButton: UIButton = {
        var config = UIButton.Configuration.plain()
        var titleAttr = AttributedString("더보기")
        titleAttr.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        config.attributedTitle = titleAttr
        config.baseForegroundColor = UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1)
        config.contentInsets = .zero
        let button = UIButton(configuration: config)
        button.isHidden = true
        return button
    }()

    private let leftArrowButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "arrow.left"), for: .normal)
        button.tintColor = UIColor(red: 0.063, green: 0.094, blue: 0.157, alpha: 1)
        button.isHidden = true
        return button
    }()

    private let rightArrowButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "arrow.right"), for: .normal)
        button.tintColor = UIColor(red: 0.063, green: 0.094, blue: 0.157, alpha: 1)
        button.isHidden = true
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupLayout()
        seeMoreButton.addTarget(self, action: #selector(seeMoreTapped), for: .touchUpInside)
        leftArrowButton.addTarget(self, action: #selector(leftArrowTapped), for: .touchUpInside)
        rightArrowButton.addTarget(self, action: #selector(rightArrowTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func prepareForReuse() {
        super.prepareForReuse()
        onSeeMoreTapped = nil
        onLeftArrowTapped = nil
        onRightArrowTapped = nil
        seeMoreButton.isHidden = true
        leftArrowButton.isHidden = true
        rightArrowButton.isHidden = true
        iconImageView.isHidden = true
        iconImageView.image = nil
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
    }

    func configure(title: String, accessory: AccessoryKind, icon: UIImage? = nil, fontSize: CGFloat = 20) {
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: fontSize, weight: .bold)
        seeMoreButton.isHidden = accessory != .seeMore
        leftArrowButton.isHidden = accessory != .arrows
        rightArrowButton.isHidden = accessory != .arrows
        iconImageView.image = icon
        iconImageView.isHidden = icon == nil
    }

    private func setupLayout() {
        titleStack.addArrangedSubview(iconImageView)
        titleStack.addArrangedSubview(titleLabel)

        addSubview(titleStack)
        addSubview(seeMoreButton)
        addSubview(leftArrowButton)
        addSubview(rightArrowButton)

        iconImageView.snp.makeConstraints { $0.size.equalTo(20) }

        titleStack.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
        }

        seeMoreButton.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
        }

        rightArrowButton.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
        }

        leftArrowButton.snp.makeConstraints {
            $0.trailing.equalTo(rightArrowButton.snp.leading).offset(-12)
            $0.centerY.equalToSuperview()
        }
    }

    @objc private func seeMoreTapped() { onSeeMoreTapped?() }
    @objc private func leftArrowTapped() { onLeftArrowTapped?() }
    @objc private func rightArrowTapped() { onRightArrowTapped?() }
}
