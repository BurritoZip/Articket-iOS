import UIKit

/// 디자인 시스템 pill 버튼. 완전 라운드(rounded-999) + 12pt Medium.
/// nav 우측 액션("직접 추가", "완료") 등에 사용. raw UIButton 대신 이 컴포넌트를 쓸 것.
final class PillButton: UIButton {

    enum Style {
        case outline   // 흰 배경 + 잉크 보더/텍스트
        case filled    // 잉크 배경 + 흰 텍스트
    }

    private let style: Style

    init(title: String, style: Style = .outline) {
        self.style = style
        super.init(frame: .zero)
        configure(title: title)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    private func configure(title: String) {
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12)

        var titleAttr = AttributedString(title)
        titleAttr.font = .systemFont(ofSize: 12, weight: .medium)
        config.attributedTitle = titleAttr

        switch style {
        case .outline:
            config.background.backgroundColor = .white
            config.baseForegroundColor = .tcInk
            layer.borderColor = UIColor.tcInk.cgColor
            layer.borderWidth = 1
        case .filled:
            config.background.backgroundColor = .tcInk
            config.baseForegroundColor = .white
            layer.borderWidth = 0
        }

        configuration = config
        layer.cornerRadius = 100
        clipsToBounds = true
    }

    func setTitleText(_ text: String) {
        var titleAttr = AttributedString(text)
        titleAttr.font = .systemFont(ofSize: 12, weight: .medium)
        configuration?.attributedTitle = titleAttr
    }
}
