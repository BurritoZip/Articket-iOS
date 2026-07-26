import UIKit
import SnapKit

// MARK: - BookingPromptCell
// 외부 예매처에 다녀온 뒤 "예매하셨나요?"를 되묻는 미니멀 가로 띠형 배너.
//
// 예매하기는 외부 링크로 나가므로 앱이 결과를 알 수 없다. 사용자가 직접 답해야만
// 예매 기록이 생기는데, 상세 화면에 다시 들어가서 누르길 기대하긴 어렵다.
// 그래서 복귀 직후 반드시 보게 되는 홈 최상단(히어로 배너 바로 아래)에서 묻는다.
//
// 디자인: 포스터·2행 텍스트를 걷어낸 얇은 한 줄 바. 위(히어로)·아래(섹션) 사이에서
// 광고 배너처럼 조용히 끼어들도록 높이를 낮추고 좌우 여백을 다른 홈 섹션과 맞춘다.

final class BookingPromptCell: UICollectionViewCell {

    static let reuseIdentifier = "BookingPromptCell"

    var onConfirm: (() -> Void)?
    var onDismiss: (() -> Void)?

    // MARK: - Views

    private let container: UIView = {
        let v = UIView()
        v.backgroundColor = .tcSurface
        v.layer.cornerRadius = 10
        v.clipsToBounds = true
        return v
    }()

    // 티켓 글리프 — 이 바가 "예매 확인"임을 한눈에 전달
    private let iconView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "ticket"))
        iv.tintColor = .tcTextSecondary
        iv.contentMode = .scaleAspectFit
        iv.setContentHuggingPriority(.required, for: .horizontal)
        return iv
    }()

    // "{공연명} 예매하셨어요?" 한 줄. 공연명이 길면 말줄임.
    private let messageLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = .tcTextPrimary
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        return l
    }()

    private let yesButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("네", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        b.backgroundColor = .tcInk
        b.layer.cornerRadius = 7
        return b
    }()

    private let noButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("아니요", for: .normal)
        b.setTitleColor(.tcTextSecondary, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        b.backgroundColor = .clear
        return b
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        yesButton.addTarget(self, action: #selector(yesTapped), for: .touchUpInside)
        noButton.addTarget(self, action: #selector(noTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        onConfirm = nil
        onDismiss = nil
    }

    // MARK: - Setup

    private func setupLayout() {
        contentView.addSubview(container)
        container.snp.makeConstraints { $0.edges.equalToSuperview() }

        iconView.snp.makeConstraints { $0.size.equalTo(16) }

        let leadingStack = UIStackView(arrangedSubviews: [iconView, messageLabel])
        leadingStack.axis = .horizontal
        leadingStack.spacing = 8
        leadingStack.alignment = .center
        container.addSubview(leadingStack)

        // 아니요(고스트) + 네(솔리드). 얇은 바라 버튼도 낮게.
        let buttonStack = UIStackView(arrangedSubviews: [noButton, yesButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 4
        buttonStack.alignment = .center
        container.addSubview(buttonStack)

        yesButton.snp.makeConstraints {
            $0.width.equalTo(40)
            $0.height.equalTo(28)
        }
        noButton.snp.makeConstraints { $0.height.equalTo(28) }

        buttonStack.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(10)
            $0.centerY.equalToSuperview()
        }
        leadingStack.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(14)
            $0.trailing.lessThanOrEqualTo(buttonStack.snp.leading).offset(-8)
            $0.centerY.equalToSuperview()
        }
    }

    // MARK: - Actions

    @objc private func yesTapped() { onConfirm?() }
    @objc private func noTapped() { onDismiss?() }

    // MARK: - Configure

    func configure(with intent: BookingIntent) {
        let title = intent.eventTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        messageLabel.text = title.isEmpty ? "예매하셨어요?" : "‘\(title)’ 예매하셨어요?"
    }
}
