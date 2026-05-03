import Foundation

struct SupabaseArtistRepository: ArtistRepositoryProtocol {

    private let service = SupabaseService.shared

    func fetchMyArtists() async throws -> [Artist] {
        // 로그인 전 빈 배열 반환 — 인증 구현 후 user_artist_followings 조인으로 교체
        []
    }

    func fetchPopularArtists() async throws -> [PopularArtist] {
        let rows: [ArtistRow] = try await service.fetch(
            table: "artists",
            query: "select=id,name,avatar_url,followers_count,upcoming_event_count&order=followers_count.desc&limit=5"
        )
        return rows.map { row in
            let badge: String = {
                if row.upcomingEventCount > 0 { return "티켓팅 오픈" }
                return "팔로워 급상승"
            }()
            return PopularArtist(id: row.id, name: row.name, imageUrl: row.avatarUrl, badge: badge)
        }
    }

    func fetchCalendarEvents(year: Int, month: Int) async throws -> [CalendarEvent] {
        // 로그인 전 빈 배열 반환 — 인증 구현 후 user_artist_followings 기반으로 교체
        []
    }

    func fetchRecommendedArtists() async throws -> [Artist] {
        let rows: [ArtistRow] = try await service.fetch(
            table: "artists",
            query: "select=id,name,avatar_url,followers_count,upcoming_event_count&order=upcoming_event_count.desc&limit=5"
        )
        return rows.map { $0.toArtist(isFollowing: false) }
    }
}
