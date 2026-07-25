# Domain Layer Codemap

모든 파일은 UIKit import 없음. 순수 Swift.

## Entity (`Domain/Entity/`)

### `Event.swift`
```swift
struct Event: Hashable, Sendable {
    let id: UUID; let title: String
    let imageAssetName: String?   // Mock 로컬 에셋명 (레거시, 새 코드는 posterUrl 사용)
    let posterUrl: String?        // Supabase Storage URL
    let startDate: Date; let endDate: Date?; let venueName: String; let isInterested: Bool
    let hasTimetable: Bool        // events.has_timetable — admin이 Supabase에서 설정
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
struct BookingLink: Sendable, Equatable {
    let provider: String  // interpark/yes24/melon/yanolja/klook
    let label: String     // 인터파크/YES24/멜론티켓/놀(야놀자)/클룩
    let url: URL          // events.booking_links(JSONB)에서 정제
}
struct ConcertDetail: Sendable {
    // status는 Optional — 로딩 전(placeholder)이거나 서버 값이 미지의 문자열이면 nil.
    // nil이면 상태 배지·판매 안내문을 그리지 않는다 (임의 기본값 노출 금지).
    let id: UUID; let title: String; let status: ConcertStatus?
    let genre: String; let duration: String; let ageRestriction: String
    let venueName: String; let address: String; let phoneNumber: String
    let dateRange: String; let ticketOpenDate: String; let ticketProvider: String
    let bookingUrl: URL?             // 대표 예매처 1곳
    let bookingLinks: [BookingLink]  // 예매처 선택지 전체 (2곳↑이면 선택 시트)
    let noticeText: String; let artist: Artist; let imageAssetName: String?
    let reviews: [ConcertReview]
    static let placeholder: ConcertDetail  // async 로딩용 빈 값
}
```
Presentation: `Presentation/ConcertDetail/` — VC + VM + Views (Header/Booking/TabBar/Info/SalesInfo/Review)
Coordinator: `showConcertDetail(concertId:imageAssetName:)` — Home(present fullScreen), Artist/My(push)
> `imageAssetName` 파라미터에 실제로는 `posterUrl` 문자열을 전달 (히어로 이미지 선로딩용)

### `BookingIntent.swift`
```swift
struct BookingIntent: Sendable, Hashable {   // Home diffable 스냅샷 아이템으로 직접 사용
    let eventId: UUID; let eventTitle: String
    let posterUrl: String?; let attemptedAt: Date
    static let expiry: TimeInterval  // 7일 — 지난 미응답 건은 조회에서 제외
    var isExpired: Bool
}
enum BookingIntentOutcome: String, Sendable { case booked; case skipped }
```
외부 예매처로 나간 기록. 복귀 후 홈 상단에서 "예매하셨나요?"로 되묻기 위한 최소 정보.
DB는 `booking_intents` 테이블(Admin 레포 `20260720000000_booking_intents.sql`), 비로그인 기록은
`Data/Service/BookingIntentLocalStore.swift`(UserDefaults)에 보관 후 로그인 시 서버로 승격.

> **`user_bookings`에 pending 행을 넣지 않는 이유** — 그 테이블은 마이페이지 목록·연간 통계·
> 아티스트 랭킹·타임테이블이 모두 집계하므로, 예매 여부가 불확실한 행을 섞으면 지표가 오염된다.

### `Artist.swift`
```swift
struct Artist: Hashable, Sendable {
    let id: UUID; let name: String; let avatarUrl: String?   // Supabase Storage URL
    let followersCount: Int; let upcomingEventCount: Int; var isFollowing: Bool
}
struct PopularArtist: Hashable, Sendable {
    let id: UUID; let name: String; let imageUrl: String?; let badge: String
}
```

