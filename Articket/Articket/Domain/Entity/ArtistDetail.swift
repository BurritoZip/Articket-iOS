import Foundation

struct UpcomingTicketing: Sendable {
    let id: UUID
    let dDay: String
    let concertTitle: String
    let ticketOpenInfo: String
    let dateVenueInfo: String
}

struct PastConcert: Sendable {
    let id: UUID
    let imageUrl: String?
    let title: String
    let dateRange: String
    let venueName: String
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

struct ProfileInfo: Sendable {
    let occupation: String
    let birthDate: String
    let birthPlace: String
    let related: String
}

struct ArtistDetail: Sendable {
    var artist: Artist
    let upcomingTicketing: UpcomingTicketing?
    let pastConcerts: [PastConcert]
    let profileInfo: ProfileInfo
    let musicVideos: [MusicVideo]
    let albums: [AlbumItem]

    static let placeholder = ArtistDetail(
        artist: Artist(id: UUID(), name: "", avatarUrl: nil,
                       followersCount: 0, upcomingEventCount: 0, isFollowing: false),
        upcomingTicketing: nil,
        pastConcerts: [],
        profileInfo: ProfileInfo(occupation: "", birthDate: "", birthPlace: "", related: ""),
        musicVideos: [],
        albums: []
    )
}
