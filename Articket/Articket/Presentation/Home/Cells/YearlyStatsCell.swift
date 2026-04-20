import UIKit
import SnapKit

// MARK: - YearlySubtitleCell
// Figma 1:1495: "2025년에는 총 22번 관람하셨네요!"
// 12pt regular #999, lineHeight 28pt, tracking -0.44pt

final class YearlySubtitleCell: UICollectionViewCell {
    static let reuseIdentifier = "YearlySubtitleCell"

    private let label: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)  // #999
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(label)
        label.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 0, bottom: 12, right: 0))
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func configure(with stats: MyStats) {
        label.text = "\(stats.year)년에는 총 \(stats.totalCount)번 관람하셨네요!"
    }
}

// MARK: - YearlyChartCell
// Figma 1:1501: 핑크 그라데이션 카드, 12개 막대 차트 + 월 레이블

final class YearlyChartCell: UICollectionViewCell {
    static let reuseIdentifier = "YearlyChartCell"

    private let containerView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 4
        v.layer.borderColor = UIColor(red: 0.988, green: 0.906, blue: 0.953, alpha: 1).cgColor  // #fce7f3
        v.layer.borderWidth = 1
        v.clipsToBounds = true
        return v
    }()

    private let gradientLayer: CAGradientLayer = {
        let l = CAGradientLayer()
        // linear-gradient(153.43°, #fdf2f8 → #fff7ed)
        l.colors = [
            UIColor(red: 0.992, green: 0.949, blue: 0.973, alpha: 1).cgColor,
            UIColor(red: 1, green: 0.969, blue: 0.929, alpha: 1).cgColor
        ]
        l.startPoint = CGPoint(x: 0.133, y: 0)
        l.endPoint = CGPoint(x: 0.867, y: 1)
        return l
    }()

    private let chartView = BarChartView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(containerView)
        containerView.layer.insertSublayer(gradientLayer, at: 0)
        containerView.addSubview(chartView)
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = containerView.bounds
    }

    private func setupLayout() {
        containerView.snp.makeConstraints { $0.edges.equalToSuperview() }
        chartView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(20)
            $0.height.equalTo(127)  // 112pt bars+labels area + 15pt labels
        }
    }

    func configure(with stats: MyStats) {
        chartView.configure(counts: stats.monthlyViewCounts)
    }
}

// MARK: - StatCardKind

enum StatCardKind: Sendable {
    case topView
    case topGenre
    case topArtist
}

// MARK: - YearlyStatRowCell
// Figma 1:1574, 1:1580, 1:1586: 최다관람/선호장르/최애아티스트 카드 3개 가로 배열
// 탭 시 해당 카드에 선택 테두리(#333 1.5pt), 나머지는 기본 테두리(#E5E7EB 1pt)

final class YearlyStatRowCell: UICollectionViewCell {
    static let reuseIdentifier = "YearlyStatRowCell"

    var onCardTapped: ((StatCardKind) -> Void)?

    private let topViewCard = StatItemCard()
    private let topGenreCard = StatItemCard()
    private let topArtistCard = StatItemCard()

    private var selectedKind: StatCardKind?

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.spacing = 8
        return sv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        stackView.addArrangedSubview(topViewCard)
        stackView.addArrangedSubview(topGenreCard)
        stackView.addArrangedSubview(topArtistCard)
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { $0.edges.equalToSuperview() }

        topViewCard.onTapped = { [weak self] in self?.selectCard(.topView) }
        topGenreCard.onTapped = { [weak self] in self?.selectCard(.topGenre) }
        topArtistCard.onTapped = { [weak self] in self?.selectCard(.topArtist) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    private func selectCard(_ kind: StatCardKind) {
        selectedKind = kind
        topViewCard.setSelected(kind == .topView)
        topGenreCard.setSelected(kind == .topGenre)
        topArtistCard.setSelected(kind == .topArtist)
        onCardTapped?(kind)
    }

    func configure(with stats: MyStats) {
        topViewCard.configure(title: "최다 관람", value: "\(stats.topMonth)월")
        topGenreCard.configure(title: "선호 장르", value: stats.topGenre)
        topArtistCard.configure(title: "최애 아티스트", value: stats.topArtist)
    }
}

// MARK: - StatItemCard
// Figma 1:1574/1:1580/1:1586: white bg, 4pt radius, 12pt padding, 11pt title + 14pt bold value
// 기본: #E5E7EB 1pt 테두리 / 선택: #333 1.5pt 테두리
// 투명 UIButton overlay로 탭 이벤트를 처리 — UIStackView 내부에서도 안정적으로 동작

private final class StatItemCard: UIView {
    var onTapped: (() -> Void)?

