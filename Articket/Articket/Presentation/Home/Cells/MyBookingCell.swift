import UIKit
import SnapKit

final class MyBookingCell: UICollectionViewCell {
    static let reuseIdentifier = "MyBookingCell"

    // MARK: - Card container
    // Figma: white bg, 1.5pt #121212 border, 4pt radius
    // Shadow: 0px 1px 3px rgba(0,0,0,0.1), 0px 1px 2px rgba(0,0,0,0.1)
    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 4
        v.layer.borderColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1).cgColor
        v.layer.borderWidth = 1.5
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.1
        v.layer.shadowOffset = CGSize(width: 0, height: 1)
        v.layer.shadowRadius = 2
        return v
    }()

    // MARK: - Badge row
    // Figma 1:1385: D-day — bg #121212, white 10pt bold, px:8 py:2, radius:4
    private let dDayBadge: BadgeLabel = {
        let l = BadgeLabel(insets: UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8))
        l.font = .systemFont(ofSize: 10, weight: .bold)
        l.textColor = .white
        l.backgroundColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1)
        l.layer.cornerRadius = 4
        l.clipsToBounds = true
        return l
    }()

    // Figma 1:1387: 배송완료 — colored bg, 10pt medium, px:8 py:2, radius:4
    private let deliveryBadge: BadgeLabel = {
        let l = BadgeLabel(insets: UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8))
        l.font = .systemFont(ofSize: 10, weight: .medium)
        l.layer.cornerRadius = 4
        l.clipsToBounds = true
        return l
    }()

    private let badgeStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 8
        sv.alignment = .center
        return sv
    }()

    // MARK: - Title
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .bold)
        l.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)  // #333
        l.numberOfLines = 2
        return l
    }()

    // MARK: - Info rows
    private let dateRow = BookingInfoRow(iconName: "calendar")
    private let venueRow = BookingInfoRow(iconName: "location")
    private let seatRow = BookingInfoRow(iconName: "ticket")

    private let infoStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 6
        return sv
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(cardView)
        cardView.addSubview(badgeStack)
        badgeStack.addArrangedSubview(dDayBadge)
        badgeStack.addArrangedSubview(deliveryBadge)
        cardView.addSubview(titleLabel)
        infoStack.addArrangedSubview(dateRow)
        infoStack.addArrangedSubview(venueRow)
        infoStack.addArrangedSubview(seatRow)
        cardView.addSubview(infoStack)
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    private func setupLayout() {
        cardView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        badgeStack.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(20)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(badgeStack.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        infoStack.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(20)
        }
    }

    // MARK: - Configure

    func configure(with booking: Booking) {
        dDayBadge.text = booking.dDayString
        titleLabel.text = booking.title
        dateRow.setText(booking.formattedDate)
        venueRow.setText(booking.venueName)
        seatRow.setText(booking.seat)

        switch booking.deliveryType {
        case .delivery:
            deliveryBadge.text = "배송완료"
            deliveryBadge.textColor = UIColor(red: 0, green: 0.298, blue: 0.510, alpha: 1)
            deliveryBadge.backgroundColor = UIColor(red: 0.851, green: 0.937, blue: 1, alpha: 1)
        case .onsite:
            deliveryBadge.text = "현장수령"
            deliveryBadge.textColor = UIColor(red: 0, green: 0.510, blue: 0.212, alpha: 1)
            deliveryBadge.backgroundColor = UIColor(red: 0.851, green: 1, blue: 0.914, alpha: 1)
        }
    }
}

// MARK: - BadgeLabel
// drawText override로 UIEdgeInsets 기반 내부 패딩을 적용하는 UILabel 서브클래스

private final class BadgeLabel: UILabel {
    private let insets: UIEdgeInsets

    init(insets: UIEdgeInsets) {
        self.insets = insets
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let base = super.intrinsicContentSize
        return CGSize(
            width: base.width + insets.left + insets.right,
            height: base.height + insets.top + insets.bottom
        )
    }
}

// MARK: - BookingInfoRow

private final class BookingInfoRow: UIView {
    private let iconView: UIImageView
    private let textLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textColor = UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1)  // #767676
        return l
    }()

    init(iconName: String) {
        iconView = UIImageView(image: UIImage(systemName: iconName))
        iconView.tintColor = UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1)
        iconView.contentMode = .scaleAspectFit
        super.init(frame: .zero)
        addSubview(iconView)
        addSubview(textLabel)

        iconView.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
            $0.size.equalTo(16)
        }
        textLabel.snp.makeConstraints {
            $0.leading.equalTo(iconView.snp.trailing).offset(8)
            $0.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualToSuperview()
            $0.top.bottom.equalToSuperview()
        }
        textLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func setText(_ text: String) { textLabel.text = text }
}
