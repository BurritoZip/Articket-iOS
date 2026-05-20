import Foundation

@MainActor
final class ConcertDetailViewModel {

    struct State {
        var detail: ConcertDetail
        var selectedTab: Int = 0
        var heroImageAssetName: String?
        var isLoading: Bool = true
        var isInterested: Bool = false
    }

    private(set) var state: State
    var onStateChanged: (() -> Void)?
    var onError: ((String) -> Void)?

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
        onStateChanged?()
        Task {
            async let detailTask = repository.fetchConcertDetail(concertId: concertId)
            async let isInterestedTask = repository.fetchIsInterested(concertId: concertId)
            do {
                let detail = try await detailTask
                state = State(
                    detail: detail,
                    heroImageAssetName: state.heroImageAssetName ?? detail.imageAssetName,
                    isLoading: false,
                    isInterested: await isInterestedTask
                )
            } catch {
                state.isLoading = false
                onError?("공연 정보를 불러오지 못했습니다.")
            }
            onStateChanged?()
        }
    }

    func toggleInterested() {
        guard AuthService.shared.isLoggedIn else {
            onError?("로그인이 필요한 기능입니다.")
            return
        }
        let wasInterested = state.isInterested
        state.isInterested = !wasInterested
        onStateChanged?()
        Task {
            do {
                try await repository.toggleInterested(concertId: concertId, currentlyInterested: wasInterested)
            } catch {
                state.isInterested = wasInterested
                onStateChanged?()
                onError?("관심 공연 처리에 실패했습니다.")
            }
        }
    }

    func selectTab(_ index: Int) {
        state.selectedTab = index
        onStateChanged?()
    }
}
