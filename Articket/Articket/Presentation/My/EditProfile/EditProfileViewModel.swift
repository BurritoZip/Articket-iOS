import Foundation

@MainActor
final class EditProfileViewModel {

    struct State {
        var displayName: String = ""
        var email: String = ""
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
            email: currentProfile.email
        )
    }

    func setDisplayName(_ name: String) {
        state.displayName = name
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
            do {
                try await repository.updateDisplayName(trimmed)
                state.displayName = trimmed
                state.isSaving = false
                onStateChanged?()
                onSaveSuccess?()
            } catch {
                state.isSaving = false
                onStateChanged?()
                onError?("정보 저장에 실패했습니다.")
            }
        }
    }
}
