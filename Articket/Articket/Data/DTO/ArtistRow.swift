import Foundation

struct ArtistRow: Decodable {
    let id: UUID
    let name: String
    let avatarUrl: String?
    let followersCount: Int
    let upcomingEventCount: Int
    let occupation: String?
    let birthDate: String?
    let birthPlace: String?
    let related: String?

    func toArtist(isFollowing: Bool = false) -> Artist {
        Artist(
            id: id,
            name: name,
            avatarUrl: avatarUrl,
            followersCount: followersCount,
            upcomingEventCount: upcomingEventCount,
            isFollowing: isFollowing
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
                related: related ?? ""
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

    func toConcertReview() -> ConcertReview {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy.MM.dd"
        return ConcertReview(
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
