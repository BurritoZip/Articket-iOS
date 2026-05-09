import UIKit
import SnapKit

final class ArtistSkeletonView: UIView {
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

    private func setupPlaceholders() {
        // Section 1: myArtists (no header, contentInsets top:12 leading:20 bottom:24)
        let circleRow = makeCircleRow(count: 4, circleSize: 80)
        addSubview(circleRow)
        circleRow.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.equalToSuperview().inset(20)
            $0.height.equalTo(108)
        }

        // Section 2: popularArtists (header 44pt, contentInsets top:12 leading:24 bottom:24)
        let sec2Title = grayBox(width: 130, height: 18, cornerRadius: 4)
        addSubview(sec2Title)
        sec2Title.snp.makeConstraints {
            $0.top.equalTo(circleRow.snp.bottom).offset(24 + 13)
            $0.leading.equalToSuperview().inset(20)
        }
        let popularCards = makeCardRow(count: 2, cardWidth: 128, cardHeight: 157)
        addSubview(popularCards)
        popularCards.snp.makeConstraints {
            $0.top.equalTo(circleRow.snp.bottom).offset(24 + 44 + 12)
            $0.leading.equalToSuperview().inset(24)
            $0.height.equalTo(157)
        }

        // Section 3: calendar (header 44pt, contentInsets top:12 leading:24 bottom:24)
        let sec3Title = grayBox(width: 110, height: 18, cornerRadius: 4)
        addSubview(sec3Title)
        sec3Title.snp.makeConstraints {
            $0.top.equalTo(popularCards.snp.bottom).offset(24 + 13)
            $0.leading.equalToSuperview().inset(20)
        }
        let calView = makeCalendarPlaceholder()
        addSubview(calView)
        calView.snp.makeConstraints {
            $0.top.equalTo(popularCards.snp.bottom).offset(24 + 44 + 12)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        // Section 4: recommendedArtists (header 44pt, contentInsets top:12 leading:24 bottom:24)
        let sec4Title = grayBox(width: 190, height: 18, cornerRadius: 4)
        addSubview(sec4Title)
        sec4Title.snp.makeConstraints {
            $0.top.equalTo(calView.snp.bottom).offset(24 + 13)
            $0.leading.equalToSuperview().inset(20)
        }
        var prev = calView.snp.bottom
        let firstRowOffset = 24 + 44 + 12
        for i in 0..<3 {
            let row = makeArtistRow()
            addSubview(row)
            row.snp.makeConstraints {
                $0.top.equalTo(prev).offset(i == 0 ? firstRowOffset : 12)
                $0.leading.trailing.equalToSuperview().inset(24)
                $0.height.equalTo(90)
            }
            prev = row.snp.bottom
        }
    }

    // MARK: - Component Builders

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
                $0.top.bottom.equalToSuperview()
                $0.leading.equalTo(prevAnchor).offset(i == 0 ? 0 : 16)
                $0.width.equalTo(circleSize)
            }
            prevAnchor = item.snp.trailing
        }
        return container
    }

    private func makeCardRow(count: Int, cardWidth: CGFloat, cardHeight: CGFloat) -> UIView {
        let container = UIView()
        var prevAnchor = container.snp.leading
        for i in 0..<count {
            let card = grayBox(width: cardWidth, height: cardHeight, cornerRadius: 4)
            container.addSubview(card)
            card.snp.makeConstraints {
                $0.top.bottom.equalToSuperview()
                $0.leading.equalTo(prevAnchor).offset(i == 0 ? 0 : 16)
            }
            prevAnchor = card.snp.trailing
        }
        return container
    }

    private func makeCalendarPlaceholder() -> UIView {
        let container = UIView()

        let prevBtn = grayBox(width: 24, height: 24, cornerRadius: 4)
        let monthLabel = grayBox(width: 80, height: 18, cornerRadius: 4)
        let nextBtn = grayBox(width: 24, height: 24, cornerRadius: 4)
        [prevBtn, monthLabel, nextBtn].forEach { container.addSubview($0) }
        prevBtn.snp.makeConstraints { $0.top.leading.equalToSuperview() }
        monthLabel.snp.makeConstraints { $0.top.equalToSuperview().offset(3); $0.centerX.equalToSuperview() }
        nextBtn.snp.makeConstraints { $0.top.trailing.equalToSuperview() }

        let dayRow = makeCalendarRow(cellHeight: 16)
        container.addSubview(dayRow)
        dayRow.snp.makeConstraints {
            $0.top.equalToSuperview().offset(36)
            $0.leading.trailing.equalToSuperview()
        }

        var prev = dayRow.snp.bottom
        for _ in 0..<3 {
            let row = makeCalendarRow(cellHeight: 36)
            container.addSubview(row)
            row.snp.makeConstraints {
                $0.top.equalTo(prev).offset(6)
                $0.leading.trailing.equalToSuperview()
            }
            prev = row.snp.bottom
        }
        container.snp.makeConstraints { $0.bottom.equalTo(prev) }
        return container
    }

    private func makeCalendarRow(cellHeight: CGFloat) -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 4
        for _ in 0..<7 {
            let v = UIView()
            v.backgroundColor = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1)
            v.layer.cornerRadius = 4
            stack.addArrangedSubview(v)
        }
        stack.snp.makeConstraints { $0.height.equalTo(cellHeight) }
        return stack
    }

    private func makeArtistRow() -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 4
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1).cgColor

        let circle = grayBox(width: 64, height: 64, cornerRadius: 32)
        let nameLine = grayBox(width: 100, height: 14, cornerRadius: 3)
        let infoLine = grayBox(width: 140, height: 12, cornerRadius: 3)
        let followBtn = grayBox(width: 60, height: 28, cornerRadius: 14)
        [circle, nameLine, infoLine, followBtn].forEach { container.addSubview($0) }

        circle.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(17)
            $0.centerY.equalToSuperview()
        }
        nameLine.snp.makeConstraints {
            $0.leading.equalTo(circle.snp.trailing).offset(16)
            $0.top.equalTo(circle).offset(8)
        }
        infoLine.snp.makeConstraints {
            $0.leading.equalTo(nameLine)
            $0.top.equalTo(nameLine.snp.bottom).offset(6)
        }
        followBtn.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(17)
            $0.centerY.equalToSuperview()
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
