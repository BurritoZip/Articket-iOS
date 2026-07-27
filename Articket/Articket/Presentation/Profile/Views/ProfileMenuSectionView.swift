import UIKit
import SnapKit

// MARK: - Data

enum MyMenuItem: CaseIterable {
    case bookingHistory, writeReview, cancelHistory, myReviews, inquiry, editProfile, customerService

    var title: String {
        switch self {
        case .bookingHistory: return "예매 티켓 현황"
        case .writeReview: return "후기 작성"
        case .cancelHistory: return "예매취소내역"
        case .myReviews: return "나의 후기"
        case .inquiry: return "1:1 문의"
        case .editProfile: return "내 정보 수정"
        case .customerService: return "고객센터"
        }
    }

    var badge: MyMenuBadge? { nil }
}

enum MyMenuBadge {
    case count(Int)
    case text(String)

    var displayText: String {
        switch self {
        case .count(let n): return "\(n)"
        case .text(let s): return s
        }
    }
}

// MARK: - ProfileMenuSectionView

final class ProfileMenuSectionView: UIView {

    var onMenuTapped: ((MyMenuItem) -> Void)?
    var onLogoutTapped: (() -> Void)?

    private let stackView: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        return s
    }()
    private let logoutButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("로그아웃", for: .normal)
        b.setTitleColor(UIColor(hex: "#767676"), for: .normal)
        b.titleLabel?.font = .scaled(15, weight: .medium, textStyle: .body)
        b.titleLabel?.adjustsFontForContentSizeCategory = true
        b.backgroundColor = UIColor(hex: "#F3F4F6")
        b.layer.cornerRadius = 8
        return b
    }()
    private let appNameLabel: UILabel = {
        let l = UILabel()
        l.text = "Articket v1.0.0"
        l.font = .scaled(12, textStyle: .caption1)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(hex: "#999999")
        l.textAlignment = .center
        return l
    }()
    private let copyrightLabel: UILabel = {
        let l = UILabel()
        l.text = "© 2025 Articket. All rights reserved."
        l.font = .scaled(11, textStyle: .caption1)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(hex: "#CCCCCC")
        l.textAlignment = .center
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        MyMenuItem.allCases.enumerated().forEach { index, item in
            let row = MenuRowView(item: item, showTopBorder: index == 0)
            row.onTapped = { [weak self] in self?.onMenuTapped?(item) }
            stackView.addArrangedSubview(row)
        }

        let footerStack = UIStackView(arrangedSubviews: [appNameLabel, copyrightLabel])
        footerStack.axis = .vertical
        footerStack.spacing = 4

        [stackView, logoutButton, footerStack].forEach { addSubview($0) }

        stackView.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview() }
        logoutButton.snp.makeConstraints {
            $0.top.equalTo(stackView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(44)
        }
        footerStack.snp.makeConstraints {
            $0.top.equalTo(logoutButton.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().inset(16)
        }
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
    }

    @objc private func logoutTapped() { onLogoutTapped?() }
}

// MARK: - MenuRowView

private final class MenuRowView: UIView {

    var onTapped: (() -> Void)?

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .scaled(15, weight: .medium, textStyle: .body)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(hex: "#333333")
        return l
    }()
    private let badgeView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 12
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor(hex: "#121212").cgColor
        return v
    }()
    private let badgeLabel: UILabel = {
        let l = UILabel()
        l.font = .scaled(11, weight: .bold, textStyle: .caption1)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(hex: "#121212")
        l.textAlignment = .center
        return l
    }()
    private let separator: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#F3F4F6")
        return v
    }()

    init(item: MyMenuItem, showTopBorder: Bool = false) {
        super.init(frame: .zero)
        titleLabel.text = item.title
        badgeView.isHidden = item.badge == nil
        if let badge = item.badge {
            badgeLabel.text = badge.displayText
        }

        badgeView.addSubview(badgeLabel)
        [titleLabel, badgeView, separator].forEach { addSubview($0) }

        snp.makeConstraints { $0.height.equalTo(48) }
        separator.snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview(); $0.height.equalTo(1) }

        // Figma: 첫 번째 row는 border-t border-b, 이후 row는 border-b만
        if showTopBorder {
            let topSep = UIView()
            topSep.backgroundColor = UIColor(hex: "#F3F4F6")
            addSubview(topSep)
            topSep.snp.makeConstraints {
                $0.top.leading.trailing.equalToSuperview()
                $0.height.equalTo(1)
            }
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
        }
        badgeView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(24)
            $0.width.greaterThanOrEqualTo(24)
        }
        badgeLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(8)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(rowTapped))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }
    required init?(coder: NSCoder) { fatalError() }

    @objc private func rowTapped() { onTapped?() }
}
