import UIKit

// MARK: - YouTubeSearchOpener
// 앨범·뮤직비디오 등 개별 URL 데이터가 없는 항목을 유튜브 "검색 결과"로 연결한다.
// 검색 URL 딥링크라 API 키·쿼터·환각(존재하지 않는 URL)이 없고, 유튜브 앱 설치 시
// 앱으로(유니버설 링크), 아니면 웹으로 열린다. 아티스트명 + 제목을 질의어로 쓴다.

enum YouTubeSearchOpener {

    /// 질의어로 유튜브 검색을 연다. 빈 문자열·인코딩 실패 시 아무것도 하지 않는다.
    static func open(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://www.youtube.com/results?search_query=\(encoded)")
        else { return }
        UIApplication.shared.open(url)
    }
}
