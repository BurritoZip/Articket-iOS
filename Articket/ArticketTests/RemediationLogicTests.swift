import XCTest
@testable import Articket

// 출시 전 결함 보수(이슈 #133/#135)의 유닛 회귀 테스트.
// 유닛으로 방어 가능한 로직만 대상으로 한다:
//   - #1 ConcertDetailViewModel.requestBooking() 예매처 분기 (2곳↑/1곳/폴백URL/없음)
//   - #2 EditProfileViewModel.save() 아바타 업로드 실패 시 경고 전달
// (#3~#7은 레이아웃/VC/Repo 레이어라 유닛 부적합 → XCUITest가 커버)

// MARK: - #1 ConcertDetail 예매처 분기

@MainActor
final class ConcertDetailBookingTests: XCTestCase {

    private func makeDetail(bookingLinks: [BookingLink], bookingUrl: URL? = nil) -> ConcertDetail {
        ConcertDetail(
            id: UUID(), title: "테스트공연", status: .onSale,
            genre: "", duration: "", ageRestriction: "",
            venueName: "홀", address: "", phoneNumber: "",
            dateRange: "", ticketOpenDate: "", ticketCloseDate: "", ticketProvider: "",
            bookingUrl: bookingUrl,
            bookingLinks: bookingLinks,
            organizer: "", noticeText: "",
            artist: Artist(id: UUID(), name: "", nameEn: nil, avatarUrl: nil,
                           followersCount: 0, upcomingEventCount: 0, isFollowing: false),
            lineupArtists: [],
            imageAssetName: nil, reviews: [], hasTimetable: false,
            sessions: []
        )
    }

    private func makeVM(detail: ConcertDetail) async -> ConcertDetailViewModel {
        let vm = ConcertDetailViewModel(
            concertId: detail.id,
            repository: StubConcertDetailRepo(detail: detail),
            artistRepository: StubArtistRepo(),
            bookingIssueReporter: StubBookingReporter(),
            bookingRepository: StubBookingRepo(),
            myPageRepository: StubMyPageRepo()
        )
        let loaded = expectation(description: "detail loaded")
        loaded.assertForOverFulfill = false
        vm.onStateChanged = { if !vm.state.isLoading { loaded.fulfill() } }
        vm.viewDidLoad()
        await fulfillment(of: [loaded], timeout: 3)
        return vm
    }

    private func link(_ p: String, _ url: String) -> BookingLink {
        BookingLink(provider: p, label: p, url: URL(string: url)!)
    }

    func test_예매처_2곳이상이면_선택시트_요청() async {
        let vm = await makeVM(detail: makeDetail(bookingLinks: [
            link("interpark", "https://interpark.com/a"),
            link("yes24", "https://yes24.com/a"),
        ]))
        var sheetLinks: [BookingLink]?
        var opened: URL?
        vm.onSelectBookingProvider = { sheetLinks = $0 }
        vm.onOpenBooking = { opened = $0 }
        vm.requestBooking()
        XCTAssertEqual(sheetLinks?.count, 2, "2곳 이상이면 선택 시트를 띄워야 함")
        XCTAssertNil(opened, "시트를 띄우므로 바로 열지 않음")
    }

    func test_예매처_1곳이면_바로_오픈() async {
        let url = "https://interpark.com/only"
        let vm = await makeVM(detail: makeDetail(bookingLinks: [link("interpark", url)]))
        var sheetLinks: [BookingLink]?
        var opened: URL?
        vm.onSelectBookingProvider = { sheetLinks = $0 }
        vm.onOpenBooking = { opened = $0 }
        vm.requestBooking()
        XCTAssertNil(sheetLinks, "1곳이면 시트 없이")
        XCTAssertEqual(opened?.absoluteString, url, "1곳이면 그 URL로 바로 오픈")
    }

    func test_링크없고_booking_url만_있으면_폴백_오픈() async {
        let fallback = URL(string: "https://legacy.com/x")!
        let vm = await makeVM(detail: makeDetail(bookingLinks: [], bookingUrl: fallback))
        var opened: URL?
        vm.onOpenBooking = { opened = $0 }
        vm.requestBooking()
        XCTAssertEqual(opened, fallback, "booking_links 비면 booking_url 단일 폴백")
    }

    func test_아무_링크도_없으면_안내토스트() async {
        let vm = await makeVM(detail: makeDetail(bookingLinks: [], bookingUrl: nil))
        var opened: URL?
        var errorMsg: String?
        vm.onOpenBooking = { opened = $0 }
        vm.onError = { errorMsg = $0 }
        vm.requestBooking()
        XCTAssertNil(opened, "링크 전무면 오픈하지 않음")
        XCTAssertNotNil(errorMsg, "링크 전무면 안내 토스트")
    }
}

// MARK: - #2 EditProfile 아바타 업로드 실패 처리

@MainActor
final class EditProfileAvatarSaveTests: XCTestCase {

    private func profile() -> UserProfile {
        UserProfile(displayName: "기존이름", email: "a@b.com", initial: "기",
                    concertCount: 0, followingArtistCount: 0, lastVisitDate: nil, avatarUrl: nil)
    }

