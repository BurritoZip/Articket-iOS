# Domain Layer Codemap

모든 파일은 UIKit import 없음. 순수 Swift.

## Entity (`Domain/Entity/`)

### `Event.swift`
```swift
struct Event: Hashable, Sendable {
    let id: UUID
    let title: String
    let imageAssetName: String?   // nil → placeholder
    let startDate: Date
    let endDate: Date
    let venueName: String
    let isInterested: Bool
    // Computed: dDayString, dateRangeString
}
```

## Repository Protocols (`Domain/Repository/`)

### `EventRepositoryProtocol.swift`
```swift
protocol EventRepositoryProtocol: Sendable {
    func fetchBannerEvents() -> [Event]
    func fetchInterestedEvents() -> [Event]
    func fetchUpcomingEvents() -> [Event]
    func fetchNewlyStartedEvents() -> [Event]
    func fetchSoonEndingEvents() -> [Event]
}
```

## UseCases (`Domain/UseCase/`)

### `FetchHomeEventsUseCase.swift`
```swift
struct HomeEventsResult: Sendable {
    let banners, interestedEvents, upcomingEvents, newlyStartedEvents, soonEndingEvents: [Event]
}
protocol FetchHomeEventsUseCaseProtocol: Sendable { func execute() -> HomeEventsResult }
final class FetchHomeEventsUseCase: FetchHomeEventsUseCaseProtocol, Sendable { ... }
```

## Data 구현체 (`Data/Repository/`)

### `MockEventRepository.swift`
`EventRepositoryProtocol` 구현. 하드코딩 더미 데이터. 네트워크 레이어 없음.

## 색상 토큰 (`Common/Extension/UIColor+Theme.swift`)

| 토큰 | 용도 |
|------|------|
| `tcBackground` | 흰색 배경 |
| `tcSurface` | 이미지 placeholder 배경 (연한 회색) |
| `tcTextPrimary` | 주요 텍스트 (#101828) |
| `tcTextSecondary` | 보조 텍스트 (#667085) |
| `tcBadgeBg` | D-day 배지 배경 |
| `tcBadgeText` | 배지 텍스트 (흰색) |
| `tcSeparator` | 구분선 |

**주의:** 앱은 라이트 모드 전용. 다크 모드 지원 없음.
