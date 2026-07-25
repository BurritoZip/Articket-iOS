@testable import Articket

import Foundation

final class MockConcertDetailRepository: ConcertDetailRepositoryProtocol {
    func fetchConcertDetail(concertId: UUID) async -> ConcertDetail {
        ConcertDetail(
            id: concertId,
            title: "백예린 2025 Live [wanna see you dance again]",
            status: .onSale,
            genre: "콘서트",
            duration: "120분",
            ageRestriction: "만 11세이상",
            venueName: "에스팩토리",
            address: "서울특별시 성동구 연무장15길 11",
            phoneNumber: "1800-6310",
            dateRange: "2025.11.20 ~ 2025.11.23",
            ticketOpenDate: "2025.11.15 20:00",
            ticketCloseDate: "",
            ticketProvider: "인터파크 티켓",
            bookingUrl: nil,
            bookingLinks: [],
            organizer: "",
            noticeText: "티켓 구매 후 티켓을 재판매하는 행위는 금지되어 있습니다. 불법 거래된 티켓은 주최 측의 권한으로 사전 통보 없이 취소 처리되며, 공연 당일 현장에서 티켓을 소지하고 있더라도 공연장 입장이 불가함을 알려 드립니다.

본 공연의 공식 지정 예매처가 아닌 다른 경로를 통한 구매 또는 취득한 티켓으로 발생한 피해와 책임은 전적으로 당사자에게 있으며, 공연의 주최/주관/협력사/예매처에서는 어떠한 책임도 지지 않습니다.",
            artist: Artist(
                id: UUID(),
                name: "백예린",
                avatarUrl: nil,
                followersCount: 128_400,
                upcomingEventCount: 1,
                isFollowing: false
            ),
            lineupArtists: [],
            imageAssetName: nil,
            reviews: [
                ConcertDetailReview(
                    id: UUID(),
                    starCount: 5,
                    title: "진짜최고",
                    username: "bogyu****",
                    date: "2025.11.26",
                    content: "11.23 세트리스트 공유합니다.
1. DUST ON YOUR MIND (Flash and Core)
2. Seeking happy in the crowd (I MET PEEJAY)
3. No man's land (feat. Qim Isle) (Flash and Core)
4. Television star (Flash and Core)
5. save me (Flash and Core)
6. Fuckin' New Year (New Year)
7. 내가 날 모르는 것처럼 (Our love is great)
8. 그의 바다 (Bye bye my blue)
9. London (Every letter I sent you.)"
                ),
                ConcertDetailReview(
                    id: UUID(),
                    starCount: 5,
                    title: "백예린 최고의 공연",
                    username: "luna****",
                    date: "2025.11.24",
                    content: "목소리가 너무 좋고 무대 연출이 정말 감동적이었어요. 또 보고 싶다는 생각이 들 만큼 완벽한 공연이었습니다."
                ),
                ConcertDetailReview(
                    id: UUID(),
                    starCount: 4,
                    title: "좋았지만 아쉬움도",
                    username: "star****",
                    date: "2025.11.23",
                    content: "공연 자체는 너무 좋았는데 음향이 조금 아쉬웠어요. 그래도 백예린 무대는 항상 최고입니다."
                )
            ],
            hasTimetable: false,
            sessions: []
        )
    }

    func fetchIsInterested(concertId: UUID) async -> Bool { false }
    func toggleInterested(concertId: UUID, currentlyInterested: Bool) async throws {}
}
