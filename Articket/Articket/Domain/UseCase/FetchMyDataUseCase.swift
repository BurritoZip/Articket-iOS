import Foundation

struct MyDataResult: Sendable {
    let bookings: [Booking]
    let stats: MyStats
    let artistRankings: [ArtistRankEntry]
    let yearlyShows: [Event]   // 올해 관람작(통계 상세 리스트 — 최다관람 월·선호장르 필터 소스)
}

final class FetchMyDataUseCase: Sendable {
    private let repository: any BookingRepositoryProtocol
    private let myPageRepository: any MyPageRepositoryProtocol

    init(repository: some BookingRepositoryProtocol,
         myPageRepository: some MyPageRepositoryProtocol) {
        self.repository = repository
        self.myPageRepository = myPageRepository
    }

    func execute() async throws -> MyDataResult {
        async let bookings = repository.fetchMyBookings()
        async let stats = repository.fetchMyStats()
        async let rankings = repository.fetchArtistRankings()
        async let yearly = myPageRepository.fetchYearlyShows()

        var fetchedStats = try await stats
        let fetchedRankings = try await rankings

        // user_bookings가 비어있어 topArtist를 계산할 수 없을 때 랭킹 1위로 대체
        if fetchedStats.topArtist.isEmpty, let top = fetchedRankings.first {
            fetchedStats = MyStats(
                year: fetchedStats.year,
                monthlyViewCounts: fetchedStats.monthlyViewCounts,
                topMonth: fetchedStats.topMonth,
                topGenre: fetchedStats.topGenre,
                topArtist: top.name,
                totalCount: fetchedStats.totalCount
            )
        }

        let fetchedBookings = try await bookings
        // 관람작 조회 실패는 통계 상세만 비므로 전체 실패로 번지지 않게 흡수
        let fetchedYearly = (try? await yearly) ?? []
        return MyDataResult(
            bookings: fetchedBookings,
            stats: fetchedStats,
            artistRankings: fetchedRankings,
            yearlyShows: fetchedYearly
        )
    }
}
