import UIKit

final class ArtistCoordinator: Coordinator, SearchCoordinatorProtocol, ArtistDetailCoordinatorProtocol, ConcertDetailCoordinatorProtocol {

    let navigationController: UINavigationController
    private let detailRepository: ArtistDetailRepositoryProtocol = SupabaseArtistDetailRepository()

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let repo = SupabaseArtistRepository()
        let useCase = FetchArtistDataUseCase(repository: repo)
        let recUseCase = FetchArtistRecommendationsUseCase(
            repository: SupabaseRecommendationRepository()
        )
        let vm = ArtistViewModel(useCase: useCase, recommendationUseCase: recUseCase)
        let vc = ArtistViewController(viewModel: vm)
        vc.coordinator = self
        navigationController.setViewControllers([vc], animated: false)
    }

    func showSearch() {
        let vm = SearchViewModel()
        let vc = SearchViewController(viewModel: vm)
        vc.coordinator = self
        navigationController.pushViewController(vc, animated: true)
    }

    func showSearchResult(keyword: String) {
        let vc = SearchResultViewController(keyword: keyword, coordinator: self)
        navigationController.pushViewController(vc, animated: true)
    }

    func showArtistDetail(artistId: UUID) {
        let vm = ArtistDetailViewModel(artistId: artistId, repository: detailRepository)
        let vc = ArtistDetailViewController(viewModel: vm)
        vc.coordinator = self
        navigationController.pushViewController(vc, animated: true)
    }

    func showConcertDetail(concertId: UUID, imageAssetName: String? = nil) {
        let repo = SupabaseConcertDetailRepository()
        let vm = ConcertDetailViewModel(concertId: concertId, imageAssetName: imageAssetName, repository: repo)
        let vc = ConcertDetailViewController(viewModel: vm)
        vc.coordinator = self
        navigationController.pushViewController(vc, animated: true)
    }

    /// 주입식 이벤트 리스트(네트워크 없음) — "다가오는 티켓팅 더보기" 등 전체 보기용
    func showEventList(title: String, events: [Event]) {
        let vc = EventListViewController(title: title, events: events, coordinator: self)
        navigationController.pushViewController(vc, animated: true)
    }
}
