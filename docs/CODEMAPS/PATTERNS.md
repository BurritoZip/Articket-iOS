# 코드 패턴 & 템플릿

새 기능을 추가할 때 아래 템플릿을 그대로 따르세요. 기존 구현을 읽지 않아도 됩니다.

---

## ViewModel 템플릿

```swift
@MainActor
final class [Feature]ViewModel {

    struct State {
        var items: [[Entity]] = []
        var isLoading: Bool = false
        var errorMessage: String? = nil
        static let empty = State()
    }

    private(set) var state: State = .empty
    var onStateChanged: (() -> Void)?
    var onError: ((String) -> Void)?
    // 로그인이 필요한 액션: 로그인 후 재실행할 클로저를 파라미터로 전달
    var onLoginRequired: ((@escaping () -> Void) -> Void)?

    private let useCase: any [Feature]UseCaseProtocol

    init(useCase: some [Feature]UseCaseProtocol) {
        self.useCase = useCase
    }

    func viewDidLoad() {
        state.isLoading = true
        onStateChanged?()
        Task {
            do {
                let result = try await useCase.execute()
                state = State(items: result.items, isLoading: false)
            } catch {
                state.isLoading = false
                state.errorMessage = error.localizedDescription
            }
            onStateChanged?()
        }
    }

    // 로그인 필요 기능 예시
    func somePersonalAction() {
        guard AuthService.shared.isLoggedIn else {
            onLoginRequired? { [weak self] in self?.somePersonalAction() }
            return
        }
        // ... 실제 로직
    }
}
```

> **주의:** init에서 데이터를 로드하는 ViewModel(`ConcertDetailViewModel`, `ArtistDetailViewModel`)은
> `static let placeholder`를 Entity에 추가하고 init에서 placeholder로 초기화,
> viewDidLoad()에서 실제 데이터를 로드한다.

---

## Cell 템플릿

```swift
final class [Type]Cell: UICollectionViewCell {

    static let reuseIdentifier = "[Type]Cell"

    private let imageView: UIImageView = { ... }()
    private let titleLabel: UILabel = { ... }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        imageView.snp.makeConstraints { ... }
        titleLabel.snp.makeConstraints { ... }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func configure(with event: Event) {
        titleLabel.text = event.title
        imageView.loadImage(urlString: event.posterUrl)  // UIImageView+Remote.swift
    }
}
```

---

## UseCase + Repository 템플릿

```swift
// Domain/Repository/[Entity]RepositoryProtocol.swift
protocol [Entity]RepositoryProtocol: Sendable {
    func fetch[Entity]s() async throws -> [[Entity]]
}

// Domain/UseCase/Fetch[Feature]UseCase.swift
protocol Fetch[Feature]UseCaseProtocol: Sendable {
    func execute() async throws -> [Result]
}
final class Fetch[Feature]UseCase: Fetch[Feature]UseCaseProtocol, Sendable {
    private let repository: any [Entity]RepositoryProtocol
    init(repository: some [Entity]RepositoryProtocol) { self.repository = repository }
    func execute() async throws -> [Result] {
        // 단일 소스일 때:
        try await repository.fetch[Entity]s()
        // 병렬 다중 소스일 때:
        // async let a = repository.fetchA()
        // async let b = repository.fetchB()
        // return try await Result(a: a, b: b)
    }
}

// Data/Repository/Mock[Entity]Repository.swift
final class Mock[Entity]Repository: [Entity]RepositoryProtocol {
    func fetch[Entity]s() async -> [[Entity]] { [ /* 더미 데이터 */ ] }
    // async (throws 없이) — async throws 프로토콜을 만족시킴
}
```

---

## Supabase Repository + DTO 템플릿

```swift
// Data/DTO/[Entity]Row.swift
struct [Entity]Row: Decodable {
    let id: UUID
    let title: String
    let posterUrl: String?       // snake_case → .convertFromSnakeCase
    struct VenueRef: Decodable { let name: String }
    let venues: VenueRef?        // PostgREST join: select=*,venues(name)

    func to[Entity]() -> [Entity] {
        [Entity](
            id: id,
            title: title,
            posterUrl: posterUrl,
            venueName: venues?.name ?? ""
        )
    }
}

// Data/Repository/Supabase[Entity]Repository.swift
struct Supabase[Entity]Repository: [Entity]RepositoryProtocol {
    private let service = SupabaseService.shared

    func fetch[Entity]s() async throws -> [[Entity]] {
        let rows: [[Entity]Row] = try await service.fetch(
            table: "[entities]",
            query: "select=*,venues(name)&order=start_date.asc"
        )
        return rows.map { $0.to[Entity]() }
    }
}
```

