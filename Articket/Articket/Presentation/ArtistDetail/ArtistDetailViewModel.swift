import Foundation

@MainActor
final class ArtistDetailViewModel {

    struct State {
        var detail: ArtistDetail
        var selectedTab: Int = 0
        var isLoading: Bool = true
    }

    private(set) var state: State
    var onStateChanged: (() -> Void)?
    var onError: ((String) -> Void)?

    private let artistId: UUID
    private let repository: any ArtistDetailRepositoryProtocol

    init(artistId: UUID, repository: some ArtistDetailRepositoryProtocol) {
        self.artistId = artistId
        self.repository = repository
        self.state = State(detail: .placeholder, isLoading: true)
    }

    func viewDidLoad() {
        onStateChanged?()
        Task {
            do {
                let detail = try await repository.fetchArtistDetail(artistId: artistId)
                state = State(detail: detail, isLoading: false)
            } catch {
                state.isLoading = false
                onError?("아티스트 정보를 불러오지 못했습니다.")
            }
            onStateChanged?()
        }
    }

    func selectTab(_ index: Int) {
        state.selectedTab = index
        onStateChanged?()
    }
}
