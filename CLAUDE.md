# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 관련 레포 (같은 Supabase 프로젝트 공유)

**Admin 콘솔**: `/Users/sjw/ted.urssu/Articket-admin`

### DB 변경 시 양방향 즉시 동기화 (필수)

**migration 파일 위치**: `supabase/migrations/YYYYMMDDHHMMSS_설명.sql` (iOS가 source of truth)

Admin 레포(`/Users/sjw/ted.urssu/Articket-admin`)에서 Supabase 스키마가 변경됐을 때 iOS에서 반영해야 할 파일:

| DB 변경 | iOS 업데이트 대상 |
|---|---|
| 컬럼 추가 (`events`) | `Data/DTO/EventRow.swift` + `Domain/Entity/Event.swift` + migration SQL |
| 컬럼 추가 (`artists`) | `Data/DTO/ArtistRow.swift` + `Domain/Entity/Artist.swift` + migration SQL |
| 새 테이블 | migration SQL + DTO + Entity + RepositoryProtocol + SupabaseRepository + MockRepository |

**iOS에서 새 기능/DB 변경 시 체크리스트**:
1. `supabase/migrations/` 에 SQL 파일 추가
2. 관련 Swift DTO/Entity 업데이트
3. Admin 타입도 수동 확인: `/Users/sjw/ted.urssu/Articket-admin/types/` — 필요시 직접 업데이트

**규칙**: iOS에서 응답 데이터에 필드가 없거나 새 기능이 생기면 `/Users/sjw/ted.urssu/Articket-admin/types/` 디렉토리의 TypeScript 타입을 먼저 확인한다.

**Admin에서 DB 변경 시**: Admin Claude가 `timetable_performances` 같은 새 테이블을 추가하면 iOS에 migration 파일이 없는 상태가 된다. Admin CLAUDE.md에도 동일한 규칙이 있으므로, **두 레포 모두 열려있을 때는 서로의 migration/types를 즉시 교차 반영**한다.

**Decoder 주의**: `SupabaseService` JSONDecoder는 `keyDecodingStrategy = .convertFromSnakeCase` → DTO 프로퍼티는 반드시 **camelCase** 선언 (`has_timetable` → `hasTimetable`)

## 개발 워크플로우

모든 개발 요청 시 자동으로 아래 순서가 실행됩니다 (UserPromptSubmit 훅):
**플랜 보고 → CODEMAPS 확인 → 코드 수정 → 검증 → 상세 보고**

완료 후 `/ship` 입력 → 한국어 커밋 + 이슈 + PR 자동 생성.

## 빠른 경로 탐색 (네이밍 → 경로 예측)

| 파일 종류 | 경로 패턴 |
|-----------|-----------|
| ViewController | `Presentation/[Feature]/[Feature]ViewController.swift` |
| ViewModel | `Presentation/[Feature]/[Feature]ViewModel.swift` |
| Section/Item enum | `Presentation/[Feature]/[Feature]Section.swift` |
| Layout Factory | `Presentation/[Feature]/[Feature]CollectionViewLayoutFactory.swift` |
| Cell | `Presentation/[Feature]/Cells/[Type]Cell.swift` |
| Supplementary View | `Presentation/[Feature]/SupplementaryViews/[Type]View.swift` |
| UseCase | `Domain/UseCase/Fetch[Feature]UseCase.swift` |
| Repository Protocol | `Domain/Repository/[Entity]RepositoryProtocol.swift` |
| Mock Repository | `Data/Repository/Mock[Entity]Repository.swift` |
| 색상 토큰 | `Common/Extension/UIColor+Theme.swift` |

## Feature 상세 코드맵

- **Home 기능**: `docs/CODEMAPS/HOME.md` — 파일 인덱스, 데이터 흐름, 레이아웃 상수
- **Domain 레이어**: `docs/CODEMAPS/DOMAIN.md` — Entity, Protocol, UseCase 인덱스
- **코드 템플릿**: `docs/CODEMAPS/PATTERNS.md` — ViewModel/Cell/UseCase 뼈대 + 새 Feature 체크리스트

## Build & Run

