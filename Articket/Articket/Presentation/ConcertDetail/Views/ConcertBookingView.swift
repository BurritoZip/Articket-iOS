import UIKit
import SnapKit

// MARK: - ConcertBookingView
// Figma 1:1704 — 티켓 예매처 + 예매하기 버튼 + 티켓팅 오픈일

final class ConcertBookingView: UIView {

    // MARK: - Views

    private let providerPrefixLabel: UILabel = {
        let l = UILabel()
        l.text = "티켓 예매처:"
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1)
        return l
    }()

    private let providerNameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .bold)
        l.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        return l
    }()

    private let bookingButton: UIButton = {
        let b = UIButton(type: .system)
        b.backgroundColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1)
        b.layer.cornerRadius = 8
        b.clipsToBounds = true

        var config = UIButton.Configuration.plain()
        config.title = "예매하기"
        config.image = UIImage(systemName: "arrow.up.right")
        config.imagePlacement = .trailing
        config.imagePadding = 8
        config.baseForegroundColor = .white
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs
            a.font = .systemFont(ofSize: 16, weight: .bold)
            return a
        }
        b.configuration = config
        return b
    }()

    private let openDateLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        l.textAlignment = .center
        return l
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Setup

    private func setupViews() {
        let providerRow = UIStackView(arrangedSubviews: [providerPrefixLabel, providerNameLabel])
        providerRow.axis = .horizontal
        providerRow.spacing = 4
        providerRow.alignment = .center

        addSubview(providerRow)
        addSubview(bookingButton)
        addSubview(openDateLabel)

        providerRow.snp.makeConstraints {
            $0.top.equalToSuperview().inset(10)
            $0.leading.equalToSuperview().inset(20)
        }

        bookingButton.snp.makeConstraints {
            $0.top.equalTo(providerRow.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(350)
            $0.height.equalTo(48)
        }

        openDateLabel.snp.makeConstraints {
            $0.top.equalTo(bookingButton.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().inset(10)  // 섹션 py-bottom 10pt
        }
    }

    // MARK: - Configure

    func configure(with detail: ConcertDetail) {
        providerNameLabel.text = detail.ticketProvider
        openDateLabel.text = "티켓팅 오픈: \(detail.ticketOpenDate)"
    }
}
