import Foundation

enum RecommendationError: LocalizedError {
    case notLoggedIn
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .notLoggedIn:        return "로그인이 필요합니다"
        case .httpError(let code): return "추천을 불러오지 못했습니다 (\(code))"
        }
    }
}

struct SupabaseRecommendationRepository: RecommendationRepositoryProtocol {

    // admin 배포 호스트 (비밀 아님). /api/recommendations 제공.
    private let adminBaseURL = "https://articket-admin.vercel.app"

    func fetchRecommendations(limit: Int, offset: Int) async throws -> RecommendationsResult {
        let client = SupabaseService.shared.client
        guard client.auth.currentSession != nil else {
            throw RecommendationError.notLoggedIn
        }
        // 만료 시 supabase-swift가 자동 refresh
        let session = try await client.auth.session
        let token = session.accessToken

        var comps = URLComponents(string: "\(adminBaseURL)/api/recommendations")!
        comps.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
        ]
        guard let url = comps.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw RecommendationError.httpError(code)
        }

        // API는 camelCase 키 → 기본 디코더(키 변환 없음)
        let decoded = try JSONDecoder().decode(RecommendationAPIResponse.self, from: data)
        return RecommendationsResult(
            items: decoded.items.map { $0.toEvent() },
            hasMore: decoded.page.hasMore
        )
    }
}

// MARK: - API Response DTOs

private struct RecommendationAPIResponse: Decodable {
    let items: [ScoredEventDTO]
    let page: Page

    struct Page: Decodable {
        let limit: Int
        let offset: Int
        let hasMore: Bool
    }
}

private struct ScoredEventDTO: Decodable {
    let eventId: String
    let title: String
    let posterUrl: String?
    let startDate: String
    let status: String
    let finalScore: Double
    let reasons: [String]

    func toEvent() -> Event {
        Event(
            id: UUID(uuidString: eventId) ?? UUID(),
            title: title,
            posterUrl: posterUrl,
            startDate: Self.parseDate(startDate),
            venueName: "",
            isInterested: false,
            recommendationScore: finalScore,
            recommendationReason: reasons.first
        )
    }

    private static let isoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
    static func parseDate(_ s: String) -> Date {
        isoFractional.date(from: s) ?? iso.date(from: s) ?? Date()
    }
}
