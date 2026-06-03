import Foundation

enum HomeSection: Int, CaseIterable, Sendable {
    case heroBanner
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
    case recommended(Event)
    case interested(Event)
    case upcoming(Event)
    case newlyStarted(Event)
    case soonEnding(Event)
}
