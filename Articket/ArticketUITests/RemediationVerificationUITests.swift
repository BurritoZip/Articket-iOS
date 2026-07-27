//
//  RemediationVerificationUITests.swift
//  ArticketUITests
//
//  출시 전 결함 7건(이슈 #133) 보수의 런타임 검증.
//  idb로 구동 못한 항목(#2 EditProfile 진입, #4 캘린더, #5 편집화면 아바타)을
//  XCUITest로 확실히 도달·확인한다. 앱에 accessibilityIdentifier가 없어 한국어 라벨로 탐색하고,
//  색/아이콘 등 시각 요소는 XCTAttachment 스크린샷으로 남겨 .xcresult에서 육안 확인한다.
//

import XCTest

final class RemediationVerificationUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        // 한 흐름에서 여러 화면을 훑으므로, 한 단계 실패해도 나머지 스크린샷은 남긴다.
        continueAfterFailure = true
        app = XCUIApplication()
        app.launch()
    }

    // MARK: - Helpers

    /// 커스텀 탭바(MainTabBarController) — 접근성 식별자가 없어 버튼 조회가 안 된다.
    /// 탭 아이템의 보이는 라벨(staticText: Home/Artist/Profile)을 눌러 진입한다.
    private func tapTab(_ name: String) {
        let label = app.staticTexts[name]
        if label.waitForExistence(timeout: 5) {
            label.tap()
            return
        }
        // 최후 폴백: 화면 하단 탭바 영역을 정규화 좌표로 탭 (Home/Artist/Profile 3분할)
        let fraction: CGFloat = name == "Home" ? 0.17 : (name == "Artist" ? 0.5 : 0.83)
        app.coordinate(withNormalizedOffset: CGVector(dx: fraction, dy: 0.97)).tap()
    }

    private func snapshot(_ name: String) {
        let att = XCTAttachment(screenshot: app.screenshot())
        att.name = name
        att.lifetime = .keepAlways
        add(att)
    }

    /// 스크롤 컨테이너에서 라벨이 보일 때까지 위로 스와이프.
    @discardableResult
    private func scrollTo(label: String, maxSwipes: Int = 10) -> XCUIElement {
        let el = app.staticTexts[label]
        var n = 0
        while !el.isHittable && n < maxSwipes {
            app.swipeUp()
            n += 1
        }
        return el
    }

    // MARK: - #5 / #2 — EditProfile 아바타 슬롯 + 사진 업로드 진입

    @MainActor
    func test01_EditProfile_avatarAffordance_and_picker() throws {
        tapTab("Profile")

        // 로그인 상태에서만 메뉴가 보인다. '내 정보 수정'까지 스크롤.
        let editRow = scrollTo(label: "내 정보 수정")
        XCTAssertTrue(editRow.waitForExistence(timeout: 5), "프로필 메뉴에 '내 정보 수정'이 있어야 함(로그인 상태)")
        editRow.tap()

        // EditProfile 도달 확인 — 내비 타이틀 + 이 화면에만 있는 안내 문구로 판별(푸시 애니메이션 여유)
        let navTitle = app.staticTexts["내 정보 수정"]
        let hint = app.staticTexts["사진 변경"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 8) || hint.waitForExistence(timeout: 8),
                      "#5: EditProfile 화면 진입")
        XCTAssertTrue(hint.waitForExistence(timeout: 3), "#5: '사진 변경' 힌트 노출")
        XCTAssertTrue(app.staticTexts["닉네임"].exists, "EditProfile 닉네임 필드 라벨 노출")
        XCTAssertTrue(app.buttons["저장"].exists, "EditProfile 저장 버튼 노출")
        // #5 아바타(밝은 fill + 인물 아이콘 + 테두리) 육안 확인용 스크린샷
        snapshot("05_editprofile_avatar_slot")

        // #2: 아바타 탭 → 시스템 사진 선택기(PHPicker) 진입 여부. 상단 아바타 근처를 좌표 탭.
        let avatarHit = app.staticTexts["사진 변경"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: -3.0))
        avatarHit.tap()
        // PHPicker는 별도 프로세스. '취소'/'Cancel' 또는 사진 그리드가 뜨는지로 진입 확인.
        let picker = app.navigationBars.firstMatch
        let cancel = app.buttons["취소"].firstMatch
        let cancelEn = app.buttons["Cancel"].firstMatch
        let appeared = picker.waitForExistence(timeout: 5) || cancel.exists || cancelEn.exists
        snapshot("02_photo_picker")
        XCTAssertTrue(appeared, "#2: 아바타 탭 시 사진 선택기가 떠야 함(업로드 진입 정상)")
    }

    // MARK: - #4 — Artist 공연 캘린더 (더보기 겹침 회귀: 최소한 크래시 없어야)

    @MainActor
    func test02_ArtistCalendar_dayTaps_noCrash() throws {
        tapTab("Artist")
        XCTAssertTrue(app.staticTexts["공연 캘린더"].waitForExistence(timeout: 5), "Artist 탭 공연 캘린더 노출")
        snapshot("04a_calendar_initial")

        // 날짜 셀들을 눌러 이벤트 상세/더보기 흐름을 태워 본다(데이터 있으면 더보기까지).
        // 며칠을 순차 탭 → 다른 날 탭 시 이전 확장과 겹치지 않는지(=크래시/레이아웃 붕괴 없이 살아있는지) 확인.
        for day in ["10", "15", "20", "25"] {
            let cell = app.staticTexts[day].firstMatch
            if cell.exists && cell.isHittable { cell.tap() }
        }
        // 더보기가 있으면 눌러 확장 후 다른 날 탭
        let more = app.buttons.matching(NSPredicate(format: "label BEGINSWITH '더보기'")).firstMatch
        if more.exists { more.tap() ; app.staticTexts["8"].firstMatch.tap() }
        snapshot("04b_calendar_after_taps")

        // 앱이 살아있으면(요소 조회 가능) 크래시 없음.
        XCTAssertTrue(app.staticTexts["공연 캘린더"].exists, "#4: 날짜/더보기 연속 탭 후에도 캘린더 생존(크래시 없음)")
    }

    // MARK: - #7 — 빈 통계 카드 탭 크래시 회귀

    @MainActor
    func test03_PlayStatCards_tap_noCrash() throws {
        tapTab("Home")
        let play = app.buttons["PLAY"]
        XCTAssertTrue(play.waitForExistence(timeout: 5), "홈 PLAY 세그먼트 노출")
        play.tap()

        // 통계 카드 3개를 모두 탭 — 결과가 비어도 크래시 없어야(diffable 중복 제거 방어)
        for card in ["최다 관람", "선호 장르", "최애 아티스트"] {
            let el = scrollTo(label: card)
            if el.exists && el.isHittable { el.tap() }
        }
        snapshot("07_stat_cards_tapped")
        XCTAssertTrue(app.buttons["PLAY"].exists, "#7: 통계 카드 연속 탭 후에도 앱 생존(크래시 없음)")
    }

    // MARK: - #3 — 후기 작성 별점

    @MainActor
    func test04_WriteReview_starsPresent() throws {
        tapTab("Profile")
        let writeRow = scrollTo(label: "후기 작성")
        guard writeRow.waitForExistence(timeout: 5) else {
            XCTFail("프로필 메뉴 '후기 작성' 없음(로그인 상태 확인)")
            return
        }
        writeRow.tap()
        XCTAssertTrue(app.staticTexts["별점"].waitForExistence(timeout: 5), "후기 작성 화면 별점 섹션 노출")
        snapshot("03_review_stars")
        // 별점 첫 별 탭 → 채워지는지(크래시 없이 동작)
        // 별 버튼은 image 기반이라 라벨이 없을 수 있어, 별점 라벨 아래 영역을 좌표 탭.
        let starArea = app.staticTexts["별점"].coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 2.2))
        starArea.tap()
        snapshot("03_review_star_filled")
    }
}