    private static let defaultBorderColor = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1).cgColor
    private static let selectedBorderColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1).cgColor

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .regular)
        l.textColor = UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1)
        l.textAlignment = .center
        return l
    }()

    private let valueLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .bold)
        l.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        l.textAlignment = .center
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.7
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.cornerRadius = 4
        layer.borderColor = StatItemCard.defaultBorderColor
        layer.borderWidth = 1

        addSubview(titleLabel)
        addSubview(valueLabel)

        titleLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(12)
        }
        valueLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(12)
            $0.bottom.equalToSuperview().inset(12)
        }

        // 투명 버튼을 최상위에 올려 UIStackView 내부에서도 안정적으로 터치 수신
        let tapButton = UIButton(type: .system)
        tapButton.backgroundColor = .clear
        tapButton.addTarget(self, action: #selector(cardTapped), for: .touchUpInside)
        addSubview(tapButton)
        tapButton.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func configure(title: String, value: String) {
        titleLabel.text = title
        valueLabel.text = value
    }

    func setSelected(_ selected: Bool) {
        layer.borderColor = selected ? StatItemCard.selectedBorderColor : StatItemCard.defaultBorderColor
        layer.borderWidth = selected ? 1.5 : 1
    }

    @objc private func cardTapped() {
        onTapped?()
    }
}

// MARK: - BarChartView
// Figma 1:1501: 막대 위 count label(10pt bold #121212), 막대(dark gradient), 아래 월 label(10pt medium #767676)

private final class BarChartView: UIView {
    private var counts: [Int] = Array(repeating: 0, count: 12)

    // 막대 + count label 쌍을 12개 보관
    private var bars: [(bar: UIView, countLabel: UILabel)] = []
    private var monthLabels: [UILabel] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        for i in 0..<12 {
            let bar = UIView()
            bar.layer.cornerRadius = 4
            // dark gradient: rgba(18,18,18,0.8) → rgba(51,51,51,0.8)
            let gradient = CAGradientLayer()
            gradient.colors = [
                UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 0.8).cgColor,
                UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.8).cgColor
            ]
            gradient.startPoint = CGPoint(x: 0.5, y: 0)
            gradient.endPoint = CGPoint(x: 0.5, y: 1)
            gradient.cornerRadius = 4
            bar.layer.insertSublayer(gradient, at: 0)
            addSubview(bar)

            let countLabel = UILabel()
            countLabel.font = .systemFont(ofSize: 10, weight: .bold)
            countLabel.textColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1)
            countLabel.textAlignment = .center
            addSubview(countLabel)

            let monthLabel = UILabel()
            monthLabel.text = String(format: "%02d", i + 1)
            monthLabel.font = .systemFont(ofSize: 10, weight: .medium)
            monthLabel.textColor = UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1)
            monthLabel.textAlignment = .center
            addSubview(monthLabel)

            bars.append((bar, countLabel))
            monthLabels.append(monthLabel)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func configure(counts: [Int]) {
        self.counts = counts
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0 else { return }

        let monthLabelHeight: CGFloat = 15
        let countLabelHeight: CGFloat = 15
        let barAreaHeight = bounds.height - monthLabelHeight
        let maxBarHeight = barAreaHeight - countLabelHeight - 8  // 8pt gap above bar
        let maxCount = counts.max().map { max($0, 1) } ?? 1

        let totalWidth = bounds.width
        let spacing: CGFloat = 2
        let barWidth = (totalWidth - spacing * 11) / 12

        for i in 0..<12 {
            let (bar, countLabel) = bars[i]
            let count = counts[i]
            let barHeight = count > 0 ? max(maxBarHeight * CGFloat(count) / CGFloat(maxCount), 4) : 4
            let x = CGFloat(i) * (barWidth + spacing)

            // 막대: 바닥에서 위로 쌓임 (barAreaHeight 기준)
            let barY = barAreaHeight - barHeight
            bar.frame = CGRect(x: x, y: barY, width: barWidth, height: barHeight)
            bar.layer.sublayers?.first?.frame = bar.bounds
            bar.alpha = count == 0 ? 0.2 : 1.0

            // count label: 막대 바로 위
            let countY = barY - countLabelHeight - 2
            countLabel.frame = CGRect(x: x, y: max(countY, 0), width: barWidth, height: countLabelHeight)
            countLabel.text = count > 0 ? "\(count)" : ""

            // 월 label: 하단
            monthLabels[i].frame = CGRect(
                x: x, y: bounds.height - monthLabelHeight,
                width: barWidth, height: monthLabelHeight
            )
        }
    }
}
