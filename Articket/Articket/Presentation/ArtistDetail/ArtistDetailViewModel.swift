import Foundation

@MainActor
final class ArtistDetailViewModel {

    struct State {
        var detail: ArtistDetail
        var selectedTab: Int = 0
    }

    private(set) var state: State
    var onStateChanged: (() -> Void)?

    private let repository: ArtistDetailRepositoryProtocol

    init(artistId: UUID, repository: ArtistDetailRepositoryProtocol) {
        self.repository = repository
        self.state = State(detail: repository.fetchArtistDetail(artistId: artistId))
    }

    func selectTab(_ index: Int) {
        state.selectedTab = index
        onStateChanged?()
    }
}
