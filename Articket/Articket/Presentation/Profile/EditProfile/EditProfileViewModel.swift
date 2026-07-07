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
    var onSaveSuccess: (() -> Void)?

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
            var avatarFailed = false
            if let avatarData = state.pendingAvatarData {
                do {
                    let url = try await repository.updateAvatar(imageData: avatarData)
                    state.avatarUrl = url
                    state.pendingAvatarData = nil
                } catch {
                    avatarFailed = true
                }
            }

            state.isSaving = false
            onStateChanged?()
            if avatarFailed {
                onError?("이미지 업로드에 실패했습니다. 이름은 저장되었습니다.")
            }
            onSaveSuccess?()
        }
    }
}
