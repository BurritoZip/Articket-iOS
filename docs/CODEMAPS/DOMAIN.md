# Domain Layer Codemap

모든 파일은 UIKit import 없음. 순수 Swift.

## Entity (`Domain/Entity/`)

### `Event.swift`
```swift
struct Event: Hashable, Sendable {
    let id: UUID; let title: String
    let imageAssetName: String?   // nil → placeholder (→ 추후 Supabase Storage URL로 교체 예정)
    let startDate: Date; let endDate: Date; let venueName: String; let isInterested: Bool
    // Computed: dDayString, dateRangeString
}
```

### `Concert.swift`
```swift
enum ConcertStatus: String, Sendable {
    case onSale = "예매 중"; case upcoming = "예매 예정"; case ended = "판매종료"
}
struct ConcertReview: Sendable {
    let id: UUID; let starCount: Int  // 1–5
    let title: String; let username: String  // "bogyu****"
    let date: String; let content: String
}
struct ConcertDetail: Sendable {
    let id: UUID; let title: String; let status: ConcertStatus
    let genre: String; let duration: String; let ageRestriction: String
    let venueName: String; let address: String; let phoneNumber: String
    let dateRange: String; let ticketOpenDate: String; let ticketProvider: String
    let noticeText: String; let artist: Artist; let imageAssetName: String?
    let reviews: [ConcertReview]
}
```
Presentation: `Presentation/ConcertDetail/` — VC + VM + Views (Header/Booking/TabBar/Info/SalesInfo/Review)
Coordinator: `showConcertDetail(concertId:imageAssetName:)` — Home(present fullScreen), Artist/My(push)

### `Artist.swift`
```swift
struct Artist: Hashable, Sendable {
    let id: UUID; let name: String; let avatarAssetName: String?
    let followersCount: Int; let upcomingEventCount: Int; var isFollowing: Bool
}
struct PopularArtist: Hashable, Sendable {
    let id: UUID; let name: String; let imageAssetName: String?; let badge: String
}
```

### `ArtistDetail.swift`
```swift
struct UpcomingTicketing: Sendable { let id: UUID; let dDay: String; let concertTitle: String; let ticketOpenInfo: String; let dateVenueInfo: String }
struct PastConcert: Sendable { let id: UUID; let imageAssetName: String?; let title: String; let dateRange: String; let venueName: String }
struct MusicVideo: Sendable { let id: UUID; let thumbnailAssetName: String?; let title: String; let viewCount: String; let likeCount: String; let uploadDate: String }
struct AlbumItem: Sendable { let id: UUID; let imageAssetName: String?; let title: String; let year: String }
struct ProfileInfo: Sendable { let occupation: String; let birthDate: String; let birthPlace: String; let related: String }
struct ArtistDetail: Sendable {
    let artist: Artist; let upcomingTicketing: UpcomingTicketing?
    let pastConcerts: [PastConcert]; let profileInfo: ProfileInfo
    let musicVideos: [MusicVideo]; let albums: [AlbumItem]
}
```

### `Booking.swift`
```swift
enum DeliveryType: Hashable, Sendable { case delivery, onsite }
struct Booking: Hashable, Sendable {
    let id: UUID; let title: String; let venueName: String; let date: Date
    let seat: String; let deliveryType: DeliveryType; let imageAssetName: String?
    // Computed: dDayString, formattedDate
}
```

### `CalendarEvent.swift`
```swift
enum CalendarEventColor: Sendable { case green, red, yellow }
enum BookingStatus: Hashable, Sendable { case onSale, upcoming, ended }
struct CalendarEvent: Hashable, Sendable {
    let id: UUID; let date: Date; let title: String; let color: CalendarEventColor
    let concertTitle: String; let concertDate: String; let venueName: String
    let bookingPlatform: String; let ticketOpenDate: String
    let ticketPrices: [String]; let bookingStatus: BookingStatus; let eventCategory: String
}
```

### `ArtistRankEntry.swift`
```swift
struct ArtistRankEntry: Hashable, Sendable {
    let id: UUID; let rank: Int; let name: String; let viewCount: Int
    let avatarAssetName: String?; let posterAssetNames: [String]; var isExpanded: Bool
}
```

### `UserProfile.swift`
```swift
struct UserProfile: Sendable {
    let displayName: String; let email: String; let initial: String
    let concertCount: Int; let followingArtistCount: Int; let lastVisitDate: Date?
    // Computed: lastVisitDateString (MM.dd)
}
```

### `MyStats.swift`
```swift
struct MyStats: Hashable, Sendable {
    let year: Int; let monthlyViewCounts: [Int]  // 12개
    let topMonth: Int; let topGenre: String; let topArtist: String; let totalCount: Int
}
```

---

## Repository Protocols (`Domain/Repository/`)

| 프로토콜 | 주요 메서드 |
|---------|------------|
| `EventRepositoryProtocol` | `fetchBannerEvents()`, `fetchInterestedEvents()`, `fetchUpcomingEvents()`, `fetchNewlyStartedEvents()`, `fetchSoonEndingEvents()` |
| `ArtistRepositoryProtocol` | `fetchMyArtists()`, `fetchPopularArtists()`, `fetchRecommendedArtists()` |
| `ArtistDetailRepositoryProtocol` | `fetchArtistDetail(artistId:)` |
| `ConcertDetailRepositoryProtocol` | `fetchConcertDetail(concertId:)` |
| `MyRepositoryProtocol` | `fetchBookings()`, `fetchStats()`, `fetchArtistRankings()`, `fetchCalendarEvents()`, `fetchUserProfile()` |

---

## UseCases (`Domain/UseCase/`)

| UseCase | 반환 |
|---------|------|
| `FetchHomeEventsUseCase` | `HomeEventsResult` (5개 섹션 이벤트 묶음) |
| `FetchArtistDetailUseCase` | `ArtistDetail` |
| `FetchConcertDetailUseCase` | `ConcertDetail` |

---

## Data 구현체 (`Data/Repository/`)

| 파일 | 구현 프로토콜 |
|------|-------------|
| `MockEventRepository` | `EventRepositoryProtocol` |
| `MockArtistRepository` | `ArtistRepositoryProtocol` |
| `MockArtistDetailRepository` | `ArtistDetailRepositoryProtocol` |
| `MockConcertDetailRepository` | `ConcertDetailRepositoryProtocol` |
| `MockMyRepository` | `MyRepositoryProtocol` |

**현재 상태**: 네트워크 레이어 없음. 전부 Mock. Supabase 연동 시 각 Mock을 `SupabaseXxxRepository`로 교체 예정.

---

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

**주의:** 앱은 라이트 모드 전용.
