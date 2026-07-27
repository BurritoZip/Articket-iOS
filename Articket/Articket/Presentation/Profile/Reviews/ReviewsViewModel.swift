import Foundation

@MainActor
final class ReviewsViewModel {

    struct State {
        var reviews: [ConcertReview] = []
        var isLoading: Bool = true
    }

    private(set) var state: State = .init()
    var onStateChanged: (() -> Void)?
    var onError: ((String) -> Void)?

    private let repository: any ReviewRepositoryProtocol

    init(repository: some ReviewRepositoryProtocol) {
        self.repository = repository
    }

    func viewDidLoad() {
        state.isLoading = true
        onStateChanged?()
        Task {
            do {
                state.reviews = try await repository.fetchMyReviews()
            } catch {
                onError?("후기 목록을 불러오지 못했어요")
            }
            state.isLoading = false
            onStateChanged?()
        }
    }
}
