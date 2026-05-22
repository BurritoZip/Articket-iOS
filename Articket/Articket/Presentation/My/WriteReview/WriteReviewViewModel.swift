import Foundation

@MainActor
final class WriteReviewViewModel {

    struct State {
        var reviewableShows: [Event] = []
        var selectedEvent: Event?
        var reviewTitle: String = ""
        var starCount: Int = 0
        var content: String = ""
        var isLoading: Bool = false
        var isSubmitting: Bool = false

        var canSubmit: Bool {
            selectedEvent != nil &&
            starCount > 0 &&
            !reviewTitle.trimmingCharacters(in: .whitespaces).isEmpty &&
            !content.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    private(set) var state: State = .init()
    var onStateChanged: (() -> Void)?
    var onError: ((String) -> Void)?
    var onSubmitSuccess: (() -> Void)?

    private let myPageRepository: any MyPageRepositoryProtocol
    private let reviewRepository: any ReviewRepositoryProtocol

    init(myPageRepository: some MyPageRepositoryProtocol, reviewRepository: some ReviewRepositoryProtocol) {
        self.myPageRepository = myPageRepository
        self.reviewRepository = reviewRepository
    }

    func viewDidLoad() {
        state.isLoading = true
        onStateChanged?()
        Task {
            do {
                state.reviewableShows = try await myPageRepository.fetchReviewableShows()
                state.selectedEvent = state.reviewableShows.first
            } catch {
                onError?("공연 목록을 불러오지 못했습니다.")
            }
            state.isLoading = false
            onStateChanged?()
        }
    }

    func selectEvent(_ event: Event) {
        state.selectedEvent = event
        onStateChanged?()
    }

    func setStarCount(_ count: Int) {
        state.starCount = count
        onStateChanged?()
    }

    func setReviewTitle(_ title: String) {
        state.reviewTitle = title
        onStateChanged?()
    }

    func setContent(_ content: String) {
        state.content = content
        onStateChanged?()
    }

    func submit() {
        guard let event = state.selectedEvent, state.canSubmit else { return }
        state.isSubmitting = true
        onStateChanged?()
        Task {
            do {
                try await reviewRepository.writeReview(
                    eventId: event.id,
                    title: state.reviewTitle,
                    starCount: state.starCount,
                    content: state.content
                )
                state.isSubmitting = false
                onStateChanged?()
                onSubmitSuccess?()
            } catch {
                state.isSubmitting = false
                onStateChanged?()
                onError?("후기 등록에 실패했습니다.")
            }
        }
    }
}
