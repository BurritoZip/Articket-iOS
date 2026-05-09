import UIKit
import SnapKit

final class MyModeSkeletonView: UIView {
    private var shimmerLayer: CAGradientLayer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupPlaceholders()
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        if shimmerLayer == nil, bounds.width > 0 { startShimmer() }
    }

    // MARK: - Layout

    // navBarHeight from HomeViewController (56pt)
    private static let navBarHeight: CGFloat = 56

    private func setupPlaceholders() {
        // Content starts at safeArea.top + navBarHeight — matching myCollectionView contentInset

        // Section 1: 내 예매 현황 (header 44pt, contentInsets top:12 leading:20 bottom:36)
        let bookingTitle = grayBox(width: 100, height: 18, cornerRadius: 4)
        addSubview(bookingTitle)
        bookingTitle.snp.makeConstraints {
            // center in 44pt header starting at safeArea.top + navBarHeight
            $0.top.equalTo(safeAreaLayoutGuide).offset(Self.navBarHeight + 13)
            $0.leading.equalToSuperview().inset(20)
        }

        let card1 = makeBookingCard()
        addSubview(card1)
        card1.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(Self.navBarHeight + 44 + 12)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        let card2 = makeBookingCard()
        addSubview(card2)
        card2.snp.makeConstraints {
            $0.top.equalTo(card1.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        // Section 2: 바로가기 (header 44pt, contentInsets top:12 leading:16 bottom:36)
        let shortcutTitle = grayBox(width: 60, height: 18, cornerRadius: 4)
        addSubview(shortcutTitle)
        shortcutTitle.snp.makeConstraints {
            $0.top.equalTo(card2.snp.bottom).offset(36 + 13)
            $0.leading.equalToSuperview().inset(20)
        }

        let shortcuts = makeShortcutRow()
        addSubview(shortcuts)
        shortcuts.snp.makeConstraints {
            $0.top.equalTo(card2.snp.bottom).offset(36 + 44 + 12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(92)
        }

        // Section 3: 올해 본 공연 (header 44pt, contentInsets top:12 leading:20 bottom:36)
        let yearlyTitle = grayBox(width: 120, height: 18, cornerRadius: 4)
        addSubview(yearlyTitle)
        yearlyTitle.snp.makeConstraints {
            $0.top.equalTo(shortcuts.snp.bottom).offset(36 + 13)
            $0.leading.equalToSuperview().inset(20)
        }

        let subtitleLine = grayBox(width: 200, height: 14, cornerRadius: 3)
        addSubview(subtitleLine)
        subtitleLine.snp.makeConstraints {
            $0.top.equalTo(shortcuts.snp.bottom).offset(36 + 44 + 12)
            $0.leading.equalToSuperview().inset(20)
        }

        let chartPlaceholder = grayBox(height: 120, cornerRadius: 4)
        addSubview(chartPlaceholder)
        chartPlaceholder.snp.makeConstraints {
            $0.top.equalTo(subtitleLine.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
    }

    // MARK: - Component Builders

    private func makeBookingCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 4
        card.layer.borderWidth = 1.5
        card.layer.borderColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1).cgColor

        let badge1 = grayBox(width: 40, height: 20, cornerRadius: 4)
        let badge2 = grayBox(width: 45, height: 20, cornerRadius: 4)
        let titleLine1 = grayBox(height: 16, cornerRadius: 3)
        let titleLine2 = grayBox(width: 200, height: 16, cornerRadius: 3)
        let infoLine1 = grayBox(width: 180, height: 13, cornerRadius: 3)
        let infoLine2 = grayBox(width: 150, height: 13, cornerRadius: 3)
        let infoLine3 = grayBox(width: 160, height: 13, cornerRadius: 3)

        [badge1, badge2, titleLine1, titleLine2, infoLine1, infoLine2, infoLine3].forEach { card.addSubview($0) }

        badge1.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(16)
        }
        badge2.snp.makeConstraints {
            $0.top.equalTo(badge1)
            $0.leading.equalTo(badge1.snp.trailing).offset(8)
        }
        titleLine1.snp.makeConstraints {
            $0.top.equalTo(badge1.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        titleLine2.snp.makeConstraints {
            $0.top.equalTo(titleLine1.snp.bottom).offset(6)
            $0.leading.equalToSuperview().inset(16)
        }
        infoLine1.snp.makeConstraints {
            $0.top.equalTo(titleLine2.snp.bottom).offset(12)
            $0.leading.equalToSuperview().inset(16)
        }
        infoLine2.snp.makeConstraints {
            $0.top.equalTo(infoLine1.snp.bottom).offset(6)
            $0.leading.equalToSuperview().inset(16)
        }
        infoLine3.snp.makeConstraints {
            $0.top.equalTo(infoLine2.snp.bottom).offset(6)
            $0.leading.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(16)
        }
        return card
    }

    private func makeShortcutRow() -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 8
        for _ in 0..<3 {
            let item = makeShortcutItem()
            stack.addArrangedSubview(item)
        }
        return stack
    }

    private func makeShortcutItem() -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1)
        container.layer.cornerRadius = 8

        let iconBox = UIView()
        iconBox.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        iconBox.layer.cornerRadius = 6

        let label = UIView()
        label.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        label.layer.cornerRadius = 3

        container.addSubview(iconBox)
        container.addSubview(label)

        iconBox.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-10)
            $0.size.equalTo(24)
        }
        label.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(iconBox.snp.bottom).offset(6)
            $0.width.equalTo(40)
            $0.height.equalTo(12)
        }
        return container
    }

    // MARK: - Helpers

    private func grayBox(width: CGFloat? = nil, height: CGFloat? = nil, cornerRadius: CGFloat = 0) -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1)
        v.layer.cornerRadius = cornerRadius
        if let w = width { v.snp.makeConstraints { $0.width.equalTo(w) } }
        if let h = height { v.snp.makeConstraints { $0.height.equalTo(h) } }
        return v
    }

    // MARK: - Shimmer

    private func startShimmer() {
        let width = bounds.width
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(x: -width, y: 0, width: width * 3, height: bounds.height)
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.colors = [
            UIColor.white.withAlphaComponent(0).cgColor,
            UIColor.white.withAlphaComponent(0.5).cgColor,
            UIColor.white.withAlphaComponent(0).cgColor
        ]
        gradient.locations = [0.25, 0.5, 0.75]
        layer.addSublayer(gradient)

        let anim = CABasicAnimation(keyPath: "transform.translation.x")
        anim.fromValue = 0
        anim.toValue = width * 2
        anim.duration = 1.4
        anim.repeatCount = .infinity
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        gradient.add(anim, forKey: "shimmer")

        shimmerLayer = gradient
    }

    func stopShimmer() {
        shimmerLayer?.removeAllAnimations()
        shimmerLayer?.removeFromSuperlayer()
        shimmerLayer = nil
    }
}