### `ArtistDetail.swift`
```swift
struct UpcomingTicketing: Sendable { let id: UUID; let dDay: String; let concertTitle: String; let ticketOpenInfo: String; let dateVenueInfo: String }
struct PastConcert: Sendable { let id: UUID; let imageUrl: String?; let title: String; let dateRange: String; let venueName: String }
struct MusicVideo: Sendable { let id: UUID; let thumbnailUrl: String?; let title: String; let viewCount: String; let likeCount: String; let uploadDate: String }
struct AlbumItem: Sendable { let id: UUID; let imageUrl: String?; let title: String; let year: String }
struct ProfileInfo: Sendable { let occupation: String; let birthDate: String; let birthPlace: String; let related: String }
struct ArtistDetail: Sendable {
    let artist: Artist; let upcomingTicketing: UpcomingTicketing?
    let pastConcerts: [PastConcert]; let profileInfo: ProfileInfo
    let musicVideos: [MusicVideo]; let albums: [AlbumItem]
    static let placeholder: ArtistDetail  // async 로딩용 빈 값
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
    let avatarUrl: String?; let posterUrls: [String]; var isExpanded: Bool
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

> **모든 메서드 시그니처: `async throws`** — 2026-05 Supabase 연동 마이그레이션 완료

| 프로토콜 | 주요 메서드 |
|---------|------------|
| `EventRepositoryProtocol` | `fetchBannerEvents()`, `fetchInterestedEvents()`, `fetchUpcomingEvents()`, `fetchNewlyStartedEvents()`, `fetchSoonEndingEvents()` |
| `TimetableRepositoryProtocol` | `fetchTimetableEvents()` — `has_timetable=true`인 이벤트 + 공연 데이터 반환 |
| `ArtistRepositoryProtocol` | `fetchMyArtists()`, `fetchPopularArtists()`, `fetchCalendarEvents(year:month:)`, `fetchRecommendedArtists()`, `searchArtists(keyword:)` |
| `ArtistDetailRepositoryProtocol` | `fetchArtistDetail(artistId:)` |
| `ConcertDetailRepositoryProtocol` | `fetchConcertDetail(concertId:)` |
| `BookingRepositoryProtocol` | `fetchMyBookings()`, `fetchMyStats()`, `fetchArtistRankings()`, `markBooked(eventId:)`, `isBooked(eventId:)`, `recordBookingIntent(eventId:eventTitle:posterUrl:)`, `fetchPendingBookingIntent()`, `resolveBookingIntent(eventId:outcome:)` |
| `BookingIssueReporting` | `reportMissingBookingLink(eventId:eventTitle:)` — booking_url 없는 공연 예매 시도 시 `event_booking_link_issues`에 기록(Admin 확인용) |
| `MyPageRepositoryProtocol` | `fetchUserProfile()`, `fetchMyArtists()`, `fetchReviewableShows()`, `fetchYearlyShows()` |

---

## UseCases (`Domain/UseCase/`)

| UseCase | 반환 | 비고 |
|---------|------|------|
| `FetchHomeEventsUseCase` | `HomeEventsResult` (5개 섹션 이벤트 묶음) | `async let` 5개 병렬 + dedup/필터 |
| `FetchArtistDataUseCase` | `ArtistDataResult` (myArtists + popularArtists + recommendedArtists) | `fetchCalendarEvents(year:month:)` 도 포함 — repository에 위임 |
| `FetchMyDataUseCase` | `MyDataResult` (bookings + stats + artistRankings) | BookingRepositoryProtocol 사용 |
| `FetchMyPageDataUseCase` | `MyPageData` (userProfile + myArtists + reviewableShows + yearlyShows) | MyPageRepositoryProtocol 사용 |
| `FetchArtistDetailUseCase` | `ArtistDetail` | |
| `FetchConcertDetailUseCase` | `ConcertDetail` | |

---

## Data 구현체

### Mock (`Data/Repository/Mock*.swift`)
로컬 하드코딩 데이터. 단위 테스트 및 오프라인 개발용으로 보존.

| 파일 | 구현 프로토콜 |
|------|-------------|
| `MockEventRepository` | `EventRepositoryProtocol` |
| `MockArtistRepository` | `ArtistRepositoryProtocol` |
| `MockArtistDetailRepository` | `ArtistDetailRepositoryProtocol` |
| `MockConcertDetailRepository` | `ConcertDetailRepositoryProtocol` |
| `MockBookingRepository` | `BookingRepositoryProtocol` |
| `MockMyPageRepository` | `MyPageRepositoryProtocol` |

### Supabase (`Data/Repository/Supabase*.swift`) — **현재 Coordinator에서 사용 중**
URLSession + PostgREST REST API 기반. `SupabaseConfig.swift`는 `.gitignore`로 보호 (`.example.swift` 참조).

| 파일 | 구현 프로토콜 | 비고 |
|------|-------------|------|
| `SupabaseEventRepository` | `EventRepositoryProtocol` | 완전 구현 |
| `SupabaseTimetableRepository` | `TimetableRepositoryProtocol` | `events + timetable_performances` 조인 |
| `SupabaseConcertDetailRepository` | `ConcertDetailRepositoryProtocol` | 완전 구현 |
| `SupabaseArtistRepository` | `ArtistRepositoryProtocol` | `fetchMyArtists` 로그인 전 빈 배열; `fetchCalendarEvents` Supabase 직접 조회 |
| `SupabaseArtistDetailRepository` | `ArtistDetailRepositoryProtocol` | 완전 구현 |
| `SupabaseBookingRepository` | `BookingRepositoryProtocol` | 로그인 전 Mock 위임 |
| `SupabaseBookingIssueReporter` | `BookingIssueReporting` | `event_booking_link_issues` insert (텔레메트리, 실패 무시) |
| `SupabaseMyPageRepository` | `MyPageRepositoryProtocol` | 로그인 전 Mock 위임 |

### DTOs (`Data/DTO/`)
Supabase REST 응답 → Domain Entity 변환.
- `EventRow.swift` — `toEvent()`, `toConcertDetail(reviews:)` (`hasTimetable` 포함)
- `TimetableEventRow.swift` — `toTimetableEvent()` / `TimetablePerformanceRow` 포함
- `ArtistRow.swift` — `toArtist()`, `toArtistDetail(...)` + 보조 Row들 (`PastConcertRow`, `AlbumRow`, `MusicVideoRow`, `ConcertReviewRow`)

### Service (`Data/Service/`)
- `SupabaseService.swift` — URLSession 래퍼, JSON decode with `convertFromSnakeCase`
- `SupabaseConfig.swift` — projectURL / anonKey (`.gitignore` 보호, `SupabaseConfig.example.swift` 참조)

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
