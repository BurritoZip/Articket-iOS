import Foundation

struct SupabaseEventRepository: EventRepositoryProtocol {

    private let service = SupabaseService.shared
    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private var nowISO: String { Self.isoFormatter.string(from: Date()) }
    private var oneMonthAgoISO: String {
        let date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return Self.isoFormatter.string(from: date)
    }

    func fetchBannerEvents() async throws -> [Event] {
        let rows: [EventRow] = try await service.fetch(
            table: "events",
            query: "select=*,venues(name)&status=in.(upcoming,on_sale)&poster_url=not.is.null&start_date=gte.\(oneMonthAgoISO)&order=start_date.asc&limit=8"
        )
        return rows.map { $0.toEvent() }
    }

    func fetchInterestedEvents() async throws -> [Event] {
        // 로그인 전 빈 배열 반환 — 인증 구현 후 user_interested_events 조인으로 교체
        []
    }

    func fetchUpcomingEvents() async throws -> [Event] {
        let rows: [EventRow] = try await service.fetch(
            table: "events",
            query: "select=*,venues(name)&status=in.(upcoming,on_sale)&start_date=gte.\(oneMonthAgoISO)&order=start_date.asc&limit=20"
        )
        return rows.map { $0.toEvent() }
    }

    func fetchNewlyStartedEvents() async throws -> [Event] {
        let rows: [EventRow] = try await service.fetch(
            table: "events",
            query: "select=*,venues(name)&start_date=gte.\(oneMonthAgoISO)&start_date=lte.\(nowISO)&end_date=gte.\(nowISO)&order=start_date.asc&limit=20"
        )
        return rows.map { $0.toEvent() }
    }

    func fetchSoonEndingEvents() async throws -> [Event] {
        let rows: [EventRow] = try await service.fetch(
            table: "events",
            query: "select=*,venues(name)&start_date=gte.\(oneMonthAgoISO)&end_date=gte.\(nowISO)&order=end_date.asc&limit=20"
        )
        return rows.map { $0.toEvent() }
    }
}
