import UIKit
import SnapKit

final class SearchViewController: UIViewController {

    private let viewModel: SearchViewModel

    // MARK: - UI

    private let backButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        b.tintColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1)
        return b
    }()

    private let searchContainerView = UIView()

    private let searchTextField: UITextField = {
        let tf = UITextField()
        tf.font = .systemFont(ofSize: 16)
        tf.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        tf.tintColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1)
        let placeholder = NSAttributedString(
            string: "아티스트, 공연, 장소로 검색해보세요",
            attributes: [.foregroundColor: UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)]
        )
        tf.attributedPlaceholder = placeholder
        tf.borderStyle = .none
        return tf
    }()

    private let searchIconView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        iv.tintColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let searchBorderLine: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1)
        return v
    }()

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    private let contentView = UIView()

    // 최근 검색어
    private let recentHeaderLabel: UILabel = {
        let l = UILabel()
        l.text = "최근 검색어"
        l.font = .systemFont(ofSize: 16)
        l.textColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1)
        return l
    }()

    private let clearAllButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("전체삭제", for: .normal)
        b.setTitleColor(UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1), for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 13)
        return b
    }()

    private let recentChipFlow = ChipFlowView(horizontalSpacing: 8, verticalSpacing: 12)

    // 추천 검색어
    private let recommendedHeaderLabel: UILabel = {
        let l = UILabel()
        l.text = "추천 검색어"
        l.font = .systemFont(ofSize: 16)
        l.textColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1)
        return l
    }()

    private let recommendedChipFlow = ChipFlowView(horizontalSpacing: 8, verticalSpacing: 12)

    // MARK: - Init

    init(viewModel: SearchViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupViews()
        bindViewModel()
        renderChips()
    }

    // MARK: - Setup

    private func setupViews() {
        view.addSubview(backButton)
        view.addSubview(searchContainerView)
        searchContainerView.addSubview(searchTextField)
        searchContainerView.addSubview(searchIconView)
        searchContainerView.addSubview(searchBorderLine)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(recentHeaderLabel)
        contentView.addSubview(clearAllButton)
        contentView.addSubview(recentChipFlow)
        contentView.addSubview(recommendedHeaderLabel)
        contentView.addSubview(recommendedChipFlow)

        backButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            $0.leading.equalToSuperview().inset(20)
            $0.size.equalTo(24)
        }

        searchContainerView.snp.makeConstraints {
            $0.top.equalTo(backButton.snp.bottom).offset(12)
            $0.leading.equalToSuperview().inset(30)
            $0.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(48)
        }

        searchTextField.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(10)
            $0.centerY.equalToSuperview()
            $0.trailing.equalTo(searchIconView.snp.leading).offset(-8)
        }

        searchIconView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(10)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(20)
        }

        searchBorderLine.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(2)
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(searchContainerView.snp.bottom).offset(32)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }

        recentHeaderLabel.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.equalToSuperview().inset(20)
        }

        clearAllButton.snp.makeConstraints {
            $0.centerY.equalTo(recentHeaderLabel)
            $0.trailing.equalToSuperview().inset(20)
        }

        recentChipFlow.snp.makeConstraints {
            $0.top.equalTo(recentHeaderLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        recommendedHeaderLabel.snp.makeConstraints {
            $0.top.equalTo(recentChipFlow.snp.bottom).offset(32)
            $0.leading.equalToSuperview().inset(20)
        }

        recommendedChipFlow.snp.makeConstraints {
            $0.top.equalTo(recommendedHeaderLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(32)
        }

        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        clearAllButton.addTarget(self, action: #selector(clearAllTapped), for: .touchUpInside)
    }

    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] in
            self?.renderChips()
        }
    }

    // MARK: - Chip Rendering

    private func renderChips() {
        let recentChips = viewModel.state.recentKeywords.map { makeRecentChip(keyword: $0) }
        recentChipFlow.setChips(recentChips)

        let recommendedChips = viewModel.state.recommendedKeywords.map { makeRecommendedChip(keyword: $0) }
        recommendedChipFlow.setChips(recommendedChips)

        clearAllButton.isHidden = viewModel.state.recentKeywords.isEmpty
    }

    private func makeRecentChip(keyword: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1).cgColor
        container.layer.cornerRadius = 100

        let label = UILabel()
        label.text = keyword
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)

        let xButton = UIButton(type: .system)
        xButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        xButton.tintColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)

        container.addSubview(label)
        container.addSubview(xButton)

        label.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(17)
            $0.top.bottom.equalToSuperview().inset(5)
        }
        xButton.snp.makeConstraints {
            $0.leading.equalTo(label.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(14)
        }

        xButton.tag = 0
        xButton.accessibilityLabel = keyword
        xButton.addTarget(self, action: #selector(removeChipTapped(_:)), for: .touchUpInside)

        return container
    }

    private func makeRecommendedChip(keyword: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1).cgColor
        container.layer.cornerRadius = 100

        let label = UILabel()
        label.text = keyword
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)

        container.addSubview(label)
        label.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 5, left: 17, bottom: 5, right: 17))
        }

        return container
    }

    // MARK: - Actions

    @objc private func backTapped() {
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @objc private func clearAllTapped() {
        viewModel.clearAll()
    }

    @objc private func removeChipTapped(_ sender: UIButton) {
        guard let keyword = sender.accessibilityLabel else { return }
        viewModel.removeKeyword(keyword)
    }
}
