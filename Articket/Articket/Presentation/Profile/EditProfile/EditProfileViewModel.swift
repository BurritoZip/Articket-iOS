import Foundation

@MainActor
final class EditProfileViewModel {

    struct State {
        var displayName: String = ""
        var email: String = ""
        var avatarUrl: String?
        var pendingAvatarData: Data?
        var isSaving: Bool = false
    }

    private(set) var state: State
    var onStateChanged: (() -> Void)?
    var onError: ((String) -> Void)?
    /// 저장 완료 — 경고 메시지(예: 아바타 실패)가 있으면 전달, 없으면 nil
    var onSaveSuccess: ((String?) -> Void)?

    private let repository: any MyPageRepositoryProtocol

    init(currentProfile: UserProfile, repository: some MyPageRepositoryProtocol) {
        self.repository = repository
        self.state = State(
            displayName: currentProfile.displayName,
            email: currentProfile.email,
            avatarUrl: currentProfile.avatarUrl
        )
    }

    func setDisplayName(_ name: String) {
        state.displayName = name
        onStateChanged?()
    }

    func setAvatar(data: Data) {
        state.pendingAvatarData = data
        onStateChanged?()
    }

    /// 업로드 실패 원인을 사용자 언어로 짧게 요약. 서버 설정 문제(버킷/권한)와
    /// 일시적 네트워크 문제를 구분해 "재시도 vs 관리자 문의"를 판단할 수 있게 한다.
    private static func reason(for error: Error) -> String {
        if error.isNetworkConnectionError { return "네트워크 연결을 확인해주세요" }
        let text = "\(error)".lowercased()
        if text.contains("not found") || text.contains("bucket") { return "저장소 설정 오류(관리자 문의)" }
        if text.contains("403") || text.contains("unauthorized")
            || text.contains("permission") || text.contains("row-level") { return "업로드 권한 오류(관리자 문의)" }
        if text.contains("401") { return "로그인이 필요해요" }
        return "잠시 후 다시 시도해주세요"
    }

    func save() {
        let trimmed = state.displayName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            onError?("닉네임을 입력해주세요.")
            return
        }
        state.isSaving = true
        onStateChanged?()
        Task {
            // 1. 닉네임 저장 — 아바타 업로드와 독립. 아바타 실패가 이름 저장을 막지 않도록 분리한다.
            do {
                try await repository.updateDisplayName(trimmed)
                state.displayName = trimmed
            } catch {
                state.isSaving = false
                onStateChanged?()
                onError?("정보 저장에 실패했습니다.")
                return
            }

            // 2. 아바타 업로드 — 실패해도 이름은 이미 저장됨. 별도 안내만 한다.
            var avatarWarning: String?
            if let avatarData = state.pendingAvatarData {
                do {
                    let url = try await repository.updateAvatar(imageData: avatarData)
                    state.avatarUrl = url
                    state.pendingAvatarData = nil
                } catch {
                    // 조용히 실패하면 "왜 안 되는지" 알 수 없어 사용자가 반복 시도만 하게 된다.
                    // 실제 원인(권한/버킷/네트워크)을 짧게 덧붙여 다음 행동을 판단할 수 있게 한다.
                    avatarWarning = "이미지 업로드 실패: \(Self.reason(for: error)) (이름은 저장됐어요)"
                }
            }

            state.isSaving = false
            onStateChanged?()
            // 아바타 실패 시 성공/실패 토스트가 겹치지 않도록 경고 메시지 하나로 통합해 전달
            onSaveSuccess?(avatarWarning)
        }
    }
}