```bash
xcodebuild -project Articket/Articket.xcodeproj -scheme Articket \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

단일 테스트:
```bash
xcodebuild -project Articket/Articket.xcodeproj -scheme Articket \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:ArticketTests/ArticketTests test
```

## 아키텍처

**Clean Architecture 3계층** (`Articket/Articket/` 하위):

```
Domain/      순수 Swift. UIKit import 없음
Data/        Domain 프로토콜 구현 (Supabase 구현체 + Mock 보조)
Presentation/ UIKit + @MainActor
Common/      Extension (UIColor+Theme, UIImageView+Remote)
```

DI 연결: `SceneDelegate` → `AppCoordinator(window:).start()` → 인증 분기 → `[Feature]Coordinator` → Repository → UseCase → ViewModel → ViewController

**Coordinator 패턴:** `Presentation/Coordinator/` 에 위치. 새 화면 라우팅은 반드시 Coordinator에 추가.
- `AppCoordinator` — 앱 진입 시 `AuthService.isLoggedIn`으로 Auth ↔ MainApp 분기. window 소유.
- `AuthCoordinator` — 로그인 플로우 (Apple Sign In). 성공 시 `authCoordinatorDidAuthenticate()` 위임
- `HomeCoordinator` — Home 플로우 (Search는 fullScreen modal)
- `ArtistCoordinator` — Artist 플로우 (Search/ArtistDetail push)
- `MyCoordinator` — My 플로우
- **ViewController에서 직접 push/present 금지** — `coordinator?.show[Screen]()` 위임

**ViewModel 패턴:** `@MainActor`, `struct State`, `onStateChanged: (() -> Void)?` 클로저. Combine 사용 안 함. 데이터 로딩은 `viewDidLoad()` 내 `Task{}` 비동기 패턴 사용.

## UI 제약사항

- **라이트 모드 전용** — 다크 모드 미지원
- **SnapKit** — 모든 constraints. Storyboard 레이아웃 없음
- **레이아웃 상수** — `HomeCollectionViewLayoutFactory`에만 정의, 인라인 금지
- **색상** — `tcBackground`, `tcTextPrimary` 등 `UIColor+Theme.swift` 토큰 사용
- 히어로 배너: `contentInsetAdjustmentBehavior = .never`, status bar까지 풀블리드
- **모든 탭은 UINavigationController로 감쌈** — navigationBar는 각 VC에서 hidden 처리

## 현재 상태

Home / Artist / ArtistDetail / Search / My / MyPage / EventList 화면 구현됨. 데이터는 Supabase 실연동 (SupabaseXxxRepository 사용 중).
이미지 로딩: `UIImageView+Remote.swift` (NSCache + URLSession). `event.posterUrl` / `artist.avatarUrl` 등 원격 URL 기반.

**인증**: `AuthService` (Apple Sign In) + `supabase-swift` SDK. 로그인 후 `SupabaseService.fetch()`가 JWT를 Authorization 헤더에 자동 주입 → RLS 통과.
**미구현 (Supabase 대시보드 설정 필요):** Apple Provider (Team ID/Key ID/Private Key) 등록 후 `fetchMyArtists()`, `SupabaseBookingRepository`, `SupabaseMyPageRepository` 실데이터 연동 가능.
**검색**: `SearchViewModel` — UserDefaults LRU 최근 검색어(최대 10개). 검색 결과 화면(`SearchResultViewController`) 미구현.

---

## /ship — 한국어 Git 워크플로우

`/ship` 입력 시 아래 순서로 실행:

### 0. 브랜치 생성 규칙

**반드시 이슈 번호 기반으로 브랜치를 생성한다. 기능명/설명 문자열 절대 금지.**

```bash
# 이슈 생성 후 반환된 번호를 사용
git checkout -b feat/#이슈번호   # 예: feat/#23
git checkout -b fix/#이슈번호    # 예: fix/#24
git checkout -b refactor/#이슈번호
```

타입 → 브랜치 prefix 대응:
- `기능` → `feat/`
- `수정` → `fix/`
- `리팩토링` → `refactor/`
- `스타일` → `style/`
- `문서` → `docs/`

**잘못된 예시 (절대 사용 금지):** `feat/my-profile`, `fix/layout-bug`, `feat/artist-search`
**올바른 예시:** `feat/#23`, `fix/#24`, `refactor/#25`

### 1. 커밋 메시지 템플릿 (한국어)

```
[타입] 한 줄 요약

변경 내용:
- 

선택 이유:
- 이 방식을 선택한 근거 (대안 대비 장점, 제약 조건, 설계 의도 등)

수정 파일:
- Articket/Articket/...
```

타입: `기능` | `수정` | `리팩토링` | `스타일` | `테스트` | `문서` | `설정`

### 2. GitHub Issue 생성 (한국어)

```bash
gh issue create \
  --title "[타입] 제목" \
  --body "## 개요
[변경 목적]

## 선택 이유
[이 방식을 선택한 근거]

## 변경 사항
- 

## 수정 파일
- 

## 검증
- [ ] 빌드 확인
- [ ] 기능 동작 확인" \
  --label "enhancement"
```

### 3. PR 생성 (한국어)

```bash
gh pr create \
  --title "[타입] 제목" \
  --body "## 개요
[PR 목적]

## 선택 이유
[이 구현 방식을 선택한 근거]

## 변경 사항
- 

## 검증 방법
- [ ] xcodebuild 빌드 성공
- [ ] 시뮬레이터 동작 확인

## 관련 이슈
Closes #이슈번호"
```
