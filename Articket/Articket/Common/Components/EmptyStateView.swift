import UIKit
import SnapKit

final class EmptyStateView: UIView {

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = UIColor(hex: "#9CA3AF")
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .scaled(16, weight: .bold, textStyle: .headline)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(hex: "#374151")
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .scaled(13, textStyle: .footnote)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(hex: "#9CA3AF")
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private let actionButton: UIButton = {
        let b = UIButton(type: .system)
        b.titleLabel?.font = .scaled(14, weight: .medium, textStyle: .subheadline)
        b.titleLabel?.adjustsFontForContentSizeCategory = true
        b.setTitleColor(UIColor(hex: "#374151"), for: .normal)
        b.backgroundColor = UIColor(hex: "#F3F4F6")
        b.layer.cornerRadius = 8
        b.contentEdgeInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20)
        return b
    }()

    private lazy var stack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [iconView, titleLabel, subtitleLabel, actionButton])
        sv.axis = .vertical
        sv.alignment = .center
        sv.spacing = 12
        return sv
    }()

    private var onButton: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(stack)
        stack.snp.makeConstraints { $0.center.equalToSuperview() }
        iconView.snp.makeConstraints { $0.size.equalTo(48) }
        actionButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func configure(
        icon: UIImage? = UIImage(systemName: "tray"),
        title: String,
        subtitle: String? = nil,
        buttonTitle: String? = nil,
        onButton: (() -> Void)? = nil
    ) {
        iconView.image = icon
        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle == nil
        actionButton.setTitle(buttonTitle, for: .normal)
        actionButton.isHidden = buttonTitle == nil
        self.onButton = onButton
    }

    @objc private func buttonTapped() {
        onButton?()
    }
}
