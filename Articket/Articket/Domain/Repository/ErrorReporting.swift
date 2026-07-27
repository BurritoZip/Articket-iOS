import Foundation

/// 앱 런타임 에러/크래시를 백엔드(app_error_logs)에 기록 — Admin 콘솔(/admin/error-logs)에서 확인.
protocol ErrorReporting: Sendable {
    func report(_ report: AppErrorReport) async
}

/// 에러 분류 — admin 필터와 동일한 값
enum AppErrorType: String, Sendable {
    case crash      // 잡히지 않은 예외/시그널
    case network    // 통신 실패
    case decoding   // 디코딩 실패
    case http       // 4xx/5xx
    case runtime    // 그 외 앱 내부 오류
}

/// 백엔드로 보낼 에러 1건
struct AppErrorReport: Sendable {
    let type: AppErrorType
    let message: String
    let domain: String?          // 발생 위치/기능 (예: "ConcertDetail", "EventRepository.fetch")
    let stackTrace: String?
    let context: [String: String]?
    let screen: String?
    let breadcrumbs: [Breadcrumb]?

    init(
        type: AppErrorType,
        message: String,
        domain: String? = nil,
        stackTrace: String? = nil,
        context: [String: String]? = nil,
        screen: String? = nil,
        breadcrumbs: [Breadcrumb]? = nil
    ) {
        self.type = type
        self.message = message
        self.domain = domain
        self.stackTrace = stackTrace
        self.context = context
        self.screen = screen
        self.breadcrumbs = breadcrumbs
    }
}
