# Articket iOS — UX 개선 백로그

> 생성: 2026-07-27 · 출처: 출시 전 UX 스캔(5개 차원 병렬 감사: empty/loading/error · 피드백/어포던스 · 네비게이션 마찰 · 접근성 · 마이크로카피)
> QA_CHECKLIST(결함 7건 #133) 완료 후 "추가 UX 개선 여지" 탐색 결과. near-bug/dead-end 우선 처리, 폴리시성은 다음 사이클.

## ✅ 이번 반영 (🅰 + 🅱 + 문법버그 = 9건)

**🅰 이중 제출 / 연타 가드 (near-bug — 데이터 중복 방지)**
- [x] 후기 등록 버튼 `isSubmitting` 게이트 + 스피너 — `WriteReviewViewController.swift` (VM은 이미 세팅했으나 VC가 무시 → 연타 시 후기 중복 insert)
- [x] 문의 접수 버튼 동일 — `InquiryViewController.swift`
- [x] 아티스트 팔로우 토글 재탭 가드(단일) — `ArtistDetailViewModel.swift` `isTogglingFollow`
- [x] 아티스트 팔로우 토글 재탭 가드(다중) — `ArtistViewModel.swift` `togglingArtistIds: Set<UUID>` (다른 아티스트 탭은 안 막힘)

**🅱 막다른 길 제거 / 재시도**
- [x] 검색 모달에서 후기작성이 모달 뒤로 push돼 안 뜨던 버그 — `HomeCoordinator.swift` `activeNavigationController`
- [x] 로그인 게이팅 2탭→1탭 (중간 "로그인 필요" 알럿 제거) — `UIViewController+ErrorAlert.swift`
- [x] 애플 로그인 실패 재시도 액션 + 문구 개선 — `AuthViewController.swift`
- [x] 검색 실패 재시도 버튼(빈뷰 스택화) — `SearchResultViewController.swift`

**🅲 카피(일부)**
- [x] 검색 결과없음 조사 문법버그 `"아티스트이 없습니다"` → `"'키워드' 검색 결과가 없어요 / 다른 키워드로 찾아보세요"` — `SearchResultViewController.swift`

---

## ⬜ 남은 후보 (다음 사이클 — 출시 블로커 아님)

### 🅲 카피 정리 — 완료 (톤·용어·용어제거·준비중)
- [x] 용어 **이벤트→공연** 통일 — Home "관심 있는 공연"(헤더·리스트·주석)
- [x] 톤 **해요체 통일** — 로드/실패 에러 문구 전반(Home·Artist·ArtistDetail·Concert·Profile 전 VM + Timetable 알럿, 40건)
- [x] `"MY 데이터/정보"` → `"내 정보"` — `MyViewModel`, `ProfilePageViewModel`
- [x] 백엔드 용어 제거 `"저장소 설정 오류(관리자 문의)"`/`"업로드 권한 오류(관리자 문의)"` → 소비자 문구(기술상세는 AppLog) — `EditProfileViewModel`
- [x] 부분성공 문구 reframe `"이미지 업로드 실패: … (이름은 저장됐어요)"` → `"닉네임은 저장했어요. 프로필 사진: …"`
- [x] `"판매정보 준비중"`/`"후기 준비중"` → `"판매 정보가 곧 공개돼요"`/`"아직 등록된 후기가 없어요"` — `ConcertDetailViewController`
- [~] 문장부호: 단문 에러/토스트는 마침표 제거로 통일. 다문장 알럿은 유지 — 전역 완전통일은 잔여

### 🅳 접근성 — 저비용분(라벨·44pt) 완료 / Dynamic Type·식별자는 잔여
- [x] 공용 백버튼 + 개별 백버튼 4곳 `accessibilityLabel = "뒤로"` — `SimpleNavigationBar`·ConcertDetail·Search·EventList·ArtistDetail VC
- [x] 홈 검색버튼 `size 44` + `"검색"` — `HomeViewController`. Artist 탭 검색버튼 `"검색"`
- [x] 아이콘버튼 라벨: 하트`"관심 공연"`·공유`"공유"`(ConcertDetailHeaderView)·닫기`"닫기"`(Auth·BookingProviderSheet)·카루셀 화살표`"이전"`/`"다음"`(SectionHeaderView)
- [x] 서브-44pt 상향: 카루셀 화살표 24→44(`SectionHeaderView`), 바텀시트 닫기 24→44(`BookingProviderSheetViewController`)
- [~] 최근검색 삭제 버튼: `"검색어 삭제"` 라벨만 부여, 프레임은 24 유지(칩 행 레이아웃 보존 위해 size 미상향) — 필요 시 hitTest 확장 후속
- [~] Dynamic Type: **1차(파운데이션+공용 크롬) + ConcertDetail 본문 완료**
  - 파운데이션: `UIFont+Scaled`(캡 필수) + `EmptyStateView`·`ToastView`·`SimpleNavigationBar`. 패턴 `PATTERNS.md#Dynamic Type`.
  - ConcertDetail 본문(23라벨): Header·InfoTab·ReviewTab·SalesInfoTab·BookingView. 아바타 이니셜(size*0.35)은 원형 비례라 제외.
  - **실기기 최대 글자크기 클리핑 QA 후보**(폰트만 적용, 제약 미변경): ReviewTab `contentLabel`(120pt 고정박스+clipsToBounds), InfoTab 라인업 `nameLabel`(108pt 스크롤)·`mapLabel`(47pt 버튼), Booking `bookingButton`(48pt), Header 상태뱃지. → 클리핑 확인 시 해당 고정 height를 `greaterThanOrEqualTo`로 flex 전환.
  - ArtistDetail 본문(25라벨): Header·TabBar·ConcertTab·ProfileTab. 아바타 이니셜 등 계산식 폰트 제외.
    - **QA 후보(고정 높이, 클리핑 확인)**: 팔로우버튼(32)·탭버튼(28)·섹션헤더(27)·D-day뱃지(20)·알림버튼(37)·프로필 섹션헤더(27)·앨범 스크롤(211). → 클리핑 시 해당 height `greaterThanOrEqualTo` 전환.
  - Home(37라벨, 12파일): NOW/PLAY 헤더·섹션헤더·이벤트/랭킹/예매/통계 셀 전반. SectionHeader `configure`의 런타임 폰트 재지정도 scaled로 교정. 계산식 폰트 없음.
    - **QA 후보(고정 높이/프레임)**: NOW·PLAY(56 헤더)·BarChart 월/카운트(15 프레임)·D-day뱃지(20)·예매확인 예/아니오 버튼(28)·랭크 라벨(24 width). → 클리핑 시 flex 전환.
  - 잔여(증분): Search·Profile·EventList·Timetable 셀/본문 라벨. 동일 패턴 + 빌드/QA 전제.
- [ ] `accessibilityIdentifier` 전면 부여 — 테스트 인프라성(사용자가치 낮음), 필요 시 XCUITest 확장과 함께 — 잔여

### 🅴 empty/loading 일관성 — 저비용(S) 완료 / 스켈레톤·pull-to-refresh(M) 잔여
- [x] 문의내역 0건 안내(빈 표 대신 "아직 접수한 문의가 없어요") — `InquiryViewController`
- [x] 문의 로드 에러 재시도 — `showErrorAlert(retry:)` → `viewDidLoad()` 재로드
- [x] 타임테이블 에러 재시도 버튼(에러 시에만 노출, `viewDidLoad()` 재로드) — `TimetableListViewController`
- [x] ArtistDetail 티켓팅/지난공연 빈 상태 문구("예정된 티켓팅이 없어요"/"지난 공연이 없어요") — `ConcertTabContentView`
- [x] EventList 빈상태 → 공용 `EmptyStateView`(아이콘+제목) — `EventListViewController`
- [~] ConcertDetail 후기탭: 기존 guideLabel("…후기로 남겨주세요")이 초대 문구로 빈 상태 겸함 → 별도 문구 스킵
- [x] BookingList/Reviews 로딩 스피너 → 스켈레톤 — 재사용 `ListSkeletonView`(shimmer) 신규
- [x] 마이페이지 pull-to-refresh — `ProfilePageViewModel.refresh(completion:)`(isLoading 미변경) + `ProfileViewController` UIRefreshControl

### 🅵 성공 피드백 · 햅틱 — 완료
- [x] 후기 등록 성공 토스트("후기가 등록됐어요", window-level이라 pop 후에도 표시) — `WriteReviewViewController`
- [x] 문의 접수 성공 모달 알럿 → 토스트("문의가 접수됐어요") — `InquiryViewController`
- [x] Artist 탭 팔로우 성공 토스트 — `ArtistViewModel.onFollowToggled` 콜백 추가 + VC 바인딩
- [x] 햅틱 도입 — `Common/Extension/Haptics.swift`(selection/impact/notify 래퍼)
  - 별점 선택 `.selection`, 후기·문의 제출 성공 `.notify(.success)`, 팔로우·관심 토글 `.impact`
  - 모든 에러 알럿 `.notify(.error)` — `showErrorAlert` 중앙 1지점

### 네비게이션 마찰(추가)
- [x] 타임테이블 액션시트 명시적 '취소' 버튼(삭제 옆, 실수 방지 겸) + detent 220→280 — `PerformanceActionSheetViewController`·`TimetableGridViewController`
- [x] 모달 제시 대비 back 일관성 — 공용 `dismissOrPop()`(`UIViewController+Navigation.swift`) + 5개 VC 백핸들러 적용
- [~] 검색 fullScreen swipe-dismiss: 의도적 몰입형 fullScreen + 상시 백버튼 존재 → 변경 보류(제품 판단)
- [~] 예매 링크 없을 때: 현행 토스트 안내 + `reportMissingBookingLink`(Admin 수집)가 합리적 → 유지(제품 판단)
