import UIKit
import ObjectiveC.runtime

extension UIViewController {
    private static let installOnce: Void = {
        let original = #selector(UIViewController.viewDidAppear(_:))
        let swizzled = #selector(UIViewController.al_viewDidAppear(_:))
        guard let o = class_getInstanceMethod(UIViewController.self, original),
              let s = class_getInstanceMethod(UIViewController.self, swizzled) else { return }
        method_exchangeImplementations(o, s)
    }()

    /// 앱 시작 시 1회 호출.
    static func installScreenTracking() { _ = installOnce }

    @objc dynamic private func al_viewDidAppear(_ animated: Bool) {
        al_viewDidAppear(animated)   // 스왑됐으므로 이게 원본 호출
        let name = String(describing: type(of: self))
        // 컨테이너/시스템 VC 노이즈 제외
        if name.hasPrefix("UI") || name.hasPrefix("_") { return }
        AppLog.shared.screen(name)
    }
}
