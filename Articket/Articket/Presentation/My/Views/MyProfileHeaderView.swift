import UIKit
import SnapKit

final class MyProfileHeaderView: UIView {

    // MARK: - Subviews

    private let gradientLayer = CAGradientLayer()

    private let avatarView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 32
        v.clipsToBounds = true
        return v
    }()
    private let avatarGradient = CAGradientLayer()
    private let initialLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 20, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 20, weight: .bold)
        l.textColor = UIColor(hex: "#333333")
        return l
    }()
    private let emailLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = UIColor(hex: "#767676")
        return l
    }()

    private let concertCard = StatCardView(labelText: "관람 공연")
    private let followCard = StatCardView(labelText: "팔로우 아티스트")
    private let lastVisitCard = StatCardView(labelText: "마지막 관람일")

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        avatarGradient.frame = avatarView.bounds
    }

    // MARK: - Setup

    private func setupUI() {
        // 배경 그라데이션 (152° ≈ top-left → bottom-right)
        gradientLayer.colors = [UIColor(hex: "#F9FAFB").cgColor, UIColor(hex: "#F3F4F6").cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.24, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.76, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)

        // 아바타 그라데이션
        avatarGradient.colors = [UIColor(hex: "#121212").cgColor, UIColor(hex: "#333333").cgColor]
        avatarGradient.startPoint = CGPoint(x: 0.5, y: 0)
        avatarGradient.endPoint = CGPoint(x: 0.5, y: 1)
        avatarView.layer.insertSublayer(avatarGradient, at: 0)
        avatarView.addSubview(initialLabel)

        let topBorder = UIView()
        topBorder.backgroundColor = UIColor(hex: "#E5E7EB")
        let bottomBorder = UIView()
        bottomBorder.backgroundColor = UIColor(hex: "#E5E7EB")

        // 닉네임 + 이메일 스택
        let nameStack = UIStackView(arrangedSubviews: [nameLabel, emailLabel])
        nameStack.axis = .vertical
        nameStack.spacing = 2
        nameStack.alignment = .leading

        // 프로필 행: 아바타 | 이름/이메일
        let profileRow = UIStackView(arrangedSubviews: [avatarView, nameStack])
        profileRow.axis = .horizontal
        profileRow.spacing = 16
        profileRow.alignment = .center

        // 통계 카드 행
        let cardRow = UIStackView(arrangedSubviews: [concertCard, followCard, lastVisitCard])
        cardRow.axis = .horizontal
        cardRow.spacing = 12
        cardRow.distribution = .fillEqually

        // 전체 컨텐츠 스택 (py-24, gap-20)
        let contentStack = UIStackView(arrangedSubviews: [profileRow, cardRow])
        contentStack.axis = .vertical
        contentStack.spacing = 20

        [topBorder, bottomBorder, contentStack].forEach { addSubview($0) }

        topBorder.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(1)
        }
        bottomBorder.snp.makeConstraints {
            $0.bottom.leading.trailing.equalToSuperview()
            $0.height.equalTo(1)
        }
        contentStack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(24)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(24)
        }
        avatarView.snp.makeConstraints { $0.size.equalTo(64) }
        initialLabel.snp.makeConstraints { $0.center.equalToSuperview() }
        cardRow.snp.makeConstraints { $0.height.equalTo(72) }
    }

    // MARK: - Configure

    func configure(with profile: UserProfile) {
        initialLabel.text = profile.initial
        nameLabel.text = profile.displayName
        emailLabel.text = profile.email
        emailLabel.isHidden = profile.email.isEmpty
        concertCard.configure(value: "\(profile.concertCount)")
        followCard.configure(value: "\(profile.followingArtistCount)")
        lastVisitCard.configure(value: profile.lastVisitDateString)
    }
}

// MARK: - StatCardView

private final class StatCardView: UIView {

    private let valueLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18, weight: .bold)
        l.textColor = UIColor(hex: "#121212")
        l.textAlignment = .center
        return l
    }()
    private let descLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = UIColor(hex: "#767676")
        l.textAlignment = .center
        return l
    }()

    init(labelText: String) {
        super.init(frame: .zero)
        backgroundColor = UIColor.white.withAlphaComponent(0.8)
        layer.cornerRadius = 8

        descLabel.text = labelText

        let stack = UIStackView(arrangedSubviews: [valueLabel, descLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .center
        addSubview(stack)
        stack.snp.makeConstraints { $0.center.equalToSuperview() }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(value: String) {
        valueLabel.text = value
        // 마지막 관람일(MM.dd 형식)은 폰트 16pt, 나머지 18pt
        valueLabel.font = value.contains(".") && !value.allSatisfy({ $0.isNumber })
            ? .systemFont(ofSize: 16, weight: .bold)
            : .systemFont(ofSize: 18, weight: .bold)
    }
}
