import UIKit
import SnapKit

// MARK: - ConcertTabContentView
// Figma 1:2848 — 다가오는 티켓팅 + 지난 공연

final class ConcertTabContentView: UIView {

    private let mainStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 36
        return sv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(mainStack)
        mainStack.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(24)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func configure(detail: ArtistDetail) {
        mainStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // 다가오는 티켓팅
        let upcomingSection = UIStackView()
        upcomingSection.axis = .vertical
        upcomingSection.spacing = 20

        let upcomingHeader = SectionHeaderRowView(title: "다가오는 티켓팅",
                                                  iconName: "calendar",
                                                  accessoryTitle: "더보기")
        upcomingSection.addArrangedSubview(upcomingHeader)

        if let ticketing = detail.upcomingTicketing {
            let card = TicketingCardView()
            card.configure(with: ticketing)
            upcomingSection.addArrangedSubview(card)
        }

        mainStack.addArrangedSubview(upcomingSection)

        // 지난 공연
        let pastSection = UIStackView()
        pastSection.axis = .vertical
        pastSection.spacing = 20

        let pastHeader = SectionHeaderRowView(title: "지난 공연", iconName: nil, accessoryTitle: nil)
        pastSection.addArrangedSubview(pastHeader)

        let concertsStack = UIStackView()
        concertsStack.axis = .vertical
        concertsStack.spacing = 16
        for concert in detail.pastConcerts {
            let row = PastConcertRowView()
            row.configure(with: concert)
            concertsStack.addArrangedSubview(row)
        }
        pastSection.addArrangedSubview(concertsStack)

        mainStack.addArrangedSubview(pastSection)

        // 하단 여백
        let spacer = UIView()
        spacer.snp.makeConstraints { $0.height.equalTo(36) }
        mainStack.addArrangedSubview(spacer)
    }
}

// MARK: - SectionHeaderRowView

private final class SectionHeaderRowView: UIView {

    init(title: String, iconName: String?, accessoryTitle: String?) {
        super.init(frame: .zero)

        let leftStack = UIStackView()
        leftStack.axis = .horizontal
        leftStack.spacing = 10
        leftStack.alignment = .center

        if let iconName = iconName {
            let icon = UIImageView(image: UIImage(systemName: iconName))
            icon.tintColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
            icon.snp.makeConstraints { $0.size.equalTo(20) }
            leftStack.addArrangedSubview(icon)
        }

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        leftStack.addArrangedSubview(titleLabel)

        addSubview(leftStack)
        leftStack.snp.makeConstraints { $0.leading.centerY.equalToSuperview() }

        if let accessoryTitle = accessoryTitle {
            let btn = UILabel()
            btn.text = accessoryTitle
            btn.font = .systemFont(ofSize: 12, weight: .medium)
            btn.textColor = UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1)
            addSubview(btn)
            btn.snp.makeConstraints { $0.trailing.centerY.equalToSuperview() }
        }

        snp.makeConstraints { $0.height.equalTo(27) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }
}

// MARK: - TicketingCardView
// Figma 1:2863 — 그라디언트 카드

private final class TicketingCardView: UIView {

    private let gradientLayer = CAGradientLayer()

    private let dDayBadgeView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1)
        v.layer.cornerRadius = 4
        return v
    }()

    private let dDayBadgeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 10, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()

    private let openLabel: UILabel = {
        let l = UILabel()
        l.text = "티켓팅 오픈"
        l.font = .systemFont(ofSize: 14, weight: .bold)
        l.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        return l
    }()

    private let concertTitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .bold)
        l.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        l.numberOfLines = 2
        return l
    }()

    private let ticketOpenInfoLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textColor = UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1)
        return l
    }()

    private let dateVenueInfoLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textColor = UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1)
        return l
    }()

    private let alarmButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("알림 설정", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1)
        b.layer.cornerRadius = 10
        return b
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    private func setupViews() {
        // gradient background
        gradientLayer.colors = [
            UIColor(red: 0.992, green: 0.949, blue: 0.973, alpha: 1).cgColor,
            UIColor(red: 1.000, green: 0.969, blue: 0.929, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.17, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.83, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)

        layer.cornerRadius = 8
        layer.borderColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1).cgColor
        layer.borderWidth = 2
        clipsToBounds = true

        // Badge row — UIView 래퍼로 px:8 패딩 구현 (UILabel에는 contentEdgeInsets 없음)
        dDayBadgeView.addSubview(dDayBadgeLabel)
        dDayBadgeLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(8)
        }
        dDayBadgeView.snp.makeConstraints { $0.height.equalTo(20) }

        let badgeRow = UIStackView(arrangedSubviews: [dDayBadgeView, openLabel])
        badgeRow.axis = .horizontal
        badgeRow.spacing = 8
        badgeRow.alignment = .center

        // Ticket open info row
        let calendarIcon = UIImageView(image: UIImage(systemName: "calendar"))
        calendarIcon.tintColor = UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1)
        calendarIcon.snp.makeConstraints { $0.size.equalTo(16) }
        let openRow = UIStackView(arrangedSubviews: [calendarIcon, ticketOpenInfoLabel])
        openRow.axis = .horizontal
        openRow.spacing = 8
        openRow.alignment = .center

        // Date/venue row
        let venueIcon = UIImageView(image: UIImage(systemName: "mappin"))
        venueIcon.tintColor = UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1)
        venueIcon.snp.makeConstraints { $0.size.equalTo(16) }
        let venueRow = UIStackView(arrangedSubviews: [venueIcon, dateVenueInfoLabel])
        venueRow.axis = .horizontal
        venueRow.spacing = 8
        venueRow.alignment = .center

        let infoStack = UIStackView(arrangedSubviews: [openRow, venueRow])
        infoStack.axis = .vertical
        infoStack.spacing = 8

        let mainStack = UIStackView(arrangedSubviews: [badgeRow, concertTitleLabel, infoStack, alarmButton])
        mainStack.axis = .vertical
        mainStack.spacing = 16

        alarmButton.snp.makeConstraints { $0.height.equalTo(37) }

        addSubview(mainStack)
        mainStack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(20)
        }
    }

    func configure(with ticketing: UpcomingTicketing) {
        dDayBadgeLabel.text = ticketing.dDay
        concertTitleLabel.text = ticketing.concertTitle
        ticketOpenInfoLabel.text = ticketing.ticketOpenInfo
        dateVenueInfoLabel.text = ticketing.dateVenueInfo
    }
}

// MARK: - PastConcertRowView
// Figma I1:2904 — 96pt 썸네일 + 제목/날짜/장소

private final class PastConcertRowView: UIView {

    private let thumbnailView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1)
        v.layer.cornerRadius = 4
        v.clipsToBounds = true
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .bold)
        l.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        l.numberOfLines = 2
        return l
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        return l
    }()

    private let venueLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        l.lineBreakMode = .byTruncatingTail
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, dateLabel, venueLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let row = UIStackView(arrangedSubviews: [thumbnailView, textStack])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center

        thumbnailView.snp.makeConstraints { $0.size.equalTo(96) }

        addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func configure(with concert: PastConcert) {
        titleLabel.text = concert.title
        dateLabel.text = concert.dateRange
        venueLabel.text = concert.venueName
    }
}
