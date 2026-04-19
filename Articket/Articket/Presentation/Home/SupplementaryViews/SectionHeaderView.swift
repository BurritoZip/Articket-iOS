import UIKit
import SnapKit

// MARK: - Layout constants (apply to all section headers across the home screen)
// ALL section titles must have leading 20pt from the screen edge.
// "더보기" button: 12pt medium, vertically centered with title.
// Section-to-section spacing: 36pt (applied via contentInsets.bottom in the layout factory).

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

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = UIColor(red: 0.063, green: 0.094, blue: 0.157, alpha: 1) // #101828
        return label
    }()

    private let seeMoreButton: UIButton = {
        var config = UIButton.Configuration.plain()
        var titleAttr = AttributedString("더보기")
        titleAttr.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        config.attributedTitle = titleAttr
        config.baseForegroundColor = UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1) // #767676
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
    }

    func configure(title: String, accessory: AccessoryKind) {
        titleLabel.text = title
        seeMoreButton.isHidden = accessory != .seeMore
        leftArrowButton.isHidden = accessory != .arrows
        rightArrowButton.isHidden = accessory != .arrows
    }

    private func setupLayout() {
        addSubview(titleLabel)
        addSubview(seeMoreButton)
        addSubview(leftArrowButton)
        addSubview(rightArrowButton)

        // Leading 20pt is required for ALL section titles on the home screen.
        titleLabel.snp.makeConstraints {
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
