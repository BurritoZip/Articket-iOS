# Home Feature Codemap

## 파일 인덱스 (`Articket/Articket/Presentation/Home/`)

| 파일 | 책임 |
|------|------|
| `HomeViewController.swift` | NOW/MY 두 CollectionView + 두 DiffableDataSource 관리, 스크롤 동기화, 히어로 블러 배경, **UIRefreshControl(pull-to-refresh)** |
| `HomeViewModel.swift` | NOW 모드 `State` 값 타입, `onStateChanged` 클로저, `FetchHomeEventsUseCase` 호출, **`reload()` — pull-to-refresh 진입점** |
| `MyViewModel.swift` | MY 모드 `State` 값 타입 (`isLoading` 포함), `FetchMyDataUseCase` 호출 |
| `HomeSection.swift` | `HomeSection`(Int enum), `HomeSectionItem`(연관값 enum) 정의 |
| `MySection.swift` | `MySection`(Int enum), `MySectionItem`(연관값 enum), `ShortcutItem` 정의 |
| `HomeCollectionViewLayoutFactory.swift` | 모든 섹션 레이아웃 상수 + `makeLayout()` 팩토리 |
| `Cells/HeroBannerCell.swift` | 풀블리드 히어로 포스터 (gradient/text 없음), `configure(with:)` |
| `Views/HeroBannerProgressView.swift` | 연속 track+slider progress bar (floating overlay), `configure(totalPages:)` / `setPage(_:)` |
| `Cells/InterestedEventCell.swift` | 세로형 포스터 카드, `configure(with:)` |
| `Cells/UpcomingEventCell.swift` | 텍스트 전용 행 + D-day 배지, `configure(with:)` |
| `Cells/HorizontalEventCell.swift` | 이미지 왼쪽 행 (새로 시작/곧 종료), `configure(with:)` |
| `SupplementaryViews/SectionHeaderView.swift` | 섹션 제목 + `.seeMore` 또는 `.arrows` 액세서리 |

## 관련 화면

| 파일 | 위치 | 설명 |
|------|------|------|
| `Presentation/EventList/EventListViewController.swift` | 신규 | 더보기 클릭 시 푸시되는 이벤트 목록 화면 (TableView) |
| `Presentation/Search/SearchViewController.swift` | 기존 | 검색 화면 (UserDefaults 기반 최근 검색어) |

## DI 연결 지점

```
HomeCoordinator.start()
  → SupabaseEventRepository()
  → FetchHomeEventsUseCase(repository:)
  → HomeViewModel(fetchHomeEventsUseCase:)
  → HomeViewController(viewModel:)

HomeCoordinator.showEventList(title:events:)
  → EventListViewController(title:events:coordinator:)
```

## 데이터 흐름

```
SupabaseEventRepository.fetch*() async throws
  → FetchHomeEventsUseCase.execute() async throws → HomeEventsResult
  → HomeViewModel.viewDidLoad() — Task{} 내부에서 호출
  → HomeViewModel.state 갱신 (State 값 타입)
  → onStateChanged 클로저 호출
  → HomeViewController.applySnapshot()
```

## 이미지 로딩 (`Common/Extension/UIImageView+Remote.swift`)

모든 셀의 이미지는 `UIImageView.loadImage(urlString:)` 로 로드:
- NSCache 기반 메모리 캐시 (100개/50MB 상한)
- URLSessionDataTask + `objc_setAssociatedObject`로 취소 가능
- `cancelImageLoad()` — prepareForReuse에서 직접 호출 불필요 (다음 `loadImage` 호출 시 자동 취소)

## 레이아웃 상수

**HomeCollectionViewLayoutFactory:**
- `heroBannerPosterSideMargin`: 45pt (포스터 좌우 여백)
- `heroBannerProgressAreaHeight`: 80.5pt (진행 표시 영역 총 높이)
- `verticalEventItemsPerPage`: 4 (새로 시작된/곧 종료되는 공연 1페이지 아이템 수)
- 섹션 간격 `contentInsets.bottom`: 기본 36pt, 히어로 배너 60pt

**makeLayout 시그니처 변경:**
- `sections: [HomeSection]` 파라미터 추가 (기본값: `HomeSection.allCases`)
- rawValue 기반 인덱싱 → `sections[sectionIndex]` 로 교체 (섹션 skip 시 인덱스 불일치 버그 수정)