`SupabaseService.shared.fetch(table:query:)` — URLSession 기반 PostgREST 래퍼.
`SupabaseConfig.projectURL` / `anonKey` 설정 후 Coordinator에서 `MockXxxRepository()` → `SupabaseXxxRepository()` 교체.

---

## Supplementary View 템플릿

```swift
final class [Type]View: UICollectionReusableView {
    static let reuseIdentifier = "[Type]View"

    override init(frame: CGRect) {
        super.init(frame: frame)
        // setup subviews
    }
    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        // 콜백/상태 초기화
    }

    func configure(...) { ... }
}
```

---

## 새 Feature 추가 체크리스트

```
[ ] Domain/Entity/[Entity].swift                          ← static let placeholder 추가 (async 로딩용)
[ ] Domain/Repository/[Entity]RepositoryProtocol.swift    ← 모든 메서드 async throws
[ ] Domain/UseCase/Fetch[Feature]UseCase.swift            ← async throws, async let 병렬 패턴
[ ] Data/Repository/Mock[Entity]Repository.swift          ← async (throws 없이)
[ ] Data/Repository/Supabase[Entity]Repository.swift      ← SupabaseService.fetch 사용
[ ] Data/DTO/[Entity]Row.swift                            ← Decodable + to[Entity]() 변환
[ ] Presentation/[Feature]/[Feature]Section.swift
[ ] Presentation/[Feature]/[Feature]ViewController.swift   ← weak var coordinator, viewModel.viewDidLoad() 호출
[ ] Presentation/[Feature]/[Feature]ViewModel.swift        ← Task{} 비동기 패턴
[ ] Presentation/[Feature]/[Feature]CollectionViewLayoutFactory.swift  (필요 시)
[ ] Presentation/[Feature]/Cells/*.swift
[ ] Presentation/Coordinator/[Feature]Coordinator.swift   ← 라우팅 메서드 추가, SupabaseXxx or MockXxx DI
[ ] 기존 Coordinator의 show[Feature]() 메서드 추가       ← 진입점 연결
[ ] docs/CODEMAPS/[FEATURE].md 생성
```

> **Xcode 주의:** `Data/Repository/Supabase*.swift`, `Data/DTO/*.swift`, `Data/Service/SupabaseService.swift`
> 는 파일 시스템에만 존재. Xcode 프로젝트 네비게이터에서 수동으로 그룹에 드래그 → "Add to target: Articket" 체크 필요.

---

## SectionHeader 액세서리 타입

`SectionHeaderView.configure(title:accessory:icon:fontSize:)`:
- `.seeMore` — 더보기 버튼 → `onSeeMoreTapped` 콜백
- `.arrows` — 좌/우 화살표 → `onLeftArrowTapped` / `onRightArrowTapped` 콜백
- `.none` — 액세서리 없음
- `icon:` — SF Symbol UIImage (optional, 기본 nil). 있으면 title 왼쪽에 20pt 아이콘 표시
- `fontSize:` — title 폰트 크기 (기본 20pt)

---

## 재사용 컴포넌트 (`Common/Components/`)

Artist 탭 개발 시 생성된 공유 컴포넌트. 추후 다른 탭에서도 사용 가능.

| 파일 | 역할 | 사용처 |
|------|------|--------|
| `ArtistAvatarView.swift` | `init(size:showMusicBadge:)` — 원형 이미지 + border + 옵션 배지. `configure(urlString:)` 으로 URL 기반 로딩 | MyArtistCell(80pt), RecommendedArtistCell(64pt) |
| `HomeSkeletonView.swift` | 홈 화면 초기 로딩 shimmer 스켈레톤. `stopShimmer()` 호출 후 숨김 | HomeViewController 로딩 중 |
| `FollowButton.swift` | `setFollowing(_:)` — 팔로우/팔로잉 pill 버튼 | RecommendedArtistCell |
| `BadgePillView.swift` | `configure(text:)` — 어두운 배경 pill 텍스트 | PopularArtistCell |
| `EventChipView.swift` | `configure(title:color:)` — CalendarEventColor 기반 칩 | CalendarCell.DayCell |

