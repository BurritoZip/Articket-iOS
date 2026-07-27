import UIKit
import SnapKit

final class PerformanceCell: UITableViewCell {

    static let reuseIdentifier = "PerformanceCell"

    // MARK: - UI

    private let startTimeLabel: UILabel = {
        let l = UILabel()
        l.font = .scaled(16, weight: .bold, textStyle: .headline)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(hex: "#333333")
        return l
    }()

    private let endTimeLabel: UILabel = {
        let l = UILabel()
        l.font = .scaled(12, weight: .regular, textStyle: .caption1)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(hex: "#767676")
        return l
    }()

    private let divider: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#E5E7EB")
        return v
    }()

    private let artistLabel: UILabel = {
        let l = UILabel()
        l.font = .scaled(16, weight: .bold, textStyle: .headline)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(hex: "#333333")
        return l
    }()

    private let stageLabel: UILabel = {
        let l = UILabel()
        l.font = .scaled(12, weight: .regular, textStyle: .caption1)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(hex: "#767676")
        return l
    }()

    private let dotLabel: UILabel = {
        let l = UILabel()
        l.text = "·"
        l.font = .scaled(12, weight: .regular, textStyle: .caption1)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(hex: "#767676")
        return l
    }()

    private let genreLabel: UILabel = {
        let l = UILabel()
        l.font = .scaled(12, weight: .regular, textStyle: .caption1)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(hex: "#121212")
        return l
    }()

    private let toggleButton: UIButton = {
        let b = UIButton(type: .custom)
        b.layer.cornerRadius = 4
        b.layer.borderWidth = 1
        return b
    }()

    // MARK: - State

    private var performanceIsSelected: Bool = false

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
        let timeStack = UIStackView(arrangedSubviews: [startTimeLabel, endTimeLabel])
        timeStack.axis = .vertical
        timeStack.spacing = 4
        timeStack.alignment = .leading

        let infoStack = UIStackView(arrangedSubviews: [stageLabel, dotLabel, genreLabel])
        infoStack.axis = .horizontal
        infoStack.spacing = 4
        infoStack.alignment = .center

        let artistStack = UIStackView(arrangedSubviews: [artistLabel, infoStack])
        artistStack.axis = .vertical
        artistStack.spacing = 4
        artistStack.alignment = .leading

        contentView.addSubview(timeStack)
        contentView.addSubview(divider)
        contentView.addSubview(artistStack)
        contentView.addSubview(toggleButton)

        timeStack.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.top.equalToSuperview().offset(16)
            $0.bottom.equalToSuperview().inset(16)
            $0.width.equalTo(56)
        }

        divider.snp.makeConstraints {
            $0.leading.equalTo(timeStack.snp.trailing).offset(16)
            $0.top.bottom.equalToSuperview()
            $0.width.equalTo(1)
        }

        toggleButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }

        artistStack.snp.makeConstraints {
            $0.leading.equalTo(divider.snp.trailing).offset(16)
            $0.trailing.equalTo(toggleButton.snp.leading).offset(-8)
            $0.centerY.equalToSuperview()
        }

        toggleButton.addTarget(self, action: #selector(toggleTapped), for: .touchUpInside)
        applyToggleAppearance()
    }

    // MARK: - Configure

    func configure(with performance: Performance, isSelected: Bool) {
        startTimeLabel.text = performance.startTime
        endTimeLabel.text = performance.endTime
        artistLabel.text = performance.artistName
        stageLabel.text = performance.stageName
        genreLabel.text = performance.genre
        performanceIsSelected = isSelected
        applyToggleAppearance()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onToggle = nil
    }

    // MARK: - Private

    private func applyToggleAppearance() {
        if performanceIsSelected {
            toggleButton.backgroundColor = UIColor(hex: "#121212")
            toggleButton.layer.borderColor = UIColor(hex: "#121212").cgColor
            let img = UIImage(named: "ic_minus_small")?.withRenderingMode(.alwaysTemplate)
            toggleButton.setImage(img, for: .normal)
            toggleButton.tintColor = .white
        } else {
            toggleButton.backgroundColor = .clear
            toggleButton.layer.borderColor = UIColor(hex: "#121212").cgColor
            let img = UIImage(named: "ic_plus_small")?.withRenderingMode(.alwaysTemplate)
            toggleButton.setImage(img, for: .normal)
            toggleButton.tintColor = UIColor(hex: "#121212")
        }
    }

    @objc private func toggleTapped() {
        onToggle?()
    }
}
