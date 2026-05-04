import UIKit
import SnapKit

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

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        backgroundColor = .clear

        posterContainerView.addSubview(imageView)
        contentView.addSubview(posterContainerView)

        posterContainerView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(45)
            $0.height.equalTo(posterContainerView.snp.width).multipliedBy(1.43)
            $0.bottom.equalToSuperview().inset(HomeCollectionViewLayoutFactory.heroBannerProgressAreaHeight)
        }

        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func configure(with event: Event) {
        imageView.loadImage(urlString: event.posterUrl)
    }
}
