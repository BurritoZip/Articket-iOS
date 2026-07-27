import UIKit
import SnapKit

// MARK: - BookingProviderSheetViewController
// 예매처가 2곳 이상인 공연에서 '예매하기' 탭 시 뜨는 선택 바텀시트.
// 같은 공연이 인터파크·YES24 등 여러 곳에서 팔릴 때 사용자가 원하는 예매처를 고른다.
// 로고 에셋(ic_provider_<provider>)이 있으면 로고를, 없으면 예매처명 첫 글자 컬러 뱃지로 폴백.

final class BookingProviderSheetViewController: UIViewController {

    // MARK: - Input

    private let links: [BookingLink]
    /// 예매처 선택 시 호출. 시트는 스스로 닫고, 오픈 처리는 호출부(ViewModel)가 담당.
    var onSelect: ((BookingLink) -> Void)?

    // MARK: - Layout Constants

    private enum L {
        static let rowHeight: CGFloat = 60
        static let hMargin: CGFloat = 20
        static let badgeSize: CGFloat = 36
        static let headerHeight: CGFloat = 56
    }

    // MARK: - Init

    init(links: [BookingLink]) {
        self.links = links
        super.init(nibName: nil, bundle: nil)
        configureSheet()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Views

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "예매처 선택"
        l.font = .systemFont(ofSize: 17, weight: .bold)
        l.textColor = .tcTextPrimary
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "원하는 예매처에서 예매를 진행하세요"
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textColor = .tcTextSecondary
        return l
    }()

    private let closeButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "xmark"), for: .normal)
        b.tintColor = .tcTextSecondary
        b.accessibilityLabel = "닫기"
        return b
    }()

    private lazy var rowsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 0
        return sv
    }()

    /// 배경 딤(탭 시 닫기). iOS 26 시스템 시트의 플로팅 마진을 피하려고 커스텀 바텀 카드로 구성.
    private let dimmingView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        return v
    }()

    /// 하단 밀착 카드(상단 모서리만 라운드). 좌우·하단 마진 없이 화면 바닥에 붙는다.
    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .tcBackground
        v.layer.cornerRadius = 20
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        v.clipsToBounds = true
        return v
    }()

    private let grabber: UIView = {
        let v = UIView()
        v.backgroundColor = .tcSeparator
        v.layer.cornerRadius = 2.5
        return v
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupLayout()
        buildRows()
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        dimmingView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(closeTapped)))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 카드를 화면 아래로 내려두고 딤을 투명하게 → viewDidAppear에서 올라오는 애니메이션
        dimmingView.alpha = 0
        cardView.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.32, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.4) {
            self.dimmingView.alpha = 1
            self.cardView.transform = .identity
        }
    }

    /// 닫기 애니메이션(카드 하강 + 딤 소멸) 후 실제 dismiss. 모든 dismiss 경로가 이 오버라이드를 탄다.
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        guard flag else { presentingViewController?.dismiss(animated: false, completion: completion); return }
        UIView.animate(withDuration: 0.24, animations: {
            self.dimmingView.alpha = 0
            self.cardView.transform = CGAffineTransform(translationX: 0, y: self.cardView.bounds.height + 40)
        }, completion: { _ in
            self.presentingViewController?.dismiss(animated: false, completion: completion)
        })
    }

    // MARK: - Setup

    /// 시스템 시트(iOS 26 플로팅) 대신 전체화면 위에 커스텀 바텀 카드로 표시.
    private func configureSheet() {
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    private func setupLayout() {
        view.addSubview(dimmingView)
        view.addSubview(cardView)
        [grabber, titleLabel, subtitleLabel, closeButton, rowsStack].forEach { cardView.addSubview($0) }

        dimmingView.snp.makeConstraints { $0.edges.equalToSuperview() }
        // 좌우·하단 마진 없이 화면 바닥에 밀착. 높이는 콘텐츠(그래버~행)로 결정.
        cardView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
        }

        grabber.snp.makeConstraints {
            $0.top.equalToSuperview().inset(8)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(36)
            $0.height.equalTo(5)
        }
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(grabber.snp.bottom).offset(12)
            $0.leading.equalToSuperview().inset(L.hMargin)
        }
        closeButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(L.hMargin)
            $0.width.height.equalTo(44)
        }
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.leading.equalToSuperview().inset(L.hMargin)
        }
        rowsStack.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview()
            // 카드가 안전영역까지 채우도록 rowsStack 하단을 카드 안전영역에 고정
            $0.bottom.equalTo(cardView.safeAreaLayoutGuide.snp.bottom).inset(8)
        }
    }

    private func buildRows() {
        for (index, link) in links.enumerated() {
            rowsStack.addArrangedSubview(makeRow(link))
            if index < links.count - 1 {
                let sep = UIView()
                sep.backgroundColor = .tcSeparator
                rowsStack.addArrangedSubview(sep)
                sep.snp.makeConstraints {
                    $0.height.equalTo(1)
                    $0.leading.trailing.equalToSuperview().inset(L.hMargin)
                }
            }
        }
    }

    private func makeRow(_ link: BookingLink) -> UIControl {
        let row = ProviderRowControl(link: link)
        row.snp.makeConstraints { $0.height.equalTo(L.rowHeight) }
        row.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            // 먼저 시트를 닫고 완료 후 오픈 콜백 — 외부 앱 전환과 dismiss 애니메이션 충돌 방지
            self.dismiss(animated: true) { self.onSelect?(link) }
        }, for: .touchUpInside)
        return row
    }

    // MARK: - Actions

    @objc private func closeTapped() { dismiss(animated: true) }
}

