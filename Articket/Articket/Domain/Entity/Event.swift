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

    // 회차 묶기 — 같은 공연·공연장의 다른 날짜를 대표 1건으로 접을 때 채워짐.
    // sessionCount=1 이면 단일 공연(회차 아님). sessionStartDates 는 대표 포함 전체 회차 시작일.
    let sessionCount: Int
    let sessionStartDates: [Date]

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
        recommendationReason: String? = nil,
        sessionCount: Int = 1,
        sessionStartDates: [Date] = []
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
        self.sessionCount = sessionCount
        self.sessionStartDates = sessionStartDates
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

    /// 회차 공연이면 배지 문자열(예 "총 3회차"), 단일이면 nil
    var sessionBadge: String? {
        sessionCount > 1 ? "총 \(sessionCount)회차" : nil
    }

    /// 회차 날짜 요약(예 "8/5·8/7·8/9"), 단일이면 dateRangeString
    var sessionDatesSummary: String {
        guard sessionCount > 1, !sessionStartDates.isEmpty else { return dateRangeString }
        return sessionStartDates
            .sorted()
            .map { Self.shortFormatter.string(from: $0) }
            .joined(separator: "·")
    }

    private static let shortFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "M/d"
        return fmt
    }()

    /// 회차 정보만 덧입힌 사본 (그룹핑 대표 이벤트 생성용)
    func withSessionInfo(count: Int, startDates: [Date]) -> Event {
        Event(
            id: id, title: title, imageAssetName: imageAssetName, posterUrl: posterUrl,
            startDate: startDate, endDate: endDate, venueName: venueName,
            isInterested: isInterested, hasTimetable: hasTimetable,
            popularityScore: popularityScore, trendingScore: trendingScore,
            recommendationScore: recommendationScore, recommendationReason: recommendationReason,
            sessionCount: count, sessionStartDates: startDates
        )
    }

    private static let dateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy.MM.dd"
        return fmt
    }()
}
