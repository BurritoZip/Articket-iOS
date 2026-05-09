import UIKit
import SnapKit

final class MyViewController: UIViewController {

    weak var coordinator: MyCoordinator?

    private let viewModel: MyPageViewModel

    // MARK: - Subviews

    private let scrollView: UIScrollView = {
        let s = UIScrollView()
        s.showsVerticalScrollIndicator = false
        return s
    }()
    private let contentStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        return s
    }()

    private let profileHeaderView = MyProfileHeaderView()

    private let artistDivider = DividerView()
    private let artistSectionView = MyArtistSectionView()

    private let reviewDivider = DividerView()
    private let reviewPromptView = MyReviewPromptView()
    private var reviewWrapper: UIView?

    private let yearlyDivider = DividerView()
    private let yearlyShowSectionView = MyYearlyShowSectionView()
    private var yearlyWrapper: UIView?

    private let menuDivider = DividerView()
    private let menuSectionView = MyMenuSectionView()
    private let myPageSkeletonView = MyPageSkeletonView()

    // MARK: - Init

    init(viewModel: MyPageViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#F9FAFB")
        setupLayout()
        bindViewModel()
        viewModel.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        scrollView.contentInset.bottom = view.safeAreaInsets.bottom
        scrollView.verticalScrollIndicatorInsets.bottom = view.safeAreaInsets.bottom
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        scrollView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        contentStack.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }

        // Figma: status bar 44pt + white bar 28pt = top-[72px]. safeArea가 status bar 처리하므로 28pt 추가
        let topSpacer = UIView()
        contentStack.addArrangedSubview(topSpacer)
        topSpacer.snp.makeConstraints { $0.height.equalTo(28) }

        contentStack.addArrangedSubview(profileHeaderView)

        // Figma outer container gap-[36px] 적용
        let artistWrapper = paddedWrapper(view: artistSectionView, top: 36, bottom: 36)
        contentStack.addArrangedSubview(artistWrapper)

        contentStack.addArrangedSubview(artistDivider)

        let rw = paddedWrapper(view: reviewPromptView, top: 36, bottom: 36)
        reviewWrapper = rw
        contentStack.addArrangedSubview(rw)

        contentStack.addArrangedSubview(reviewDivider)

        let yw = paddedWrapper(view: yearlyShowSectionView, top: 36, bottom: 36)
        yearlyWrapper = yw
        contentStack.addArrangedSubview(yw)

        contentStack.addArrangedSubview(yearlyDivider)

        contentStack.addArrangedSubview(paddedWrapper(view: menuSectionView, top: 36, bottom: 0))

        view.addSubview(myPageSkeletonView)
        myPageSkeletonView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    private func paddedWrapper(view: UIView, top: CGFloat = 0, bottom: CGFloat = 0) -> UIView {
        let wrapper = UIView()
        wrapper.addSubview(view)
        view.snp.makeConstraints {
            $0.top.equalToSuperview().offset(top)
            $0.bottom.equalToSuperview().inset(bottom)
            $0.leading.trailing.equalToSuperview()
        }
        return wrapper
    }

    // MARK: - Binding

    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] in
            guard let self else { return }
            if !viewModel.state.isLoading && !myPageSkeletonView.isHidden {
                UIView.animate(withDuration: 0.25) {
                    self.myPageSkeletonView.alpha = 0
                } completion: { _ in
                    self.myPageSkeletonView.isHidden = true
                    self.myPageSkeletonView.stopShimmer()
                }
            }
            self.applyState()
        }
        viewModel.onError = { [weak self] message in
            self?.showErrorAlert(message)
        }
        yearlyShowSectionView.onShowTapped = { [weak self] event in
            self?.coordinator?.showConcertDetail(concertId: event.id, imageAssetName: event.posterUrl)
        }
    }

    private func showErrorAlert(_ message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private func applyState() {
        guard let profile = viewModel.state.userProfile else { return }
        profileHeaderView.configure(with: profile)
        artistSectionView.configure(artists: viewModel.state.myArtists)

        let hasReviewable = !viewModel.state.reviewableShows.isEmpty
        reviewWrapper?.isHidden = !hasReviewable
        reviewDivider.isHidden = !hasReviewable
        if let firstShow = viewModel.state.reviewableShows.first {
            reviewPromptView.configure(show: firstShow)
        }

        let hasYearly = !viewModel.state.yearlyShows.isEmpty
        yearlyWrapper?.isHidden = !hasYearly
        yearlyDivider.isHidden = !hasYearly
        yearlyShowSectionView.configure(shows: viewModel.state.yearlyShows)
    }
}

// MARK: - DividerView

private final class DividerView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(hex: "#F3F4F6")
        snp.makeConstraints { $0.height.equalTo(8) }
    }
    required init?(coder: NSCoder) { fatalError() }
}
