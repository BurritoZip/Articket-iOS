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
}
