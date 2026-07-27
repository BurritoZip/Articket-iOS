import UIKit
import SnapKit

// MARK: - SalesInfoTabView
// Figma 1:2243 — 판매정보 탭: 상태에 따른 메시지 박스

final class SalesInfoTabView: UIView {

    private let messageBox: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 8
        v.clipsToBounds = true
        return v
    }()

    private let messageLabel: UILabel = {
        let l = UILabel()
        l.font = .scaled(14, weight: .medium, textStyle: .body)
        l.adjustsFontForContentSizeCategory = true
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        messageBox.addSubview(messageLabel)
        messageLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        addSubview(messageBox)
        messageBox.snp.makeConstraints {
            $0.top.equalToSuperview().inset(24)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(24)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with detail: ConcertDetail) {
        // status를 모르면 안내 박스 자체를 숨긴다 (추측성 문구 노출 방지)
        guard let status = detail.status else {
            messageBox.isHidden = true
            return
        }
        messageBox.isHidden = false
        switch status {
        case .ended:
            messageBox.backgroundColor = UIColor(red: 0.953, green: 0.957, blue: 0.965, alpha: 1) // #f3f4f6
            messageBox.layer.borderWidth = 0
            messageLabel.text = "판매가 종료됐어요"
            messageLabel.textColor = UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1)
        case .onSale:
            messageBox.backgroundColor = UIColor(red: 0.941, green: 0.976, blue: 0.953, alpha: 1) // light green
            messageBox.layer.borderWidth = 0
            messageLabel.text = "현재 예매 진행 중입니다."
            messageLabel.textColor = UIColor(red: 0.1, green: 0.55, blue: 0.27, alpha: 1)
        case .upcoming:
            messageBox.backgroundColor = UIColor(red: 0.937, green: 0.949, blue: 1.0, alpha: 1) // light blue
            messageBox.layer.borderWidth = 0
            messageLabel.text = "곧 예매가 시작됩니다."
            messageLabel.textColor = UIColor(red: 0.22, green: 0.33, blue: 0.80, alpha: 1)
        case .ongoing:
            messageBox.backgroundColor = UIColor(red: 0.941, green: 0.976, blue: 0.953, alpha: 1) // light green
            messageBox.layer.borderWidth = 0
            messageLabel.text = "공연이 진행 중입니다."
            messageLabel.textColor = UIColor(red: 0.1, green: 0.55, blue: 0.27, alpha: 1)
        }
    }
}
