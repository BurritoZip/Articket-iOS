# Articket iOS — 진단 로깅 시스템 설계

> 생성: 2026-07-27 · 상태: 설계 승인 완료(구현 대기)
> 목적: 에러 발생 시 **어느 화면에서 · 어느 UI 조작으로 · 어떤 API 콜에서** 문제가 났는지를
> 매우 상세히 재구성할 수 있게 하는 로깅 시스템. admin(`app_error_logs` 조회)에서 원인 확정.

## 배경 / 문제

- 최근 디버깅(예매 확인 배너 크래시, 프로필 사진 업로드 403)에서 원인 파악이 오래 걸렸다.
  - `os_log`는 privacy로 메시지가 `<compose failure>`로 가려져 실사유가 안 보였다.
  - 어느 화면·어느 버튼·어떤 엔드포인트에서 실패했는지 구조적으로 기록되지 않는다.
  - `ErrorReporter.capture(...)` 인프라는 있으나 호출처가 드물고, 컨텍스트(화면/UI/API)가 얕다.
- 기존 자산:
  - `ErrorReporter.shared.capture(type, message, domain, error, context)` → `app_error_logs` insert.
  - 크래시 best-effort(`NSSetUncaughtExceptionHandler` + 시그널 핸들러 + UserDefaults flush).
  - `SupabaseErrorReporter`/`SupabaseService`가 모든 REST/Storage 호출의 단일 통로.

## 목표 / 비목표

**목표**
- 에러 리포트에 **현재 화면 + 직전 흔적(breadcrumb trail) + 실패 API 상세**를 첨부해 admin에서 한눈에 원인 확정.
- 자동 계측 위주로 누락 최소화(화면·API 자동, UI 액션 핵심만 수동).
- 로거 자신은 절대 크래시/블로킹하지 않는다(fire-and-forget).

**비목표 (YAGNI)**
- 상시 전체 텔레메트리, 원격 로그 스트리밍, 세션 리플레이.
- 요청/응답 body 원문·PII 덤프.
- admin 웹 UI 신규 구축(admin이 신규 2컬럼을 렌더 — admin 레포 소관). iOS는 SQL 초안만 제공.
- 네트워크(오프라인) 에러 리포트(사용자 환경 문제 = 노이즈, 기존 정책 유지).

## 핵심 결정 (brainstorming 확정)

1. **성격**: 에러 + 직전 breadcrumb trail(상시 전송 아님).
2. **캡처**: 자동 위주 3층 — API 자동(SupabaseService), 화면 자동(viewDidAppear 스위즐), UI 액션 수동 소수.
3. **디테일/PII**: 진단축만(엔드포인트·메서드·정제쿼리·상태·소요시간·에러요약·디코드 실패키). body 원문 제외. 서버 에러 메시지 스니펫(비-PII)만 truncate 포함.
4. **저장소**: 기존 `app_error_logs` 재사용 + `screen`(text)·`breadcrumbs`(jsonb) 컬럼 추가.
5. **트리거**: HTTP(4xx/5xx)·디코드·런타임·크래시 자동 리포트. **네트워크(오프라인) 제외**. DEBUG 상세 콘솔 / RELEASE 리포트만.

## 아키텍처

### 1) `AppLog` — 코어 (신규 `Common/Logging/AppLog.swift`)

