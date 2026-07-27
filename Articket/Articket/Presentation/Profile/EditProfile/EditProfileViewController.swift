import UIKit
import SnapKit
import PhotosUI

final class EditProfileViewController: UIViewController {

    weak var coordinator: ProfileCoordinator?
    private let viewModel: EditProfileViewModel
    var onSaved: (() -> Void)?

    private let navigationBar = SimpleNavigationBar(title: "내 정보 수정")

    /// 아바타 지름 — 편집 화면에서는 선택한 사진을 확인할 수 있도록 프로필 탭(64pt)보다 크게 잡는다
    private static let avatarSize: CGFloat = 100

    private let avatarView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = EditProfileViewController.avatarSize / 2
        v.clipsToBounds = true
        // 밝은 면 + 실선 테두리로 "여기에 사진이 들어간다"는 빈 슬롯임을 드러낸다.
        // (기존 어두운 tcInk 원은 배경과 대비는 되지만 사진 자리라는 신호가 약했다)
        // 주의: 토큰 `tcSurface`는 이름과 달리 어두운 색(#1c1c1c)이라 밝은 슬롯 의도에 안 맞는다.
        // 흰 배경 위에서 살짝 떠 보이는 연회색을 명시적으로 쓴다.
        v.backgroundColor = UIColor(hex: "#F3F4F6")
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.tcFieldBorder.cgColor
        return v
    }()

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        // 부모(avatarView)의 clipsToBounds에만 의존하지 않고 자체적으로도 원형 마스킹 —
        // 부모 clip이 걸리지 않는 렌더 경로에서도 사각 이미지가 새어나오지 않게 한다
        iv.layer.cornerRadius = EditProfileViewController.avatarSize / 2
        iv.isHidden = true
        return iv
    }()

    /// 아바타 업로드 대기 표시 — 저장 중 새 사진이 서버로 올라가는 동안 아바타 위에 딤+스피너.
    /// 저장 버튼 스피너만으론 "사진이 올라가는 중"임이 안 드러나 별도로 표시한다.
    private let avatarUploadingOverlay: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        v.isHidden = true
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = .white
        spinner.startAnimating()
        spinner.tag = 991
        v.addSubview(spinner)
        spinner.snp.makeConstraints { $0.center.equalToSuperview() }
        return v
    }()

    /// 사진 미등록 시 노출되는 인물 실루엣 — 빈 사진 슬롯임을 한눈에 전달
    private let avatarPlaceholderIcon: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)
        let iv = UIImageView(image: UIImage(systemName: "person.fill", withConfiguration: config))
        iv.tintColor = .tcPlaceholder
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let cameraButton: UIView = {
        let v = UIView()
        v.backgroundColor = .tcInk
        v.layer.cornerRadius = 15
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor.white.cgColor
        let iv = UIImageView(image: UIImage(systemName: "camera.fill"))
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        v.addSubview(iv)
        iv.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(14) }
        return v
    }()

    private let initialLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 36, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()

    /// 아바타 아래 안내 — 탭 가능하다는 사실을 카메라 배지만으로는 알기 어려워 문구로 보강
    private let avatarHintLabel: UILabel = {
        let l = UILabel()
        l.text = "사진 변경"
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.textColor = .tcInk
        l.textAlignment = .center
        return l
    }()

    // 입력 가능한 필드는 흰 배경 + 실선 테두리, 비활성 필드는 회색 면으로 — 색만이 아니라
    // 테두리 유무로도 편집 가능 여부가 드러나게 한다
    private let nameField: UITextField = {
        let f = UITextField()
        f.font = .systemFont(ofSize: 16)
        f.textColor = .tcTextPrimary
        f.backgroundColor = .tcBackground
        f.layer.cornerRadius = 12
        f.layer.borderWidth = 1
        f.layer.borderColor = UIColor.tcFieldBorder.cgColor
        f.attributedPlaceholder = NSAttributedString(
            string: "닉네임을 입력해주세요",
            attributes: [.foregroundColor: UIColor.tcPlaceholder]
        )
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
        f.textColor = .tcTextSecondary
        f.backgroundColor = .tcSurface
        f.layer.cornerRadius = 12
        f.isEnabled = false
        let pad = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        f.leftView = pad
        f.leftViewMode = .always
        return f
    }()

    /// 닉네임 글자 수 카운터 — 저장 후에야 길이 문제를 알게 되는 상황을 막는다
    private let nameCountLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textColor = .tcTextSecondary
        l.textAlignment = .right
        return l
    }()

    private let saveButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("저장", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.backgroundColor = .tcInk
        b.layer.cornerRadius = 12
        return b
    }()

    /// 저장 중 버튼 위에 표시 — 알파만 낮추면 눌린 건지 처리 중인지 구분이 안 됨
    private let savingIndicator: UIActivityIndicatorView = {
        let i = UIActivityIndicatorView(style: .medium)
        i.color = .white
        i.hidesWhenStopped = true
        return i
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

        let size = Self.avatarSize

        avatarView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        avatarView.addSubview(avatarPlaceholderIcon)
        avatarPlaceholderIcon.snp.makeConstraints { $0.center.equalToSuperview() }

        avatarView.addSubview(initialLabel)
        initialLabel.snp.makeConstraints { $0.center.equalToSuperview() }

        avatarView.addSubview(avatarUploadingOverlay)
        avatarUploadingOverlay.snp.makeConstraints { $0.edges.equalToSuperview() }

        // 아바타 + 카메라 배지 묶음. avatarView는 clipsToBounds라 배지를 안에 넣으면 잘리므로
        // 한 단계 위 컨테이너에 배지를 얹고, 탭 영역도 이 컨테이너가 갖는다.
        let avatarContainer = UIView()
        avatarContainer.addSubview(avatarView)
        avatarContainer.addSubview(cameraButton)
        avatarView.snp.makeConstraints {
            $0.top.bottom.centerX.equalToSuperview()
            $0.size.equalTo(size)
        }
        avatarContainer.snp.makeConstraints { $0.height.equalTo(size) }
        cameraButton.snp.makeConstraints {
            $0.trailing.equalTo(avatarView.snp.trailing).offset(2)
            $0.bottom.equalTo(avatarView.snp.bottom).offset(2)
            $0.size.equalTo(30)
        }

        let avatarTap = UITapGestureRecognizer(target: self, action: #selector(avatarTapped))
        avatarContainer.isUserInteractionEnabled = true
        avatarContainer.addGestureRecognizer(avatarTap)

        let hintTap = UITapGestureRecognizer(target: self, action: #selector(avatarTapped))
        avatarHintLabel.isUserInteractionEnabled = true
        avatarHintLabel.addGestureRecognizer(hintTap)

        let avatarBlock = UIStackView(arrangedSubviews: [avatarContainer, avatarHintLabel])
        avatarBlock.axis = .vertical
        avatarBlock.spacing = 12
        avatarBlock.alignment = .fill

        let nameStack = formField(label: "닉네임", field: nameField, accessory: nameCountLabel)
        let emailStack = formField(label: "이메일", field: emailField,
                                   caption: "로그인 계정 이메일이라 변경할 수 없어요")

        // 아바타 블록과 입력 폼 사이를 구분선으로 나눠 영역이 두 덩어리로 읽히게 한다
        let divider = UIView()
        divider.backgroundColor = .tcSeparator
        divider.snp.makeConstraints { $0.height.equalTo(1) }

        let mainStack = UIStackView(arrangedSubviews: [avatarBlock, divider, nameStack, emailStack])
        mainStack.axis = .vertical
        mainStack.spacing = 28
        mainStack.alignment = .fill
        mainStack.setCustomSpacing(28, after: avatarBlock)
        mainStack.setCustomSpacing(24, after: divider)

        view.addSubview(mainStack)
        mainStack.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom).offset(32)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        nameField.snp.makeConstraints { $0.height.equalTo(52) }
        emailField.snp.makeConstraints { $0.height.equalTo(52) }

        view.addSubview(saveButton)
        saveButton.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(52)
        }
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        saveButton.addSubview(savingIndicator)
        savingIndicator.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    /// 라벨 + 입력 필드 한 세트. accessory는 라벨 우측(글자 수), caption은 필드 아래 보조 설명.
    private func formField(label: String,
                           field: UITextField,
                           accessory: UIView? = nil,
                           caption: String? = nil) -> UIView {
        let l = UILabel()
        l.text = label
        l.font = .systemFont(ofSize: 13, weight: .semibold)
        l.textColor = .tcTextSecondary

        let labelRow = UIStackView(arrangedSubviews: [l])
        labelRow.axis = .horizontal
        labelRow.alignment = .center
        if let accessory {
            labelRow.addArrangedSubview(UIView())   // spacer
            labelRow.addArrangedSubview(accessory)
        }

        let stack = UIStackView(arrangedSubviews: [labelRow, field])
        stack.axis = .vertical
        stack.spacing = 8

        if let caption {
            let c = UILabel()
            c.text = caption
            c.font = .systemFont(ofSize: 12)
            c.textColor = .tcPlaceholder
            c.numberOfLines = 0
            stack.addArrangedSubview(c)
            stack.setCustomSpacing(6, after: field)
        }
        return stack
    }

    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] in self?.render() }
        viewModel.onError = { [weak self] msg in
            self?.showToast(msg, type: .error)
        }
        viewModel.onSaveSuccess = { [weak self] warning in
            if let warning {
                ToastView.show(message: warning, type: .error)
            } else {
                ToastView.show(message: "프로필이 저장됐어요", type: .success)
            }
            self?.onSaved?()
            self?.navigationController?.popViewController(animated: true)
        }
    }

    private func render() {
        let state = viewModel.state
        // 편집 중 커서가 튀지 않도록 값이 실제로 다를 때만 대입
        if nameField.text != state.displayName { nameField.text = state.displayName }
        emailField.text = state.email.isEmpty ? "이메일 정보 없음" : state.email
        initialLabel.text = String(state.displayName.first ?? "U")

        nameCountLabel.text = "\(state.displayName.count)/\(Self.maxNameLength)"

        // 이름이 비면 저장 자체가 실패하므로 버튼을 미리 잠가 헛탭을 막는다
        let canSave = !state.isSaving
            && !state.displayName.trimmingCharacters(in: .whitespaces).isEmpty
        saveButton.isEnabled = canSave
        saveButton.backgroundColor = canSave ? .tcInk : .tcPlaceholder
        saveButton.setTitle(state.isSaving ? "" : "저장", for: .normal)
        if state.isSaving { savingIndicator.startAnimating() } else { savingIndicator.stopAnimating() }

        // 저장 중 + 올릴 새 사진이 있을 때만 아바타 위 업로드 표시(이름만 저장이면 불필요)
        avatarUploadingOverlay.isHidden = !(state.isSaving && state.pendingAvatarData != nil)

        // 사진 자리는 인물 아이콘(빈 슬롯)으로 안내하므로 이니셜 글자는 쓰지 않는다
        initialLabel.isHidden = true
        if let data = state.pendingAvatarData, let image = UIImage(data: data) {
            avatarImageView.image = image
            avatarImageView.isHidden = false
            avatarPlaceholderIcon.isHidden = true
        } else if let urlString = state.avatarUrl, !urlString.isEmpty {
            avatarImageView.loadImage(urlString: urlString)
            avatarImageView.isHidden = false
            avatarPlaceholderIcon.isHidden = true
        } else {
            avatarImageView.isHidden = true
            avatarPlaceholderIcon.isHidden = false
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

    /// 닉네임 최대 길이 — 서버 제약이 아니라 표시 깨짐 방지용 클라이언트 상한
    private static let maxNameLength = 20

    @objc private func nameChanged(_ field: UITextField) {
        var text = field.text ?? ""
        // 조합 중인 한글(markedTextRange)은 자르지 않는다 — 입력 도중 글자가 사라지는 현상 방지
        if field.markedTextRange == nil, text.count > Self.maxNameLength {
            text = String(text.prefix(Self.maxNameLength))
            field.text = text
        }
        viewModel.setDisplayName(text)
    }

    @objc private func saveTapped() {
        AppLog.shared.action("프로필저장")
        viewModel.save()
    }

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

        // 아무것도 안 고르고 닫은 것(취소)은 정상 흐름 — 조용히 끝낸다
        guard let provider = results.first?.itemProvider else { return }

        // UIImage로 못 여는 형식(GIF, 일부 RAW 등)은 여기서 걸린다.
        // 조용히 return하면 사진을 골랐는데 아무 일도 안 일어나 앱이 멈춘 것처럼 보이므로 안내한다.
        guard provider.canLoadObject(ofClass: UIImage.self) else {
            showToast("지원하지 않는 이미지 형식이에요", type: .error)
            return
        }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            DispatchQueue.main.async {
                guard let image = object as? UIImage else {
                    // iCloud 미다운로드·손상 파일 등 로드 자체가 실패한 경우
                    self?.showToast("이미지를 불러오지 못했어요", type: .error)
                    return
                }
                // 압축 전에 원형 크롭을 먼저 거친다 — 잘려나갈 영역까지 압축에 쓰면 화질만 손해
                self?.presentCropper(for: image)
            }
        }
    }

    private func presentCropper(for image: UIImage) {
        let cropper = AvatarCropViewController(image: image)
        cropper.onCropped = { [weak self] cropped in
            // 크롭 결과를 업로드 전 100KB 이내로 다운스케일+압축
            guard let data = cropped.resizedForUpload(maxBytes: 100_000) else {
                self?.showToast("이미지를 처리하지 못했어요", type: .error)
                return
            }
            self?.viewModel.setAvatar(data: data)
        }
        present(cropper, animated: true)
    }
}
