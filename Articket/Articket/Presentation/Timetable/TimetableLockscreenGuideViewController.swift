import UIKit
import SnapKit
import Photos

final class TimetableLockscreenGuideViewController: UIViewController {

    private let event: TimetableEvent
    private let selectedPerformanceIds: Set<UUID>

    /// 갤러리에서 고른 배경 원본 — imageView만 믿지 않고 저장·합성의 단일 소스
    private var selectedWallpaperImage: UIImage?

    private var allSelectedPerformances: [Performance] {
        event.days.flatMap(\.performances).filter { selectedPerformanceIds.contains($0.id) }
    }

    // MARK: - Scroll

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    private let contentView = UIView()

    // MARK: - Lockscreen Preview

    private let previewHintLabel: UILabel = {
        let l = UILabel()
        l.text = "잠금화면 미리보기"
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textColor = UIColor(hex: "#767676")
        l.textAlignment = .center
        return l
    }()

    /// 갤러리에서 잠금화면 배경 사진 선택 (저장 버튼 바로 위에 배치)
    private let selectBackgroundButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("갤러리에서 배경 선택", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = UIColor(hex: "#121212")
        b.layer.cornerRadius = 8
        return b
    }()

    // 폰 액자 역할 — 저장되는 이미지
    private let phoneFrameView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#1C1C1E")
        v.layer.cornerRadius = 36
        v.clipsToBounds = true
        return v
    }()

    private let wallpaperImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(hex: "#1C1C1E")
        return iv
    }()

    private let wallpaperDimView: UIView = {
        let v = UIView()
        // 잠금화면 가독성용 약한 딤 — 과하면 배경 사진이 회색처럼 보임
        v.backgroundColor = UIColor.black.withAlphaComponent(0.22)
        v.isUserInteractionEnabled = false
        return v
    }()

    // 배경 선택 안내 (배경이 없을 때만 표시)
    private let wallpaperSelectHint: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        v.layer.cornerRadius = 12
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        return v
    }()

    private let wallpaperSelectLabel: UILabel = {
        let l = UILabel()
        l.text = "📷  내 배경화면 사진 선택하기"
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()

    private let lockClockLabel: UILabel = {
        let l = UILabel()
        l.text = "9:41"
        l.font = .systemFont(ofSize: 52, weight: .thin)
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()

    private let lockDateLabel: UILabel = {
        let l = UILabel()
        l.text = "토요일, 5월 22일"
        l.font = .systemFont(ofSize: 15, weight: .regular)
        l.textColor = UIColor.white.withAlphaComponent(0.9)
        l.textAlignment = .center
        return l
    }()

    private let timetableCardView = LockscreenTimetableCardView()

    /// 배경 미선택 시 미리보기 전체 탭 → 갤러리 (타임테이블 카드가 터치를 가로채지 않도록 별도 레이어)
    private let wallpaperTapOverlay: UIButton = {
        let b = UIButton(type: .custom)
        b.backgroundColor = .clear
        b.accessibilityLabel = "배경 사진 선택"
        return b
    }()

    // MARK: - Guide Section

    private let guideTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Apple 단축어로 잠금화면 설정"
        l.font = .systemFont(ofSize: 18, weight: .bold)
        l.textColor = UIColor(hex: "#121212")
        return l
    }()

    private let actionButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("타임테이블 이미지 저장하기", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = UIColor(hex: "#121212")
        b.layer.cornerRadius = 8
        return b
    }()

    private let openShortcutsButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("단축어 앱 열기 →", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 13, weight: .regular)
        b.setTitleColor(UIColor(hex: "#767676"), for: .normal)
        return b
    }()

    // MARK: - Init

    init(event: TimetableEvent, selectedPerformanceIds: Set<UUID>) {
        self.event = event
        self.selectedPerformanceIds = selectedPerformanceIds
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationItem.title = "내 타임테이블"
        setupUI()
        configureContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
        (navigationController?.parent as? MainTabBarController)?.setTabBarHidden(true)
    }

    // MARK: - Setup

    private func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = nil
        appearance.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 16, weight: .bold),
            .foregroundColor: UIColor(hex: "#121212")
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = UIColor(hex: "#121212")
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    private func setupUI() {
        // Scroll
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }

        // Preview
        contentView.addSubview(previewHintLabel)
        contentView.addSubview(phoneFrameView)

        phoneFrameView.addSubview(wallpaperImageView)
        phoneFrameView.addSubview(wallpaperDimView)
        phoneFrameView.addSubview(wallpaperSelectHint)
        wallpaperSelectHint.addSubview(wallpaperSelectLabel)
        phoneFrameView.addSubview(lockClockLabel)
        phoneFrameView.addSubview(lockDateLabel)
        phoneFrameView.addSubview(timetableCardView)
        phoneFrameView.addSubview(wallpaperTapOverlay)

        let phoneW = UIScreen.main.bounds.width - 80
        let phoneH = phoneW * 2.1

        previewHintLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.centerX.equalToSuperview()
        }
        phoneFrameView.snp.makeConstraints {
            $0.top.equalTo(previewHintLabel.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(phoneW)
            $0.height.equalTo(phoneH)
        }
        wallpaperImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        wallpaperDimView.snp.makeConstraints { $0.edges.equalToSuperview() }
        wallpaperTapOverlay.snp.makeConstraints { $0.edges.equalToSuperview() }

        wallpaperSelectHint.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(48)
        }
        wallpaperSelectLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.equalToSuperview().offset(8)
            $0.trailing.equalToSuperview().inset(8)
        }

        // Figma 886:4779 — Lock Screen iPhone (402×874pt) 기준 비율 적용
        // clock top: 115/874 = 13.2%, widget area bottom: 286/874 = 32.7%
        // controls (카메라·손전등) top: 766/874 = 87.6% → 카드 하단 inset = 12.4% + 여유
        lockClockLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(phoneH * 0.132)
            $0.centerX.equalToSuperview()
        }
        lockDateLabel.snp.makeConstraints {
            $0.top.equalTo(lockClockLabel.snp.bottom).offset(4)
            $0.centerX.equalToSuperview()
        }
        timetableCardView.snp.makeConstraints {
            // widget area bottom(32.7%) + 여유 → 38% (Apple 공식 위젯 아래로 충분히 이격)
            $0.top.equalToSuperview().offset(phoneH * 0.38)
            $0.leading.equalToSuperview().offset(11)
            $0.trailing.equalToSuperview().inset(11)
            // controls top(87.6%) 기준 → 16% inset (카메라·손전등 버튼과 겹침 방지)
            $0.bottom.equalToSuperview().inset(phoneH * 0.16)
        }

        // Guide
        let step1 = makeStepView(num: "1", text: "갤러리에서 배경 사진을 선택합니다")
        let step2 = makeStepView(num: "2", text: "'타임테이블 이미지 저장하기' — 배경+타임테이블 합성본이 사진 앱에 저장됩니다")
        let step3 = makeStepView(num: "3", text: "단축어: Articket '배경화면 가져오기' → '배경화면 사진 설정' (잠금 화면) → 실행")
        let stepsStack = UIStackView(arrangedSubviews: [step1, step2, step3])
        stepsStack.axis = .vertical
        stepsStack.spacing = 14

        contentView.addSubview(guideTitleLabel)
        contentView.addSubview(stepsStack)
        contentView.addSubview(selectBackgroundButton)
        contentView.addSubview(actionButton)
        contentView.addSubview(openShortcutsButton)

        guideTitleLabel.snp.makeConstraints {
            $0.top.equalTo(phoneFrameView.snp.bottom).offset(28)
            $0.leading.equalToSuperview().offset(24)
        }
        stepsStack.snp.makeConstraints {
            $0.top.equalTo(guideTitleLabel.snp.bottom).offset(16)
            $0.leading.equalToSuperview().offset(24)
            $0.trailing.equalToSuperview().inset(24)
        }
        selectBackgroundButton.snp.makeConstraints {
            $0.top.equalTo(stepsStack.snp.bottom).offset(20)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(52)
        }
        actionButton.snp.makeConstraints {
            $0.top.equalTo(selectBackgroundButton.snp.bottom).offset(12)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(52)
        }
        openShortcutsButton.snp.makeConstraints {
            $0.top.equalTo(actionButton.snp.bottom).offset(12)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().inset(40)
        }

        wallpaperTapOverlay.addTarget(self, action: #selector(selectBackgroundTapped), for: .touchUpInside)
        selectBackgroundButton.addTarget(self, action: #selector(selectBackgroundTapped), for: .touchUpInside)
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        openShortcutsButton.addTarget(self, action: #selector(openShortcutsTapped), for: .touchUpInside)
    }

    private func configureContent() {
        timetableCardView.configure(event: event, performances: allSelectedPerformances)
        applyWallpaper(TimetableWallpaperStorage.loadWallpaper())
    }

    private func applyWallpaper(_ image: UIImage?) {
        let fixed = image.map { Self.prepareWallpaper($0) }
        selectedWallpaperImage = fixed
        wallpaperImageView.image = fixed
        wallpaperImageView.backgroundColor = fixed == nil ? UIColor(hex: "#1C1C1E") : .clear

        let hasWallpaper = fixed != nil
        wallpaperSelectHint.isHidden = hasWallpaper
        wallpaperDimView.isHidden = !hasWallpaper
        wallpaperTapOverlay.isHidden = hasWallpaper
        timetableCardView.isUserInteractionEnabled = hasWallpaper

        selectBackgroundButton.setTitle(
            hasWallpaper ? "배경 사진 변경" : "갤러리에서 배경 선택",
            for: .normal
        )
        selectBackgroundButton.backgroundColor = hasWallpaper
            ? UIColor(hex: "#F5F5F5")
            : UIColor(hex: "#121212")
        selectBackgroundButton.setTitleColor(
            hasWallpaper ? UIColor(hex: "#121212") : .white,
            for: .normal
        )
        actionButton.setTitle(
            hasWallpaper ? "타임테이블 이미지 저장하기" : "배경 선택 후 저장하기",
            for: .normal
        )
        actionButton.alpha = hasWallpaper ? 1 : 0.45
    }

    private static func prepareWallpaper(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = true
        return UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

private func makeStepView(num: String, text: String) -> UIView {
        let container = UIView()

        let circle = UIView()
        circle.backgroundColor = UIColor(hex: "#121212")
        circle.layer.cornerRadius = 12

        let numLabel = UILabel()
        numLabel.text = num
        numLabel.font = .systemFont(ofSize: 11, weight: .bold)
        numLabel.textColor = .white
        numLabel.textAlignment = .center

        let textLabel = UILabel()
        textLabel.text = text
        textLabel.font = .systemFont(ofSize: 14, weight: .regular)
        textLabel.textColor = UIColor(hex: "#333333")
        textLabel.numberOfLines = 0

        circle.addSubview(numLabel)
        container.addSubview(circle)
        container.addSubview(textLabel)

        numLabel.snp.makeConstraints { $0.center.equalToSuperview() }
        circle.snp.makeConstraints {
            $0.leading.top.equalToSuperview()
            $0.size.equalTo(24)
            $0.bottom.lessThanOrEqualToSuperview()
        }
        textLabel.snp.makeConstraints {
            $0.leading.equalTo(circle.snp.trailing).offset(12)
            $0.trailing.equalToSuperview()
            $0.top.bottom.equalToSuperview()
        }
        return container
    }

    // MARK: - Actions

    @objc private func selectBackgroundTapped() {
        showWallpaperPicker()
    }

    @objc private func actionTapped() {
        guard selectedWallpaperImage != nil else {
            showWallpaperPicker()
            return
        }
        saveToPhotosAndOpenShortcuts()
    }

    @objc private func openShortcutsTapped() {
        guard let url = URL(string: "shortcuts://") else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Wallpaper Picker

    private func showWallpaperPicker() {
        guard presentedViewController == nil else { return }
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            showAlert(title: "사진 앱을 사용할 수 없습니다", message: "이 기기에서 사진 라이브러리를 열 수 없습니다.")
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = false
        present(picker, animated: true)
    }

    // MARK: - Save & Shortcuts

    private func saveToPhotosAndOpenShortcuts() {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    self?.performSave()
                default:
                    self?.showPermissionAlert()
                }
            }
        }
    }

    private func performSave() {
        view.layoutIfNeeded()

        guard let composite = renderFinalLockscreenImage() else {
            showAlert(title: "저장 실패", message: "배경 사진을 불러오지 못했습니다. 배경을 다시 선택해주세요.")
            return
        }

        // AppIntent용 — 전체 화면 투명 PNG (Shortcuts '배경 흐리게 하기' ON 시 기존 배경 유지)
        TimetableWallpaperStorage.saveCard(renderCardOnlyImage())
        // 합성 이미지 (배경+카드) — Photos 저장 및 Documents 캐시
        TimetableWallpaperStorage.save(composite)

        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: composite)
        }) { [weak self] success, _ in
            DispatchQueue.main.async {
                if success {
                    self?.showSaveSuccessGuide()
                } else {
                    self?.showAlert(title: "저장 실패", message: "이미지를 저장하는 중 오류가 발생했습니다.")
                }
            }
        }
    }

    // AppIntent용 — 전체 화면 크기, 카드만 위치 포함, 나머지 투명
    private func renderCardOnlyImage() -> UIImage {
        let screenSize = UIScreen.main.bounds.size
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(size: screenSize, format: format)
        return renderer.image { _ in
            let scaleX = screenSize.width / phoneFrameView.bounds.width
            let scaleY = screenSize.height / phoneFrameView.bounds.height
            let cardF = timetableCardView.frame
            timetableCardView.drawHierarchy(
                in: CGRect(
                    x: cardF.minX * scaleX,
                    y: cardF.minY * scaleY,
                    width: cardF.width * scaleX,
                    height: cardF.height * scaleY
                ),
                afterScreenUpdates: true
            )
        }
    }

    /// phoneFrameView 전체를 drawHierarchy로 캡처 → 잠금화면 해상도로 확대
    /// wallpaperImageView가 이미 scaleAspectFill로 배경을 렌더링하므로 별도 합성 없이 그대로 캡처
    private func renderFinalLockscreenImage() -> UIImage? {
        guard selectedWallpaperImage != nil else { return nil }

        view.layoutIfNeeded()
        let phoneSize = phoneFrameView.bounds.size
        guard phoneSize.width > 1, phoneSize.height > 1 else { return nil }

        // 미리보기 전용 UI 요소 숨기기 (저장 이미지에 포함 불필요)
        lockClockLabel.isHidden = true
        lockDateLabel.isHidden = true
        wallpaperSelectHint.isHidden = true
        wallpaperTapOverlay.isHidden = true
        defer {
            lockClockLabel.isHidden = false
            lockDateLabel.isHidden = false
            // wallpaperSelectHint·wallpaperTapOverlay은 applyWallpaper 상태에 따라 제어되므로 복원 생략
        }

        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = UIScreen.main.scale

        // phoneFrameView 전체 캡처 (wallpaperImageView + dim + card 포함)
        let phoneImage = UIGraphicsImageRenderer(size: phoneSize, format: format).image { _ in
            phoneFrameView.drawHierarchy(
                in: CGRect(origin: .zero, size: phoneSize),
                afterScreenUpdates: true
            )
        }

        // phoneFrame 비율 → 실제 화면 해상도로 aspect-fill 확대
        let screenSize = UIScreen.main.bounds.size
        return UIGraphicsImageRenderer(size: screenSize, format: format).image { _ in
            let scale = max(screenSize.width / phoneSize.width, screenSize.height / phoneSize.height)
            let width = phoneSize.width * scale
            let height = phoneSize.height * scale
            phoneImage.draw(in: CGRect(
                x: (screenSize.width - width) / 2,
                y: (screenSize.height - height) / 2,
                width: width,
                height: height
            ))
        }
    }

    private func showSaveSuccessGuide() {
        let alert = UIAlertController(
            title: "저장 완료",
            message: """
            배경+타임테이블 합성 이미지가 사진 앱에 저장되었습니다.

            단축어 자동화:
            1. 단축어 앱 → + → Articket → '배경화면 가져오기'
            2. '배경화면 사진 설정' 추가 → 잠금 화면 선택
            3. 실행
            """,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "단축어 앱 열기", style: .default) { _ in
            if let url = URL(string: "shortcuts://") {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "닫기", style: .cancel))
        present(alert, animated: true)
    }


    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "사진 접근 권한 필요",
            message: "잠금화면 이미지를 저장하려면 사진 접근 권한이 필요합니다.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "설정 열기", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension TimetableLockscreenGuideViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else {
            showAlert(title: "사진을 불러올 수 없습니다", message: "다시 선택해주세요.")
            return
        }
        applyWallpaper(image)
        if selectedWallpaperImage != nil {
            TimetableWallpaperStorage.saveWallpaper(selectedWallpaperImage!)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - LockscreenTimetableCardView

// Figma 686:5019 기준 — bg rgba(255,255,255,0.15), backdrop-blur-1.65px
// DAY 탭 슬라이더 + STAGE 컬럼 헤더 + 시간축 + 공연 블록
final class LockscreenTimetableCardView: UIView {

    // Figma 스테이지 순서별 왼쪽 border 색상
    private static let stageAccentColors: [UIColor] = [
        UIColor(hex: "#FF8080"),  // STAGE A — 핑크레드
        UIColor(hex: "#121212"),  // STAGE B — 다크
        UIColor(hex: "#FFFD80"),  // STAGE C — 옐로우
        UIColor(hex: "#80CFFF"),  // STAGE D — 스카이블루
        UIColor(hex: "#D080FF"),  // STAGE E — 퍼플
    ]

    private var event: TimetableEvent?
    private var performances: [Performance] = []
    private var selectedDayIndex: Int = 0
    private var lastBuiltBounds: CGRect = .zero

    // 슬라이더 버튼 참조 (업데이트용)
    private var dayButtons: [UIButton] = []
    private var sliderSegments: [UIView] = []

    // Figma 686:5019 레이아웃 상수
    // py-8, slider h-36, gap-4, stageHeader h-32, gap-8
    private let topPad: CGFloat = 8
    private let sliderH: CGFloat = 36
    private let sliderGap: CGFloat = 4
    private let stageHeaderH: CGFloat = 32
    private let contentGap: CGFloat = 8
    private let rightPad: CGFloat = 12

    override init(frame: CGRect) {
        super.init(frame: frame)
        // UIVisualEffectView 오프스크린 회색 렌더링 방지용 정적 색 (Figma glass 대체)
        backgroundColor = UIColor(hex: "#121212").withAlphaComponent(0.82)
        layer.cornerRadius = 12
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        clipsToBounds = true
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(event: TimetableEvent, performances: [Performance]) {
        self.event = event
        self.performances = performances
        self.selectedDayIndex = 0
        lastBuiltBounds = .zero
        setNeedsLayout()
    }

    private func rebuild() {
        lastBuiltBounds = bounds
        subviews.forEach { $0.removeFromSuperview() }
        dayButtons.removeAll()
        sliderSegments.removeAll()
        guard let event = event else { return }
        buildSliderBar(days: event.days)
        buildStageHeaders(days: event.days)
        buildGrid(days: event.days)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds != .zero, bounds != lastBuiltBounds else { return }
        rebuild()
    }

    // MARK: - Slider Bar (Day Tabs)

    private func buildSliderBar(days: [TimetableDay]) {
        guard !days.isEmpty else { return }
        let bar = UIView(frame: CGRect(x: 0, y: topPad, width: bounds.width, height: sliderH))
        addSubview(bar)

        // 하단 border (Figma: border-b #e5e7eb)
        let borderLine = UIView(frame: CGRect(x: 0, y: sliderH - 0.5, width: bounds.width, height: 0.5))
        borderLine.backgroundColor = UIColor(hex: "#E5E7EB").withAlphaComponent(0.4)
        bar.addSubview(borderLine)

        let segW = bounds.width / CGFloat(days.count)

        for (i, day) in days.enumerated() {
            // 슬라이더 세그먼트 (Figma: 2px white track)
            let seg = UIView(frame: CGRect(x: CGFloat(i) * segW, y: sliderH - 2, width: segW, height: 2))
            seg.backgroundColor = i == selectedDayIndex ? .white : .clear
            bar.addSubview(seg)
            sliderSegments.append(seg)

            // DAY 버튼
            let btn = UIButton(type: .custom)
            btn.tag = i
            btn.frame = CGRect(x: CGFloat(i) * segW, y: 0, width: segW, height: sliderH - 2)
            btn.addTarget(self, action: #selector(dayTapped(_:)), for: .touchUpInside)

            let label = UILabel(frame: btn.bounds)
            label.text = "DAY \(day.dayNumber)"
            label.font = i == selectedDayIndex
                ? .systemFont(ofSize: 14, weight: .semibold)
                : .systemFont(ofSize: 14, weight: .medium)
            label.textColor = i == selectedDayIndex ? .white : UIColor.white.withAlphaComponent(0.8)
            label.textAlignment = .center
            label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            btn.addSubview(label)

            bar.addSubview(btn)
            dayButtons.append(btn)
        }
    }

    @objc private func dayTapped(_ sender: UIButton) {
        guard sender.tag != selectedDayIndex else { return }
        selectedDayIndex = sender.tag
        lastBuiltBounds = .zero
        setNeedsLayout()
    }

    // MARK: - Stage Headers

    private func buildStageHeaders(days: [TimetableDay]) {
        guard selectedDayIndex < days.count else { return }
        let day = days[selectedDayIndex]
        let stages = orderedStages(from: day.performances)
        guard !stages.isEmpty else { return }

        let headerTop = topPad + sliderH + sliderGap
        let timeColW = timeColumnWidth()
        let stageW = stageColumnWidth(count: stages.count, timeColW: timeColW)

        let header = UIView(frame: CGRect(x: 0, y: headerTop, width: bounds.width, height: stageHeaderH))
        addSubview(header)

        for (i, stage) in stages.enumerated() {
            let x = timeColW + CGFloat(i) * (stageW + 4)
            let label = UILabel(frame: CGRect(x: x, y: 0, width: stageW, height: stageHeaderH))
            label.text = stage
            label.font = .systemFont(ofSize: 12, weight: .semibold)
            label.textColor = .white
            label.adjustsFontSizeToFitWidth = true
            header.addSubview(label)
        }
    }

    // MARK: - Grid (Timeline + Blocks)

    private func buildGrid(days: [TimetableDay]) {
        guard selectedDayIndex < days.count else { return }
        let day = days[selectedDayIndex]
        let stages = orderedStages(from: day.performances)

        // 현재 DAY에서 선택된 공연만 필터
        let selectedIds = Set(performances.map(\.id))
        let dayPerfs = day.performances.filter { selectedIds.contains($0.id) }

        let gridTop = topPad + sliderH + sliderGap + stageHeaderH + contentGap
        let gridH = bounds.height - gridTop
        guard gridH > 30 else { return }

        let timeColW = timeColumnWidth()
        let stageW = stageColumnWidth(count: stages.isEmpty ? 1 : stages.count, timeColW: timeColW)

        // 시간 범위: start times → min, 유효한(e>s) end times → max
        // end_time 잘못 입력된 데이터가 grid 시작을 당기지 않도록 분리 계산
        let startMins = day.performances.compactMap { minutes(from: $0.startTime) }
        let endMins = day.performances.compactMap { p -> Int? in
            guard let s = minutes(from: p.startTime),
                  let e = minutes(from: p.endTime), e > s else { return nil }
            return e
        }
        let minMinute = ((startMins.min() ?? 11 * 60) / 60) * 60
        let maxMinute = (((endMins.max() ?? 22 * 60) + 59) / 60) * 60
        let totalMinutes = maxMinute - minMinute
        guard totalMinutes > 0 else { return }

        // 하단 24pt 패딩: 마지막 시간 레이블(h=14)이 clipsToBounds에 잘리지 않도록 + 시각 여백
        let pxPerMin = max((gridH - 24) / CGFloat(totalMinutes), 0.1)
        let numHours = totalMinutes / 60

        // 시간축 레이블 + 구분선
        for h in 0...numHours {
            let minute = minMinute + h * 60
            let hour = minute / 60
            let y = gridTop + CGFloat(h * 60) * pxPerMin

            let timeLabel = UILabel(frame: CGRect(x: 8, y: y - 7, width: timeColW - 10, height: 14))
            timeLabel.text = String(format: "%02d:00", hour)
            timeLabel.font = .systemFont(ofSize: 11, weight: .medium)
            timeLabel.textColor = .white
            addSubview(timeLabel)

            let line = UIView(frame: CGRect(x: timeColW, y: y, width: bounds.width - timeColW - rightPad, height: 0.5))
            line.backgroundColor = UIColor.white.withAlphaComponent(0.1)
            addSubview(line)
        }

        // 공연 블록
        let parsed: [(perf: Performance, start: Int, end: Int)] = dayPerfs.compactMap { p in
            guard let s = minutes(from: p.startTime),
                  let e = minutes(from: p.endTime), e > s else { return nil }
            return (p, s, e)
        }

        for item in parsed {
            guard let stageIdx = stages.firstIndex(of: item.perf.stageName) else { continue }
            let accent = Self.stageAccentColors[stageIdx % Self.stageAccentColors.count]

            let x = timeColW + CGFloat(stageIdx) * (stageW + 4)
            let y = gridTop + CGFloat(item.start - minMinute) * pxPerMin
            let blockH = max(CGFloat(item.end - item.start) * pxPerMin, 28)
            let durationMin = item.end - item.start

            // Figma: bg-rgba(18,18,18,0.4) — nested UIVisualEffectView는 iOS에서 렌더 불가
            let block = UIView(frame: CGRect(x: x, y: y, width: stageW, height: blockH))
            block.backgroundColor = UIColor(hex: "#121212").withAlphaComponent(0.4)
            block.clipsToBounds = true
            addSubview(block)

            // 왼쪽 accent border (1px)
            let accentBar = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: blockH))
            accentBar.backgroundColor = accent
            block.addSubview(accentBar)

            // 아티스트명
            let nameLabel = UILabel(frame: CGRect(x: 8, y: 4, width: stageW - 16, height: max(blockH - 18, 14)))
            nameLabel.text = item.perf.artistName
            nameLabel.font = .systemFont(ofSize: 11, weight: .medium)
            nameLabel.textColor = .white
            nameLabel.numberOfLines = 2
            nameLabel.lineBreakMode = .byTruncatingTail
            block.addSubview(nameLabel)

            // 공연 시간 (Figma: "50'", "60'")
            let durationLabel = UILabel(frame: CGRect(x: 8, y: blockH - 14, width: stageW - 16, height: 12))
            durationLabel.text = "\(durationMin)'"
            durationLabel.font = .systemFont(ofSize: 10, weight: .regular)
            durationLabel.textColor = UIColor.white.withAlphaComponent(0.85)
            durationLabel.textAlignment = .right
            block.addSubview(durationLabel)
        }

        // 선택된 공연 없음 표시
        if parsed.isEmpty {
            let empty = UILabel(frame: CGRect(x: timeColW, y: gridTop + gridH / 2 - 10, width: bounds.width - timeColW, height: 20))
            empty.text = "선택한 공연이 없습니다"
            empty.font = .systemFont(ofSize: 12, weight: .regular)
            empty.textColor = UIColor.white.withAlphaComponent(0.5)
            empty.textAlignment = .center
            addSubview(empty)
        }
    }

    // MARK: - Helpers

    private func orderedStages(from performances: [Performance]) -> [String] {
        var seen = Set<String>()
        return performances.compactMap { p in
            seen.insert(p.stageName).inserted ? p.stageName : nil
        }
    }

    private func timeColumnWidth() -> CGFloat {
        // Figma: 72pt / 358pt 비율 스케일
        return bounds.width * (72.0 / 358.0)
    }

    private func stageColumnWidth(count: Int, timeColW: CGFloat) -> CGFloat {
        guard count > 0 else { return bounds.width - timeColW - rightPad }
        let gaps = CGFloat(count - 1) * 4
        return max((bounds.width - timeColW - rightPad - gaps) / CGFloat(count), 36)
    }

    private func minutes(from timeString: String) -> Int? {
        let clean = timeString.trimmingCharacters(in: CharacterSet(charactersIn: "~").union(.whitespaces))
        let parts = clean.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        return parts[0] * 60 + parts[1]
    }
}
