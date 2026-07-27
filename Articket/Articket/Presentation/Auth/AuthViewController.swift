import UIKit
import AuthenticationServices
import SnapKit

final class AuthViewController: UIViewController {

    var onSignInSuccess: (() -> Void)?

    // MARK: - UI

    private let logoImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "AppIcon")
        iv.contentMode = .scaleAspectFit
        iv.layer.cornerRadius = 24
        iv.clipsToBounds = true
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "아티켓"
        l.font = .systemFont(ofSize: 32, weight: .bold)
        l.textColor = .tcTextPrimary
        l.textAlignment = .center
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "좋아하는 아티스트의\n공연을 한 눈에"
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.textColor = .tcTextSecondary
        l.textAlignment = .center
        l.numberOfLines = 2
        return l
    }()

    private let appleSignInButton: ASAuthorizationAppleIDButton = {
        ASAuthorizationAppleIDButton(type: .signIn, style: .black)
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.hidesWhenStopped = true
        return ai
    }()

    private let closeButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "xmark"), for: .normal)
        b.tintColor = .tcTextSecondary
        return b
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .tcBackground

        view.addSubview(logoImageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(appleSignInButton)
        view.addSubview(activityIndicator)
        view.addSubview(closeButton)

        closeButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            $0.trailing.equalToSuperview().inset(16)
            $0.size.equalTo(44)
        }
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        logoImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-80)
            $0.width.height.equalTo(100)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(logoImageView.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
        }

        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.centerX.equalToSuperview()
        }

        appleSignInButton.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-24)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(54)
        }

        activityIndicator.snp.makeConstraints {
            $0.center.equalTo(appleSignInButton)
        }

        appleSignInButton.addTarget(self, action: #selector(handleAppleSignIn), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func handleAppleSignIn() {
        appleSignInButton.isEnabled = false
        activityIndicator.startAnimating()

        Task {
            defer {
                appleSignInButton.isEnabled = true
                activityIndicator.stopAnimating()
            }
            do {
                try await AuthService.shared.signInWithApple()
                onSignInSuccess?()
            } catch let error as ASAuthorizationError where error.code == .canceled {
                // 사용자가 취소한 경우 — 아무 처리 없음
            } catch {
                showError(error)
            }
        }
    }

    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "로그인하지 못했어요",
            message: "네트워크 상태를 확인한 뒤 다시 시도해 주세요.",
            preferredStyle: .alert
        )
        // 실패 후 사용자가 Apple 버튼을 다시 찾아 누르지 않도록 재시도 액션을 바로 제공
        alert.addAction(UIAlertAction(title: "다시 시도", style: .default) { [weak self] _ in
            self?.handleAppleSignIn()
        })
        alert.addAction(UIAlertAction(title: "닫기", style: .cancel))
        present(alert, animated: true)
    }
}
