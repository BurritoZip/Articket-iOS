import Foundation

final class MockArtistDetailRepository: ArtistDetailRepositoryProtocol {

    func fetchArtistDetail(artistId: UUID) async -> ArtistDetail {
        ArtistDetail(
            artist: Artist(
                id: artistId, name: "백예린", avatarUrl: nil,
                followersCount: 1_200_000, upcomingEventCount: 24, isFollowing: false
            ),
            upcomingTicketing: UpcomingTicketing(
                id: UUID(), dDay: "D-7",
                concertTitle: "백예린 2025 Live\n[wanna see you dance again]",
                ticketOpenInfo: "2025.11.02 20:00 · NOL 티켓",
                dateVenueInfo: "2025.11.20 ~ 11.23 · 에스펙토리"
            ),
            pastConcerts: [
                PastConcert(
                    id: UUID(), imageUrl: nil,
                    title: "백예린 2025 단독 콘서트 : Flash and Core",
                    dateRange: "2025.10.25 ~ 2025.10.26", venueName: "인스파이어 아레나"
                ),
                PastConcert(
                    id: UUID(), imageUrl: nil,
                    title: "Yerin Baek Concert : Square",
                    dateRange: "2023.05.19 ~ 2023.05.21", venueName: "올림픽공원 SK핸드볼경기장"
                ),
                PastConcert(
                    id: UUID(), imageUrl: nil,
                    title: "Yerin Baek 1st Concert : \"Turn on that Blue Vinyl\"",
                    dateRange: "2020.02.08 ~ 2020.02.09", venueName: "예스24 라이브홀"
                ),
            ],
            profileInfo: ProfileInfo(
                occupation: "가수",
                birthDate: "1997년 6월 26일 (양력)",
                birthPlace: "대한민국 대전",
                related: "#The Volunteers\n#peoplelikepeople"
            ),
            musicVideos: [
                MusicVideo(
                    id: UUID(), thumbnailUrl: nil,
                    title: "백예린(Yerin Baek)\n'MIRROR' M/V",
                    viewCount: "4.4M", likeCount: "299K", uploadDate: "2025.10.02"
                ),
                MusicVideo(
                    id: UUID(), thumbnailUrl: nil,
                    title: "백예린(Yerin Baek)\n'1-4-3' Lyric Video",
                    viewCount: "230K", likeCount: "63K", uploadDate: "2025.05.07"
                ),
            ],
            albums: [
                AlbumItem(id: UUID(), imageUrl: nil, title: "Flash and Core", year: "2025"),
                AlbumItem(id: UUID(), imageUrl: nil, title: "I MET PEEJAY", year: "2025"),
                AlbumItem(id: UUID(), imageUrl: nil, title: "Tellusaboutyourself", year: "2020"),
            ]
        )
    }
}
