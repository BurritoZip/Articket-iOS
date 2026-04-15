import UIKit

// Segmented progress bar footer for the hero banner carousel.
//
// Layout (within the 30pt footer area):
//   20pt top gap  ┌──── bar (2.5pt tall) ────┐
//                 ← 45pt →         ← 45pt →
//
// The bar is divided into equal segments, one per banner.
// Active segment: #ffffff  |  Inactive: #000000 @ 60% opacity

final class PageIndicatorFooterView: UICollectionReusableView {
    static let reuseIdentifier = "PageIndicatorFooterView"

    private var barStackView: UIStackView?
    private var segmentViews: [UIView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func configure(numberOfPages: Int, currentPage: Int) {
        // If segment count matches, just update colours — avoid full rebuild.
        if segmentViews.count == numberOfPages {
            updateSegmentColors(currentPage: currentPage)
            return
        }

        // Full rebuild
        barStackView?.removeFromSuperview()
        segmentViews = []

        guard numberOfPages > 0 else { return }

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 45),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -45),
            stack.heightAnchor.constraint(equalToConstant: 2.5),
        ])

        for i in 0..<numberOfPages {
            let segment = UIView()
            segment.backgroundColor = segmentColor(index: i, currentPage: currentPage)
            stack.addArrangedSubview(segment)
            segmentViews.append(segment)
        }
        barStackView = stack
    }

    private func updateSegmentColors(currentPage: Int) {
        for (i, segment) in segmentViews.enumerated() {
            segment.backgroundColor = segmentColor(index: i, currentPage: currentPage)
        }
    }

    private func segmentColor(index: Int, currentPage: Int) -> UIColor {
        index == currentPage ? .white : UIColor.black.withAlphaComponent(0.6)
    }
}
