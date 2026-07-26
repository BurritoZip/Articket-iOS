import Foundation

protocol Coordinator: AnyObject {
    func start()
}

// ArtistDetail 화면에서 콘서트 상세·이벤트 리스트로 라우팅
protocol ArtistDetailCoordinatorProtocol: AnyObject {
    func showConcertDetail(concertId: UUID, imageAssetName: String?)
    func showEventList(title: String, events: [Event])
}

// ConcertDetail 화면에서 아티스트 상세·후기 작성으로 라우팅
protocol ConcertDetailCoordinatorProtocol: AnyObject {
    func showArtistDetail(artistId: UUID)
    func showWriteReview(preselectedEventId: UUID)
}

// Search 화면에서 검색결과·공연/아티스트 상세로 라우팅
protocol SearchCoordinatorProtocol: AnyObject {
    func showSearchResult(keyword: String)
    func showConcertDetail(concertId: UUID, imageAssetName: String?)
    func showArtistDetail(artistId: UUID)
}
