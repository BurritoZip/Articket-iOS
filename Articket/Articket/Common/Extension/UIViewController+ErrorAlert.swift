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
    /// 사용자가 이미 개인 기능을 탭해 의도를 밝혔으므로 "로그인 필요" 확인 알럿을 한 번 더
    /// 띄우지 않고 로그인 시트를 바로 연다(게스트 로그인 경로와 동일, 2탭→1탭).
    /// 로그인 시트 자체에 닫기 버튼이 있어 취소 경로도 보존된다.
    func showLoginPrompt(then action: @escaping () -> Void) {
        guard let scene = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate,
              let appCoordinator = scene.appCoordinator else { return }
        appCoordinator.presentLogin(from: self, completion: action)
    }
}
