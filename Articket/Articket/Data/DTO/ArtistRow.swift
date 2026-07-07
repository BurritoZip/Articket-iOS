import Foundation

// 키 매핑은 SupabaseService 디코더의 .convertFromSnakeCase가 처리 (apple_music → appleMusic)
struct SnsLinksRow: Decodable {
    let spotify: String?
    let appleMusic: String?
    let youtube: String?
    let instagram: String?
    let twitter: String?
}

struct ArtistRow: Decodable {
    let id: UUID
    let name: String
    /// 영문 이름 (예: IU, BTS)
    let nameEn: String?
    let avatarUrl: String?
    let followersCount: Int
    let upcomingEventCount: Int
    let occupation: String?
    let birthDate: String?
    let birthPlace: String?
    let related: String?
    /// 소속사 / 레이블
    let label: String?
    /// 국가 코드 (예: KR, US)
    let country: String?
    /// 한 줄 소개 (Gemini 보강) — artists.description
    let description: String?
    /// SNS 링크
    let snsLinks: SnsLinksRow?
    /// 스코어링 엔진 컬럼 (옵셔널 — 미산출 시 null)
    let popularityScore: Double?
    let trendingScore: Double?

    // CodingKeys 미선언: SupabaseService 디코더의 .convertFromSnakeCase가
    // snake_case(JSON) ↔ camelCase(프로퍼티)를 자동 매핑.
    // snake_case raw value를 가진 CodingKeys를 함께 선언하면 변환된 키와 매칭 실패 → keyNotFound 예외.

    func toArtist(isFollowing: Bool = false) -> Artist {
        Artist(
            id: id,
            name: name,
            nameEn: nameEn,
            avatarUrl: avatarUrl,
            followersCount: followersCount,
            upcomingEventCount: upcomingEventCount,
            isFollowing: isFollowing,
            popularityScore: popularityScore,
            trendingScore: trendingScore
        )
    }

    func toArtistDetail(
        upcomingTicketing: UpcomingTicketing? = nil,
        pastConcerts: [PastConcert] = [],
        musicVideos: [MusicVideo] = [],
        albums: [AlbumItem] = []
    ) -> ArtistDetail {
        ArtistDetail(
            artist: toArtist(),
            upcomingTicketing: upcomingTicketing,
            pastConcerts: pastConcerts,
            profileInfo: ProfileInfo(
                occupation: occupation ?? "",
                birthDate: birthDate ?? "",
                birthPlace: birthPlace ?? "",
                related: related ?? "",
                label: label ?? "",
                country: country ?? "",
                snsLinks: snsLinks.map { sns in
                    ProfileSnsLinks(
                        spotify: sns.spotify,
                        appleMusic: sns.appleMusic,
                        youtube: sns.youtube,
                        instagram: sns.instagram,
                        twitter: sns.twitter
                    )
                }
            ),
            musicVideos: musicVideos,
            albums: albums
        )
    }
}

struct ConcertReviewRow: Decodable {
    let id: UUID
    let starCount: Int
    let title: String
    let username: String
    let createdAt: Date

    func toConcertDetailReview() -> ConcertDetailReview {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy.MM.dd"
        return ConcertDetailReview(
            id: id,
            starCount: starCount,
            title: title,
            username: username,
            date: fmt.string(from: createdAt),
            content: ""
        )
    }
}

struct PastConcertRow: Decodable {
    let id: UUID
    let title: String
    let posterUrl: String?
    let startDate: Date?
    let endDate: Date?
    let venueName: String?

    func toPastConcert() -> PastConcert {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy.MM.dd"
        let start = startDate.map { fmt.string(from: $0) } ?? ""
        let end   = endDate.map   { fmt.string(from: $0) } ?? ""
        let range = end.isEmpty ? start : "\(start) ~ \(end)"
        return PastConcert(
            id: id,
            imageUrl: posterUrl,
            title: title,
            dateRange: range,
            venueName: venueName ?? ""
        )
    }
}

struct AlbumRow: Decodable {
    let id: UUID
    let title: String
    let coverUrl: String?
    let releasedYear: String?

    func toAlbumItem() -> AlbumItem {
        AlbumItem(id: id, imageUrl: coverUrl, title: title, year: releasedYear ?? "")
    }
}

struct MusicVideoRow: Decodable {
    let id: UUID
    let title: String
    let thumbnailUrl: String?
    let viewCount: String?
    let likeCount: String?
    let uploadedAt: Date?

    func toMusicVideo() -> MusicVideo {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy.MM.dd"
        let date = uploadedAt.map { fmt.string(from: $0) } ?? ""
        return MusicVideo(
            id: id,
            thumbnailUrl: thumbnailUrl,
            title: title,
            viewCount: viewCount ?? "",
            likeCount: likeCount ?? "",
            uploadDate: date
        )
    }
}
