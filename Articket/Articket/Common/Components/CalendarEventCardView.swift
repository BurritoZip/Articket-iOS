import UIKit
import SnapKit

// Figma 1:6144 PopupButtonCalender 기준

final class CalendarEventCardView: UIView {

    // MARK: - Header

    private let artistNameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .bold)
        return l
    }()

    private let dotView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 5
        return v
    }()

    private let categoryLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        return l
    }()

    private let categoryStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.alignment = .center
        sv.spacing = 4
        return sv
    }()

    private let headerTopRow: UIView = UIView()

    private let concertTitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 20, weight: .bold)
        l.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        return l
    }()

    private let headerSection = UIView()
    private let headerBorder: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1)
        return v
    }()

    // MARK: - Body

    private let infoRowsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 8
        return sv
    }()

    private let priceTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "티켓 가격"
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        return l
    }()

    private let priceListStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 2
        return sv
    }()

    private let priceSection: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 4
        return sv
    }()

    private let bodyStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 12
        return sv
    }()

    // MARK: - Footer

    private let footerBorder: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1)
        return v
    }()

    private let detailButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("상세보기", for: .normal)
        b.setTitleColor(UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1), for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        b.backgroundColor = UIColor(red: 0.953, green: 0.957, blue: 0.961, alpha: 1)
        return b
    }()

    private let footerDivider: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1)
        return v
    }()

    private let statusLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .medium)
        l.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        l.textAlignment = .center
        return l
    }()

    private let footerContainer = UIView()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    private func setupViews() {
        backgroundColor = .white
        layer.cornerRadius = 8
        layer.borderColor = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1).cgColor
        layer.borderWidth = 1

        // Header top row: artist(left) ← → dot+category(right)
        categoryStack.addArrangedSubview(dotView)
        categoryStack.addArrangedSubview(categoryLabel)

        headerTopRow.addSubview(artistNameLabel)
        headerTopRow.addSubview(categoryStack)
        artistNameLabel.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(categoryStack.snp.leading).offset(-8)
        }
        categoryStack.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
        }
        dotView.snp.makeConstraints { $0.size.equalTo(10) }

        // Header section
        headerSection.addSubview(headerTopRow)
        headerSection.addSubview(concertTitleLabel)
        headerTopRow.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(24)
        }
        concertTitleLabel.snp.makeConstraints {
            $0.top.equalTo(headerTopRow.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        // Body: info rows + price section
        priceSection.addArrangedSubview(priceTitleLabel)
        let priceListWrapper = UIView()
        priceListWrapper.addSubview(priceListStack)
        priceListStack.snp.makeConstraints {
            $0.top.bottom.trailing.equalToSuperview()
            $0.leading.equalToSuperview().inset(8)
        }
        priceSection.addArrangedSubview(priceListWrapper)

        bodyStack.addArrangedSubview(infoRowsStack)
        bodyStack.addArrangedSubview(priceSection)

        // Footer
        footerContainer.addSubview(detailButton)
        footerContainer.addSubview(footerDivider)
        footerContainer.addSubview(statusLabel)
        detailButton.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.trailing.equalTo(footerContainer.snp.centerX).offset(-0.5)
        }
        footerDivider.snp.makeConstraints {
            $0.centerX.top.bottom.equalToSuperview()
            $0.width.equalTo(1)
        }
        statusLabel.snp.makeConstraints {
            $0.leading.equalTo(footerContainer.snp.centerX).offset(0.5)
            $0.trailing.top.bottom.equalToSuperview()
        }

        // Add to self
        addSubview(headerSection)
        addSubview(headerBorder)
        addSubview(bodyStack)
        addSubview(footerBorder)
        addSubview(footerContainer)

        headerSection.snp.makeConstraints {
            $0.top.equalToSuperview().inset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        headerBorder.snp.makeConstraints {
            $0.top.equalTo(headerSection.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(1)
        }
        bodyStack.snp.makeConstraints {
            $0.top.equalTo(headerBorder.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        footerBorder.snp.makeConstraints {
            $0.top.equalTo(bodyStack.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(1)
        }
        footerContainer.snp.makeConstraints {
            $0.top.equalTo(footerBorder.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(44)
        }
    }

    // MARK: - Configure

    func configure(with event: CalendarEvent) {
        let (nameColor, dotColor) = eventColors(for: event.color)
        artistNameLabel.text = event.title
        artistNameLabel.textColor = nameColor
        dotView.backgroundColor = dotColor
        categoryLabel.text = event.eventCategory
        concertTitleLabel.text = event.concertTitle

        // Info rows
        infoRowsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        infoRowsStack.addArrangedSubview(InfoRowView(label: "일시", value: event.concertDate))
        infoRowsStack.addArrangedSubview(InfoRowView(label: "장소", value: event.venueName))
        infoRowsStack.addArrangedSubview(InfoRowView(label: "예매처", value: event.bookingPlatform))
        infoRowsStack.addArrangedSubview(InfoRowView(label: "티켓오픈", value: event.ticketOpenDate))

        // Ticket prices
        priceListStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for price in event.ticketPrices {
            let l = UILabel()
            l.text = "• \(price)"
            l.font = .systemFont(ofSize: 11, weight: .regular)
            l.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
            l.numberOfLines = 0
            priceListStack.addArrangedSubview(l)
        }

        statusLabel.text = event.bookingStatus.label
    }

    private func eventColors(for color: CalendarEventColor) -> (UIColor, UIColor) {
        switch color {
        case .green:
            return (UIColor(red: 0.000, green: 0.510, blue: 0.212, alpha: 1),
                    UIColor(red: 0.000, green: 0.788, blue: 0.314, alpha: 1))
        case .red:
            return (UIColor(red: 1.000, green: 0.278, blue: 0.337, alpha: 1),
                    UIColor(red: 1.000, green: 0.400, blue: 0.451, alpha: 1))
        case .yellow:
            return (UIColor(red: 0.976, green: 0.831, blue: 0.000, alpha: 1),
                    UIColor(red: 0.992, green: 0.941, blue: 0.408, alpha: 1))
        }
    }
}

// MARK: - InfoRowView

private final class InfoRowView: UIView {

    init(label: String, value: String) {
        super.init(frame: .zero)

        let labelView = UILabel()
        labelView.text = label
        labelView.font = .systemFont(ofSize: 12, weight: .medium)
        labelView.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 12, weight: .medium)
        valueLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        valueLabel.numberOfLines = 0

        addSubview(labelView)
        addSubview(valueLabel)

        labelView.snp.makeConstraints {
            $0.leading.top.equalToSuperview()
            $0.width.equalTo(80)
            $0.bottom.lessThanOrEqualToSuperview()
            $0.height.greaterThanOrEqualTo(20)
        }
        valueLabel.snp.makeConstraints {
            $0.leading.equalTo(labelView.snp.trailing)
            $0.trailing.top.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }
}
