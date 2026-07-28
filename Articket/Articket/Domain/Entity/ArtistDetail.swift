import Foundation

struct UpcomingTicketing: Sendable {
    let id: UUID
    let dDay: String
    let concertTitle: String
    let ticketOpenInfo: String
    let dateVenueInfo: String
    /// 티켓 오픈 실제 시각 — 로컬 알림 예약용(없으면 알림 설정 불가)
    let ticketOpenDate: Date?
}

struct PastConcert: Sendable {
    let id: UUID
    let imageUrl: String?
    let title: String
    let dateRange: String
    let venueName: String
}

/// 아티스트 상세 "예정된 공연" 섹션 — 미래에 예정된 모든 공연(직접 출연 + 라인업).
/// PastConcert 와 동일 표시 형태이나, 다가올 공연이라 D-Day 를 함께 노출한다.
struct UpcomingConcert: Sendable {
    let id: UUID
    let imageUrl: String?
    let title: String
    let dateRange: String
    let venueName: String
    /// "D-3" 형태. 오늘이면 "D-DAY". 계산 불가 시 빈 문자열(배지 숨김).
    let dDay: String
}

struct MusicVideo: Sendable {
    let id: UUID
    let thumbnailUrl: String?
    let title: String
    let viewCount: String
    let likeCount: String
    let uploadDate: String
}

struct AlbumItem: Sendable {
    let id: UUID
    let imageUrl: String?
    let title: String
    let year: String
}

struct ProfileSnsLinks: Sendable {
    let spotify: String?
    let appleMusic: String?
    let youtube: String?
    let instagram: String?
    let twitter: String?
}

struct ProfileInfo: Sendable {
    let occupation: String
    let birthDate: String
    let birthPlace: String
    let related: String
    /// 소속사 / 레이블
    let label: String
    /// 국가 코드 (예: KR, US)
    let country: String
    /// SNS / 스트리밍 링크
    let snsLinks: ProfileSnsLinks?

    init(
        occupation: String,
        birthDate: String,
        birthPlace: String,
        related: String,
        label: String = "",
        country: String = "",
        snsLinks: ProfileSnsLinks? = nil
    ) {
        self.occupation = occupation
        self.birthDate = birthDate
        self.birthPlace = birthPlace
        self.related = related
        self.label = label
        self.country = country
        self.snsLinks = snsLinks
    }
}

struct ArtistDetail: Sendable {
    var artist: Artist
    let upcomingTicketing: UpcomingTicketing?
    /// 미래에 예정된 모든 공연 (start_date >= 오늘). 상세 "예정된 공연" 섹션에 표기.
    let upcomingConcerts: [UpcomingConcert]
    let pastConcerts: [PastConcert]
    let profileInfo: ProfileInfo
    let musicVideos: [MusicVideo]
    let albums: [AlbumItem]

    static let placeholder = ArtistDetail(
        artist: Artist(id: UUID(), name: "", nameEn: nil, avatarUrl: nil,
                       followersCount: 0, upcomingEventCount: 0, isFollowing: false),
        upcomingTicketing: nil,
        upcomingConcerts: [],
        pastConcerts: [],
        profileInfo: ProfileInfo(occupation: "", birthDate: "", birthPlace: "", related: ""),
        musicVideos: [],
        albums: []
    )
}
