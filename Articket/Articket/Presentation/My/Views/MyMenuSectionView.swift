import UIKit
import SnapKit

// MARK: - Data

enum MyMenuItem: CaseIterable {
    case writeReview, cancelHistory, myReviews, inquiry, editProfile, customerService, notice

    var title: String {
        switch self {
        case .writeReview: return "후기 작성"
        case .cancelHistory: return "예매취소내역"
        case .myReviews: return "나의 후기"
        case .inquiry: return "1:1 문의"
        case .editProfile: return "내 정보 수정"
        case .customerService: return "고객센터"
        case .notice: return "공지사항"
        }
    }

    var badge: MyMenuBadge? {
        switch self {
        case .writeReview: return .count(3)
        case .myReviews: return .count(12)
        case .notice: return .text("NEW")
        default: return nil
        }
    }
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

// MARK: - MyMenuSectionView

final class MyMenuSectionView: UIView {

    private let stackView: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        return s
    }()
    private let logoutButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("로그아웃", for: .normal)
        b.setTitleColor(UIColor(hex: "#767676"), for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        b.backgroundColor = UIColor(hex: "#F3F4F6")
        b.layer.cornerRadius = 8
        return b
    }()
    private let appNameLabel: UILabel = {
        let l = UILabel()
        l.text = "Articket v1.0.0"
        l.font = .systemFont(ofSize: 12)
        l.textColor = UIColor(hex: "#999999")
        l.textAlignment = .center
        return l
    }()
    private let copyrightLabel: UILabel = {
        let l = UILabel()
        l.text = "© 2025 Articket. All rights reserved."
        l.font = .systemFont(ofSize: 11)
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
        MyMenuItem.allCases.forEach { item in
            let row = MenuRowView(item: item)
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
    }
}

// MARK: - MenuRowView

private final class MenuRowView: UIView {

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .medium)
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
        l.font = .systemFont(ofSize: 11, weight: .bold)
        l.textColor = UIColor(hex: "#121212")
        l.textAlignment = .center
        return l
    }()
    private let separator: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#F3F4F6")
        return v
    }()

    init(item: MyMenuItem) {
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
    }
    required init?(coder: NSCoder) { fatalError() }
}
