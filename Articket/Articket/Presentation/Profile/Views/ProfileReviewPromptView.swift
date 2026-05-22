import UIKit
import SnapKit

final class ProfileReviewPromptView: UIView {

    var onWriteTapped: (() -> Void)?

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "공연은 즐거우셨나요?"
        l.font = .systemFont(ofSize: 20, weight: .bold)
        l.textColor = UIColor(hex: "#333333")
        return l
    }()
    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "후기를 남겨 아티스트를 응원해보세요!"
        l.font = .systemFont(ofSize: 12)
        l.textColor = UIColor(hex: "#999999")
        return l
    }()

    private let cardView: UIView = {
        let v = UIView()
        return v
    }()
    private let posterImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(hex: "#E5E7EB")
        iv.layer.cornerRadius = 2
        return iv
    }()
    private let showTitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = UIColor(hex: "#333333")
        l.numberOfLines = 2
        return l
    }()
    private let writeButton: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 4
        v.clipsToBounds = true
        return v
    }()
    private let writeGradient = CAGradientLayer()
    private let writeLabel: UILabel = {
        let l = UILabel()
        l.text = "후기 작성"
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        writeGradient.frame = writeButton.bounds
    }

    private func setupUI() {
        writeGradient.colors = [UIColor(hex: "#121212").cgColor, UIColor(hex: "#333333").cgColor]
        writeGradient.startPoint = CGPoint(x: 0.5, y: 0)
        writeGradient.endPoint = CGPoint(x: 0.5, y: 1)
        writeButton.layer.insertSublayer(writeGradient, at: 0)

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 4

        [headerStack, cardView].forEach { addSubview($0) }
        [posterImageView, showTitleLabel, writeButton].forEach { cardView.addSubview($0) }
        writeButton.addSubview(writeLabel)

        headerStack.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.equalToSuperview().inset(20)
        }
        cardView.snp.makeConstraints {
            $0.top.equalTo(headerStack.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview()
            $0.height.equalTo(56)
        }
        posterImageView.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.width.equalTo(44)
        }
        showTitleLabel.snp.makeConstraints {
            $0.leading.equalTo(posterImageView.snp.trailing).offset(10)
            $0.centerY.equalToSuperview()
            $0.trailing.equalTo(writeButton.snp.leading).offset(-10)
        }
        writeButton.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.width.equalTo(72)
            $0.height.equalTo(32)
        }
        writeLabel.snp.makeConstraints { $0.edges.equalToSuperview() }

        let tap = UITapGestureRecognizer(target: self, action: #selector(writeTapped))
        writeButton.addGestureRecognizer(tap)
        writeButton.isUserInteractionEnabled = true
    }

    @objc private func writeTapped() {
        onWriteTapped?()
    }

    func configure(show: Event) {
        showTitleLabel.text = show.title
        posterImageView.loadImage(urlString: show.posterUrl)
    }
}
