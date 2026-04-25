# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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
Data/        Domain 프로토콜 구현 (현재 Mock만 존재, 네트워크 레이어 없음)
Presentation/ UIKit + @MainActor
Common/      Extension (UIColor+Theme)
```

DI 연결: `SceneDelegate` → `AppCoordinator.start()` → `[Feature]Coordinator` → Repository → UseCase → ViewModel → ViewController

**Coordinator 패턴:** `Presentation/Coordinator/` 에 위치. 새 화면 라우팅은 반드시 Coordinator에 추가.
- `AppCoordinator` — 탭 조율, 각 Coordinator 소유
- `HomeCoordinator` — Home 플로우 (Search는 fullScreen modal)
- `ArtistCoordinator` — Artist 플로우 (Search/ArtistDetail push)
- `MyCoordinator` — My 플로우
- **ViewController에서 직접 push/present 금지** — `coordinator?.show[Screen]()` 위임

**ViewModel 패턴:** `@MainActor`, `struct State`, `onStateChanged: (() -> Void)?` 클로저. Combine/async 사용 안 함.

## UI 제약사항

- **라이트 모드 전용** — 다크 모드 미지원
- **SnapKit** — 모든 constraints. Storyboard 레이아웃 없음
- **레이아웃 상수** — `HomeCollectionViewLayoutFactory`에만 정의, 인라인 금지
- **색상** — `tcBackground`, `tcTextPrimary` 등 `UIColor+Theme.swift` 토큰 사용
- 히어로 배너: `contentInsetAdjustmentBehavior = .never`, status bar까지 풀블리드
- **HomeViewController는 UINavigationController 없이** 탭에 직접 추가 (iOS 26 히어로 블러 이슈)

## 현재 상태

Home / Artist / ArtistDetail / Search 화면 구현됨. My 탭은 빈 placeholder. 데이터는 전부 Mock.

---

## /ship — 한국어 Git 워크플로우

`/ship` 입력 시 아래 순서로 실행:

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
