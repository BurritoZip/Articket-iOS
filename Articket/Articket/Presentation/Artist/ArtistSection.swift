import Foundation

enum ArtistSection: Int, CaseIterable, Sendable {
    case myArtists
    case popularArtists
    case calendar
    case recommendedArtists
}

enum ArtistSectionItem: @preconcurrency Hashable, Sendable {
    case myArtist(Artist)
    case popularArtist(PopularArtist)
    case calendar(year: Int, month: Int)
    case recommendedArtist(Artist)
}
