import UIKit
import SnapKit

/// 리스트형 화면(예매 내역·내 후기 등)의 로딩 스켈레톤.
/// 스피너 대신 셀 형태의 회색 플레이스홀더 + shimmer로 프로젝트 로딩 관례에 맞춘다.
/// (shimmer 구현은 MyPageSkeletonView와 동일 패턴)
final class ListSkeletonView: UIView {
    private var shimmerLayer: CAGradientLayer?

    init(rowHeight: CGFloat = 96, rowCount: Int = 6) {
        super.init(frame: .zero)
        backgroundColor = .white
        setupRows(rowHeight: rowHeight, rowCount: rowCount)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        if shimmerLayer == nil, bounds.width > 0 { startShimmer() }
    }

    private func setupRows(rowHeight: CGFloat, rowCount: Int) {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        addSubview(stack)
        stack.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }
        for _ in 0..<rowCount {
            stack.addArrangedSubview(makeRow(height: rowHeight))
        }
    }

    private func makeRow(height: CGFloat) -> UIView {
        let row = UIView()
        row.snp.makeConstraints { $0.height.equalTo(height) }

        let poster = grayBox(cornerRadius: 6)
        let titleLine = grayBox(cornerRadius: 3)
        let subLine = grayBox(cornerRadius: 3)

        [poster, titleLine, subLine].forEach { row.addSubview($0) }

        poster.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(48)
            $0.height.equalTo(height - 32)
        }
        titleLine.snp.makeConstraints {
            $0.leading.equalTo(poster.snp.trailing).offset(14)
            $0.top.equalTo(poster).offset(6)
            $0.width.equalTo(180)
            $0.height.equalTo(15)
        }
        subLine.snp.makeConstraints {
            $0.leading.equalTo(titleLine)
            $0.top.equalTo(titleLine.snp.bottom).offset(8)
            $0.width.equalTo(120)
            $0.height.equalTo(12)
        }
        return row
    }

    private func grayBox(cornerRadius: CGFloat) -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1) // #E5E7EB
        v.layer.cornerRadius = cornerRadius
        return v
    }

    // MARK: - Shimmer (MyPageSkeletonView와 동일)

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
