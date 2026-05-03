import UIKit
import SnapKit

final class HeroBannerProgressView: UIView {

    private let trackView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        return v
    }()

    private let sliderView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        return v
    }()

    private var sliderLeadingConstraint: Constraint?
    private var sliderWidthConstraint: Constraint?
    private var totalPages: Int = 0
    private var currentPage: Int = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(trackView)
        trackView.snp.makeConstraints { $0.edges.equalToSuperview() }

        addSubview(sliderView)
        sliderView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            sliderLeadingConstraint = $0.leading.equalToSuperview().constraint
            sliderWidthConstraint = $0.width.equalTo(0).constraint
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateSliderPosition(animated: false)
    }

    func configure(totalPages: Int) {
        guard totalPages != self.totalPages, totalPages > 0 else { return }
        self.totalPages = totalPages
        updateSliderPosition(animated: false)
    }

    func setPage(_ page: Int) {
        guard page != currentPage else { return }
        currentPage = page
        updateSliderPosition(animated: true)
    }

    private func updateSliderPosition(animated: Bool) {
        guard totalPages > 0, bounds.width > 0 else { return }
        let sliderWidth = bounds.width / CGFloat(totalPages)
        sliderWidthConstraint?.update(offset: sliderWidth)
        sliderLeadingConstraint?.update(offset: sliderWidth * CGFloat(currentPage))

        if animated {
            UIView.animate(withDuration: 0.2) { self.layoutIfNeeded() }
        } else {
            layoutIfNeeded()
        }
    }
}
