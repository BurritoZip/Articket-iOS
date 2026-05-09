import Foundation

struct SupabaseEventRepository: EventRepositoryProtocol {

    private let service = SupabaseService.shared
    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private var nowISO: String { Self.isoFormatter.string(from: Date()) }

    func fetchBannerEvents() async throws -> [Event] {
        let rows: [EventRow] = try await service.fetch(
            table: "events",
            query: "select=*,venues(name)&status=in.(upcoming,on_sale)&poster_url=not.is.null&end_date=gte.\(nowISO)&order=start_date.asc&limit=8"
        )
        return performanceOnly(rows).map { $0.toEvent() }
    }

    func fetchInterestedEvents() async throws -> [Event] {
        // 로그인 전 빈 배열 반환 — 인증 구현 후 user_interested_events 조인으로 교체
        []
    }

    func fetchUpcomingEvents() async throws -> [Event] {
        let rows: [EventRow] = try await service.fetch(
            table: "events",
            query: "select=*,venues(name)&status=in.(upcoming,on_sale)&end_date=gte.\(nowISO)&order=start_date.asc&limit=20"
        )
        return performanceOnly(rows).map { $0.toEvent() }
    }

    func fetchNewlyStartedEvents() async throws -> [Event] {
        let rows: [EventRow] = try await service.fetch(
            table: "events",
            query: "select=*,venues(name)&start_date=lte.\(nowISO)&end_date=gte.\(nowISO)&order=start_date.desc&limit=20"
        )
        return performanceOnly(rows).map { $0.toEvent() }
    }

    func fetchSoonEndingEvents() async throws -> [Event] {
        let rows: [EventRow] = try await service.fetch(
            table: "events",
            query: "select=*,venues(name)&end_date=gte.\(nowISO)&order=end_date.asc&limit=20"
        )
        return performanceOnly(rows).map { $0.toEvent() }
    }

    // 전시·박물관·갤러리 등 비공연 이벤트 제외 — genre 미기재는 공연으로 간주
    private func performanceOnly(_ rows: [EventRow]) -> [EventRow] {
        let excluded = ["전시", "박물관", "갤러리", "전람회", "미술관",
                        "exhibition", "museum", "gallery"]
        return rows.filter { row in
            guard let genre = row.genre?.lowercased() else { return true }
            return !excluded.contains { genre.contains($0) }
        }
    }
}
