import UIKit
import SnapKit
import PhotosUI

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

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isHidden = true
        return iv
    }()

    private let cameraButton: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#121212")
        v.layer.cornerRadius = 12
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor.white.cgColor
        let iv = UIImageView(image: UIImage(systemName: "camera.fill"))
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        v.addSubview(iv)
        iv.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(12) }
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

        avatarView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

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

        // 아바타 컨테이너(avatarView 바깥) — clipsToBounds를 피해 카메라 배지가 보이도록
        let avatarContainer = UIView()
        view.addSubview(avatarContainer)
        avatarContainer.addSubview(cameraButton)
        avatarContainer.snp.makeConstraints {
            $0.center.equalTo(avatarView)
            $0.size.equalTo(80)
        }
        cameraButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(8)
            $0.bottom.equalToSuperview().offset(8)
            $0.size.equalTo(24)
        }

        let avatarTap = UITapGestureRecognizer(target: self, action: #selector(avatarTapped))
        avatarContainer.isUserInteractionEnabled = true
        avatarContainer.addGestureRecognizer(avatarTap)
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
            self?.showToast(msg, type: .error)
        }
        viewModel.onSaveSuccess = { [weak self] warning in
            if let warning {
                ToastView.show(message: warning, type: .info)
            } else {
                ToastView.show(message: "프로필이 저장됐어요", type: .success)
            }
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

        if let data = state.pendingAvatarData, let image = UIImage(data: data) {
            avatarImageView.image = image
            avatarImageView.isHidden = false
            initialLabel.isHidden = true
        } else if let urlString = state.avatarUrl, !urlString.isEmpty {
            avatarImageView.loadImage(urlString: urlString)
            avatarImageView.isHidden = false
            initialLabel.isHidden = true
        } else {
            avatarImageView.isHidden = true
            initialLabel.isHidden = false
        }
    }

    @objc private func avatarTapped() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
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

extension EditProfileViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            // 원본을 그대로 올리지 않고 업로드 전 100KB 이내로 자동 다운스케일+압축
            guard let image = object as? UIImage,
                  let data = image.resizedForUpload(maxBytes: 100_000) else { return }
            DispatchQueue.main.async {
                self?.viewModel.setAvatar(data: data)
            }
        }
    }
}
