import UIKit
import SnapKit

// MARK: - ConcertTabBarView
// Figma 1:1714 — 3탭(공연정보/판매정보/후기) 슬라이딩 언더라인

final class ConcertTabBarView: UIView {

    var onTabSelected: ((Int) -> Void)?

    private var tabTitles: [String] = ["공연정보", "판매정보", "후기"]
    private var buttons: [UIButton] = []

    private let sliderView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        return v
    }()

    private let bottomBorder: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1)
        return v
    }()

    private var sliderLeadingConstraint: Constraint?
    private var sliderWidthConstraint: Constraint?
    private(set) var selectedIndex: Int = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    private func setupViews() {
        addSubview(bottomBorder)
        bottomBorder.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }

        tabTitles.enumerated().forEach { index, title in
            let btn = UIButton(type: .system)
            btn.setTitle(title, for: .normal)
            btn.tintColor = .clear
            btn.tag = index
            btn.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
            stack.addArrangedSubview(btn)
            buttons.append(btn)
        }

        addSubview(sliderView)
        sliderView.snp.makeConstraints {
            $0.bottom.equalToSuperview()
            $0.height.equalTo(2)
            self.sliderLeadingConstraint = $0.leading.equalToSuperview().constraint
            self.sliderWidthConstraint = $0.width.equalTo(0).constraint
        }

        // 실제 너비는 layoutSubviews에서 반영
        updateButtonStyles(selectedIndex: 0)
    }

    @objc private func tabTapped(_ sender: UIButton) {
        selectTab(sender.tag, animated: true)
        onTabSelected?(sender.tag)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 레이아웃이 확정된 시점에 슬라이더 너비·위치를 반영
        let sliderWidth = bounds.width / CGFloat(tabTitles.count)
        sliderWidthConstraint?.update(offset: sliderWidth)
        sliderLeadingConstraint?.update(offset: sliderWidth * CGFloat(selectedIndex))
    }

    // 탭 라벨은 예매 상태와 무관하게 고정('정보/판매정보/후기') — 상태별 분기가 없으므로
    // configure(status:) 는 제거했다. (내용은 항상 후기인데 라벨만 'Q&A'로 바뀌던 과거 불일치도 함께 해소)

    func selectTab(_ index: Int, animated: Bool) {
        selectedIndex = index
        updateButtonStyles(selectedIndex: index)

        guard bounds.width > 0 else { return }
        let sliderWidth = bounds.width / CGFloat(tabTitles.count)
        let newLeading = sliderWidth * CGFloat(index)
        sliderWidthConstraint?.update(offset: sliderWidth)
        sliderLeadingConstraint?.update(offset: newLeading)

        if animated {
            UIView.animate(withDuration: 0.2) { self.layoutIfNeeded() }
        } else {
            layoutIfNeeded()
        }
    }

    private func updateButtonStyles(selectedIndex: Int) {
        buttons.enumerated().forEach { i, btn in
            let isSelected = i == selectedIndex
            btn.titleLabel?.font = .systemFont(ofSize: 16, weight: isSelected ? .bold : .medium)
            btn.setTitleColor(
                isSelected ? UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
                           : UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1),
                for: .normal
            )
        }
    }
}
