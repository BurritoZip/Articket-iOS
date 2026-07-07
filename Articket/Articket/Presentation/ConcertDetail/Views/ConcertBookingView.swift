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

    private lazy var providerRow: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [providerPrefixLabel, providerNameLabel])
        sv.axis = .horizontal
        sv.spacing = 4
        sv.alignment = .center
        return sv
    }()

    private let bookingButton: UIButton = {
        let b = UIButton(type: .system)
        b.backgroundColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1)
        b.layer.cornerRadius = 8
        b.clipsToBounds = true

        var config = UIButton.Configuration.plain()
        config.title = "예매하기"
        config.image = UIImage(named: "ic_web")?.withRenderingMode(.alwaysTemplate)
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

    var onBookingTapped: (() -> Void)?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        bookingButton.addTarget(self, action: #selector(bookingTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Setup

    private func setupViews() {
        addSubview(providerRow)
        addSubview(bookingButton)
        addSubview(openDateLabel)

        providerRow.snp.makeConstraints {
            $0.top.equalToSuperview().inset(10)
            $0.leading.equalToSuperview().inset(20)
        }

        bookingButton.snp.makeConstraints {
            $0.top.equalTo(providerRow.snp.bottom).offset(8)
            // 고정 350pt는 작은 기기(iPhone SE 320pt)서 오버플로우 → 좌우 20pt 인셋으로 반응형
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(48)
        }

        openDateLabel.snp.makeConstraints {
            $0.top.equalTo(bookingButton.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().inset(10)  // 섹션 py-bottom 10pt
        }
    }

    // MARK: - Actions

    @objc private func bookingTapped() { onBookingTapped?() }

    // MARK: - Configure

    func configure(with detail: ConcertDetail) {
        let hasProvider = !detail.ticketProvider.isEmpty
        providerRow.isHidden = !hasProvider
        providerNameLabel.text = detail.ticketProvider

        // 버튼은 항상 검정 활성 유지 (Figma 정합). URL 없으면 탭 시 ViewModel.requestBooking()이 안내 토스트 + 이슈 기록.
        bookingButton.isEnabled = true
        bookingButton.alpha = 1.0

        let hasOpenDate = !detail.ticketOpenDate.isEmpty
        openDateLabel.isHidden = !hasOpenDate
        openDateLabel.text = hasOpenDate ? "티켓팅 오픈: \(detail.ticketOpenDate)" : ""
    }
}