**HomeViewController:**
- `navBarHeight`: 56pt (커스텀 상단 헤더)
- `posterTopGap`: 17pt (헤더 아래에서 포스터까지 간격)
- `heroBannerTopInset` = `safeAreaInsets.top` + 56 + 17

## NOW 모드 — HomeSection rawValue 순서

| rawValue | 섹션 | 셀 타입 |
|----------|------|---------|
| 0 | `heroBanner` | `HeroBannerCell` |
| 1 | `interestedEvents` | `InterestedEventCell` |
| 2 | `upcomingEvents` | `UpcomingEventCell` |
| 3 | `newlyStarted` | `HorizontalEventCell` |
| 4 | `soonEnding` | `HorizontalEventCell` |

## MY 모드 — MySection rawValue 순서

| rawValue | 섹션 | 아이템 타입 | 비고 |
|----------|------|------------|------|
| 0 | `myBookings` | `.booking(Booking)` | 빈 경우 섹션 제외 |
| 1 | `shortcuts` | `.shortcut(ShortcutItem)` | 예매 일정/타임테이블/좌석확인 |
| 2 | `yearlyStats` | `.yearlySubtitle` / `.yearlyChart` / `.yearlyStatRow` | 빈 경우 섹션 제외 |
| 3 | `artistRanking` | `.artistRanking(ArtistRankEntry)` | 빈 경우 섹션 제외 |

> **구현 주의:** `applyMySnapshot()`에서 빈 섹션은 snapshot에 추가하지 않음.
> supplementaryView는 `snapshot().sectionIdentifiers[indexPath.section]`으로 조회 (rawValue 직접 사용 금지).

## ShortcutItem 케이스 (MySection.swift)

| 케이스 | 라벨 | 아이콘 | 탭 동작 |
|--------|------|--------|---------|
| `.schedule` | 예매 일정 | `calendar` | 미구현 |
| `.timetable` | 타임테이블 | `tablecells` | `coordinator?.showTimetable()` |
| `.seat` | 좌석확인 | `chair.lounge` | 미구현 |

## 더보기 라우팅

`SectionHeaderView.onSeeMoreTapped` → `HomeViewController.showSeeMore(section:)`:
- `.interestedEvents` → `coordinator?.showEventList(title: "관심 있는 이벤트", events: state.interestedEvents)`
- `.upcomingEvents` → `coordinator?.showEventList(title: "다가오는 이벤트", events: state.upcomingEvents)`
- 그 외 섹션: 미구현 (break)

## 데이터 품질 필터

**`FetchHomeEventsUseCase`:**
- **날짜 범위**: 모든 쿼리에 `start_date=gte.{1개월전}` 필터 적용 — 오래된 공연 노출 방지
- **상태 필터**: 배너·다가오는 이벤트는 `status=in.(upcoming,on_sale)` 만
- **중복 제거**: 섹션 내 id 기반 dedup + 섹션 간 cross-dedup (배너↔upcoming, newlyStarted↔soonEnding)
- **불완전 데이터 제거**: title 또는 venueName이 빈 이벤트 필터링; 이미지 섹션은 posterUrl도 필수
- **정렬**: 전 섹션 `start_date asc` (곧 종료는 `end_date asc`)

**`SupabaseEventRepository.performanceOnly(_:)`:**
- **장르 필터**: `전시`, `박물관`, `갤러리`, `전람회`, `미술관`, `exhibition`, `museum`, `gallery` 포함 이벤트 제외
- genre 미기재(`nil`) 이벤트는 공연으로 간주하여 포함
- 모든 fetch 메서드(banner/upcoming/newlyStarted/soonEnding)에 적용

**`HomeViewController.applySnapshot()`:**
- `upcomingEvents`: 홈에는 `prefix(2)`로 최대 2개만 표시 (더보기는 전체 목록 전달)
- `currentHomeSections` 추적 → 섹션 구성 변경 시 layout 재생성 (rawValue 인덱스 버그 방지)
- `banners = []`이면 `HomeSectionItem.bannerPlaceholder` 삽입 → heroBanner 섹션 높이 유지 (collapse 방지)
- `heroBannerProgressView.isHidden = banners.isEmpty` (빈 배너 시 progress bar 숨김)

## 이미지 소스

이벤트 포스터는 모두 `event.posterUrl` (Supabase Storage URL) 로 원격 로드.
`event.imageAssetName`은 레거시 필드로 신규 코드에서 사용 금지.

아이콘 에셋 (`Assets.xcassets/Icons/`):
- `ic_[name]_thin` / `ic_[name]_filled` — 예: `ic_home_filled`
