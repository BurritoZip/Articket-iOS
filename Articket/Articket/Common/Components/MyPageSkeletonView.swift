import UIKit
import SnapKit

final class MyPageSkeletonView: UIView {
    private var shimmerLayer: CAGradientLayer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(red: 0.976, green: 0.980, blue: 0.984, alpha: 1) // #F9FAFB
        setupPlaceholders()
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        if shimmerLayer == nil, bounds.width > 0 { startShimmer() }
    }

    // MARK: - Layout

    private func setupPlaceholders() {
        // Top spacer: 28pt below safeArea (matching ProfileViewController's topSpacer)
        let topAnchor = UIView()
        addSubview(topAnchor)
        topAnchor.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(28)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(0)
        }

        // Profile header (border-t/b, py-24, gradient bg)
        let profileHeader = makeProfileHeader()
        addSubview(profileHeader)
        profileHeader.snp.makeConstraints {
            $0.top.equalTo(topAnchor.snp.bottom)
            $0.leading.trailing.equalToSuperview()
        }

        // Artist section wrapper (paddedWrapper top:36 bottom:36)
        let artistSection = makeArtistSection()
        addSubview(artistSection)
        artistSection.snp.makeConstraints {
            $0.top.equalTo(profileHeader.snp.bottom)
            $0.leading.trailing.equalToSuperview()
        }

        // 8pt divider
        let divider1 = makeDivider()
        addSubview(divider1)
        divider1.snp.makeConstraints {
            $0.top.equalTo(artistSection.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(8)
        }

        // Review section wrapper (paddedWrapper top:36 bottom:36)
        let reviewSection = makeReviewSection()
        addSubview(reviewSection)
        reviewSection.snp.makeConstraints {
            $0.top.equalTo(divider1.snp.bottom)
            $0.leading.trailing.equalToSuperview()
        }

        // 8pt divider
        let divider2 = makeDivider()
        addSubview(divider2)
        divider2.snp.makeConstraints {
            $0.top.equalTo(reviewSection.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(8)
        }

        // Yearly shows section wrapper (paddedWrapper top:36 bottom:36)
        let yearlySection = makeYearlySection()
        addSubview(yearlySection)
        yearlySection.snp.makeConstraints {
            $0.top.equalTo(divider2.snp.bottom)
            $0.leading.trailing.equalToSuperview()
        }
    }

    // MARK: - Section Builders

    private func makeProfileHeader() -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(red: 0.976, green: 0.980, blue: 0.984, alpha: 1)

        let topBorder = UIView()
        topBorder.backgroundColor = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1)
        let bottomBorder = UIView()
        bottomBorder.backgroundColor = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1)

        // Avatar circle placeholder
        let avatar = grayBox(width: 64, height: 64, cornerRadius: 32)
        let nameLine = grayBox(width: 80, height: 16, cornerRadius: 3)
        let emailLine = grayBox(width: 140, height: 13, cornerRadius: 3)

        let nameStack = UIStackView(arrangedSubviews: [nameLine, emailLine])
        nameStack.axis = .vertical
        nameStack.spacing = 6
        nameStack.alignment = .leading

        let profileRow = UIStackView(arrangedSubviews: [avatar, nameStack])
        profileRow.axis = .horizontal
        profileRow.spacing = 16
        profileRow.alignment = .center

        // 3 stat cards
        let card1 = makeStatCard()
        let card2 = makeStatCard()
        let card3 = makeStatCard()
        let cardRow = UIStackView(arrangedSubviews: [card1, card2, card3])
        cardRow.axis = .horizontal
        cardRow.spacing = 12
        cardRow.distribution = .fillEqually

        let contentStack = UIStackView(arrangedSubviews: [profileRow, cardRow])
        contentStack.axis = .vertical
        contentStack.spacing = 20

        [topBorder, bottomBorder, contentStack].forEach { container.addSubview($0) }

        topBorder.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(1)
        }
        bottomBorder.snp.makeConstraints {
            $0.bottom.leading.trailing.equalToSuperview()
            $0.height.equalTo(1)
        }
        contentStack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(24)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(24)
        }
        avatar.snp.makeConstraints { $0.size.equalTo(64) }
        cardRow.snp.makeConstraints { $0.height.equalTo(72) }

        return container
    }

    private func makeStatCard() -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        card.layer.cornerRadius = 8

        let valueLine = grayBox(width: 40, height: 18, cornerRadius: 3)
        let descLine = grayBox(width: 56, height: 12, cornerRadius: 3)

        let stack = UIStackView(arrangedSubviews: [valueLine, descLine])
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .center
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.center.equalToSuperview() }
        return card
    }

    private func makeArtistSection() -> UIView {
        let container = UIView()

        let title = grayBox(width: 80, height: 20, cornerRadius: 4)
        container.addSubview(title)
        title.snp.makeConstraints {
            $0.top.equalToSuperview().offset(36)
            $0.leading.equalToSuperview().inset(20)
        }

        let circleRow = makeCircleRow(count: 4, circleSize: 80)
        container.addSubview(circleRow)
        circleRow.snp.makeConstraints {
            $0.top.equalTo(title.snp.bottom).offset(20)
            $0.leading.equalToSuperview().inset(20)
            $0.height.equalTo(100)
            $0.bottom.equalToSuperview().inset(36)
        }
        return container
    }

    private func makeReviewSection() -> UIView {
        let container = UIView()

        let title = grayBox(width: 120, height: 20, cornerRadius: 4)
        container.addSubview(title)
        title.snp.makeConstraints {
            $0.top.equalToSuperview().offset(36)
            $0.leading.equalToSuperview().inset(20)
        }

        let subtitle = grayBox(width: 180, height: 13, cornerRadius: 3)
        container.addSubview(subtitle)
        subtitle.snp.makeConstraints {
            $0.top.equalTo(title.snp.bottom).offset(8)
            $0.leading.equalToSuperview().inset(20)
        }

        let reviewCard = makeReviewCard()
        container.addSubview(reviewCard)
        reviewCard.snp.makeConstraints {
            $0.top.equalTo(subtitle.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(36)
        }
        return container
    }

    private func makeReviewCard() -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor(red: 0.957, green: 0.961, blue: 0.965, alpha: 1)
        card.layer.cornerRadius = 8

        let poster = grayBox(width: 44, height: 56, cornerRadius: 4)
        let titleLine = grayBox(width: 160, height: 14, cornerRadius: 3)
        let subtitleLine = grayBox(width: 120, height: 12, cornerRadius: 3)
        let reviewBtn = grayBox(width: 72, height: 32, cornerRadius: 16)

        [poster, titleLine, subtitleLine, reviewBtn].forEach { card.addSubview($0) }

        poster.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }
        titleLine.snp.makeConstraints {
            $0.leading.equalTo(poster.snp.trailing).offset(12)
            $0.top.equalTo(poster).offset(4)
        }
        subtitleLine.snp.makeConstraints {
            $0.leading.equalTo(titleLine)
            $0.top.equalTo(titleLine.snp.bottom).offset(6)
        }
        reviewBtn.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }
        card.snp.makeConstraints { $0.height.equalTo(80) }
        return card
    }

    private func makeYearlySection() -> UIView {
        let container = UIView()

        let title = grayBox(width: 100, height: 20, cornerRadius: 4)
        container.addSubview(title)
        title.snp.makeConstraints {
            $0.top.equalToSuperview().offset(36)
            $0.leading.equalToSuperview().inset(20)
        }

        // Horizontal row of 3 poster cards (128×180 each, 16pt gap, leading 20pt)
        let card1 = grayBox(width: 128, height: 180, cornerRadius: 4)
        let card2 = grayBox(width: 128, height: 180, cornerRadius: 4)
        let card3 = grayBox(width: 128, height: 180, cornerRadius: 4)
        [card1, card2, card3].forEach { container.addSubview($0) }

        card1.snp.makeConstraints {
            $0.top.equalTo(title.snp.bottom).offset(20)
            $0.leading.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(36)
        }
        card2.snp.makeConstraints {
            $0.top.equalTo(card1)
            $0.leading.equalTo(card1.snp.trailing).offset(16)
        }
        card3.snp.makeConstraints {
            $0.top.equalTo(card1)
            $0.leading.equalTo(card2.snp.trailing).offset(16)
        }
        return container
    }

    private func makeCircleRow(count: Int, circleSize: CGFloat) -> UIView {
        let container = UIView()
        var prevAnchor = container.snp.leading
        for i in 0..<count {
            let item = UIView()
            let circle = grayBox(width: circleSize, height: circleSize, cornerRadius: circleSize / 2)
            let name = grayBox(width: circleSize - 20, height: 12, cornerRadius: 3)
            item.addSubview(circle)
            item.addSubview(name)
            circle.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview() }
            name.snp.makeConstraints {
                $0.top.equalTo(circle.snp.bottom).offset(8)
                $0.centerX.equalToSuperview()
            }
            container.addSubview(item)
            item.snp.makeConstraints {
                $0.top.equalToSuperview()
                $0.leading.equalTo(prevAnchor).offset(i == 0 ? 0 : 16)
                $0.width.equalTo(circleSize)
            }
            prevAnchor = item.snp.trailing
        }
        return container
    }

    private func makeDivider() -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.953, green: 0.957, blue: 0.965, alpha: 1)
        return v
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