---

## Artist 탭 섹션 구조

| 섹션 | 헤더 | 레이아웃 | 아이템 |
|------|------|---------|--------|
| myArtists | 없음 | 가로 스크롤 80×108pt | `.myArtist(Artist)` |
| popularArtists | ♫ 인기 아티스트 | 가로 스크롤 128×157pt | `.popularArtist(PopularArtist)` |
| calendar | 공연 캘린더 (`.arrows` 헤더) | full-width estimated(380) | `.calendar(year:month:)` |
| recommendedArtists | ✨ 당신이 좋아할 만한 아티스트 (18pt) | 세로 90pt 고정 | `.recommendedArtist(Artist)` |

**DI**: `ArtistCoordinator` → `SupabaseArtistRepository` → `FetchArtistDataUseCase` → `ArtistViewModel`

**캘린더 데이터 흐름:**
- `ArtistViewModel.viewDidLoad()`: `async let execute + fetchCalendarEvents` 병렬 호출
- `ArtistViewModel.changeMonth(by:)`: Task 내부에서 `fetchCalendarEvents(year:month:)` 재조회
- `SupabaseArtistRepository.fetchCalendarEvents`: `start_date lte lastDay AND end_date gte firstDay` 범위 쿼리, 다일 공연 날짜별 전개

**라우팅**: `ArtistCoordinator.showArtistDetail(artistId:)` / `showConcertDetail(concertId:imageAssetName:)` / `showSearch()`
- `fetchMyArtists()` — 인증 전 빈 배열 (팔로우 목록은 로그인 필요)

---

## 진단 로깅 (AppLog)

- 화면: 자동(viewDidAppear 스위즐). 별도 호출 불필요.
- API: 자동(SupabaseService.fetch/uploadToStorage). 엔드포인트·상태·소요시간 breadcrumb.
- UI 액션: 의미있는 버튼에 `AppLog.shared.action("라벨")` 1줄.
- 에러: 기존 `ErrorReporter.shared.capture(...)` 그대로 — 현재 화면 + 최근 20 breadcrumb가 자동 첨부돼 app_error_logs(screen/breadcrumbs)로 전송.
- 원칙: body 원문·PII 미기록. 네트워크(오프라인)는 breadcrumb만, 리포트 안 함.

## Dynamic Type (글자 크기 접근성)

- 폰트 팩토리: `UIFont.scaled(_:weight:textStyle:maxSize:)` (`Common/Extension/UIFont+Scaled.swift`).
  - `UIFontMetrics`로 스케일 + `maximumPointSize` **상한 필수**(기본 `size*1.4`). 라이트모드 전용 + SnapKit 고정 높이가 많아, 캡이 세로 클리핑을 막는 핵심 레버.
  - 라벨은 `UILabel.applyScaledFont(...)` 또는 프로퍼티에서 `.scaled(...)` + `adjustsFontForContentSizeCategory = true`.
- **적용 원칙(안전 우선)**:
  - 안전: multiline(`numberOfLines = 0/2`) 라벨, 세로 스택 안의 라벨(높이 유연) → 넉넉한 캡(1.4~1.5×).
  - 주의: 고정 높이(`height.equalTo`) 컨테이너의 라벨 → 캡을 좁게(예: 내비바 44 → maxSize 22). 배지/버튼 등 폭 고정은 스킵하거나 truncation 허용.
  - 컨테이너가 못 늘면 폰트만 키우지 말 것(클리핑). 필요 시 고정 height → `greaterThanOrEqualTo`로 flex 전환 후 적용.
- 적용됨(1차, 앱 전역 크롬): `EmptyStateView`·`ToastView`·`SimpleNavigationBar`.
- 롤아웃: 화면별 본문/셀은 증분 적용 + **실기기 최대 글자 크기로 클리핑 확인 필수**(빌드/QA 반복). 진행 상태는 `docs/decisions/UX_IMPROVEMENT_BACKLOG.md`.
