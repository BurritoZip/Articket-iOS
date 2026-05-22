import UIKit
import SnapKit

final class EditProfileViewController: UIViewController {

    weak var coordinator: ProfileCoordinator?
    private let viewModel: EditProfileViewModel
    var onSaved: (() -> Void)?

    private let navigationBar = SimpleNavigationBar(title: "내 정보 수정")

    private let avatarView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 40
        v.clipsToBounds = true
        v.backgroundColor = UIColor(hex: "#333333")
        return v
    }()

    private let initialLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 28, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()

    private let nameField: UITextField = {
        let f = UITextField()
        f.font = .systemFont(ofSize: 16)
        f.textColor = UIColor(hex: "#121212")
        f.backgroundColor = UIColor(hex: "#F3F4F6")
        f.layer.cornerRadius = 10
        let pad = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        f.leftView = pad
        f.leftViewMode = .always
        f.clearButtonMode = .whileEditing
        f.returnKeyType = .done
        return f
    }()

    private let emailField: UITextField = {
        let f = UITextField()
        f.font = .systemFont(ofSize: 16)
        f.textColor = UIColor(hex: "#767676")
        f.backgroundColor = UIColor(hex: "#F9FAFB")
        f.layer.cornerRadius = 10
        f.isEnabled = false
        let pad = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        f.leftView = pad
        f.leftViewMode = .always
        return f
    }()

    private let saveButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("저장", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.backgroundColor = UIColor(hex: "#121212")
        b.layer.cornerRadius = 12
        return b
    }()

    init(viewModel: EditProfileViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupLayout()
        bindViewModel()

        nameField.addTarget(self, action: #selector(nameChanged), for: .editingChanged)
        nameField.delegate = self

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        render()
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

        avatarView.addSubview(initialLabel)
        initialLabel.snp.makeConstraints { $0.center.equalToSuperview() }

        let nameStack = formField(label: "닉네임", field: nameField)
        let emailStack = formField(label: "이메일 (변경 불가)", field: emailField)

        let mainStack = UIStackView(arrangedSubviews: [avatarView, nameStack, emailStack])
        mainStack.axis = .vertical
        mainStack.spacing = 20
        mainStack.alignment = .fill

        view.addSubview(mainStack)
        mainStack.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom).offset(32)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        avatarView.snp.makeConstraints { $0.width.height.equalTo(80); $0.centerX.equalToSuperview() }
        nameField.snp.makeConstraints { $0.height.equalTo(48) }
        emailField.snp.makeConstraints { $0.height.equalTo(48) }

        view.addSubview(saveButton)
        saveButton.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(50)
        }
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
    }

    private func formField(label: String, field: UITextField) -> UIView {
        let l = UILabel()
        l.text = label
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = UIColor(hex: "#767676")
        let stack = UIStackView(arrangedSubviews: [l, field])
        stack.axis = .vertical
        stack.spacing = 6
        return stack
    }

    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] in self?.render() }
        viewModel.onError = { [weak self] msg in
            self?.showErrorAlert(msg)
        }
        viewModel.onSaveSuccess = { [weak self] in
            self?.onSaved?()
            self?.navigationController?.popViewController(animated: true)
        }
    }

    private func render() {
        let state = viewModel.state
        nameField.text = state.displayName
        emailField.text = state.email.isEmpty ? "이메일 정보 없음" : state.email
        initialLabel.text = String(state.displayName.first ?? "U")
        saveButton.isEnabled = !state.isSaving
        saveButton.alpha = state.isSaving ? 0.6 : 1
    }

    @objc private func nameChanged(_ field: UITextField) {
        viewModel.setDisplayName(field.text ?? "")
    }

    @objc private func saveTapped() { viewModel.save() }

    @objc private func dismissKeyboard() { view.endEditing(true) }
}

extension EditProfileViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
