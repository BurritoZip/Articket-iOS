import UIKit

extension UIViewController {
    /// 뒤로가기 공통 처리 — nav 스택에 이전 화면이 있으면 pop, 없으면(모달 루트) dismiss.
    /// 같은 화면이 push로도 모달로도 뜰 수 있을 때 '뒤로'가 화면에 갇히지 않게 한다.
    func dismissOrPop(animated: Bool = true) {
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: animated)
        } else {
            dismiss(animated: animated)
        }
    }
}
