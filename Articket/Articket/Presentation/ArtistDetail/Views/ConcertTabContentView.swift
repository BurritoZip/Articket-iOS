import UIKit
import SnapKit

// MARK: - ConcertTabContentView
// Figma 1:2848 — 오픈 예정 + 지난 공연

final class ConcertTabContentView: UIView {

    var onConcertTapped: ((UUID, String?) -> Void)?
    var onMoreTapped: (() -> Void)?
    var onAlarmTapped: ((UpcomingTicketing) -> Void)?

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

        // 오픈 예정 티켓팅
        let upcomingSection = UIStackView()
        upcomingSection.axis = .vertical
        upcomingSection.spacing = 20

        let upcomingHeader = SectionHeaderRowView(title: "다가오는 티켓팅",
                                                  iconName: "ic_callender",
                                                  accessoryTitle: "더보기")
        upcomingHeader.onAccessoryTapped = { [weak self] in self?.onMoreTapped?() }
        upcomingSection.addArrangedSubview(upcomingHeader)

        if let ticketing = detail.upcomingTicketing {
            let card = TicketingCardView()
            card.configure(with: ticketing)
            card.onTapped = { [weak self] in self?.onConcertTapped?(ticketing.id, nil) }
            card.onAlarmTapped = { [weak self] in self?.onAlarmTapped?(ticketing) }
            upcomingSection.addArrangedSubview(card)
        } else {
            // 헤더만 남고 내용이 비던 문제 — 빈 상태 문구로 안내
            upcomingSection.addArrangedSubview(makeEmptyRow("예정된 티켓팅이 없어요"))
        }

        mainStack.addArrangedSubview(upcomingSection)

        // 지난 공연
        let pastSection = UIStackView()
        pastSection.axis = .vertical
        pastSection.spacing = 20

        let pastHeader = SectionHeaderRowView(title: "지난 공연", iconName: nil, accessoryTitle: nil)
        pastSection.addArrangedSubview(pastHeader)

        if detail.pastConcerts.isEmpty {
            pastSection.addArrangedSubview(makeEmptyRow("지난 공연이 없어요"))
        } else {
            let concertsStack = UIStackView()
            concertsStack.axis = .vertical
            concertsStack.spacing = 16
            for concert in detail.pastConcerts {
                let row = PastConcertRowView()
                row.configure(with: concert)
                row.onTapped = { [weak self] in self?.onConcertTapped?(concert.id, concert.imageUrl) }
                concertsStack.addArrangedSubview(row)
            }
            pastSection.addArrangedSubview(concertsStack)
        }

        mainStack.addArrangedSubview(pastSection)

        // 하단 여백
        let spacer = UIView()
        spacer.snp.makeConstraints { $0.height.equalTo(36) }
        mainStack.addArrangedSubview(spacer)
    }

    /// 섹션 헤더만 있고 내용이 비었을 때 표시하는 안내 행
    private func makeEmptyRow(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .scaled(13, textStyle: .footnote)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(hex: "#9CA3AF")
        return l
    }
}

// MARK: - SectionHeaderRowView

private final class SectionHeaderRowView: UIView {

    var onAccessoryTapped: (() -> Void)?

    init(title: String, iconName: String?, accessoryTitle: String?) {
        super.init(frame: .zero)

        let leftStack = UIStackView()
        leftStack.axis = .horizontal
        leftStack.spacing = 10
        leftStack.alignment = .center

        if let iconName = iconName {
            // 애셋 우선(원본 색 유지), 없으면 SF Symbol 폴백
            let image = UIImage(named: iconName)?.withRenderingMode(.alwaysTemplate)
                ?? UIImage(systemName: iconName)
            let icon = UIImageView(image: image)
            icon.tintColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
            icon.contentMode = .scaleAspectFit
            icon.snp.makeConstraints { $0.size.equalTo(20) }
            leftStack.addArrangedSubview(icon)
        }

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .scaled(20, weight: .bold, textStyle: .title3)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        leftStack.addArrangedSubview(titleLabel)

        addSubview(leftStack)
        leftStack.snp.makeConstraints { $0.leading.centerY.equalToSuperview() }

        if let accessoryTitle = accessoryTitle {
            let btn = UIButton(type: .system)
            btn.setTitle(accessoryTitle, for: .normal)
            btn.titleLabel?.font = .scaled(12, weight: .medium, textStyle: .caption1)
            btn.titleLabel?.adjustsFontForContentSizeCategory = true
            btn.setTitleColor(UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1), for: .normal)
            btn.addTarget(self, action: #selector(accessoryTapped), for: .touchUpInside)
            addSubview(btn)
            btn.snp.makeConstraints { $0.trailing.centerY.equalToSuperview() }
        }

        snp.makeConstraints { $0.height.equalTo(27) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    @objc private func accessoryTapped() { onAccessoryTapped?() }
}

// MARK: - TicketingCardView
// Figma 1:2863 — 그라디언트 카드

private final class TicketingCardView: UIView {

    var onTapped: (() -> Void)?
    var onAlarmTapped: (() -> Void)?

    private let gradientLayer = CAGradientLayer()

    private let dDayBadgeView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1)
        v.layer.cornerRadius = 4
        return v
    }()

    private let dDayBadgeLabel: UILabel = {
        let l = UILabel()
        l.font = .scaled(10, weight: .bold, textStyle: .caption2)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()

    private let openLabel: UILabel = {
        let l = UILabel()
        l.text = "티켓팅 오픈"
        l.font = .scaled(14, weight: .bold, textStyle: .subheadline)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        return l
    }()

    private let concertTitleLabel: UILabel = {
        let l = UILabel()
        l.font = .scaled(16, weight: .bold, textStyle: .headline)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        l.numberOfLines = 2
        return l
    }()

    private let ticketOpenInfoLabel: UILabel = {
        let l = UILabel()
        l.font = .scaled(13, weight: .regular, textStyle: .footnote)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1)
        return l
    }()

    private let dateVenueInfoLabel: UILabel = {
        let l = UILabel()
        l.font = .scaled(13, weight: .regular, textStyle: .footnote)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1)
        return l
    }()

    private let alarmButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("알림 설정", for: .normal)
        b.titleLabel?.font = .scaled(14, weight: .bold, textStyle: .subheadline)
        b.titleLabel?.adjustsFontForContentSizeCategory = true
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1)
        b.layer.cornerRadius = 10
        return b
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        isUserInteractionEnabled = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
        alarmButton.addTarget(self, action: #selector(alarmTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    @objc private func handleTap() { onTapped?() }
    @objc private func alarmTapped() { onAlarmTapped?() }

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

    var onTapped: (() -> Void)?

    private let thumbnailView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1)
        iv.layer.cornerRadius = 4
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .scaled(16, weight: .bold, textStyle: .headline)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        l.numberOfLines = 2
        return l
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .scaled(12, weight: .regular, textStyle: .caption1)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        return l
    }()

    private let venueLabel: UILabel = {
        let l = UILabel()
        l.font = .scaled(12, weight: .medium, textStyle: .caption1)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        l.lineBreakMode = .byTruncatingTail
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))

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

    @objc private func handleTap() { onTapped?() }

    func configure(with concert: PastConcert) {
        titleLabel.text = concert.title
        dateLabel.text = concert.dateRange
        venueLabel.text = concert.venueName
        thumbnailView.loadImage(urlString: concert.imageUrl)
    }
}
