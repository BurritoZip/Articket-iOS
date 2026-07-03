import UIKit
import SnapKit

final class PerformanceActionSheetViewController: UIViewController {

    private let performance: Performance
    var onDelete: (() -> Void)?
    var onEdit: (() -> Void)?

    // MARK: - UI

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18, weight: .bold)
        l.textColor = UIColor(hex: "#121212")
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textColor = UIColor(hex: "#767676")
        return l
    }()

    private let editButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitleColor(UIColor(hex: "#121212"), for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        b.contentHorizontalAlignment = .left
        return b
    }()

    private let deleteButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitleColor(UIColor(hex: "#121212"), for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        b.contentHorizontalAlignment = .left
        return b
    }()

    // MARK: - Init

    init(performance: Performance) {
        self.performance = performance
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()

        let dur = minsFromTime(performance.endTime) - minsFromTime(performance.startTime)
        nameLabel.text = performance.artistName
        subtitleLabel.text = "\(performance.stageName) · \(dur)분 · \(performance.startTime) ~ \(performance.endTime)"
        editButton.setTitle("수정", for: .normal)
        deleteButton.setTitle("삭제", for: .normal)

        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
    }

    // MARK: - Setup

    private func setupUI() {
        let editIcon = makeIcon("pencil")
        let deleteIcon = makeIcon("trash")

        let editRow = makeRow(icon: editIcon, button: editButton)
        let deleteRow = makeRow(icon: deleteIcon, button: deleteButton)

        let sep = UIView()
        sep.backgroundColor = UIColor(hex: "#F3F4F6")

        [nameLabel, subtitleLabel, editRow, sep, deleteRow].forEach { view.addSubview($0) }

        nameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(28)
            $0.leading.equalToSuperview().offset(24)
            $0.trailing.equalToSuperview().inset(24)
        }
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalTo(nameLabel)
        }
        editRow.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(52)
        }
        sep.snp.makeConstraints {
            $0.top.equalTo(editRow.snp.bottom)
            $0.leading.equalToSuperview().offset(24)
            $0.trailing.equalToSuperview()
            $0.height.equalTo(1)
        }
        deleteRow.snp.makeConstraints {
            $0.top.equalTo(sep.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(52)
        }
    }

    private func makeIcon(_ systemName: String) -> UIImageView {
        let iv = UIImageView(image: UIImage(systemName: systemName))
        iv.tintColor = UIColor(hex: "#121212")
        iv.contentMode = .scaleAspectFit
        return iv
    }

    private func makeRow(icon: UIImageView, button: UIButton) -> UIView {
        let container = UIView()
        container.addSubview(icon)
        container.addSubview(button)
        icon.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(24)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(18)
        }
        button.snp.makeConstraints {
            $0.leading.equalTo(icon.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().inset(24)
            $0.centerY.equalToSuperview()
            $0.height.equalToSuperview()
        }
        return container
    }

    // MARK: - Actions

    @objc private func editTapped() {
        dismiss(animated: true) { [weak self] in
            self?.onEdit?()
        }
    }

    @objc private func deleteTapped() {
        dismiss(animated: true) { [weak self] in
            self?.onDelete?()
        }
    }

    private func minsFromTime(_ t: String) -> Int {
        let p = t.split(separator: ":")
        return (Int(p.first ?? "0") ?? 0) * 60 + (p.count > 1 ? Int(p[1]) ?? 0 : 0)
    }
}
