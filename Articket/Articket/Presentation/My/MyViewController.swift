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

    private let yearlyDivider = DividerView()
    private let yearlyShowSectionView = MyYearlyShowSectionView()

    private let menuDivider = DividerView()
    private let menuSectionView = MyMenuSectionView()

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

        // 섹션 패딩 래퍼: 프로필 헤더 (border 포함)
        contentStack.addArrangedSubview(profileHeaderView)

        // 내 아티스트 섹션
        let artistWrapper = paddedWrapper(view: artistSectionView, top: 20, bottom: 20)
        contentStack.addArrangedSubview(artistWrapper)

        // 구분선
        contentStack.addArrangedSubview(artistDivider)

        // 후기 프롬프트 섹션
        let reviewWrapper = paddedWrapper(view: reviewPromptView, top: 20, bottom: 20)
        contentStack.addArrangedSubview(reviewWrapper)

        // 구분선
        contentStack.addArrangedSubview(reviewDivider)

        // 올해 본 공연 섹션
        let yearlyWrapper = paddedWrapper(view: yearlyShowSectionView, top: 20, bottom: 20)
        contentStack.addArrangedSubview(yearlyWrapper)

        // 구분선
        contentStack.addArrangedSubview(yearlyDivider)

        // 메뉴 섹션
        contentStack.addArrangedSubview(menuSectionView)
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
            self?.applyState()
        }
        yearlyShowSectionView.onShowTapped = { [weak self] event in
            self?.coordinator?.showConcertDetail(concertId: event.id, imageAssetName: event.posterUrl)
        }
    }

    private func applyState() {
        if let profile = viewModel.state.userProfile {
            profileHeaderView.configure(with: profile)
        }
        artistSectionView.configure(artists: viewModel.state.myArtists)
        if let firstShow = viewModel.state.reviewableShows.first {
            reviewPromptView.configure(show: firstShow)
        }
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
