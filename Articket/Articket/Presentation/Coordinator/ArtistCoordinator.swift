import UIKit

final class ArtistCoordinator: Coordinator {

    let navigationController: UINavigationController
    private let detailRepository: ArtistDetailRepositoryProtocol = SupabaseArtistDetailRepository()

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let repo = SupabaseArtistRepository()
        let useCase = FetchArtistDataUseCase(repository: repo)
        let vm = ArtistViewModel(useCase: useCase)
        let vc = ArtistViewController(viewModel: vm)
        vc.coordinator = self
        navigationController.setViewControllers([vc], animated: false)
    }

    func showSearch() {
        let vm = SearchViewModel()
        let vc = SearchViewController(viewModel: vm)
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
        navigationController.pushViewController(vc, animated: true)
    }
}
