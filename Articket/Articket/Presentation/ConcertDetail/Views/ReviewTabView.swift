import UIKit
import SnapKit

// MARK: - ReviewTabView
// Figma 1:2326 — 후기 탭: 안내 문구 + 후기 작성 버튼 + 리뷰 리스트

final class ReviewTabView: UIView {

    private let mainStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 12
        return sv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(mainStack)
        mainStack.snp.makeConstraints {
            $0.top.equalToSuperview().inset(24)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(24)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with detail: ConcertDetail) {
        mainStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // 안내 문구
        let guideLabel = UILabel()
        guideLabel.text = "공연이 끝난 뒤 느꼈던\n생생한 감동을 후기로 남겨주세요."
        guideLabel.font = .systemFont(ofSize: 12, weight: .regular)
        guideLabel.textColor = UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1)
        guideLabel.textAlignment = .center
        guideLabel.numberOfLines = 2
        mainStack.addArrangedSubview(guideLabel)

        // 후기 작성 버튼 (outlined)
        let writeButton = UIButton(type: .system)
        writeButton.setTitle("후기 작성", for: .normal)
        writeButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        writeButton.setTitleColor(UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1), for: .normal)
        writeButton.layer.borderColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1).cgColor
        writeButton.layer.borderWidth = 1
        writeButton.layer.cornerRadius = 8
        writeButton.snp.makeConstraints { $0.height.equalTo(47) }
        mainStack.addArrangedSubview(writeButton)

        guard !detail.reviews.isEmpty else { return }

        // 구분선
        let separator = UIView()
        separator.backgroundColor = UIColor(red: 0.953, green: 0.957, blue: 0.961, alpha: 1) // #f3f4f5
        separator.snp.makeConstraints { $0.height.equalTo(1) }
        mainStack.addArrangedSubview(separator)

        // 리뷰 리스트 (gap-24)
        let reviewStack = UIStackView()
        reviewStack.axis = .vertical
        reviewStack.spacing = 24
        for review in detail.reviews {
            reviewStack.addArrangedSubview(makeReviewCell(review))
        }
        mainStack.addArrangedSubview(reviewStack)
    }

    // MARK: - Review Cell Builder

    private func makeReviewCell(_ review: ConcertReview) -> UIView {
        let cell = UIStackView()
        cell.axis = .vertical
        cell.spacing = 6

        // 별점 행 — trailing spacer로 별들을 leading에 고정
        let starsRow = UIStackView()
        starsRow.axis = .horizontal
        starsRow.spacing = 2
        for i in 0..<5 {
            let star = UIImageView()
            let name = i < review.starCount ? "star.fill" : "star"
            star.image = UIImage(systemName: name)
            star.tintColor = UIColor(red: 1.0, green: 0.76, blue: 0.0, alpha: 1)
            star.contentMode = .scaleAspectFit
            star.snp.makeConstraints { $0.size.equalTo(17) }
            starsRow.addArrangedSubview(star)
        }
        let starsSpacer = UIView()
        starsSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        starsRow.addArrangedSubview(starsSpacer)
        cell.addArrangedSubview(starsRow)

        // 제목
        let titleLabel = UILabel()
        titleLabel.text = review.title
        titleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        titleLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        cell.addArrangedSubview(titleLabel)

        // 닉네임
        let usernameLabel = UILabel()
        usernameLabel.text = review.username
        usernameLabel.font = .systemFont(ofSize: 13, weight: .regular)
        usernameLabel.textColor = UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1)
        cell.addArrangedSubview(usernameLabel)

        // 날짜
        let dateLabel = UILabel()
        dateLabel.text = review.date
        dateLabel.font = .systemFont(ofSize: 13, weight: .regular)
        dateLabel.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        cell.addArrangedSubview(dateLabel)

        // 본문 미리보기 박스
        let contentBox = makeContentBox(text: review.content)
        cell.addArrangedSubview(contentBox)

        return cell
    }

    private func makeContentBox(text: String) -> UIView {
        let box = UIView()
        box.backgroundColor = UIColor(red: 0.953, green: 0.957, blue: 0.961, alpha: 1) // #f3f4f5
        box.layer.borderColor = UIColor(red: 0.953, green: 0.957, blue: 0.961, alpha: 1).cgColor
        box.layer.borderWidth = 1
        box.snp.makeConstraints { $0.height.equalTo(120) }
        box.clipsToBounds = true

        let contentLabel = UILabel()
        contentLabel.text = text
        contentLabel.font = .systemFont(ofSize: 14, weight: .regular)
        contentLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        contentLabel.numberOfLines = 0
        box.addSubview(contentLabel)
        contentLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(16)
        }

        // 더보기 아이콘 (하단 중앙)
        let chevron = UIImageView(image: UIImage(systemName: "chevron.down"))
        chevron.tintColor = UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1)
        chevron.contentMode = .scaleAspectFit
        box.addSubview(chevron)
        chevron.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().inset(8)
            $0.size.equalTo(16)
        }

        return box
    }
}
