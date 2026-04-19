# Home Feature Codemap

## 파일 인덱스 (`Articket/Articket/Presentation/Home/`)

| 파일 | 책임 |
|------|------|
| `HomeViewController.swift` | DiffableDataSource 관리, 스크롤 동기화, 히어로 블러 배경 업데이트 |
| `HomeViewModel.swift` | `State` 값 타입, `onStateChanged` 클로저, UseCase 호출 |
| `HomeSection.swift` | `HomeSection`(Int enum), `HomeSectionItem`(연관값 enum) 정의 |
| `HomeCollectionViewLayoutFactory.swift` | 모든 섹션 레이아웃 상수 + `makeLayout()` 팩토리 |
| `Cells/HeroBannerCell.swift` | 풀블리드 히어로 포스터, 진행 도트, `configure(with:pageIndex:totalPages:)` |
| `Cells/InterestedEventCell.swift` | 세로형 포스터 카드, `configure(with:)` |
| `Cells/UpcomingEventCell.swift` | 텍스트 전용 행 + D-day 배지, `configure(with:)` |
| `Cells/HorizontalEventCell.swift` | 이미지 왼쪽 행 (새로 시작/곧 종료), `configure(with:)` |
| `SupplementaryViews/SectionHeaderView.swift` | 섹션 제목 + `.seeMore` 또는 `.arrows` 액세서리 |

## DI 연결 지점

```
MainTabBarController.setupTabs()
  → MockEventRepository()
  → FetchHomeEventsUseCase(repository:)
  → HomeViewModel(fetchHomeEventsUseCase:)
  → HomeViewController(viewModel:)
```

## 데이터 흐름

```
MockEventRepository.fetch*()
  → FetchHomeEventsUseCase.execute() → HomeEventsResult
  → HomeViewModel.state (State 값 타입)
  → onStateChanged 클로저 호출
  → HomeViewController.applySnapshot()
```

## 레이아웃 상수

**HomeCollectionViewLayoutFactory:**
- `heroBannerPosterSideMargin`: 45pt (포스터 좌우 여백)
- `heroBannerProgressAreaHeight`: 80.5pt (진행 표시 영역 총 높이)
- 섹션 간격 `contentInsets.bottom`: 기본 36pt, 히어로 배너 60pt

**HomeViewController:**
- `navBarHeight`: 56pt (커스텀 상단 헤더)
- `posterTopGap`: 17pt (헤더 아래에서 포스터까지 간격)
- `heroBannerTopInset` = `safeAreaInsets.top` + 56 + 17

## HomeSection rawValue 순서

| rawValue | 섹션 | 셀 타입 |
|----------|------|---------|
| 0 | `heroBanner` | `HeroBannerCell` |
| 1 | `interestedEvents` | `InterestedEventCell` |
| 2 | `upcomingEvents` | `UpcomingEventCell` |
| 3 | `newlyStarted` | `HorizontalEventCell` |
| 4 | `soonEnding` | `HorizontalEventCell` |

## Asset 네이밍 패턴 (`Assets.xcassets/Events/`)

| 폴더 | 패턴 | 예시 |
|------|------|------|
| `Banners/` | `banner_[artist]` | `banner_yerin_baek` |
| `Interested/` | `poster_[artist]` | `poster_black_skirts` |
| `NewlyStarted/` | `newly_[artist]` | `newly_chuu` |
| `SoonEnding/` | `ending_[artist]` | `ending_soran` |
| 아이콘 | `ic_[name]_thin` / `ic_[name]_filled` | `ic_home_filled` |
