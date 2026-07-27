import UIKit
import SnapKit

final class GridPanelCell: UITableViewCell {

    static let reuseIdentifier = "GridPanelCell"

    // MARK: - UI

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .scaled(16, weight: .bold, textStyle: .headline)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(hex: "#121212")
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .scaled(13, weight: .medium, textStyle: .footnote)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(hex: "#767676")
        return l
    }()

    private let toggleButton: UIButton = {
        let b = UIButton(type: .custom)
        b.layer.cornerRadius = 4
        b.layer.borderWidth = 1
        b.layer.borderColor = UIColor(hex: "#121212").cgColor
        return b
    }()

    private var isPerformanceSelected = false
    var onToggle: (() -> Void)?

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .white
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupUI() {
        let labelStack = UIStackView(arrangedSubviews: [nameLabel, subtitleLabel])
        labelStack.axis = .vertical
        labelStack.spacing = 4

        contentView.addSubview(labelStack)
        contentView.addSubview(toggleButton)

        labelStack.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(24)
            $0.trailing.equalTo(toggleButton.snp.leading).offset(-20)
            $0.centerY.equalToSuperview()
        }

        toggleButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(24)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }

        // contentView 는 autoresizing(전체 폭) 유지 — SnapKit 제약을 걸면
        // translatesAutoresizingMaskIntoConstraints=false 로 바뀌어 폭이 무너짐.
        // 높이 최소값만 raw anchor 로 지정.
        contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 72).isActive = true

        toggleButton.addTarget(self, action: #selector(toggleTapped), for: .touchUpInside)
        applyToggleAppearance()
    }

    // MARK: - Configure

    func configure(with performance: Performance, subtitle: String, isSelected: Bool) {
        nameLabel.text = performance.artistName
        subtitleLabel.text = subtitle
        isPerformanceSelected = isSelected
        applyToggleAppearance()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onToggle = nil
    }

    // MARK: - Private

    private func applyToggleAppearance() {
        if isPerformanceSelected {
            toggleButton.backgroundColor = UIColor(hex: "#121212")
            toggleButton.layer.borderColor = UIColor(hex: "#121212").cgColor
            toggleButton.setImage(
                UIImage(named: "ic_minus_small")?.withRenderingMode(.alwaysTemplate),
                for: .normal
            )
            toggleButton.tintColor = .white
        } else {
            toggleButton.backgroundColor = .clear
            toggleButton.layer.borderColor = UIColor(hex: "#121212").cgColor
            toggleButton.setImage(
                UIImage(named: "ic_plus_small")?.withRenderingMode(.alwaysTemplate),
                for: .normal
            )
            toggleButton.tintColor = UIColor(hex: "#121212")
        }
    }

    @objc private func toggleTapped() {
        onToggle?()
    }
}
