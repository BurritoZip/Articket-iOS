import UIKit

/// 가벼운 햅틱 피드백 래퍼. 의미 있는 상호작용(토글·선택·제출 결과)에만 사용한다.
/// 라이트 모드 전용 앱이지만 햅틱은 접근성/촉각 피드백으로 가치가 있어 최소 지점에만 얹는다.
enum Haptics {
    /// 값 선택 변경(별점 등)
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    /// 토글/탭 성공 등 가벼운 물리 피드백
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    /// 작업 결과 알림(성공/경고/실패)
    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}