```
final class AppLog: @unchecked Sendable {
    static let shared = AppLog()

    struct Breadcrumb {
        let time: Date
        let kind: Kind            // .screen / .action / .api
        let screen: String?       // 발생 시점 현재 화면
        let message: String
        let meta: [String: String]?   // endpoint, method, status, ms 등
        enum Kind: String { case screen, action, api }
    }

    // 최근 N개 링버퍼 (기본 20). NSLock 보호 — 여러 스레드/async에서 fire-and-forget.
    private let lock = NSLock()
    private var ring: [Breadcrumb] = []     // append + prefix-drop, 최대 maxBreadcrumbs
    private(set) var currentScreen: String? // screen 브레드크럼이 갱신

    // 계측 API
    func screen(_ name: String)                                  // 화면 진입
    func action(_ label: String)                                 // UI 조작
    func api(endpoint: String, method: String, status: Int?, ms: Int, error: String?)  // API 결과

    // 에러 캡처 — 현재 screen + trail 스냅샷을 붙여 ErrorReporter로 위임
    func capture(_ type: AppErrorType, message: String, domain: String? = nil,
                 endpoint: String? = nil, status: Int? = nil, error: Error? = nil)

    // 크래시용 — 현재 trail을 문자열로 직렬화(ErrorReporter의 UserDefaults 경로가 함께 저장)
    func breadcrumbTrailString() -> String
}
```

- **DEBUG 콘솔**: 각 breadcrumb를 `print`로 uncensored 출력.
  포맷 예: `15:38:07 🧭 EditProfile` · `15:38:09 🖲️ 사진저장` · `15:38:10 🌐 PUT storage/avatars/{uid}/avatar.jpg → 403 (RLS)`.
- **RELEASE**: 콘솔 출력 없음(버퍼만 유지). 에러 시에만 전송.
- 스레드 안전: 모든 공개 메서드는 `lock` 하에 배열 조작. 절대 throw 안 함.

### 2) 통합 3층

**(a) API 자동 — `SupabaseService`**
- `fetch` / `execute` / `uploadToStorage`를 얇게 감싸 계측:
  - 시작 시각 기록 → 종료 시 `ms` 계산.
  - 성공: `AppLog.api(endpoint, method, status: 200, ms, error: nil)` 브레드크럼.
  - 실패 분류:
    - HTTP 상태 있음(4xx/5xx) → `api(... status ...)` + `capture(.http, endpoint, status, message=서버에러스니펫)`.
    - 디코딩 실패(`DecodingError`) → `api(... status: 200 ...)` + `capture(.decoding, message=실패키+경로)`.
    - 네트워크(`Error.isNetworkConnectionError`) → `api(... status: nil, error:"offline")` 브레드크럼만, **capture 안 함**.
  - `endpoint`: `table + 정제된 query`(select/필터 앞부분, 길이 truncate). Storage는 `bucket/path`.
  - `method`: GET/POST/PATCH/DELETE/PUT(upload).
  - **body 원문 미포함**. 서버 에러 응답은 Supabase 에러의 `message` 필드(비-PII)만 스니펫.

**(b) 화면 자동 — `viewDidAppear` 메서드 스위즐**
- `UIViewController` 확장에서 `viewDidAppear(_:)`를 스위즐, 원본 호출 후 `AppLog.shared.screen(String(describing: type(of: self)))`.
- 설치: `SceneDelegate`(또는 AppDelegate)에서 앱 시작 1회 `AppLog.installScreenTracking()`.
- 시스템/컨테이너 VC 노이즈 필터: 이름이 `UI`/`_`로 시작하거나 알려진 컨테이너(UINavigationController 등)는 스킵.

**(c) UI 액션 수동 — 핵심 버튼만**
- `AppLog.shared.action("예매하기")` 등. 대상(초기):
  - ConcertDetail 예매하기, 예매 확인 배너 네/아니요, 팔로우 토글, 프로필 저장(사진 업로드), 후기/문의 제출.
- 전 버튼 자동계측은 비용 대비 낮아 제외.

### 3) 저장소 / 스키마

**admin 마이그레이션 초안** (적용은 admin 레포 — `/Users/sjw/ted.urssu/Articket-admin/supabase/migrations/`):
```sql
ALTER TABLE app_error_logs ADD COLUMN IF NOT EXISTS screen text;
ALTER TABLE app_error_logs ADD COLUMN IF NOT EXISTS breadcrumbs jsonb;
COMMENT ON COLUMN app_error_logs.screen IS '에러 발생 화면(뷰컨트롤러명)';
COMMENT ON COLUMN app_error_logs.breadcrumbs IS '직전 흔적 trail [{time,kind,screen,message,meta}]';
```

