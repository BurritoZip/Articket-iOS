import UIKit
import SnapKit

final class InquiryViewController: UIViewController {

    weak var coordinator: ProfileCoordinator?
    private let viewModel: InquiryViewModel

    private let navigationBar = SimpleNavigationBar(title: "1:1 문의")

    private let scrollView = UIScrollView()
    private let contentStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 20
        return s
    }()

    private let titleField: UITextField = {
        let f = UITextField()
        f.placeholder = "문의 제목을 입력해주세요."
        f.font = .systemFont(ofSize: 15)
        f.backgroundColor = UIColor(hex: "#F3F4F6")
        f.layer.cornerRadius = 10
        let pad = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        f.leftView = pad
        f.leftViewMode = .always
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

    private let contentPlaceholder: UILabel = {
        let l = UILabel()
        l.text = "문의 내용을 자세히 입력해주세요."
        l.font = .systemFont(ofSize: 15)
        l.textColor = UIColor(hex: "#AAAAAA")
        return l
    }()

    private let submitButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("문의 접수", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.backgroundColor = UIColor(hex: "#121212")
        b.layer.cornerRadius = 12
        return b
    }()

    /// 제출 진행 중 버튼 위에 표시 (연타로 인한 문의 중복 접수 방지)
    private let submitIndicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.color = .white
        v.hidesWhenStopped = true
        return v
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.hidesWhenStopped = true
        v.color = UIColor(hex: "#6B7280")
        return v
    }()

    // 과거 문의 목록
    private let historyTableView: UITableView = {
        let tv = UITableView()
        tv.separatorStyle = .none
        tv.isScrollEnabled = false
        tv.register(InquiryHistoryCell.self, forCellReuseIdentifier: InquiryHistoryCell.reuseId)
        return tv
    }()

    /// 문의 내역 0건일 때 빈 표(높이 0) 대신 노출하는 안내
    private let historyEmptyLabel: UILabel = {
        let l = UILabel()
        l.text = "아직 접수한 문의가 없어요"
        l.font = .systemFont(ofSize: 14)
        l.textColor = UIColor(hex: "#9CA3AF")
        l.isHidden = true
        return l
    }()

    init(viewModel: InquiryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

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

    private func setupLayout() {
        view.addSubview(navigationBar)
        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(44)
        }
        navigationBar.onBackTapped = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }

        view.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints { $0.center.equalToSuperview() }

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

        // Form section
        let formHeaderLabel = sectionLabel("새 문의")
        titleField.snp.makeConstraints { $0.height.equalTo(48) }
        contentTextView.snp.makeConstraints { $0.height.equalTo(140) }
        contentTextView.addSubview(contentPlaceholder)
        contentPlaceholder.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.equalToSuperview().offset(16)
        }
        contentTextView.delegate = self

        submitButton.snp.makeConstraints { $0.height.equalTo(50) }
        submitButton.addSubview(submitIndicator)
        submitIndicator.snp.makeConstraints { $0.center.equalToSuperview() }
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)

        titleField.addTarget(self, action: #selector(titleChanged), for: .editingChanged)

        let formStack = UIStackView(arrangedSubviews: [titleField, contentTextView, submitButton])
        formStack.axis = .vertical
        formStack.spacing = 12

        let formSection = UIStackView(arrangedSubviews: [formHeaderLabel, formStack])
        formSection.axis = .vertical
        formSection.spacing = 8
        contentStack.addArrangedSubview(formSection)

        // History section
        let historyHeaderLabel = sectionLabel("문의 내역")
        contentStack.addArrangedSubview(historyHeaderLabel)
        contentStack.addArrangedSubview(historyEmptyLabel)
        contentStack.addArrangedSubview(historyTableView)

        historyTableView.dataSource = self
        historyTableView.snp.makeConstraints { $0.height.equalTo(0) }
    }

    private func sectionLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = UIColor(hex: "#121212")
        return l
    }

    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] in self?.render() }
        viewModel.onError = { [weak self] msg in
            // 로드 실패로 화면이 비어버리는 데드엔드를 막기 위해 재시도 제공
            // (제출 실패 시엔 폼 내용이 보존되므로 재시도가 목록 재로딩이어도 무해)
            self?.showErrorAlert(msg, retry: { self?.viewModel.viewDidLoad() })
        }
        viewModel.onSubmitSuccess = { [weak self] in
            // 모달 알럿(확인 탭 필요) 대신 앱 관례인 가벼운 토스트로 통일
            Haptics.notify(.success)
            self?.showToast("문의가 접수됐어요", type: .success)
        }
    }

    private func render() {
        let state = viewModel.state

        if state.isLoading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }

        // 제출 중엔 버튼을 잠그고 스피너 노출 → 연타로 인한 문의 중복 접수 방지
        let canSubmit = state.canSubmit && !state.isSubmitting
        submitButton.isEnabled = canSubmit
        submitButton.alpha = canSubmit ? 1 : 0.4
        submitButton.setTitle(state.isSubmitting ? "" : "문의 접수", for: .normal)
        if state.isSubmitting { submitIndicator.startAnimating() } else { submitIndicator.stopAnimating() }

        historyTableView.reloadData()
        let rowCount = state.inquiries.count
        historyTableView.snp.remakeConstraints { $0.height.equalTo(rowCount * 80) }
        // 로딩이 끝났는데 내역이 0건이면 빈 표(높이 0) 대신 안내 노출
        historyEmptyLabel.isHidden = !(state.inquiries.isEmpty && !state.isLoading)
    }

    @objc private func submitTapped() {
        AppLog.shared.action("문의접수")
        viewModel.submit()
    }

    @objc private func titleChanged(_ field: UITextField) {
        viewModel.setTitle(field.text ?? "")
    }

    @objc private func dismissKeyboard() { view.endEditing(true) }
}

