import UIKit
import SnapKit

final class HomeSkeletonView: UIView {

    private var shimmerLayer: CAGradientLayer?
    private var bannerHeightConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupPlaceholders()
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateBannerHeight()
        if shimmerLayer == nil, bounds.width > 0 {
            startShimmer()
        }
    }

    // MARK: - Layout

    private func setupPlaceholders() {
        // ── Hero Banner ───────────────────────────────────────────────
        // Dark background matching actual blurredBackgroundImageView
        let banner = UIView()
        banner.backgroundColor = UIColor(red: 18/255, green: 18/255, blue: 18/255, alpha: 1)
        addSubview(banner)
        banner.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            // Initial fallback height: updated dynamically in layoutSubviews
            bannerHeightConstraint = $0.height.equalTo(520).constraint
        }

        // Poster placeholder — same constraints as HeroBannerCell posterContainerView
        let poster = UIView()
        poster.backgroundColor = UIColor(red: 44/255, green: 44/255, blue: 44/255, alpha: 1)
        poster.layer.cornerRadius = 8
        banner.addSubview(poster)
        poster.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(45)
            $0.height.equalTo(poster.snp.width).multipliedBy(1.43)
            // bottom inset = heroBannerProgressAreaHeight (80.5) so poster top lands at navBar bottom
            $0.bottom.equalToSuperview().inset(80.5)
        }

        // Progress bar placeholder
        let progressBar = UIView()
        progressBar.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        progressBar.layer.cornerRadius = 1.25
        banner.addSubview(progressBar)
        progressBar.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(45)
            $0.height.equalTo(2.5)
            $0.bottom.equalToSuperview().inset(58)
        }

        // ── 다가오는 이벤트 Section ────────────────────────────────────
        let header = grayBox(width: 130, height: 18, cornerRadius: 4)
        addSubview(header)
        header.snp.makeConstraints {
            $0.top.equalTo(banner.snp.bottom).offset(24)
            $0.leading.equalToSuperview().inset(20)
        }

        // 2 UpcomingEventCell-style placeholders (matches actual cell: border card, 80pt)
        var prevAnchor = header.snp.bottom
        for _ in 0..<2 {
            let card = makeUpcomingCardPlaceholder()
            addSubview(card)
            card.snp.makeConstraints {
                $0.top.equalTo(prevAnchor).offset(12)
                $0.leading.trailing.equalToSuperview().inset(20)
                $0.height.equalTo(80)
            }
            prevAnchor = card.snp.bottom
        }
    }

    // Matches UpcomingEventCell visual: rounded border card, D-day badge + title + info line
    private func makeUpcomingCardPlaceholder() -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 8
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor(red: 0.90, green: 0.91, blue: 0.92, alpha: 1).cgColor

        let badge = grayBox(width: 40, height: 20, cornerRadius: 4)
        let titleLine = grayBox(height: 14, cornerRadius: 3)
        let infoLine = grayBox(width: 160, height: 12, cornerRadius: 3)

        container.addSubview(badge)
        container.addSubview(titleLine)
        container.addSubview(infoLine)

        badge.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.top.equalToSuperview().inset(16)
        }
        titleLine.snp.makeConstraints {
            $0.leading.equalTo(badge.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalTo(badge)
        }
        infoLine.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.top.equalTo(badge.snp.bottom).offset(8)
        }
        return container
    }

    // Update banner height to exactly match HomeCollectionViewLayoutFactory.heroBannerSection
    private func updateBannerHeight() {
        let safeTop = safeAreaInsets.top
        let posterWidth = bounds.width - 90          // 2 × 45pt side margin
        let posterHeight = posterWidth * 1.43
        let navBarHeight: CGFloat = 56
        let posterTopGap: CGFloat = 17
        let progressAreaHeight: CGFloat = 80.5       // heroBannerProgressAreaHeight
        let bannerHeight = safeTop + navBarHeight + posterTopGap + posterHeight + progressAreaHeight
        bannerHeightConstraint?.update(offset: bannerHeight)
    }

    // MARK: - Helpers

    private func grayBox(width: CGFloat? = nil, height: CGFloat? = nil, cornerRadius: CGFloat = 0) -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1) // #E5E7EB
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
