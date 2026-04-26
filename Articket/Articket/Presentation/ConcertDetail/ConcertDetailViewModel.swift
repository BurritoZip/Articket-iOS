import Foundation

@MainActor
final class ConcertDetailViewModel {

    struct State {
        var detail: ConcertDetail
        var selectedTab: Int = 0
        var heroImageAssetName: String?
    }

    private(set) var state: State
    var onStateChanged: (() -> Void)?

    private let useCase: FetchConcertDetailUseCase

    init(concertId: UUID, imageAssetName: String? = nil, repository: ConcertDetailRepositoryProtocol) {
        self.useCase = FetchConcertDetailUseCase(repository: repository)
        let detail = repository.fetchConcertDetail(concertId: concertId)
        self.state = State(detail: detail, heroImageAssetName: imageAssetName ?? detail.imageAssetName)
    }

    func selectTab(_ index: Int) {
        state.selectedTab = index
        onStateChanged?()
    }
}
