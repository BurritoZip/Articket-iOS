import UIKit

final class ChipFlowView: UIView {

    private var chipViews: [UIView] = []
    private let horizontalSpacing: CGFloat
    private let verticalSpacing: CGFloat

    private var calculatedHeight: CGFloat = 0

    init(horizontalSpacing: CGFloat = 8, verticalSpacing: CGFloat = 12) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError() }

    func setChips(_ chips: [UIView]) {
        chipViews.forEach { $0.removeFromSuperview() }
        chipViews = chips
        chips.forEach { addSubview($0) }
        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let containerWidth = bounds.width
        guard containerWidth > 0 else { return }

        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for chip in chipViews {
            let size = chip.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            if x + size.width > containerWidth && x > 0 {
                x = 0
                y += rowHeight + verticalSpacing
                rowHeight = 0
            }
            chip.frame = CGRect(x: x, y: y, width: size.width, height: size.height)
            x += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }

        calculatedHeight = chipViews.isEmpty ? 0 : y + rowHeight
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: calculatedHeight)
    }
}