    func test_아바타_업로드_실패시_경고메시지_전달_이름은_저장() async {
        let repo = StubMyPageRepo()
        repo.avatarError = URLError(.badServerResponse)   // 업로드만 실패
        let vm = EditProfileViewModel(currentProfile: profile(), repository: repo)
        vm.setDisplayName("새이름")
        vm.setAvatar(data: Data([0x01, 0x02]))

        let done = expectation(description: "save done")
        var warning: String?? = nil
        vm.onSaveSuccess = { warning = $0; done.fulfill() }
        vm.save()
        await fulfillment(of: [done], timeout: 3)

        XCTAssertNotNil(warning ?? nil, "아바타 실패 시 경고 메시지가 있어야 함")
        XCTAssertTrue(repo.didUpdateName, "이름 저장은 아바타 실패와 무관하게 수행")
    }

    func test_아바타_없으면_경고없이_성공() async {
        let repo = StubMyPageRepo()
        let vm = EditProfileViewModel(currentProfile: profile(), repository: repo)
        vm.setDisplayName("새이름")   // 아바타 미설정

        let done = expectation(description: "save done")
        var warning: String?? = nil
        vm.onSaveSuccess = { warning = $0; done.fulfill() }
        vm.save()
        await fulfillment(of: [done], timeout: 3)

        XCTAssertNil(warning ?? nil, "아바타 없으면 경고 없음(nil)")
    }

    func test_이름_공백이면_저장_거부() async {
        let repo = StubMyPageRepo()
        let vm = EditProfileViewModel(currentProfile: profile(), repository: repo)
        vm.setDisplayName("   ")

        var errored = false
        var saved = false
        vm.onError = { _ in errored = true }
        vm.onSaveSuccess = { _ in saved = true }
        vm.save()

        XCTAssertTrue(errored, "공백 이름은 에러 안내")
        XCTAssertFalse(saved, "공백 이름은 저장 진행 안 함")
        XCTAssertFalse(repo.didUpdateName, "네트워크 호출도 없어야 함")
    }
}

// MARK: - Stubs

private struct StubConcertDetailRepo: ConcertDetailRepositoryProtocol {
    let detail: ConcertDetail
    func fetchConcertDetail(concertId: UUID) async throws -> ConcertDetail { detail }
    func fetchIsInterested(concertId: UUID) async -> Bool { false }
    func toggleInterested(concertId: UUID, currentlyInterested: Bool) async throws {}
}

private struct StubArtistRepo: ArtistRepositoryProtocol {
    func fetchMyArtists() async throws -> [Artist] { [] }
    func fetchPopularArtists() async throws -> [PopularArtist] { [] }
    func fetchCalendarEvents(year: Int, month: Int) async throws -> [CalendarEvent] { [] }
    func fetchRecommendedArtists() async throws -> [Artist] { [] }
    func fetchFollowedArtistIds() async -> Set<UUID> { [] }
    func toggleFollow(artistId: UUID, currentlyFollowing: Bool) async throws {}
    func searchArtists(keyword: String) async throws -> [Artist] { [] }
}

private struct StubBookingReporter: BookingIssueReporting {
    func reportMissingBookingLink(eventId: UUID, eventTitle: String) async {}
}

private struct StubBookingRepo: BookingRepositoryProtocol {
    func fetchMyBookings() async throws -> [Booking] { [] }
    func fetchCancelledBookings() async throws -> [Booking] { [] }
    func fetchMyStats() async throws -> MyStats {
        MyStats(year: 2026, monthlyViewCounts: Array(repeating: 0, count: 12),
                topMonth: 1, topGenre: "", topArtist: "", totalCount: 0)
    }
    func fetchArtistRankings() async throws -> [ArtistRankEntry] { [] }
    func markBooked(eventId: UUID) async throws {}
    func isBooked(eventId: UUID) async throws -> Bool { false }
    func recordBookingIntent(eventId: UUID, eventTitle: String, posterUrl: String?) async {}
    func fetchPendingBookingIntent() async -> BookingIntent? { nil }
    func resolveBookingIntent(eventId: UUID, outcome: BookingIntentOutcome) async throws {}
}

/// MyPage 스텁 — 아바타 업로드 실패를 주입할 수 있고, 이름 저장 호출 여부를 기록한다.
private final class StubMyPageRepo: MyPageRepositoryProtocol, @unchecked Sendable {
    var avatarError: Error?
    private(set) var didUpdateName = false

    func fetchUserProfile() async throws -> UserProfile {
        UserProfile(displayName: "", email: "", initial: "U",
                    concertCount: 0, followingArtistCount: 0, lastVisitDate: nil, avatarUrl: nil)
    }
    func fetchMyArtists() async throws -> [Artist] { [] }
    func fetchReviewableShows() async throws -> [Event] { [] }
    func fetchYearlyShows() async throws -> [Event] { [] }
    func updateDisplayName(_ name: String) async throws { didUpdateName = true }
    func updateAvatar(imageData: Data) async throws -> String {
        if let avatarError { throw avatarError }
        return "https://cdn/avatar.jpg"
    }
}
