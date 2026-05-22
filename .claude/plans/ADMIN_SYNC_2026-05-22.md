# Admin → iOS 동기화 노트 (2026-05-22)

Admin 콘솔 UX 전면 재검증 후 확인된 iOS 측 확인/대응 항목입니다.

---

## 1. Events — 이제 실제로 채워지는 필드들 (DB 스키마 변경 없음)

Admin 폼에 입력 경로가 없어 사실상 항상 `null`이던 아래 5개 필드가
이번 Admin 수정으로 **정상 입력 가능**해졌습니다.

| DB 컬럼 | EventRow.swift 프로퍼티 | 비고 |
|---|---|---|
| `duration` | `duration: String?` | ✅ 이미 선언됨 |
| `age_restriction` | `ageRestriction: String?` | ✅ 이미 선언됨 |
| `ticket_open_date` | `ticketOpenDate: Date?` | ✅ 이미 선언됨 |
| `ticket_provider` | `ticketProvider: String?` | ✅ 이미 선언됨 |
| `notice_text` | `noticeText: String?` | ✅ 이미 선언됨 |

`EventRow.toConcertDetail()` 에서 모두 `?? ""` 로 처리 중 — **크래시 위험 없음**.

### 실제 영향

- 지금까지는 이 필드들이 항상 빈 문자열(`""`)로 매핑됐을 것
- 이제 Admin에서 데이터를 채우면 **처음으로 실제 값**이 들어옴
- `ConcertDetail` 화면에서 빈 문자열일 때 해당 섹션을 숨기는 로직이 있는지 확인 권장
  - 예: `duration.isEmpty` 면 러닝타임 행 숨기기
  - 예: `noticeText.isEmpty` 면 공지사항 섹션 숨기기
  - 예: `ticketProvider.isEmpty` 면 예매처 행 숨기기

### 체크리스트

- [ ] `ConcertDetailView` 에서 빈 문자열일 때 섹션/행 숨김 처리 여부 검토
- [ ] `ticketOpenDate` 가 오늘 기준 D-7 이내일 때 배지/알림 UI 추가 검토 (Admin에서 이미 D-Day 배지 노출 중)
- [ ] 기존 데이터(null → `""` 매핑)와 새 데이터(실제 문자열) 혼재 UI 확인

---

## 2. Events — status 자동 종료 처리

Admin 대시보드에 `end_date < now AND status != "ended"` 인 이벤트를
일괄 `ended` 처리하는 기능이 추가됐습니다.

### iOS 영향

- `status == "ended"` 이벤트 필터링 로직이 있다면 갑자기 목록에서 사라지는 케이스 발생 가능
- **예상된 정상 동작**이므로 별도 수정 불필요
- `Event.dDayString` 은 `startDate` 기준이라 영향 없음

---

## 3. 이미지 Storage 경로 규칙

Admin 업로더 기준 Supabase Storage `images` bucket 내 경로:

| 용도 | 경로 |
|---|---|
| 공연 포스터 | `posters/{uuid}.{ext}` |
| 아티스트 아바타 | `avatars/{uuid}.{ext}` |
| 앨범 커버 | `covers/{uuid}.{ext}` |
| 뮤직비디오 썸네일 | `thumbnails/{uuid}.{ext}` |

iOS는 `poster_url` / `avatar_url` DB 컬럼에서 URL을 직접 읽으므로 **별도 변경 없음**.

---

## 4. DB 스키마 변경 없음

이번 Admin 수정은 migration 파일 추가 불필요.
기존 컬럼에 UI 입력 경로를 추가한 것뿐입니다.

---

## 요약

| 우선순위 | 항목 | 예상 작업량 |
|---|---|---|
| **P1** | `ConcertDetailView` 빈 문자열 시 섹션 숨김 처리 | 小 |
| **P2** | `ticket_open_date` D-Day 배지/알림 검토 | 中 |
| **P3** | `notice_text` 공지 섹션 UI 검토 | 小 |
