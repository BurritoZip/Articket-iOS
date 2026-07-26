# 1.0 출시 리메디에이션 플랜

> 2026-07-22 grilling 세션 산출. App Store 1.0 출시 게이트 기준으로 미완성/결함 표면을 전수 triage한 결과.
> 결정 근거·과정은 이 문서, 검증 항목은 `docs/decisions/QA_CHECKLIST.md`.

## 출시 차단 기준 (bar)

**판돈**: App Store 첫 출시 게이트 (MARKETING_VERSION 1.0). 상시 회귀 자동화(CI)는 출시 후 과제.

**차단 등급 — P0~P3 전부 0이어야 제출:**

| 등급 | 정의 | 처리 |
|---|---|---|
| P0 | 크래시·데이터손실·인증깨짐 | 차단 |
| P1 | 핵심 플로우 불능(예매·검색·로그인·상세) | 차단 |
| P2 | 죽은 버튼(탭 무반응, 피드백 0) | 고치거나 숨김 |
| P3 | "준비 중" 정직 안내 | **이번 출시는 P3도 차단** — 구현 or 진입점 제거 |

"준비 중" 알럿도 남기지 않는다(최고 엄격). 각 항목 = 구현 / 제거 / 최소구현 중 하나로 0 만듦.

## 13개 항목 결정

| # | 항목 | 결정 | 방법 | PR |
|---|---|---|---|---|
| 1 | ConcertDetail 후기 더보기 `>` | 제거 | 죽은 chevron 삭제 | A |
| 2 | Home 통계 최다관람/선호장르 | 구현 | 3카드 공용 하단영역 스왑, top3+더보기. 소스 `fetchYearlyShows`. 최애=아티스트랭킹 유지, 최다관람=`topMonth` 월 공연, 선호장르=`topGenre` 관람작 | D |
| 3 | ArtistDetail 앨범 카드 | 구현 | 탭→유튜브 검색 딥링크(아티스트+앨범명) | C |
| 4 | Profile 올해본공연 더보기 | 구현 | `ProfileCoordinator.showEventList` 신설+배선 | B |
| 5 | BookingList 셀 탭 | 구현 | 탭→공연상세(`booking.eventId`) | B |
| 6 | ConcertDetail 후기작성 | 구현(게이트) | 이 공연이 관람작일 때만 버튼 노출→WriteReview(공연 고정), 로그인 필요 | E |
| 7a | Home 좌석확인 | 제거 | 좌석 데이터 없음, 바로가기 칩 삭제 | A |
| 7b | Home 예매일정 | 구현 | 바로가기 칩 유지+배선 → `EventList` 재사용, `ticketOpenDate` 오픈 임박순 정렬 | F |
| 8 | ArtistDetail 티켓팅 더보기 | 구현 | 아티스트별 예정공연 쿼리 신설 + `ArtistCoordinator.showEventList` | B |
| 9 | ArtistDetail 알림설정 | 최소구현 | `UNUserNotificationCenter` 로컬알림 @`ticketOpenDate`, 토글(설정/해제) | G |
| 10 | ArtistDetail 뮤비 | 구현 | 탭→유튜브 검색 딥링크(#3 헬퍼 재사용) | C |
| 11a | Profile 고객센터 | 구현 | mailto 지원이메일 | H (이메일 대기) |
| 11b | Profile 공지사항 | 제거 | 인프라·콘텐츠 없음, 메뉴 항목 삭제 | A |
| 12 | Timetable 멀티슬롯 추가 | 제거 | "직접 추가"가 핵심 커버, 버튼 삭제 | A |
| 13 | 예매앱 딥링크 | 변경 없음 | UL 검증 완료(아래) — iOS 코드 무변경 | — |

## PR 묶음 & 권장 순서

1. ✅ **PR-A 죽은 진입점 제거** (#1·7a·11b·12) — 🔧2026-07-22 완료. `ReviewTabView`(chevron 삭제)·`MySection`+`HomeViewController`(좌석확인 칩·핸들러)·`ProfileMenuSectionView`+`ProfileViewController`(공지사항)·`TimetableGridViewController`(멀티슬롯 버튼·메서드). 빌드/런타임 검증 대기
2. ✅ **PR-C 유튜브 검색 딥링크** (#3·10) — 머지 #113. 공용 `YouTubeSearchOpener` + 앨범/뮤비 배선
3. ✅ **PR-B 네비게이션 배선** (#4·5) — 머지 #115. `ProfileCoordinator.showEventList` + EventList 코디네이터 일반화 / **#8** 별도 분리 → 머지 #118(아티스트별 예정공연 쿼리 + `ArtistCoordinator.showEventList`)
4. ✅ **PR-D 통계 카드 스왑** (#2) — 머지 #121. MySection statDetail 스왑 + `fetchYearlyShows` + `Event.genre` + 신규 셀
5. ✅ **PR-E 후기작성 게이트** (#6) — 머지 #123. `canWriteReview`(관람작 판정) + `showWriteReview(preselectedEventId:)` 프로토콜 승격
6. ✅ **PR-F 예매일정** (#7b) — 머지 #125. `fetchTicketOpenSchedule`(임박순) + EventList 재사용
7. ✅ **PR-G 티켓 오픈 로컬알림** (#9) — 머지 #127. `TicketOpenNotifier` + `UpcomingTicketing.ticketOpenDate` + 토글 토스트
8. ✅ **PR-H 고객센터 mailto** (#11a) — 머지 #131. `mailto:articket2026@gmail.com`(+메일 앱 없을 때 폴백)

> **회차+예매처 시트**(별도 기능)도 머지 #119. **#13 예매앱 딥링크**는 UL 검증 후 iOS 무변경.
> **완료: 13개 전부 머지(2026-07-26). 코드 리메디에이션 종료 — 실기기 런타임 QA만 남음.**

## 홀드 / 외부 의존

- **#11a mailto 주소**: 지원 이메일 미정 → PR-H 홀드
- **#7b 예매일정 전용 디자인**: Figma에 화면 없음 → EventList 재사용으로 1.0. 전용 디자인 나오면 2.0 개선
- **admin 이슈 (iOS 아님)**: 인터파크 티켓 앱 2025-08 종료 → NOL 이관(2026-09). admin `PROVIDERS` 정규식(`tickets.interpark.com`)을 NOL 도메인으로 갱신 필요. `lib/ingestion/booking-links.ts`

## #13 UL 검증 근거 (apple-app-site-association 직접 조회)

| 예매처 | AASA | 결과 |
|---|---|---|
| 인터파크(NOL) `tickets.interpark.com` | 404 | 웹 오픈 |
| YES24 `ticket.yes24.com` | 200이나 HTML 에러페이지(가짜) | 웹 오픈 |
| 멜론 `ticket.melon.com` | 404 | 웹 오픈 |
| 놀(야놀자) `nol.yanolja.com` | 404 | 웹 오픈 |
| **Klook** `www.klook.com` | 유효 JSON(`Q2T8K3RPZ5.com.klook.klook`, `/activity/*`) | **앱 자동 딥링크** |

결론: 현 `UIApplication.open(https booking_url)`이 이미 최적. UL 지원 벤더(Klook)는 앱 자동 오픈, 나머지는 웹. 커스텀 스킴(B안)은 한국 예매앱에서 비공식·특정공연 미지원이라 UX 열화 → 채택 안 함. **iOS 코드 무변경.**
