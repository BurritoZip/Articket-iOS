import UIKit
import SnapKit

// MARK: - ConcertDetailSkeletonView
// 공연 상세 로딩 중 placeholder(빈 문자열·미상 상태)가 실데이터인 척 노출되는 것을 막는 스켈레톤.
// ArtistDetailSkeletonView와 동일한 shimmer 패턴을 따른다.

final class ConcertDetailSkeletonView: UIView {

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
        // 히어로 이미지 영역 — 실제 heroImageView와 동일한 400pt, 어두운 배경으로 톤 일치
        let hero = UIView()
        hero.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        addSubview(hero)
        hero.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(400)
        }

        // 히어로 위로 24pt 겹쳐 올라오는 화이트 카드 (실제 cardView와 동일한 오프셋/라운드)
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        card.clipsToBounds = true
        addSubview(card)
        card.snp.makeConstraints {
            $0.top.equalTo(hero.snp.bottom).offset(-24)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        // 상태 배지 + 제목
        let badge = grayBox(width: 72, height: 28, cornerRadius: 8)
        card.addSubview(badge)
        badge.snp.makeConstraints {
            $0.top.equalToSuperview().offset(30)
            $0.leading.equalToSuperview().inset(20)
        }

        let titleLine = grayBox(height: 24, cornerRadius: 4)
        card.addSubview(titleLine)
        titleLine.snp.makeConstraints {
            $0.top.equalTo(badge.snp.bottom).offset(12)
            $0.leading.equalToSuperview().inset(20)
            $0.trailing.equalToSuperview().inset(80)
        }

        // 장르 · 러닝타임 · 관람등급 한 줄
        let subtitleLine = grayBox(width: 180, height: 14, cornerRadius: 3)
        card.addSubview(subtitleLine)
        subtitleLine.snp.makeConstraints {
            $0.top.equalTo(titleLine.snp.bottom).offset(10)
            $0.leading.equalToSuperview().inset(20)
        }

        // 공연장 / 기간 2줄
        let venueLine = grayBox(width: 140, height: 14, cornerRadius: 3)
        card.addSubview(venueLine)
        venueLine.snp.makeConstraints {
            $0.top.equalTo(subtitleLine.snp.bottom).offset(14)
            $0.leading.equalToSuperview().inset(20)
        }

        let dateLine = grayBox(width: 200, height: 14, cornerRadius: 3)
        card.addSubview(dateLine)
        dateLine.snp.makeConstraints {
            $0.top.equalTo(venueLine.snp.bottom).offset(8)
            $0.leading.equalToSuperview().inset(20)
        }

        // 예매하기 버튼 자리 (실제 48pt)
        let bookingButton = grayBox(height: 48, cornerRadius: 8)
        card.addSubview(bookingButton)
        bookingButton.snp.makeConstraints {
            $0.top.equalTo(dateLine.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        // 탭바 자리 (실제 36pt)
        let tabBar = grayBox(height: 36, cornerRadius: 8)
        card.addSubview(tabBar)
        tabBar.snp.makeConstraints {
            $0.top.equalTo(bookingButton.snp.bottom).offset(32)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        // 탭 콘텐츠 본문 라인 4개
        var prevAnchor = tabBar.snp.bottom
        let widths: [CGFloat] = [220, 260, 180, 240]
        for (i, w) in widths.enumerated() {
            let line = grayBox(width: w, height: 14, cornerRadius: 3)
            card.addSubview(line)
            line.snp.makeConstraints {
                $0.top.equalTo(prevAnchor).offset(i == 0 ? 28 : 12)
                $0.leading.equalToSuperview().inset(20)
            }
            prevAnchor = line.snp.bottom
        }
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
