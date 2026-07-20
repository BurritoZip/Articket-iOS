import UIKit

extension UIViewController {
    func showErrorAlert(_ message: String, retry: (() -> Void)? = nil) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        if let retry {
            alert.addAction(UIAlertAction(title: "다시 시도", style: .default) { _ in retry() })
            alert.addAction(UIAlertAction(title: "닫기", style: .cancel))
        } else {
            alert.addAction(UIAlertAction(title: "확인", style: .default))
        }
        present(alert, animated: true)
    }

    func showToast(_ message: String, type: ToastType = .info) {
        ToastView.show(message: message, type: type)
    }

    /// 개인 기능 진입 시 로그인 유도 → 완료 후 원래 액션 재실행.
    /// ConcertDetail·Home 등 여러 화면이 같은 흐름을 쓰므로 공용 extension으로 둔다.
    func showLoginPrompt(then action: @escaping () -> Void) {
        let alert = UIAlertController(title: "로그인 필요",
                                      message: "이 기능을 사용하려면 로그인이 필요합니다.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "로그인", style: .default) { [weak self] _ in
            guard let self,
                  let scene = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate,
                  let appCoordinator = scene.appCoordinator else { return }
            appCoordinator.presentLogin(from: self, completion: action)
        })
        present(alert, animated: true)
    }
}
