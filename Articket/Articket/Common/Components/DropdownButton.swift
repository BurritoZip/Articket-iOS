import UIKit

/// 디자인 시스템 드롭다운 선택 버튼. 좌측 값 텍스트 + 우측 chevron.down.
/// 폼의 STAGE / 시간 선택 등에 사용. `menu`는 호출부에서 주입.
final class DropdownButton: UIButton {

    init(placeholder: String = "") {
        super.init(frame: .zero)
        configure(placeholder: placeholder)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    private func configure(placeholder: String) {
        var config = UIButton.Configuration.plain()
        config.contentInsets = .zero
        config.imagePadding = 6
        config.baseForegroundColor = .tcInk
        config.image = UIImage(systemName: "chevron.down")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold))

        var titleAttr = AttributedString(placeholder)
        titleAttr.font = .systemFont(ofSize: 15, weight: .medium)
        config.attributedTitle = titleAttr

        configuration = config
        // chevron 을 텍스트 우측에 배치
        semanticContentAttribute = .forceRightToLeft
        contentHorizontalAlignment = .leading
        showsMenuAsPrimaryAction = true
    }

    func setValue(_ text: String) {
        var titleAttr = AttributedString(text)
        titleAttr.font = .systemFont(ofSize: 15, weight: .medium)
        configuration?.attributedTitle = titleAttr
    }
}
