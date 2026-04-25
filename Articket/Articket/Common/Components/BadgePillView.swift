import UIKit
import SnapKit

// 어두운 배경 + 흰 텍스트 pill 배지. PopularArtistCell에서 사용.
final class BadgePillView: UIView {

    private let label: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 10, weight: .bold)
        l.textColor = .white
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(white: 0, alpha: 0.8)
        layer.cornerRadius = 100
        clipsToBounds = true
        addSubview(label)
        label.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(4)
            $0.leading.trailing.equalToSuperview().inset(8)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func configure(text: String) {
        label.text = text
    }
}
