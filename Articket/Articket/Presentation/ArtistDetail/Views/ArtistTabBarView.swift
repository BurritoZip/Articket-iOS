import UIKit
import SnapKit

// MARK: - ArtistTabBarView
// Figma 1:2841 — 콘서트/프로필 탭 + 슬라이더 언더라인

final class ArtistTabBarView: UIView {

    var onTabSelected: ((Int) -> Void)?
    private(set) var selectedIndex: Int = 0

    private let tabTitles = ["콘서트", "프로필"]
    private var tabButtons: [UIButton] = []

    private let slider: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        return v
    }()

    private let bottomBorder: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1)
        return v
    }()

    // 탭 버튼 leading offsets (Figma: 콘서트→0, 프로필→72)
    private let tabLeadingOffsets: [CGFloat] = [0, 72]
    private let tabWidth: CGFloat = 60

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    private func setupViews() {
        addSubview(bottomBorder)
        addSubview(slider)

        bottomBorder.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }

        for (i, title) in tabTitles.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(title, for: .normal)
            btn.tag = i
            btn.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
            addSubview(btn)
            btn.snp.makeConstraints {
                $0.leading.equalToSuperview().offset(tabLeadingOffsets[i])
                $0.top.equalToSuperview()
                $0.width.equalTo(tabWidth)
                $0.height.equalTo(28)
            }
            tabButtons.append(btn)
        }

        slider.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(tabLeadingOffsets[0])
            $0.bottom.equalToSuperview()
            $0.width.equalTo(tabWidth)
            $0.height.equalTo(2)
        }

        updateButtonStyles(selectedIndex: 0)
    }

    func selectTab(_ index: Int, animated: Bool = true) {
        guard index != selectedIndex else { return }
        selectedIndex = index
        updateButtonStyles(selectedIndex: index)

        let newLeading = tabLeadingOffsets[index]
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.slider.snp.updateConstraints {
                    $0.leading.equalToSuperview().offset(newLeading)
                }
                self.layoutIfNeeded()
            }
        } else {
            slider.snp.updateConstraints {
                $0.leading.equalToSuperview().offset(newLeading)
            }
        }
    }

    private func updateButtonStyles(selectedIndex: Int) {
        for (i, btn) in tabButtons.enumerated() {
            if i == selectedIndex {
                btn.setTitleColor(UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1), for: .normal)
                btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
            } else {
                btn.setTitleColor(UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1), for: .normal)
                btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
            }
        }
    }

    @objc private func tabTapped(_ sender: UIButton) {
        let index = sender.tag
        selectTab(index)
        onTabSelected?(index)
    }
}
