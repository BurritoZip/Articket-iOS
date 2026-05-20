import UIKit

final class MyCoordinator: Coordinator {

    let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let repository = SupabaseMyPageRepository()
        let useCase = FetchMyPageDataUseCase(repository: repository)
        let viewModel = MyPageViewModel(useCase: useCase)
        let vc = MyViewController(viewModel: viewModel)
        vc.coordinator = self
        navigationController.setViewControllers([vc], animated: false)
    }

    // MARK: - Navigation

    func showConcertDetail(concertId: UUID, imageAssetName: String? = nil) {
        let repo = SupabaseConcertDetailRepository()
        let vm = ConcertDetailViewModel(concertId: concertId, imageAssetName: imageAssetName, repository: repo)
        let vc = ConcertDetailViewController(viewModel: vm)
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

    func showMyReviews() {
        let vm = MyReviewsViewModel(repository: SupabaseReviewRepository())
        let vc = MyReviewsViewController(viewModel: vm)
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
            lastVisitDate: nil
        )
        let vm = EditProfileViewModel(currentProfile: profile, repository: SupabaseMyPageRepository())
        let vc = EditProfileViewController(viewModel: vm)
        vc.coordinator = self
        vc.onSaved = onSaved
        navigationController.pushViewController(vc, animated: true)
    }
}
