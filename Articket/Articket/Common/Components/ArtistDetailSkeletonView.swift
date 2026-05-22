import UIKit
import SnapKit

final class ArtistDetailSkeletonView: UIView {

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
        // 헤더 영역: safeArea 아래 48pt 오프셋 (scrollView contentInset과 일치)
        let headerBlock = makeHeaderBlock()
        addSubview(headerBlock)
        headerBlock.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(48)
            $0.leading.trailing.equalToSuperview()
        }

        // 탭바 영역 (height 36)
        let tabBar = makeTabBar()
        addSubview(tabBar)
        tabBar.snp.makeConstraints {
            $0.top.equalTo(headerBlock.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(36)
        }

        // 구분선
        let divider = UIView()
        divider.backgroundColor = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1)
        addSubview(divider)
        divider.snp.makeConstraints {
            $0.top.equalTo(tabBar.snp.bottom).offset(1)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(1)
        }

        // 섹션 헤더 라인
        let sectionTitle = grayBox(width: 100, height: 18, cornerRadius: 4)
        addSubview(sectionTitle)
        sectionTitle.snp.makeConstraints {
            $0.top.equalTo(divider.snp.bottom).offset(32)
            $0.leading.equalToSuperview().inset(24)
        }

        // 콘서트 아이템 행 3개
        var prevAnchor = sectionTitle.snp.bottom
        for i in 0..<3 {
            let row = makeConcertRow()
            addSubview(row)
            row.snp.makeConstraints {
                $0.top.equalTo(prevAnchor).offset(i == 0 ? 20 : 16)
                $0.leading.trailing.equalToSuperview().inset(24)
            }
            prevAnchor = row.snp.bottom
        }
    }

    // MARK: - Section Builders

    private func makeHeaderBlock() -> UIView {
        let container = UIView()

        let avatar = grayBox(width: 108, height: 108, cornerRadius: 54)
        let nameLine = grayBox(width: 120, height: 20, cornerRadius: 4)
        let followBtn = grayBox(width: 100, height: 32, cornerRadius: 16)

        let stat1 = makeStatItem()
        let stat2 = makeStatItem()
        let statsRow = UIStackView(arrangedSubviews: [stat1, stat2])
        statsRow.axis = .horizontal
        statsRow.spacing = 24
        statsRow.alignment = .center

        let stack = UIStackView(arrangedSubviews: [avatar, nameLine, followBtn, statsRow])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12

        container.addSubview(stack)
        stack.snp.makeConstraints {
            $0.top.equalToSuperview().inset(24)
            $0.bottom.equalToSuperview().inset(24)
            $0.centerX.equalToSuperview()
        }
        return container
    }

    private func makeStatItem() -> UIView {
        let container = UIView()
        let valueLine = grayBox(width: 40, height: 16, cornerRadius: 3)
        let labelLine = grayBox(width: 30, height: 12, cornerRadius: 3)
        let stack = UIStackView(arrangedSubviews: [valueLine, labelLine])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        container.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        return container
    }

    private func makeTabBar() -> UIView {
        let container = UIView()
        let tab1 = grayBox(width: 60, height: 32, cornerRadius: 8)
        let tab2 = grayBox(width: 60, height: 32, cornerRadius: 8)
        [tab1, tab2].forEach { container.addSubview($0) }
        tab1.snp.makeConstraints { $0.leading.centerY.equalToSuperview() }
        tab2.snp.makeConstraints { $0.leading.equalTo(tab1.snp.trailing).offset(20); $0.centerY.equalToSuperview() }
        return container
    }

    private func makeConcertRow() -> UIView {
        let container = UIView()
        let thumb = grayBox(width: 80, height: 80, cornerRadius: 6)
        let titleLine = grayBox(width: 160, height: 15, cornerRadius: 3)
        let dateLine = grayBox(width: 100, height: 13, cornerRadius: 3)
        let venueLine = grayBox(width: 120, height: 13, cornerRadius: 3)

        let textStack = UIStackView(arrangedSubviews: [titleLine, dateLine, venueLine])
        textStack.axis = .vertical
        textStack.spacing = 6
        textStack.alignment = .leading

        [thumb, textStack].forEach { container.addSubview($0) }
        thumb.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.size.equalTo(80)
        }
        textStack.snp.makeConstraints {
            $0.leading.equalTo(thumb.snp.trailing).offset(12)
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview()
        }
        container.snp.makeConstraints { $0.height.equalTo(80) }
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
            UIColor.white.withAlphaComponent(0.6).cgColor,
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
