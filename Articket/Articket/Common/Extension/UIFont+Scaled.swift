import UIKit

extension UIFont {
    /// Dynamic Type 대응 스케일 폰트.
    /// 기존 고정 크기(size)를 기준으로 `UIFontMetrics`로 스케일하되, SnapKit 고정 높이
    /// 컨테이너에서의 텍스트 클리핑을 막기 위해 `maximumPointSize` 상한을 둔다.
    /// - Parameters:
    ///   - size: 기본(100% 접근성 크기) 포인트
    ///   - weight: 폰트 굵기
    ///   - textStyle: 스케일 기준 텍스트 스타일(기본 `.body`)
    ///   - maxSize: 상한 포인트. nil이면 `size * 1.4`(140%)로 캡 — 고정 높이 레이아웃 보호
    static func scaled(
        _ size: CGFloat,
        weight: UIFont.Weight = .regular,
        textStyle: UIFont.TextStyle = .body,
        maxSize: CGFloat? = nil
    ) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        let cap = maxSize ?? size * 1.4
        return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: base, maximumPointSize: cap)
    }
}

extension UILabel {
    /// Dynamic Type 반영 활성화 + 스케일 폰트 지정.
    /// (`adjustsFontForContentSizeCategory = true`로 사용자 글자 크기 변경 시 실시간 반영)
    func applyScaledFont(
        _ size: CGFloat,
        weight: UIFont.Weight = .regular,
        textStyle: UIFont.TextStyle = .body,
        maxSize: CGFloat? = nil
    ) {
        font = .scaled(size, weight: weight, textStyle: textStyle, maxSize: maxSize)
        adjustsFontForContentSizeCategory = true
    }
}
