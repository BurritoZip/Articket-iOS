import UIKit

extension UIImage {
    /// 업로드용으로 이미지를 자동 다운스케일 + JPEG 압축한다.
    ///
    /// - 긴 변 기준 `maxDimension` 이내로만 축소(원본이 더 작으면 확대하지 않음).
    /// - 종횡비 유지. `scale = 1`로 렌더링해 픽셀 크기 = 포인트 크기.
    /// - 아바타처럼 작은 표시 영역에 큰 원본을 그대로 올리면 업로드 실패·용량 낭비가 생기므로,
    ///   화면 표시에 충분한 해상도로 줄여 전송한다.
    ///
    /// - Parameters:
    ///   - maxDimension: 긴 변의 최대 픽셀 (기본 512 — 아바타용)
    ///   - compressionQuality: JPEG 품질 0~1 (기본 0.8)
    /// - Returns: 압축된 JPEG 데이터 (실패 시 nil)
    func resizedForUpload(maxDimension: CGFloat = 512, compressionQuality: CGFloat = 0.8) -> Data? {
        let longestSide = max(size.width, size.height)
        // 원본이 이미 작으면 리사이즈 없이 압축만 수행
        let scaleRatio = longestSide > maxDimension ? maxDimension / longestSide : 1
        let targetSize = CGSize(width: size.width * scaleRatio, height: size.height * scaleRatio)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1            // 포인트=픽셀 매핑 (Retina 배율로 인한 추가 확대 방지)
        format.opaque = true        // 알파 불필요 — JPEG는 어차피 불투명
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let resized = renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return resized.jpegData(compressionQuality: compressionQuality)
    }

    /// 업로드용으로 이미지를 지정한 바이트 크기 이내로 압축한다.
    ///
    /// - 먼저 JPEG 품질을 0.8 → 0.1까지 단계적으로 낮추며 `maxBytes` 이내를 시도.
    /// - 최저 품질에서도 초과하면 긴 변(maxDimension)을 512 → 384 → 256 → 192로 줄여 재시도.
    /// - 모든 시도 실패 시 마지막(가장 작은) 데이터를 반환한다.
    ///
    /// 사용자가 고른 사진 용량이 제각각(수 MB)이라 서버 업로드 실패·낭비를 막기 위해
    /// 아바타를 100KB 수준으로 자동 축약하는 용도.
    ///
    /// - Parameter maxBytes: 목표 최대 바이트 (예: 100_000 = 약 100KB)
    /// - Returns: 목표 이내(또는 도달 가능한 최소) JPEG 데이터 (실패 시 nil)
    func resizedForUpload(maxBytes: Int) -> Data? {
        let dimensionSteps: [CGFloat] = [512, 384, 256, 192]
        let qualitySteps: [CGFloat] = [0.8, 0.6, 0.4, 0.25, 0.1]

        var smallest: Data?
        for dimension in dimensionSteps {
            for quality in qualitySteps {
                guard let data = resizedForUpload(maxDimension: dimension, compressionQuality: quality) else { continue }
                if smallest == nil || data.count < (smallest?.count ?? .max) {
                    smallest = data
                }
                if data.count <= maxBytes {
                    return data
                }
            }
        }
        return smallest
    }
}
