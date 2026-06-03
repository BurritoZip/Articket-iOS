import Foundation

struct Event: Hashable, Sendable {
    let id: UUID
    let title: String
    let imageAssetName: String?   // local asset name (mock data)
    let posterUrl: String?        // remote Supabase Storage URL
    let startDate: Date
    let endDate: Date?
    let venueName: String
    let isInterested: Bool
    let hasTimetable: Bool        // events.has_timetable 컬럼

    // 스코어링 엔진 산출 (events.popularity_score / trending_score) — 옵셔널 미러
    let popularityScore: Double?
    let trendingScore: Double?
    // 개인화 추천 (admin /api/recommendations) — 추천 섹션에서만 채워짐
    let recommendationScore: Double?
    let recommendationReason: String?

    init(
        id: UUID,
        title: String,
        imageAssetName: String? = nil,
        posterUrl: String? = nil,
        startDate: Date,
        endDate: Date? = nil,
        venueName: String,
        isInterested: Bool,
        hasTimetable: Bool = false,
        popularityScore: Double? = nil,
        trendingScore: Double? = nil,
        recommendationScore: Double? = nil,
        recommendationReason: String? = nil
    ) {
        self.id = id
        self.title = title
        self.imageAssetName = imageAssetName
        self.posterUrl = posterUrl
        self.startDate = startDate
        self.endDate = endDate
        self.venueName = venueName
        self.isInterested = isInterested
        self.hasTimetable = hasTimetable
        self.popularityScore = popularityScore
        self.trendingScore = trendingScore
        self.recommendationScore = recommendationScore
        self.recommendationReason = recommendationReason
    }

    // MARK: - Computed

    var dDayString: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.startOfDay(for: startDate)
        if today > start { return "진행중" }
        let days = calendar.dateComponents([.day], from: today, to: start).day ?? 0
        return days == 0 ? "D-0" : "D-\(days)"
    }

    var dateRangeString: String {
        let start = Self.dateFormatter.string(from: startDate)
        let end = endDate.map { Self.dateFormatter.string(from: $0) } ?? start
        return "\(start) - \(end)"
    }

    private static let dateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy.MM.dd"
        return fmt
    }()
}
