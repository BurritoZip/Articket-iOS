import UIKit
import SnapKit

// MARK: - ConcertDetailHeaderView
// Figma 1:1659 — 공연 제목 + 상태 배지 + 메타 정보 + 관심/공유 버튼

final class ConcertDetailHeaderView: UIView {

    // MARK: - Views

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .bold)
        l.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        l.numberOfLines = 0
        return l
    }()

    private let statusBadgeView = ConcertStatusBadgeView()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1)
        return l
    }()

    private let venueIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "mappin"))
        iv.tintColor = UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1)
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let venueLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1)
        return l
    }()

    private let calendarIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "calendar"))
        iv.tintColor = UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1)
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1)
        return l
    }()

    private let heartButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "heart"), for: .normal)
        b.tintColor = UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1)
        return b
    }()

    private let shareButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        b.tintColor = UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1)
        return b
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Setup

    private func setupViews() {
        // Title row — title takes remaining space, badge fixed on right
        let titleRow = UIStackView(arrangedSubviews: [titleLabel, statusBadgeView])
        titleRow.axis = .horizontal
        titleRow.spacing = 8
        titleRow.alignment = .top

        // Venue row
        venueIcon.snp.makeConstraints { $0.size.equalTo(16) }
        let venueRow = UIStackView(arrangedSubviews: [venueIcon, venueLabel])
        venueRow.axis = .horizontal
        venueRow.spacing = 8
        venueRow.alignment = .center

        // Date row
        calendarIcon.snp.makeConstraints { $0.size.equalTo(16) }
        let dateRow = UIStackView(arrangedSubviews: [calendarIcon, dateLabel])
        dateRow.axis = .horizontal
        dateRow.spacing = 8
        dateRow.alignment = .center

        // Icon buttons (right-aligned)
        let iconStack = UIStackView(arrangedSubviews: [heartButton, shareButton])
        iconStack.axis = .horizontal
        iconStack.spacing = 4
        heartButton.snp.makeConstraints { $0.size.equalTo(28) }
        shareButton.snp.makeConstraints { $0.size.equalTo(28) }

        // Info row (venue + date left, icons right)
        let infoLeft = UIStackView(arrangedSubviews: [venueRow, dateRow])
        infoLeft.axis = .vertical
        infoLeft.spacing = 4

        let infoRow = UIStackView(arrangedSubviews: [infoLeft, iconStack])
        infoRow.axis = .horizontal
        infoRow.alignment = .bottom
        infoRow.distribution = .equalSpacing

        // Top block: title row + subtitle (4pt gap)
        let topBlock = UIStackView(arrangedSubviews: [titleRow, subtitleLabel])
        topBlock.axis = .vertical
        topBlock.spacing = 4

        // Main stack: topBlock then venue/date/icons (16pt gap)
        let mainStack = UIStackView(arrangedSubviews: [topBlock, infoRow])
        mainStack.axis = .vertical
        mainStack.spacing = 16

        addSubview(mainStack)
        mainStack.snp.makeConstraints {
            $0.top.equalToSuperview().inset(10)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(10)
        }
    }

    // MARK: - Configure

    func configure(with detail: ConcertDetail) {
        titleLabel.text = detail.title
        statusBadgeView.configure(status: detail.status)
        let parts = [detail.genre, detail.duration, detail.ageRestriction].filter { !$0.isEmpty }
        subtitleLabel.text = parts.joined(separator: " · ")
        subtitleLabel.isHidden = parts.isEmpty
        venueLabel.text = detail.venueName
        dateLabel.text = detail.dateRange
    }
}

// MARK: - ConcertStatusBadgeView
// 자체 layoutSubviews에서 gradient frame을 갱신해 UIStackView 내에서도 안정적으로 렌더링

private final class ConcertStatusBadgeView: UIView {

    private let label: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = .white
        return l
    }()

    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 8
        clipsToBounds = true

        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)

        addSubview(label)
        label.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(6)
            $0.leading.trailing.equalToSuperview().inset(12)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    func configure(status: ConcertStatus) {
        label.text = status.rawValue
        switch status {
        case .onSale:
            // Figma 1:1662 — #121212 → #333
            gradientLayer.colors = [
                UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1).cgColor,
                UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1).cgColor
            ]
        case .upcoming:
            gradientLayer.colors = [
                UIColor(red: 0.22, green: 0.33, blue: 0.80, alpha: 1).cgColor,
                UIColor(red: 0.30, green: 0.42, blue: 0.90, alpha: 1).cgColor
            ]
        case .ended:
            gradientLayer.colors = [
                UIColor(red: 0.50, green: 0.50, blue: 0.50, alpha: 1).cgColor,
                UIColor(red: 0.60, green: 0.60, blue: 0.60, alpha: 1).cgColor
            ]
        }
    }
}
