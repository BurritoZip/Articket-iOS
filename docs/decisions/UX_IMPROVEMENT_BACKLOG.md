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
- [ ] Dynamic Type: 본문/라벨 주요 표면 `UIFontMetrics` 적용(263 하드코딩 폰트, 현재 0개) — 노력 L, 잔여
- [ ] `accessibilityIdentifier` 부재(0개) — 주요 CTA/네비에 부여(XCUITest 안정화 겸) — 잔여

### 🅴 empty/loading 일관성 — 저비용(S) 완료 / 스켈레톤·pull-to-refresh(M) 잔여
- [x] 문의내역 0건 안내(빈 표 대신 "아직 접수한 문의가 없어요") — `InquiryViewController`
- [x] 문의 로드 에러 재시도 — `showErrorAlert(retry:)` → `viewDidLoad()` 재로드
- [x] 타임테이블 에러 재시도 버튼(에러 시에만 노출, `viewDidLoad()` 재로드) — `TimetableListViewController`
- [x] ArtistDetail 티켓팅/지난공연 빈 상태 문구("예정된 티켓팅이 없어요"/"지난 공연이 없어요") — `ConcertTabContentView`
- [x] EventList 빈상태 → 공용 `EmptyStateView`(아이콘+제목) — `EventListViewController`
- [~] ConcertDetail 후기탭: 기존 guideLabel("…후기로 남겨주세요")이 초대 문구로 빈 상태 겸함 → 별도 문구 스킵
- [ ] BookingList/Reviews 로딩 스피너 → 스켈레톤(프로젝트 관례) — 노력 M, 잔여
- [ ] 마이페이지 pull-to-refresh — 노력 M(VM 재로드 진입점 필요), 잔여

### 🅵 성공 피드백 · 햅틱 — 임팩트 中 / 노력 S~M
- [ ] 후기 등록 성공 토스트 없음(조용히 pop) — `WriteReviewViewController.swift:201`
- [ ] 문의 접수 성공이 모달 알럿(앱 관례는 토스트) — `InquiryViewController.swift:171`
- [ ] Artist 탭 팔로우 성공 토스트 없음(ArtistDetail은 있음) — `ArtistViewModel.swift`
- [ ] 앱 전역 햅틱 0개 — 토글/별점 `.selection`, 제출 결과 `.notification(.success/.error)`

### 네비게이션 마찰(추가) — 임팩트 中~低 / 노력 S
- [ ] 검색 fullScreen 모달 swipe-dismiss 불가(닫기 백버튼만) — `.pageSheet` 검토, `HomeCoordinator.swift:35`
- [ ] 타임테이블 액션시트 명시적 취소/닫기 없음(swipe만) — `PerformanceActionSheetViewController.swift`
- [ ] 예매하기 링크 없을 때 소프트 데드엔드(토스트만) → 폴백/비활성 — `ConcertDetailViewModel.swift:147`
- [ ] 모달 제시 대비 back 일관성(pop-or-dismiss 가드) — EditProfile/WriteReview/Inquiry/BookingList/Reviews VC
