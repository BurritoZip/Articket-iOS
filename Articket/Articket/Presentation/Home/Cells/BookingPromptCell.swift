import UIKit
import SnapKit

// MARK: - BookingPromptCell
// 외부 예매처에 다녀온 뒤 "예매하셨나요?"를 되묻는 가로 띠형 배너.
//
// 예매하기는 외부 링크로 나가므로 앱이 결과를 알 수 없다. 사용자가 직접 답해야만
// 예매 기록이 생기는데, 상세 화면에 다시 들어가서 누르길 기대하긴 어렵다.
// 그래서 복귀 직후 반드시 보게 되는 홈 최상단(히어로 배너 바로 아래)에서 묻는다.

final class BookingPromptCell: UICollectionViewCell {

    static let reuseIdentifier = "BookingPromptCell"

    var onConfirm: (() -> Void)?
    var onDismiss: (() -> Void)?

    // MARK: - Views

    private let container: UIView = {
        let v = UIView()
        v.backgroundColor = .tcSurface
        v.layer.cornerRadius = 12
        v.clipsToBounds = true
        return v
    }()

    private let posterImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 6
        iv.backgroundColor = .tcSeparator
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .semibold)
        l.textColor = .tcTextPrimary
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        return l
    }()

    private let questionLabel: UILabel = {
        let l = UILabel()
        l.text = "예매하셨나요?"
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textColor = .tcTextSecondary
        return l
    }()

    private let yesButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("네", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        b.backgroundColor = .tcInk
        b.layer.cornerRadius = 8
        return b
    }()

    private let noButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("아니요", for: .normal)
        b.setTitleColor(.tcTextSecondary, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        b.backgroundColor = .tcBackground
        b.layer.cornerRadius = 8
        b.layer.borderWidth = 1
        b.layer.borderColor = UIColor.tcFieldBorder.cgColor
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
        posterImageView.image = nil
        onConfirm = nil
        onDismiss = nil
    }

    // MARK: - Setup

    private func setupLayout() {
        contentView.addSubview(container)
        container.snp.makeConstraints { $0.edges.equalToSuperview() }

        posterImageView.snp.makeConstraints {
            $0.width.equalTo(38)
            $0.height.equalTo(52)
        }

        let textStack = UIStackView(arrangedSubviews: [titleLabel, questionLabel])
        textStack.axis = .vertical
        textStack.spacing = 3
        textStack.alignment = .leading

        // 포스터를 stack의 arranged subview로 두면 isHidden 시 자리까지 접힌다
        // (일반 subview + 제약이면 숨겨도 폭이 남아 텍스트가 밀린다)
        let leadingStack = UIStackView(arrangedSubviews: [posterImageView, textStack])
        leadingStack.axis = .horizontal
        leadingStack.spacing = 10
        leadingStack.alignment = .center
        container.addSubview(leadingStack)

        let buttonStack = UIStackView(arrangedSubviews: [noButton, yesButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 6
        buttonStack.distribution = .fillEqually

        container.addSubview(buttonStack)
        buttonStack.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(122)
            $0.height.equalTo(34)
        }

        leadingStack.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(12)
            $0.trailing.lessThanOrEqualTo(buttonStack.snp.leading).offset(-10)
            $0.centerY.equalToSuperview()
        }
    }

    // MARK: - Actions

    @objc private func yesTapped() { onConfirm?() }
    @objc private func noTapped() { onDismiss?() }

    // MARK: - Configure

    func configure(with intent: BookingIntent) {
        titleLabel.text = intent.eventTitle
        if let poster = intent.posterUrl, !poster.isEmpty {
            posterImageView.isHidden = false
            posterImageView.loadImage(urlString: poster)
        } else {
            // 포스터가 없으면 자리를 비우지 않고 아예 숨겨 텍스트가 왼쪽부터 차게 한다
            posterImageView.isHidden = true
        }
    }
}
