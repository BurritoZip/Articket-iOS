import Foundation

enum HomeSection: Int, CaseIterable, Sendable {
    case heroBanner
    /// 외부 예매처에 다녀온 뒤 "예매하셨나요?"를 되묻는 확인 배너. 미응답 intent가 있을 때만 노출.
    case bookingPrompt
    case recommendations
    case interestedEvents
    case upcomingEvents
    case newlyStarted
    case soonEnding
}

// @preconcurrency suppresses the Swift 6 "main actor-isolated conformance" error
// that arises when UICollectionViewDiffableDataSource infers isolation from @MainActor context.
enum HomeSectionItem: @preconcurrency Hashable, Sendable {
    case banner(Event)
    case bannerPlaceholder      // holds section height when banners = []
    case bookingPrompt(BookingIntent)
    case recommended(Event)
    case interested(Event)
    case upcoming(Event)
    case newlyStarted(Event)
    case soonEnding(Event)
}
