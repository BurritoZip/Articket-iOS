import UIKit
import SnapKit

// MARK: - AvatarCropViewController
// 프로필 사진 원형 크롭 편집 화면.
//
// PHPicker 자체에는 크롭 UI가 없어 직사각 원본이 그대로 들어온다. 이 경우 원형 마스크에서
// 인물이 잘리거나 한쪽으로 치우쳐 보이므로, 사용자가 확대/이동으로 원형 영역을 직접 맞추게 한다.
//
// 구현: scrollView의 frame을 크롭 원의 외접 정사각형과 정확히 일치시켜, 화면에 보이는 영역
// (contentOffset ~ bounds.size)이 곧 크롭 영역이 되도록 한다. 별도 좌표 변환이 필요 없다.

final class AvatarCropViewController: UIViewController {

    /// 크롭 완료 시 정사각형 이미지 전달 (원형 마스킹은 표시 단계에서 cornerRadius로 처리)
    var onCropped: ((UIImage) -> Void)?

    private let originalImage: UIImage
    /// 결과 이미지 한 변의 최대 픽셀 — 업로드 전 추가 압축(resizedForUpload)이 뒤따르므로 넉넉히 512
    private let outputSize: CGFloat = 512

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.showsHorizontalScrollIndicator = false
        sv.bouncesZoom = true
        sv.contentInsetAdjustmentBehavior = .never
        sv.backgroundColor = .clear
        return sv
    }()

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        return iv
    }()

    /// 크롭 원 밖을 어둡게 덮는 오버레이 (터치는 통과시켜 스크롤/줌 방해 안 함)
    private let overlayView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        v.isUserInteractionEnabled = false
        return v
    }()

    private let guideLabel: UILabel = {
        let l = UILabel()
        l.text = "확대하거나 움직여 원 안에 맞춰주세요"
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = UIColor.white.withAlphaComponent(0.85)
        l.textAlignment = .center
        return l
    }()

    private let cancelButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("취소", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return b
    }()

    private let doneButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("완료", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        return b
    }()

    private var cropDiameter: CGFloat = 0
    private var didConfigureZoom = false

    // MARK: - Init

    init(image: UIImage) {
        self.originalImage = image
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        imageView.image = originalImage
        setupLayout()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyOverlayMask()
        guard !didConfigureZoom, scrollView.bounds.width > 0 else { return }
        didConfigureZoom = true
        configureZoom()
    }

    // MARK: - Setup

    private func setupLayout() {
        // 크롭 원 지름 — 좌우 32pt 여백, 화면이 길쭉해도 세로를 넘지 않도록 상한
        cropDiameter = min(UIScreen.main.bounds.width - 64, UIScreen.main.bounds.height * 0.5)

        view.addSubview(scrollView)
        scrollView.delegate = self
        scrollView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(cropDiameter)
        }

        scrollView.addSubview(imageView)

        view.addSubview(overlayView)
        overlayView.snp.makeConstraints { $0.edges.equalToSuperview() }

        // 원 테두리 — 오버레이 위에 얹어 경계를 명확히
        let ring = UIView()
        ring.layer.borderColor = UIColor.white.cgColor
        ring.layer.borderWidth = 2
        ring.layer.cornerRadius = cropDiameter / 2
        ring.isUserInteractionEnabled = false
        view.addSubview(ring)
        ring.snp.makeConstraints {
            $0.center.equalTo(scrollView)
            $0.size.equalTo(cropDiameter)
        }

        view.addSubview(guideLabel)
        guideLabel.snp.makeConstraints {
            $0.top.equalTo(scrollView.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        view.addSubview(cancelButton)
        cancelButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            $0.leading.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        view.addSubview(doneButton)
        doneButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            $0.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
    }

    /// 오버레이 가운데를 원형으로 뚫는다 (even-odd 규칙)
    private func applyOverlayMask() {
        let path = UIBezierPath(rect: overlayView.bounds)
        let circleRect = CGRect(
            x: scrollView.frame.minX,
            y: scrollView.frame.minY,
            width: cropDiameter,
            height: cropDiameter
        )
        path.append(UIBezierPath(ovalIn: circleRect))

        let mask = CAShapeLayer()
        mask.path = path.cgPath
        mask.fillRule = .evenOdd
        overlayView.layer.mask = mask
    }

    private func configureZoom() {
        let imageSize = originalImage.size
        guard imageSize.width > 0, imageSize.height > 0 else { return }

        // imageView는 원본 픽셀 크기로 두고 zoomScale로만 배율을 제어한다 (좌표 계산이 단순해짐)
        imageView.frame = CGRect(origin: .zero, size: imageSize)
        scrollView.contentSize = imageSize

        // 크롭 원을 빈틈없이 채우는 최소 배율
        let minScale = max(cropDiameter / imageSize.width, cropDiameter / imageSize.height)
        scrollView.minimumZoomScale = minScale
        scrollView.maximumZoomScale = max(minScale * 4, minScale)
        scrollView.zoomScale = minScale

        // 초기 위치를 가운데로
        let offsetX = max(0, (imageSize.width * minScale - cropDiameter) / 2)
        let offsetY = max(0, (imageSize.height * minScale - cropDiameter) / 2)
        scrollView.contentOffset = CGPoint(x: offsetX, y: offsetY)
    }

    // MARK: - Actions

    @objc private func cancelTapped() { dismiss(animated: true) }

    @objc private func doneTapped() {
        guard let cropped = makeCroppedImage() else {
            dismiss(animated: true)
            return
        }
        let handler = onCropped
        dismiss(animated: true) { handler?(cropped) }
    }

    /// 현재 보이는 영역(=크롭 원의 외접 정사각형)을 잘라 정사각 이미지로 반환
    private func makeCroppedImage() -> UIImage? {
        let scale = scrollView.zoomScale
        guard scale > 0 else { return nil }

        // scrollView.frame == 크롭 정사각형이므로, 보이는 영역은 contentOffset ~ bounds.size 그대로다.
        let visibleRect = CGRect(
            x: scrollView.contentOffset.x / scale,
            y: scrollView.contentOffset.y / scale,
            width: cropDiameter / scale,
            height: cropDiameter / scale
        )

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let outputRect = CGRect(x: 0, y: 0, width: outputSize, height: outputSize)

        return UIGraphicsImageRenderer(size: outputRect.size, format: format).image { _ in
            // 잘라낼 영역이 출력 사각형에 오도록 원본을 확대·이동해 그린다
            let ratio = outputSize / visibleRect.width
            let drawRect = CGRect(
                x: -visibleRect.origin.x * ratio,
                y: -visibleRect.origin.y * ratio,
                width: originalImage.size.width * ratio,
                height: originalImage.size.height * ratio
            )
            originalImage.draw(in: drawRect)
        }
    }
}

// MARK: - UIScrollViewDelegate

extension AvatarCropViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }
}