extension InquiryViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        contentPlaceholder.isHidden = !textView.text.isEmpty
        viewModel.setContent(textView.text)
    }
}

extension InquiryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.state.inquiries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: InquiryHistoryCell.reuseId, for: indexPath) as! InquiryHistoryCell
        cell.configure(with: viewModel.state.inquiries[indexPath.row])
        return cell
    }
}

// MARK: - InquiryHistoryCell

private final class InquiryHistoryCell: UITableViewCell {

    static let reuseId = "InquiryHistoryCell"

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#F9FAFB")
        v.layer.cornerRadius = 10
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = UIColor(hex: "#121212")
        return l
    }()

    private let statusLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        l.layer.cornerRadius = 4
        l.clipsToBounds = true
        l.textAlignment = .center
        return l
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11)
        l.textColor = UIColor(hex: "#AAAAAA")
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(cardView)
        cardView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(4)
            $0.leading.trailing.equalToSuperview()
        }

        [titleLabel, statusLabel, dateLabel].forEach { cardView.addSubview($0) }

        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(12)
            $0.top.equalToSuperview().inset(12)
            $0.trailing.equalTo(statusLabel.snp.leading).offset(-8)
        }
        statusLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalTo(titleLabel)
            $0.width.greaterThanOrEqualTo(52)
            $0.height.equalTo(20)
        }
        dateLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(12)
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.bottom.equalToSuperview().inset(12)
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with inquiry: Inquiry) {
        titleLabel.text = inquiry.title
        dateLabel.text = inquiry.formattedDate
        let isAnswered = inquiry.status == .answered
        statusLabel.text = " \(inquiry.status.displayText) "
        statusLabel.textColor = isAnswered ? UIColor(hex: "#1A7A3F") : UIColor(hex: "#767676")
        statusLabel.backgroundColor = isAnswered ? UIColor(hex: "#E6F4EC") : UIColor(hex: "#F3F4F6")
    }
}
