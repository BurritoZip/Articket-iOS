import UIKit

final class ProfileCoordinator: Coordinator, ArtistDetailCoordinatorProtocol, ConcertDetailCoordinatorProtocol {

    let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let repository = SupabaseMyPageRepository()
        let useCase = FetchMyPageDataUseCase(repository: repository)
        let viewModel = ProfilePageViewModel(useCase: useCase)
        let vc = ProfileViewController(viewModel: viewModel)
        vc.coordinator = self
        navigationController.setViewControllers([vc], animated: false)
    }

    // MARK: - Navigation

    func showConcertDetail(concertId: UUID, imageAssetName: String? = nil) {
        let repo = SupabaseConcertDetailRepository()
        let vm = ConcertDetailViewModel(concertId: concertId, imageAssetName: imageAssetName, repository: repo)
        let vc = ConcertDetailViewController(viewModel: vm)
        vc.coordinator = self
        navigationController.pushViewController(vc, animated: true)
    }

    func showArtistDetail(artistId: UUID) {
        let repo = SupabaseArtistDetailRepository()
        let vm = ArtistDetailViewModel(artistId: artistId, repository: repo)
        let vc = ArtistDetailViewController(viewModel: vm)
        vc.coordinator = self
        navigationController.pushViewController(vc, animated: true)
    }

    func showBookingList(initialTab: BookingListViewModel.Tab = .active) {
        let vm = BookingListViewModel(initialTab: initialTab, repository: SupabaseBookingRepository())
        let vc = BookingListViewController(viewModel: vm)
        vc.coordinator = self
        navigationController.pushViewController(vc, animated: true)
    }

    func showWriteReview(currentProfile: UserProfile?) {
        let vm = WriteReviewViewModel(
            myPageRepository: SupabaseMyPageRepository(),
            reviewRepository: SupabaseReviewRepository()
        )
        let vc = WriteReviewViewController(viewModel: vm)
        vc.coordinator = self
        navigationController.pushViewController(vc, animated: true)
    }

    func showReviews() {
        let vm = ReviewsViewModel(repository: SupabaseReviewRepository())
        let vc = ReviewsViewController(viewModel: vm)
        vc.coordinator = self
        navigationController.pushViewController(vc, animated: true)
    }

    func showInquiry() {
        let vm = InquiryViewModel(repository: SupabaseInquiryRepository())
        let vc = InquiryViewController(viewModel: vm)
        vc.coordinator = self
        navigationController.pushViewController(vc, animated: true)
    }

    func showEditProfile(currentProfile: UserProfile?, onSaved: @escaping () -> Void) {
        let profile = currentProfile ?? UserProfile(
            displayName: "아티켓 유저",
            email: "",
            initial: "U",
            concertCount: 0,
            followingArtistCount: 0,
            lastVisitDate: nil,
            avatarUrl: nil
        )
        let vm = EditProfileViewModel(currentProfile: profile, repository: SupabaseMyPageRepository())
        let vc = EditProfileViewController(viewModel: vm)
        vc.coordinator = self
        vc.onSaved = onSaved
        navigationController.pushViewController(vc, animated: true)
    }
}
