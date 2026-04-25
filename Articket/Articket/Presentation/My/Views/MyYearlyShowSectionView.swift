import UIKit
import SnapKit

final class MyYearlyShowSectionView: UIView {

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "올해 본 공연"
        l.font = .systemFont(ofSize: 20, weight: .bold)
        l.textColor = UIColor(hex: "#333333")
        return l
    }()
    private let moreButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("더보기", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        b.setTitleColor(UIColor(hex: "#767676"), for: .normal)
        return b
    }()

    private let scrollView: UIScrollView = {
        let s = UIScrollView()
        s.showsHorizontalScrollIndicator = false
        s.clipsToBounds = false
        return s
    }()
    private let stackView: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 16
        s.alignment = .center
        return s
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        addSubview(titleLabel)
        addSubview(moreButton)
        addSubview(scrollView)
        scrollView.addSubview(stackView)

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.equalToSuperview().inset(24)
            $0.centerY.equalTo(moreButton)
        }
        moreButton.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.trailing.equalToSuperview().inset(24)
        }
        // scrollView: full width, height = 180(poster) + 8(gap) + ~57(text) = 245
        scrollView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.height.equalTo(245)
        }
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalToSuperview()
        }
    }

    func configure(shows: [Event]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let leading = UIView()
        leading.snp.makeConstraints { $0.width.equalTo(24) }
        stackView.addArrangedSubview(leading)

        shows.forEach { show in
            let card = YearlyShowCardView()
            card.configure(show: show)
            stackView.addArrangedSubview(card)
        }

        let trailing = UIView()
        trailing.snp.makeConstraints { $0.width.equalTo(24) }
        stackView.addArrangedSubview(trailing)
    }
}

// MARK: - YearlyShowCardView

private final class YearlyShowCardView: UIView {

    // 그림자는 posterView 레이어에, 이미지 클립은 posterImageView에 분리
    private let posterView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.layer.shadowColor = UIColor(red: 18/255, green: 18/255, blue: 18/255, alpha: 0.3).cgColor
        v.layer.shadowOffset = CGSize(width: 0, height: 1.9)
        v.layer.shadowRadius = 6.4
        v.layer.shadowOpacity = 1
        return v
    }()
    private let posterImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(hex: "#D1D5DB")
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .bold)
        l.textColor = UIColor(hex: "#333333")
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        return l
    }()
    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 10)
        l.textColor = UIColor(hex: "#999999")
        return l
    }()
    private let venueLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 10, weight: .medium)
        l.textColor = UIColor(hex: "#999999")
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        return l
    }()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd"
        return f
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        // 텍스트 영역: Figma flex-col, gap 없이 line-height로 간격 결정
        let textStack = UIStackView(arrangedSubviews: [titleLabel, dateLabel, venueLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading

        addSubview(posterView)
        posterView.addSubview(posterImageView)
        addSubview(textStack)

        snp.makeConstraints { $0.width.equalTo(128) }

        posterView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(180)
        }
        posterImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        textStack.snp.makeConstraints {
            $0.top.equalTo(posterView.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.lessThanOrEqualToSuperview()
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(show: Event) {
        titleLabel.text = show.title
        let start = Self.dateFormatter.string(from: show.startDate)
        let end = Self.dateFormatter.string(from: show.endDate)
        dateLabel.text = "\(start) ~ \(end)"
        venueLabel.text = show.venueName
        if let assetName = show.imageAssetName, let img = UIImage(named: assetName) {
            posterImageView.image = img
        } else {
            posterImageView.image = nil
        }
    }
}
