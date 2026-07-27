import UIKit
import SnapKit

final class ShortcutCell: UICollectionViewCell {
    static let reuseIdentifier = "ShortcutCell"

    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1).cgColor,
            UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1).cgColor
        ]
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 1, y: 1)
        layer.cornerRadius = 8
        return layer
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .scaled(12, weight: .medium, textStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 8
        contentView.layer.insertSublayer(gradientLayer, at: 0)
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)

        iconView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-10)
            $0.size.equalTo(24)
        }

        titleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(iconView.snp.bottom).offset(6)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = contentView.bounds
    }

    func configure(with item: ShortcutItem) {
        iconView.image = UIImage(systemName: item.iconSystemName)
        titleLabel.text = item.rawValue
    }
}
