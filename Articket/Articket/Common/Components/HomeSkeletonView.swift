import UIKit
import SnapKit

final class HomeSkeletonView: UIView {

    private var shimmerLayer: CAGradientLayer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupPlaceholders()
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard shimmerLayer == nil, bounds.width > 0 else { return }
        startShimmer()
    }

    private func setupPlaceholders() {
        // 배너 포스터 영역 — 헤더 흰 텍스트가 보이도록 어두운 배경 유지
        let banner = UIView()
        banner.backgroundColor = UIColor(hex: "#1A1A1A")
        addSubview(banner)
        banner.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalToSuperview().multipliedBy(0.42)
        }

        // 배너 내부 포스터 플레이스홀더 (가운데 회색 박스)
        let posterBox = grayBox(cornerRadius: 8)
        posterBox.backgroundColor = UIColor(hex: "#2C2C2C")
        banner.addSubview(posterBox)
        posterBox.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalToSuperview().multipliedBy(0.65)
            $0.height.equalTo(posterBox.snp.width).multipliedBy(1.43)
        }

        // 섹션 헤더 1
        let header1 = grayBox(width: 140, height: 18, cornerRadius: 4)
        addSubview(header1)
        header1.snp.makeConstraints {
            $0.top.equalTo(banner.snp.bottom).offset(24)
            $0.leading.equalToSuperview().inset(20)
        }

        // 가로 카드 3개
        let cardStack = UIStackView()
        cardStack.axis = .horizontal
        cardStack.spacing = 12
        addSubview(cardStack)
        cardStack.snp.makeConstraints {
            $0.top.equalTo(header1.snp.bottom).offset(12)
            $0.leading.equalToSuperview().inset(20)
            $0.height.equalTo(130)
        }
        for _ in 0..<3 {
            let card = grayBox(width: 88, height: 130, cornerRadius: 6)
            cardStack.addArrangedSubview(card)
        }

        // 섹션 헤더 2
        let header2 = grayBox(width: 110, height: 18, cornerRadius: 4)
        addSubview(header2)
        header2.snp.makeConstraints {
            $0.top.equalTo(cardStack.snp.bottom).offset(28)
            $0.leading.equalToSuperview().inset(20)
        }

        // 리스트 행 2개
        var prevAnchor = header2.snp.bottom
        for _ in 0..<2 {
            let row = makeListRow()
            addSubview(row)
            row.snp.makeConstraints {
                $0.top.equalTo(prevAnchor).offset(14)
                $0.leading.trailing.equalToSuperview().inset(20)
                $0.height.equalTo(72)
            }
            prevAnchor = row.snp.bottom
        }
    }

    private func makeListRow() -> UIView {
        let container = UIView()
        let thumb = grayBox(width: 56, height: 56, cornerRadius: 4)
        let line1 = grayBox(width: 160, height: 13, cornerRadius: 3)
        let line2 = grayBox(width: 100, height: 11, cornerRadius: 3)

        [thumb, line1, line2].forEach { container.addSubview($0) }

        thumb.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
            $0.width.height.equalTo(56)
        }
        line1.snp.makeConstraints {
            $0.leading.equalTo(thumb.snp.trailing).offset(12)
            $0.centerY.equalToSuperview().offset(-10)
        }
        line2.snp.makeConstraints {
            $0.leading.equalTo(thumb.snp.trailing).offset(12)
            $0.centerY.equalToSuperview().offset(10)
        }
        return container
    }

    private func grayBox(width: CGFloat? = nil, height: CGFloat? = nil, cornerRadius: CGFloat = 0) -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#E5E7EB")
        v.layer.cornerRadius = cornerRadius
        if let w = width { v.snp.makeConstraints { $0.width.equalTo(w) } }
        if let h = height { v.snp.makeConstraints { $0.height.equalTo(h) } }
        return v
    }

    private func startShimmer() {
        let width = bounds.width
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(x: -width, y: 0, width: width * 3, height: bounds.height)
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.colors = [
            UIColor.white.withAlphaComponent(0).cgColor,
            UIColor.white.withAlphaComponent(0.65).cgColor,
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
