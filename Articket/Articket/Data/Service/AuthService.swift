import UIKit
import Supabase
import AuthenticationServices
import CryptoKit

@MainActor
final class AuthService: NSObject {
    static let shared = AuthService()
    private override init() { super.init() }

    private var authContinuation: CheckedContinuation<ASAuthorization, Error>?
    private var authController: ASAuthorizationController?
    private var pendingNonce: String?

    var isLoggedIn: Bool {
        client.auth.currentSession != nil
    }

    var currentUserId: UUID? {
        client.auth.currentSession?.user.id
    }

    private var client: SupabaseClient { SupabaseService.shared.client }

    // MARK: - Apple Sign In

    func signInWithApple() async throws {
        let nonce = randomNonce()
        pendingNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let authorization = try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else { return }
            self.authContinuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
            self.authController = controller
        }
        authController = nil

        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = credential.identityToken,
            let idToken = String(data: tokenData, encoding: .utf8),
            let nonce = pendingNonce
        else { throw AuthError.invalidCredential }

        try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
        pendingNonce = nil

        // 첫 로그인 시 user_profiles 생성 (이미 존재하면 무시)
        let user = try await client.auth.user()
        let displayName: String? = credential.fullName.flatMap {
            let formatted = PersonNameComponentsFormatter.localizedString(from: $0, style: .default)
            return formatted.trimmingCharacters(in: .whitespaces).isEmpty ? nil : formatted
        }
        try? await upsertUserProfile(userId: user.id, displayName: displayName)
        NotificationCenter.default.post(name: .userDidLogin, object: nil)
    }

    private func upsertUserProfile(userId: UUID, displayName: String?) async throws {
        try await client.from("user_profiles")
            .upsert(UserProfileUpsert(id: userId, displayName: displayName),
                    onConflict: "id",
                    ignoreDuplicates: true)
            .execute()
    }

    func validateSession() async {
        guard client.auth.currentSession != nil else { return }
        do {
            _ = try await client.auth.session
        } catch {
            try? await client.auth.signOut()
            NotificationCenter.default.post(name: .userDidLogout, object: nil)
        }
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    // MARK: - Helpers

    private func randomNonce(length: Int = 32) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    private func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthService: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in
            self.authContinuation?.resume(returning: authorization)
            self.authContinuation = nil
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            self.authContinuation?.resume(throwing: error)
            self.authContinuation = nil
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthService: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow } ?? UIWindow()
        }
    }
}

// MARK: - Error

enum AuthError: Error {
    case invalidCredential
}
