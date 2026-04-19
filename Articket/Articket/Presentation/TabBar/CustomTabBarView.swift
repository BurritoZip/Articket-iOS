import UIKit
import SnapKit

// Custom tab bar view — matches Figma "component > Container (Property 1=Home/Artist/My)" spec.
//
// Visual area  : 60pt content area (icon + label, bottom-aligned with 4pt padding)
// Total height : 60pt + safeAreaInsets.bottom (home indicator zone is transparent)
//
// Selected  : #121212, weight .medium
// Unselected: #999999, weight .regular

final class CustomTabBarView: UIView {

    // MARK: - Public

    var onTabSelected: ((Int) -> Void)?
    private(set) var selectedIndex: Int = 0

    func setSelectedIndex(_ index: Int) {
        guard index != selectedIndex else { return }
        selectedIndex = index
        updateAppearance()
    }

    // MARK: - Constants

    static let contentHeight: CGFloat = 60

    // MARK: - Bottom Inset

    private var deviceBottomInset: CGFloat = 0

    func updateBottomInset(_ inset: CGFloat) {
        guard inset != deviceBottomInset else { return }
        deviceBottomInset = inset
        invalidateIntrinsicContentSize()
    }

    // MARK: - Subviews

    private let separator: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1) // #E5E7EB
        return v
    }()

    private var itemButtons: [TabItemButton] = []

    // MARK: - Init

    struct Item {
        let title: String
        let image: UIImage?         // unselected
        let selectedImage: UIImage? // selected; falls back to image if nil
    }

    init(items: [Item]) {
        super.init(frame: .zero)
        backgroundColor = .white
        setupSeparator()
        setupItems(items)
        updateAppearance()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // Total height = 60pt content + device safe area bottom.
    // deviceBottomInset is injected by MainTabBarController.viewSafeAreaInsetsDidChange(),
    // which fires after layout is complete and window?.safeAreaInsets is reliable.
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: Self.contentHeight + deviceBottomInset)
    }

    // MARK: - Setup

    private func setupSeparator() {
        addSubview(separator)
        separator.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(0.5)
        }
    }

    private func setupItems(_ items: [Item]) {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        addSubview(stack)

        // Stack covers ONLY the 60pt content area.
        // Safe area (home indicator) sits below — background colour fills it naturally.
        stack.snp.makeConstraints {
            $0.leading.trailing.top.equalToSuperview()
            $0.height.equalTo(Self.contentHeight)
        }

        for (index, item) in items.enumerated() {
            let btn = TabItemButton(item: item)
            btn.tag = index
            btn.addTarget(self, action: #selector(itemTapped(_:)), for: .touchUpInside)
            stack.addArrangedSubview(btn)
            itemButtons.append(btn)
        }
    }

    private func updateAppearance() {
        for (i, btn) in itemButtons.enumerated() {
            btn.applyStyle(selected: i == selectedIndex)
        }
    }

    // MARK: - Actions

    @objc private func itemTapped(_ sender: UIControl) {
        selectedIndex = sender.tag
        updateAppearance()
        onTabSelected?(sender.tag)
    }
}

// MARK: - Tab Item Button

private final class TabItemButton: UIControl {

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.textAlignment = .center
        lbl.font = .systemFont(ofSize: 12, weight: .regular)
        return lbl
    }()

    private let normalImage: UIImage?
    private let filledImage: UIImage?

    init(item: CustomTabBarView.Item) {
        normalImage = item.image?.withRenderingMode(.alwaysTemplate)
        filledImage = (item.selectedImage ?? item.image)?.withRenderingMode(.alwaysTemplate)
        super.init(frame: .zero)

        iconView.image = normalImage
        titleLabel.text = item.title

        addSubview(iconView)
        addSubview(titleLabel)

        // Label: 4pt from the bottom of the 60pt content area (matches Figma pb-[4px])
        titleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().inset(4)
        }

        // Icon: 24×24pt, 4pt above the label (matches Figma gap-[4px])
        iconView.snp.makeConstraints {
            $0.size.equalTo(24)
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(titleLabel.snp.top).offset(-4)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func applyStyle(selected: Bool) {
        let color = selected
            ? UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1) // #121212
            : UIColor(red: 0.6,   green: 0.6,   blue: 0.6,   alpha: 1) // #999999
        iconView.image = selected ? filledImage : normalImage
        iconView.tintColor = color
        titleLabel.textColor = color
        titleLabel.font = .systemFont(ofSize: 12, weight: selected ? .medium : .regular)
    }
}
