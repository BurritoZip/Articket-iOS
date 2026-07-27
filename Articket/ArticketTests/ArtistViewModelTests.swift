import XCTest
@testable import Articket

// 아티스트 탭 캘린더 월 이동(연말/연초 경계) 검증.
// toggleFollow는 AuthService.shared 의존이라 제외.
@MainActor
final class ArtistViewModelTests: XCTestCase {

    private func makeVM() -> ArtistViewModel {
        ArtistViewModel(
            useCase: FetchArtistDataUseCase(repository: TestArtistRepo()),
            recommendationUseCase: StubArtistRecoUseCase()
        )
    }

    func test_12월에서_다음달_이듬해_1월로() {
        let vm = makeVM()
        let startY = vm.state.calendarYear
        let startM = vm.state.calendarMonth
        vm.changeMonth(by: 12 - startM)          // 12월로 이동(단일 wrap 범위 유지)
        XCTAssertEqual(vm.state.calendarMonth, 12)
        XCTAssertEqual(vm.state.calendarYear, startY)
        vm.changeMonth(by: 1)                     // 13 → 1월, 해 넘김
        XCTAssertEqual(vm.state.calendarMonth, 1)
        XCTAssertEqual(vm.state.calendarYear, startY + 1)
    }

    func test_1월에서_이전달_전년_12월로() {
        let vm = makeVM()
        let startY = vm.state.calendarYear
        let startM = vm.state.calendarMonth
        vm.changeMonth(by: 1 - startM)           // 1월로 이동
        XCTAssertEqual(vm.state.calendarMonth, 1)
        XCTAssertEqual(vm.state.calendarYear, startY)
        vm.changeMonth(by: -1)                    // 0 → 12월, 전년
        XCTAssertEqual(vm.state.calendarMonth, 12)
        XCTAssertEqual(vm.state.calendarYear, startY - 1)
    }
}

private struct TestArtistRepo: ArtistRepositoryProtocol {
    func fetchMyArtists() async throws -> [Artist] { [] }
    func fetchPopularArtists() async throws -> [PopularArtist] { [] }
    func fetchCalendarEvents(year: Int, month: Int) async throws -> [CalendarEvent] { [] }
    func fetchRecommendedArtists() async throws -> [Artist] { [] }
    func fetchFollowedArtistIds() async -> Set<UUID> { [] }
    func toggleFollow(artistId: UUID, currentlyFollowing: Bool) async throws {}
    func searchArtists(keyword: String) async throws -> [Artist] { [] }
}

private struct StubArtistRecoUseCase: FetchArtistRecommendationsUseCaseProtocol {
    func execute(popularLimit: Int, forYouLimit: Int) async throws -> ArtistRecommendationsResult {
        throw URLError(.unsupportedURL)   // 이 테스트 경로에선 호출되지 않음
    }
}