// MARK: - ProviderRowControl
// 예매처 한 줄: [뱃지/로고] 예매처명 ......... chevron. 탭 가능한 UIControl.

private final class ProviderRowControl: UIControl {

    private let badge = UIView()
    private let badgeLabel = UILabel()
    private let logoView = UIImageView()
    private let nameLabel = UILabel()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))

    init(link: BookingLink) {
        super.init(frame: .zero)
        setup(link)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    private func setup(_ link: BookingLink) {
        let badgeSize: CGFloat = 36

        badge.layer.cornerRadius = badgeSize / 2
        badge.clipsToBounds = true
        badge.backgroundColor = Self.brandColor(link.provider)
        badge.isUserInteractionEnabled = false

        badgeLabel.text = String(link.label.prefix(1))
        badgeLabel.font = .systemFont(ofSize: 16, weight: .bold)
        badgeLabel.textColor = .white
        badgeLabel.textAlignment = .center

        // 로고 에셋이 등록돼 있으면 뱃지 대신 로고 표시
        logoView.contentMode = .scaleAspectFit
        logoView.clipsToBounds = true
        logoView.layer.cornerRadius = badgeSize / 2
        if let logo = UIImage(named: "ic_provider_\(link.provider)") {
            logoView.image = logo
            logoView.isHidden = false
            badge.isHidden = true
        } else {
            logoView.isHidden = true
            badge.isHidden = false
        }

        nameLabel.text = link.label
        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = .tcTextPrimary

        chevron.tintColor = UIColor(white: 0.7, alpha: 1)
        chevron.contentMode = .scaleAspectFit
        chevron.isUserInteractionEnabled = false

        addSubview(badge)
        badge.addSubview(badgeLabel)
        addSubview(logoView)
        addSubview(nameLabel)
        addSubview(chevron)

        badge.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(badgeSize)
        }
        badgeLabel.snp.makeConstraints { $0.edges.equalToSuperview() }
        logoView.snp.makeConstraints {
            $0.edges.equalTo(badge)
        }
        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(badge.snp.trailing).offset(12)
            $0.centerY.equalToSuperview()
        }
        chevron.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(8)
            $0.height.equalTo(14)
        }
    }

    // 탭 피드백 — 눌림 상태에서 살짝 회색
    override var isHighlighted: Bool {
        didSet { backgroundColor = isHighlighted ? UIColor(white: 0.96, alpha: 1) : .clear }
    }

    /// 예매처별 브랜드 컬러 (로고 없을 때 뱃지 배경). 미지 예매처는 회색.
    private static func brandColor(_ provider: String) -> UIColor {
        switch provider {
        case "interpark": return UIColor(red: 0.90, green: 0.15, blue: 0.20, alpha: 1) // 인터파크 레드
        case "yes24":     return UIColor(red: 0.00, green: 0.44, blue: 0.84, alpha: 1) // YES24 블루
        case "melon":     return UIColor(red: 0.00, green: 0.80, blue: 0.47, alpha: 1) // 멜론 그린
        case "yanolja":   return UIColor(red: 0.95, green: 0.28, blue: 0.35, alpha: 1) // 놀 핑크레드
        case "klook":     return UIColor(red: 1.00, green: 0.44, blue: 0.09, alpha: 1) // 클룩 오렌지
        default:          return UIColor(white: 0.55, alpha: 1)
        }
    }
}
