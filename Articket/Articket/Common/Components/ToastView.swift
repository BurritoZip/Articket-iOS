import UIKit
import SnapKit

enum ToastType {
    case success
    case error
    case info

    var iconName: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var iconColor: UIColor {
        switch self {
        case .success: return UIColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1)
        case .error: return UIColor(red: 1.0, green: 0.27, blue: 0.27, alpha: 1)
        case .info: return UIColor(red: 0.65, green: 0.65, blue: 0.65, alpha: 1)
        }
    }
}

final class ToastView: UIView {

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let messageLabel: UILabel = {
        let l = UILabel()
        l.font = .scaled(14, weight: .medium)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = .white
        l.numberOfLines = 2
        return l
    }()

    private init(message: String, type: ToastType) {
        super.init(frame: .zero)
        backgroundColor = UIColor(hex: "#121212")
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.25
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8

        iconView.image = UIImage(systemName: type.iconName)
        iconView.tintColor = type.iconColor
        messageLabel.text = message

        let stack = UIStackView(arrangedSubviews: [iconView, messageLabel])
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center

        addSubview(stack)
        iconView.snp.makeConstraints { $0.size.equalTo(20) }
        stack.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(14)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    static func show(message: String, type: ToastType = .info, duration: TimeInterval = 2.5) {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else { return }

        let toast = ToastView(message: message, type: type)
        window.addSubview(toast)
        toast.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(window.safeAreaLayoutGuide.snp.bottom).inset(24)
        }
        window.layoutIfNeeded()

        toast.alpha = 0
        toast.transform = CGAffineTransform(translationX: 0, y: 40)

        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            toast.alpha = 1
            toast.transform = .identity
        } completion: { _ in
            UIView.animate(withDuration: 0.3, delay: duration) {
                toast.alpha = 0
                toast.transform = CGAffineTransform(translationX: 0, y: 20)
            } completion: { _ in
                toast.removeFromSuperview()
            }
        }
    }
}
