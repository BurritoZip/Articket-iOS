import Foundation

/// 앱 표시용 날짜는 항상 KST 벽시계로 통일한다.
/// (기기 TZ·UTC 저장값 때문에 티켓 오픈일이 9시간 어긋나 보이던 회귀 방지)
enum KSTDateFormat {
    static let day: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        f.dateFormat = "yyyy.MM.dd"
        return f
    }()

    static let dateTime: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        f.dateFormat = "yyyy.MM.dd HH:mm"
        return f
    }()
}
