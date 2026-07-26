import UIKit
import SnapKit

// MARK: - 통계 상세 리스트 셀
// 홈 PLAY 통계 카드(최다관람/선호장르) 탭 시 하단에 뜨는 관람작 행 + "더보기" + 빈 상태.
// 최애 카드의 아티스트 행은 기존 ArtistRankingCell 재사용.

// MARK: - StatEventCell (관람작 한 건)

final class StatEventCell: UICollectionViewCell {
    static let reuseIdentifier = "StatEventCell"

    private let poster: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 4
        iv.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .bold)
        l.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        l.numberOfLines = 2
        return l
    }()

    private let subLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        l.numberOfLines = 1
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        let textStack = UIStackView(arrangedSubviews: [titleLabel, subLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let row = UIStackView(arrangedSubviews: [poster, textStack])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center

        poster.snp.makeConstraints { $0.width.equalTo(48); $0.height.equalTo(64) }

        contentView.addSubview(row)
        row.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(6)
            $0.leading.trailing.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func prepareForReuse() {
        super.prepareForReuse()
        poster.image = nil
    }

    func configure(with event: Event) {
        titleLabel.text = event.title
        subLabel.text = [event.dateRangeString, event.venueName]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
        poster.loadImage(urlString: event.posterUrl)
    }
}

// MARK: - StatSeeMoreCell ("더보기" / "접기")

final class StatSeeMoreCell: UICollectionViewCell {
    static let reuseIdentifier = "StatSeeMoreCell"

    private let label: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
        l.textAlignment = .center
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(label)
        label.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(10)
            $0.leading.trailing.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    /// expanded=true 는 최애 인라인 확장 상태(접기 노출), 그 외 "더보기 >"
    func configure(expanded: Bool) {
        label.text = expanded ? "접기" : "더보기"
    }
}

// MARK: - StatEmptyCell (해당 카드 데이터 0건)

final class StatEmptyCell: UICollectionViewCell {
    static let reuseIdentifier = "StatEmptyCell"

    private let label: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(label)
        label.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(16)
            $0.leading.trailing.equalToSuperview().inset(8)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func configure(kind: StatCardKind) {
        switch kind {
        case .topView:   label.text = "이 달에 본 공연 기록이 없어요"
        case .topGenre:  label.text = "이 장르의 관람 기록이 없어요"
        case .topArtist: label.text = "아직 관람한 공연이 없어요"
        }
    }
}