**iOS DTO 반영** — `SupabaseErrorReporter.ErrorInsert`에 추가:
- `screen: String?` (→ `screen`)
- `breadcrumbs: [BreadcrumbDTO]?` (→ `breadcrumbs`, jsonb)

`AppErrorReport`(도메인)에 `screen`·`breadcrumbs` 필드 추가, `ErrorReporter.capture`가 `AppLog`에서 스냅샷을 받아 채운다.

### 데이터 흐름 예 (사진 업로드 403)

```
EditProfile 진입           → AppLog.screen("EditProfileViewController")   [🧭]
저장 탭                     → AppLog.action("사진저장")                    [🖲️]
uploadToStorage(avatars)   → 403                                          [🌐 capture]
                             → AppLog.api(PUT, avatars/{uid}/avatar.jpg, 403, 120ms, "RLS")
                             → AppLog.capture(.http, endpoint, 403, "storage 403 …RLS…")
결과 app_error_logs 1행:
  screen="EditProfileViewController"
  error_type="http", message="storage 403 …", context={endpoint,status,ms}
  breadcrumbs=[🧭EditProfile, 🖲️사진저장, 🌐PUT avatars 403]
```
admin: screen 필터 + trail로 "어느 화면 → 어느 UI → 어떤 API"가 즉시 드러남.

## 에러 처리 / 안전

- 로거는 어떤 경우에도 throw/크래시/블로킹 금지. 버퍼 조작은 O(1), 문자열 truncate 상한(예: endpoint 200자, message 2000자).
- 링버퍼 상한(20)으로 메모리 일정.
- 리포트 전송은 기존대로 `try?`(실패 무시). 네트워크 제외로 오프라인 노이즈 차단.
- 스위즐은 앱 시작 1회, dispatch_once 가드. 원본 IMP 보존·정상 체이닝.

## 테스트

**유닛 (`ArticketTests`)**
- `AppLogTests`
  - 링버퍼 cap 20 유지, 최신 우선 순서.
  - `screen()`이 `currentScreen` 갱신.
  - `capture()` 시 리포트에 `screen` + 최근 trail이 첨부됨(`ErrorReporting` 목으로 캡처 검증).
  - API 분류: status 4xx→`.http` 리포트 발생 / DecodingError→`.decoding` / 네트워크→리포트 없음(브레드크럼만).
- 목: `ErrorReporting` 프로토콜 스텁으로 report 인자 검증(기존 `Support/TestStubs.swift` 패턴 재사용).

**비테스트(수동/코드리뷰)**
- 스위즐 화면 추적: 시뮬 화면 순회 시 콘솔에 🧭 로그(DEBUG).
- 실제 admin 렌더는 admin 레포.

## 파일 영향 (예상)

- 신규: `Common/Logging/AppLog.swift`, `Common/Logging/UIViewController+ScreenTracking.swift`(스위즐)
- 수정: `Data/Service/SupabaseService.swift`(계측), `Data/Repository/SupabaseErrorReporter.swift`(screen/breadcrumbs), `Data/Service/ErrorReporter.swift`(AppErrorReport 필드·capture 연동), `SceneDelegate.swift`(설치), 핵심 VC 몇 곳(action 호출)
- 신규 테스트: `ArticketTests/AppLogTests.swift`
- admin: 마이그레이션 SQL(초안 제공, 적용은 admin 레포) + `SupabaseErrorReporter` 대응 확인
- 문서: `docs/CODEMAPS/PATTERNS.md`(로깅 사용법), 필요 시 `CLAUDE.md`

## 오픈 이슈 / 후속

- 크래시 경로에서 trail을 UserDefaults에 함께 저장할지 → best-effort 포함(문자열 직렬화).
- 리포트 rate-limit/dedup은 1차 범위 밖(필요 시 후속). 네트워크 제외로 대부분의 폭주는 이미 차단.
