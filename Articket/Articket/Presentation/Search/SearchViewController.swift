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
        tf.returnKeyType = .search
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
        sv.keyboardDismissMode = .onDrag
        return sv
    }()

    private let contentView = UIView()

    // 최근 검색어
    private let recentSection = UIView()

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

    private let emptyRecentLabel: UILabel = {
        let l = UILabel()
        l.text = "최근 검색어가 없습니다"
        l.font = .systemFont(ofSize: 14)
        l.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        l.textAlignment = .center
        return l
    }()

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
        searchTextField.delegate = self
        searchTextField.becomeFirstResponder()
        registerKeyboardObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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

        // 최근 검색어 섹션
        recentSection.addSubview(recentHeaderLabel)
        recentSection.addSubview(clearAllButton)
        recentSection.addSubview(recentChipFlow)
        recentSection.addSubview(emptyRecentLabel)
        contentView.addSubview(recentSection)

        // 추천 검색어 섹션
        contentView.addSubview(recommendedHeaderLabel)
        contentView.addSubview(recommendedChipFlow)

        backButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(4)
            $0.leading.equalToSuperview().inset(12)
            $0.size.equalTo(44)
        }

        searchContainerView.snp.makeConstraints {
            $0.centerY.equalTo(backButton)
            $0.leading.equalTo(backButton.snp.trailing).offset(4)
            $0.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }

        searchTextField.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(4)
            $0.centerY.equalToSuperview()
            $0.trailing.equalTo(searchIconView.snp.leading).offset(-8)
        }

        searchIconView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(4)
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

        // 최근 검색어 섹션 레이아웃
        recentSection.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
        }

        recentHeaderLabel.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.equalToSuperview().inset(20)
        }

        clearAllButton.snp.makeConstraints {
            $0.centerY.equalTo(recentHeaderLabel)
            $0.trailing.equalToSuperview().inset(20)
        }

        emptyRecentLabel.snp.makeConstraints {
            $0.top.equalTo(recentHeaderLabel.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().inset(8)
        }

        recentChipFlow.snp.makeConstraints {
            $0.top.equalTo(recentHeaderLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview()
        }

        // 추천 검색어 섹션 레이아웃
        recommendedHeaderLabel.snp.makeConstraints {
            $0.top.equalTo(recentSection.snp.bottom).offset(32)
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

    private func registerKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification, object: nil
        )
    }

    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] in
            self?.renderChips()
        }
    }

    // MARK: - Chip Rendering

    private func renderChips() {
        let hasRecent = !viewModel.state.recentKeywords.isEmpty
        emptyRecentLabel.isHidden = hasRecent
        recentChipFlow.isHidden = !hasRecent
        clearAllButton.isHidden = !hasRecent

        let recentChips = viewModel.state.recentKeywords.map { makeRecentChip(keyword: $0) }
        recentChipFlow.setChips(recentChips)

        let recommendedChips = viewModel.state.recommendedKeywords.map { makeRecommendedChip(keyword: $0) }
        recommendedChipFlow.setChips(recommendedChips)
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
        // 터치 영역 확보
        xButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

        container.addSubview(label)
        container.addSubview(xButton)

        label.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(17)
            $0.top.bottom.equalToSuperview().inset(5)
        }
        xButton.snp.makeConstraints {
            $0.leading.equalTo(label.snp.trailing).offset(2)
            $0.trailing.equalToSuperview().inset(8)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }

        xButton.accessibilityLabel = keyword
        xButton.addTarget(self, action: #selector(removeChipTapped(_:)), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(recentChipTapped(_:)))
        container.addGestureRecognizer(tap)
        container.accessibilityLabel = keyword

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

        let tap = UITapGestureRecognizer(target: self, action: #selector(recommendedChipTapped(_:)))
        container.addGestureRecognizer(tap)
        container.accessibilityLabel = keyword

        return container
    }

    // MARK: - Actions

    @objc private func backTapped() {
        searchTextField.resignFirstResponder()
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

    @objc private func recentChipTapped(_ gesture: UITapGestureRecognizer) {
        guard let keyword = gesture.view?.accessibilityLabel else { return }
        searchTextField.text = keyword
        performSearch(keyword: keyword)
    }

    @objc private func recommendedChipTapped(_ gesture: UITapGestureRecognizer) {
        guard let keyword = gesture.view?.accessibilityLabel else { return }
        searchTextField.text = keyword
        performSearch(keyword: keyword)
    }

    private func performSearch(keyword: String) {
        let trimmed = keyword.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        viewModel.addKeyword(trimmed)
        // TODO: 검색 결과 화면으로 이동 (SearchResultViewController 구현 후 연결)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let info = notification.userInfo,
              let frame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let inset = frame.height - view.safeAreaInsets.bottom
        scrollView.contentInset.bottom = inset
        scrollView.verticalScrollIndicatorInsets.bottom = inset
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
}

// MARK: - UITextFieldDelegate

extension SearchViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let keyword = textField.text, !keyword.trimmingCharacters(in: .whitespaces).isEmpty else {
            return false
        }
        performSearch(keyword: keyword)
        textField.resignFirstResponder()
        return true
    }
}
