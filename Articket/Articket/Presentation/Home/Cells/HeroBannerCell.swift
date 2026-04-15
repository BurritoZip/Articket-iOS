import UIKit
import SnapKit

// Hero banner cell layout (full screen width):
//
//  ┌─────────────────── cell ────────────────────────────────────┐
//  │                                                              │ ← topInset (safeAreaTop+44+17)
//  │   ← 45pt → ┌──── posterContainer ────┐ ← 45pt →            │
//  │             │   imageView (1:1.43)    │                      │
//  │             │   + gradient overlay    │                      │
//  │             │   + title / subtitle    │                      │
//  │             └─────────────────────────┘                      │
//  │                    ← 20pt gap →                              │
//  │   ← 45pt → [seg0][seg1][seg2]...       ← 45pt →            │ ← 2.5pt bar
//  │                    ← 10pt →                                  │ ← bottom padding
//  └──────────────────────────────────────────────────────────────┘
//
// Each cell knows its own pageIndex → shows the correct active segment.
// No corner radius on the poster. No separate footer needed.

final class HeroBannerCell: UICollectionViewCell {
    static let reuseIdentifier = "HeroBannerCell"

    private let posterContainerView: UIView = {
        let v = UIView()
        v.clipsToBounds = true
        return v
    }()

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .tcSurface
        return iv
    }()

    private let gradientLayer: CAGradientLayer = {
        let gl = CAGradientLayer()
        gl.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.65).cgColor]
        gl.locations = [0.45, 1.0]
        return gl
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.85)
        return label
    }()

    private let progressStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.spacing = 4
        return sv
    }()

    private var progressSegmentViews: [UIView] = []
    private var lastTotalPages: Int = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        backgroundColor = .clear

        posterContainerView.addSubview(imageView)
        posterContainerView.addSubview(titleLabel)
        posterContainerView.addSubview(subtitleLabel)
        contentView.addSubview(posterContainerView)
        contentView.addSubview(progressStackView)

        // Progress bar: 2.5pt tall, 45pt side margins, 58pt above cell bottom
        progressStackView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(45)
            $0.height.equalTo(2.5)
            $0.bottom.equalToSuperview().inset(58)
        }

        // Poster: 45pt side margins, 1:1.43 aspect ratio, 20pt above progress bar
        posterContainerView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(45)
            $0.height.equalTo(posterContainerView.snp.width).multipliedBy(1.43)
            $0.bottom.equalTo(progressStackView.snp.top).offset(-20)
        }

        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        subtitleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(18)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(subtitleLabel.snp.top).offset(-4)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = posterContainerView.bounds
        if gradientLayer.superlayer == nil {
            posterContainerView.layer.insertSublayer(gradientLayer, above: imageView.layer)
        }
    }

    func configure(with event: Event, pageIndex: Int, totalPages: Int) {
        titleLabel.text = event.title
        subtitleLabel.text = "\(event.dateRangeString)  \(event.venueName)"
        if let name = event.imageAssetName {
            imageView.image = UIImage(named: name)
        } else {
            imageView.image = UIImage(systemName: "photo")
            imageView.tintColor = .tcTextSecondary
        }

        // Rebuild segments only when count changes
        if lastTotalPages != totalPages {
            progressStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            progressSegmentViews = []
            for _ in 0..<totalPages {
                let seg = UIView()
                progressStackView.addArrangedSubview(seg)
                progressSegmentViews.append(seg)
            }
            lastTotalPages = totalPages
        }

        // Active segment = this cell's own page index
        for (i, seg) in progressSegmentViews.enumerated() {
            seg.backgroundColor = i == pageIndex ? .white : UIColor.black.withAlphaComponent(0.6)
        }
    }
}
