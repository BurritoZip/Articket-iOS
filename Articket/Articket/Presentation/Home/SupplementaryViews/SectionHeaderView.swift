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
        label.font = .scaled(20, weight: .bold, textStyle: .title3)
        label.adjustsFontForContentSizeCategory = true
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
        titleAttr.font = .scaled(12, weight: .medium, textStyle: .caption1)
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
        button.accessibilityLabel = "이전"
        button.isHidden = true
        return button
    }()

    private let rightArrowButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "arrow.right"), for: .normal)
        button.tintColor = UIColor(red: 0.063, green: 0.094, blue: 0.157, alpha: 1)
        button.accessibilityLabel = "다음"
        button.isHidden = true
        return button
    }()

    private let arrowsView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 12
        sv.alignment = .center
        return sv
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
        arrowsView.isHidden = true
        iconImageView.isHidden = true
        iconImageView.image = nil
        titleLabel.font = .scaled(20, weight: .bold, textStyle: .title3)
        titleLabel.adjustsFontForContentSizeCategory = true
    }

    func configure(title: String, accessory: AccessoryKind, icon: UIImage? = nil, fontSize: CGFloat = 20) {
        titleLabel.text = title
        // configure가 런타임에 폰트를 재지정하므로 여기서도 scaled로 둬야 Dynamic Type이 유지됨
        titleLabel.font = .scaled(fontSize, weight: .bold, textStyle: .title3)
        seeMoreButton.isHidden = accessory != .seeMore
        // arrowsView의 isHidden이 UIStackView collapse를 통해 leading 기준점을 trailing으로 밀어냄
        arrowsView.isHidden = accessory != .arrows
        leftArrowButton.isHidden = false
        rightArrowButton.isHidden = false
        iconImageView.image = icon
        iconImageView.isHidden = icon == nil
    }

    private func setupLayout() {
        arrowsView.addArrangedSubview(leftArrowButton)
        arrowsView.addArrangedSubview(rightArrowButton)

        titleStack.addArrangedSubview(iconImageView)
        titleStack.addArrangedSubview(titleLabel)

        // 제목은 공간이 부족하면 truncate, 액세서리는 항상 크기 유지
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        seeMoreButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        seeMoreButton.setContentHuggingPriority(.required, for: .horizontal)
        arrowsView.setContentCompressionResistancePriority(.required, for: .horizontal)
        arrowsView.setContentHuggingPriority(.required, for: .horizontal)

        addSubview(titleStack)
        addSubview(seeMoreButton)
        addSubview(arrowsView)

        iconImageView.snp.makeConstraints { $0.size.equalTo(20) }
        // 명시적 크기 지정 → trailing 기준점 계산이 확정적
        leftArrowButton.snp.makeConstraints { $0.size.equalTo(44) }
        rightArrowButton.snp.makeConstraints { $0.size.equalTo(44) }

        seeMoreButton.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
        }

        arrowsView.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
        }

        titleStack.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
            // 두 액세서리 모두 겹치지 않도록 — 더 촉박한 쪽이 실제 상한으로 작동
            $0.trailing.lessThanOrEqualTo(seeMoreButton.snp.leading).offset(-8)
            $0.trailing.lessThanOrEqualTo(arrowsView.snp.leading).offset(-8)
        }
    }

    @objc private func seeMoreTapped() { onSeeMoreTapped?() }
    @objc private func leftArrowTapped() { onLeftArrowTapped?() }
    @objc private func rightArrowTapped() { onRightArrowTapped?() }
}
