import Foundation

@MainActor
final class InquiryViewModel {

    struct State {
        var inquiries: [Inquiry] = []
        var title: String = ""
        var content: String = ""
        var isLoading: Bool = true
        var isSubmitting: Bool = false

        var canSubmit: Bool {
            !title.trimmingCharacters(in: .whitespaces).isEmpty &&
            !content.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    private(set) var state: State = .init()
    var onStateChanged: (() -> Void)?
    var onError: ((String) -> Void)?
    var onSubmitSuccess: (() -> Void)?

    private let repository: any InquiryRepositoryProtocol

    init(repository: some InquiryRepositoryProtocol) {
        self.repository = repository
    }

    func viewDidLoad() {
        state.isLoading = true
        onStateChanged?()
        Task {
            do {
                state.inquiries = try await repository.fetchMyInquiries()
            } catch {
                onError?("문의 내역을 불러오지 못했어요")
            }
            state.isLoading = false
            onStateChanged?()
        }
    }

    func setTitle(_ title: String) {
        state.title = title
        onStateChanged?()
    }

    func setContent(_ content: String) {
        state.content = content
        onStateChanged?()
    }

    func submit() {
        guard state.canSubmit else { return }
        state.isSubmitting = true
        onStateChanged?()
        Task {
            do {
                try await repository.submitInquiry(title: state.title, content: state.content)
                state.title = ""
                state.content = ""
                state.isSubmitting = false
                onStateChanged?()
                onSubmitSuccess?()
                // 제출 후 목록 새로고침
                state.inquiries = (try? await repository.fetchMyInquiries()) ?? state.inquiries
                onStateChanged?()
            } catch {
                state.isSubmitting = false
                onStateChanged?()
                onError?("문의 접수에 실패했어요")
            }
        }
    }
}
