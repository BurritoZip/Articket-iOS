import UIKit
import SnapKit

final class WriteReviewViewController: UIViewController {

    weak var coordinator: ProfileCoordinator?
    private let viewModel: WriteReviewViewModel

    // MARK: - Views

    private let navigationBar = SimpleNavigationBar(title: "후기 작성")

    private let scrollView = UIScrollView()
    private let contentStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 24
        return s
    }()

    private let showPickerButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("공연 선택", for: .normal)
        b.setTitleColor(UIColor(hex: "#121212"), for: .normal)
        b.titleLabel?.font = .scaled(15, weight: .medium, textStyle: .body)
        b.titleLabel?.adjustsFontForContentSizeCategory = true
        b.backgroundColor = UIColor(hex: "#F3F4F6")
        b.layer.cornerRadius = 10
        b.contentHorizontalAlignment = .left
        b.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        return b
    }()

    private let ratingStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 8
        s.alignment = .center
        return s
    }()

    private let titleField: UITextField = {
        let f = UITextField()
        f.placeholder = "후기 제목을 입력해주세요."
        f.font = .systemFont(ofSize: 15)
        f.backgroundColor = UIColor(hex: "#F3F4F6")
        f.layer.cornerRadius = 10
        let pad = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        f.leftView = pad
        f.leftViewMode = .always
        f.clearButtonMode = .whileEditing
        return f
    }()

    private let contentTextView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 15)
        tv.textColor = UIColor(hex: "#121212")
        tv.backgroundColor = UIColor(hex: "#F3F4F6")
        tv.layer.cornerRadius = 10
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return tv
    }()

    private let placeholderLabel: UILabel = {
        let l = UILabel()
        l.text = "공연 후기를 자유롭게 작성해주세요."
        l.font = .scaled(15, textStyle: .body)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(hex: "#AAAAAA")
        return l
    }()

    private let submitButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("후기 등록", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .scaled(16, weight: .semibold, textStyle: .headline)
        b.titleLabel?.adjustsFontForContentSizeCategory = true
        b.backgroundColor = UIColor(hex: "#121212")
        b.layer.cornerRadius = 12
        return b
    }()

    /// 제출 진행 중 버튼 위에 표시 (EditProfile.savingIndicator 와 동일 패턴)
    private let submitIndicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.color = .white
        v.hidesWhenStopped = true
        return v
    }()

    private var starButtons: [UIButton] = []

    // MARK: - Init

    init(viewModel: WriteReviewViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupLayout()
        bindViewModel()
        viewModel.viewDidLoad()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    // MARK: - Setup

    private func setupLayout() {
        view.addSubview(navigationBar)
        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(44)
        }
        navigationBar.onBackTapped = { [weak self] in
            self?.dismissOrPop()
        }

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide).inset(20)
            $0.width.equalTo(scrollView.frameLayoutGuide).offset(-40)
        }

        // 공연 선택
        showPickerButton.snp.makeConstraints { $0.height.equalTo(48) }
        contentStack.addArrangedSubview(sectionStack(label: sectionLabel("공연"), content: showPickerButton))
        showPickerButton.addTarget(self, action: #selector(showPickerTapped), for: .touchUpInside)

        // 별점
        (1...5).forEach { i in
            let btn = UIButton(type: .system)
            btn.tag = i
            btn.setImage(UIImage(systemName: "star"), for: .normal)
            btn.tintColor = UIColor(hex: "#DDDDDD")
            btn.snp.makeConstraints { $0.size.equalTo(36) }
            btn.addTarget(self, action: #selector(starTapped(_:)), for: .touchUpInside)
            ratingStack.addArrangedSubview(btn)
            starButtons.append(btn)
        }
        // 별 5개는 고정 폭이라 stack이 남는 가로 공간을 별 사이에 흩뿌려 간격이 벌어진다.
        // 끝에 늘어나는 스페이서를 두어 별들이 왼쪽에 8pt 간격으로 붙게 한다.
        let ratingSpacer = UIView()
        ratingSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        ratingSpacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        ratingStack.addArrangedSubview(ratingSpacer)
        contentStack.addArrangedSubview(sectionStack(label: sectionLabel("별점"), content: ratingStack))

        // 후기 제목
        titleField.snp.makeConstraints { $0.height.equalTo(48) }
        contentStack.addArrangedSubview(sectionStack(label: sectionLabel("제목"), content: titleField))
        titleField.addTarget(self, action: #selector(titleChanged), for: .editingChanged)

        // 후기 내용
        contentTextView.snp.makeConstraints { $0.height.equalTo(160) }
        contentTextView.addSubview(placeholderLabel)
        placeholderLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.equalToSuperview().offset(16)
        }
        contentTextView.delegate = self
        contentStack.addArrangedSubview(sectionStack(label: sectionLabel("내용"), content: contentTextView))

        // 등록 버튼
        submitButton.snp.makeConstraints { $0.height.equalTo(50) }
        contentStack.addArrangedSubview(submitButton)
        submitButton.addSubview(submitIndicator)
        submitIndicator.snp.makeConstraints { $0.center.equalToSuperview() }
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
    }

    private func sectionLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .scaled(13, weight: .medium, textStyle: .footnote)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(hex: "#767676")
        return l
    }

    private func sectionStack(label: UILabel, content: UIView) -> UIView {
        let s = UIStackView(arrangedSubviews: [label, content])
        s.axis = .vertical
        s.spacing = 8
        return s
    }

    // MARK: - Bind

    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] in self?.render() }
        viewModel.onError = { [weak self] msg in self?.showErrorAlert(msg) }
        viewModel.onSubmitSuccess = { [weak self] in
            // 성공 토스트는 window-level이라 pop 후에도 표시됨 → 조용히 사라지던 문제 해결
            Haptics.notify(.success)
            self?.showToast("후기가 등록됐어요", type: .success)
            self?.navigationController?.popViewController(animated: true)
        }
    }

    private func render() {
        let state = viewModel.state
        showPickerButton.setTitle(state.selectedEvent?.title ?? "공연 선택", for: .normal)
        updateStars(starCount: state.starCount)
        // 제출 중엔 버튼을 잠그고 스피너 노출 → 연타로 인한 후기 중복 등록 방지
        let canSubmit = state.canSubmit && !state.isSubmitting
        submitButton.isEnabled = canSubmit
        submitButton.alpha = canSubmit ? 1 : 0.4
        submitButton.setTitle(state.isSubmitting ? "" : "후기 등록", for: .normal)
        if state.isSubmitting { submitIndicator.startAnimating() } else { submitIndicator.stopAnimating() }
    }

    private func updateStars(starCount: Int) {
        starButtons.enumerated().forEach { i, btn in
            let filled = i < starCount
            btn.setImage(UIImage(systemName: filled ? "star.fill" : "star"), for: .normal)
            btn.tintColor = filled ? UIColor(hex: "#FFCC00") : UIColor(hex: "#DDDDDD")
        }
    }

    // MARK: - Actions

    @objc private func showPickerTapped() {
        let shows = viewModel.state.reviewableShows
        guard !shows.isEmpty else { return }
        let alert = UIAlertController(title: "공연 선택", message: nil, preferredStyle: .actionSheet)
        shows.forEach { show in
            alert.addAction(UIAlertAction(title: show.title, style: .default) { [weak self] _ in
                self?.viewModel.selectEvent(show)
            })
        }
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func starTapped(_ sender: UIButton) {
        Haptics.selection()
        viewModel.setStarCount(sender.tag)
    }

    @objc private func titleChanged(_ field: UITextField) {
        viewModel.setReviewTitle(field.text ?? "")
    }

    @objc private func submitTapped() {
        AppLog.shared.action("후기등록")
        viewModel.submit()
    }

    @objc private func dismissKeyboard() { view.endEditing(true) }
}

// MARK: - UITextViewDelegate

extension WriteReviewViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        viewModel.setContent(textView.text)
    }
}
