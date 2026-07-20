import Foundation
import MapKit

// MARK: - VenueMapOpener
// 공연장 위치를 지도 앱에서 여는 헬퍼.
//
// 기존 구현은 "공연장명 + 주소"를 하나의 문자열로 이어붙여 maps.apple.com/?q= 에 넘겼는데,
// 예) "공상온도 서울 마포구 동교로41길 19" → Apple Maps가 단일 검색어로 해석해 매칭에 실패했다.
// venues 테이블에 위경도 컬럼이 없으므로, MKLocalSearch로 앱 안에서 먼저 좌표를 확정한 뒤
// MKMapItem으로 지도 앱을 연다. 실패는 조용히 넘기지 않고 호출부에 알린다.

enum VenueMapOpener {

    enum Failure: Error {
        /// 공연장명·주소가 모두 비어 검색할 거리가 없음
        case noQuery
        /// 검색은 했으나 일치하는 장소를 못 찾음
        case notFound
    }

    /// 공연장명/주소로 지도 앱을 연다.
    /// - 검색 순서: ① 주소 ② 공연장명 ③ "공연장명 주소" 결합
    ///   주소를 먼저 쓰는 이유 — 도로명 주소가 가장 높은 확률로 단일 좌표에 매칭된다.
    ///   공연장명은 동명 업소가 많아 단독 검색 시 엉뚱한 지점이 잡힐 수 있어 2순위.
    @MainActor
    static func open(venueName: String, address: String) async throws {
        let candidates = [
            address,
            venueName,
            [venueName, address].filter { !$0.isEmpty }.joined(separator: " ")
        ]
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

        guard !candidates.isEmpty else { throw Failure.noQuery }

        for query in candidates {
            guard let item = await search(query: query) else { continue }
            // 지도 앱 상단에 공연장 이름이 뜨도록 표기명을 덮어쓴다 (검색 결과 상호명이 다를 수 있음)
            if !venueName.isEmpty { item.name = venueName }
            // iOS 18+ 에서 openInMaps 는 async 오버로드로 해석된다 (반환값은 실행 성공 여부)
            _ = await item.openInMaps(launchOptions: [
                MKLaunchOptionsMapTypeKey: NSNumber(value: MKMapType.standard.rawValue)
            ])
            return
        }

        throw Failure.notFound
    }

    private static func search(query: String) async -> MKMapItem? {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        // 국내 공연장 대상이므로 한반도 전역으로 힌트를 제한해 해외 동명 지점이 잡히는 것을 줄인다
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 36.5, longitude: 127.8),
            span: MKCoordinateSpan(latitudeDelta: 6, longitudeDelta: 6)
        )

        do {
            let response = try await MKLocalSearch(request: request).start()
            return response.mapItems.first
        } catch {
            return nil
        }
    }
}
