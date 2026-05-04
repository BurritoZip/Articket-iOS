import Foundation

@MainActor
final class ConcertDetailViewModel {

    struct State {
        var detail: ConcertDetail
        var selectedTab: Int = 0
        var heroImageAssetName: String?
        var isLoading: Bool = true
    }

    private(set) var state: State
    var onStateChanged: (() -> Void)?

    private let concertId: UUID
    private let repository: any ConcertDetailRepositoryProtocol

    init(concertId: UUID, imageAssetName: String? = nil, repository: some ConcertDetailRepositoryProtocol) {
        self.concertId = concertId
        self.repository = repository
        self.state = State(
            detail: .placeholder,
            heroImageAssetName: imageAssetName,
            isLoading: true
        )
    }

    func viewDidLoad() {
        Task {
            do {
                let detail = try await repository.fetchConcertDetail(concertId: concertId)
                state = State(
                    detail: detail,
                    heroImageAssetName: state.heroImageAssetName ?? detail.imageAssetName,
                    isLoading: false
                )
            } catch {
                state.isLoading = false
            }
            onStateChanged?()
        }
    }

    func selectTab(_ index: Int) {
        state.selectedTab = index
        onStateChanged?()
    }
}
