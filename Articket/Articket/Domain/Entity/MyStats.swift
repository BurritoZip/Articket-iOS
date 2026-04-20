import Foundation

struct MyStats: Hashable, Sendable {
    let year: Int
    let monthlyViewCounts: [Int]  // 12개 (1월~12월)
    let topMonth: Int             // 최다 관람 월 (1~12)
    let topGenre: String
    let topArtist: String
    let totalCount: Int
}
