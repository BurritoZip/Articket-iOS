import UIKit
import SnapKit

final class SimpleNavigationBar: UIView {

    var onBackTapped: (() -> Void)?

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        l.textColor = UIColor(hex: "#121212")
        l.textAlignment = .center
        return l
    }()

    private let backButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        b.tintColor = UIColor(hex: "#121212")
        b.accessibilityLabel = "뒤로"
        return b
    }()

    private let bottomBorder: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#F3F4F6")
        return v
    }()

    init(title: String) {
        super.init(frame: .zero)
        backgroundColor = .white
        titleLabel.text = title

        [backButton, titleLabel, bottomBorder].forEach { addSubview($0) }

        backButton.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(4)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(44)
        }
        titleLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        bottomBorder.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError() }

    func setTitle(_ title: String) { titleLabel.text = title }

    @objc private func backTapped() { onBackTapped?() }
}
