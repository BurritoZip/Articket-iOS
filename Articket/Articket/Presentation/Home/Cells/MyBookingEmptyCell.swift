import UIKit
import SnapKit

final class MyBookingEmptyCell: UICollectionViewCell {
    static let reuseIdentifier = "MyBookingEmptyCell"

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.976, green: 0.976, blue: 0.980, alpha: 1)
        v.layer.cornerRadius = 4
        v.layer.borderColor = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1).cgColor
        v.layer.borderWidth = 1
        return v
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "ticket"))
        iv.tintColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "예매한 공연이 없어요"
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        l.textAlignment = .center
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "공연을 예매하면 이곳에서 확인할 수 있어요"
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        l.textAlignment = .center
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(cardView)
        cardView.addSubview(iconView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(subtitleLabel)

        cardView.snp.makeConstraints { $0.edges.equalToSuperview() }
        iconView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().inset(28)
            $0.size.equalTo(32)
        }
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(iconView.snp.bottom).offset(12)
            $0.centerX.equalToSuperview()
        }
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().inset(28)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }
}
