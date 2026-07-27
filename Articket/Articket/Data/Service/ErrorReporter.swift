import Foundation

/// 앱 전역 에러 리포터. 어디서든 `ErrorReporter.shared.capture(...)` 로 호출.
///
/// 두 경로로 에러를 백엔드(app_error_logs)에 남긴다:
///  1. 잡힌 에러 — 네트워크/디코딩/HTTP/런타임: `capture(...)` 즉시 async insert.
///  2. 잡히지 않은 예외(크래시) — 종료 직전이라 async insert 불가 → UserDefaults 에 동기 저장 후,
///     다음 실행 시 `install()` 이 flush 한다.
///
/// 주의: `NSSetUncaughtExceptionHandler` 는 Obj-C 예외만, 시그널 핸들러는 SIGABRT/SIGTRAP 등만 잡는다.
/// Swift 순수 fatalError 등 완전한 크래시 수집엔 전용 SDK(Crashlytics 등)가 필요하다 — 여기선 best-effort.
final class ErrorReporter: @unchecked Sendable {

    static let shared = ErrorReporter()

    private let reporter: any ErrorReporting
    private let appLog: AppLog
    private let pendingKey = "pending_crash_report_v1"

    init(reporter: any ErrorReporting = SupabaseErrorReporter(), appLog: AppLog = .shared) {
        self.reporter = reporter
        self.appLog = appLog
    }

    // MARK: - 설치 (앱 시작 시 1회)

    /// 앱 시작 시 호출: 지난 실행의 미전송 크래시를 flush 하고 예외/시그널 핸들러를 설치한다.
    func install() {
        flushPendingCrash()
        installHandlers()
    }

    // MARK: - 잡힌 에러 리포트

    /// 잡힌 에러를 백엔드에 기록. 실패는 무시.
    func capture(
        _ type: AppErrorType,
        message: String,
        domain: String? = nil,
        error: Error? = nil,
        context: [String: String]? = nil
    ) {
        var merged = context ?? [:]
        if let error { merged["error"] = String(describing: error) }
        let report = AppErrorReport(
            type: type,
            message: message,
            domain: domain,
            stackTrace: nil,
            context: merged.isEmpty ? nil : merged,
            screen: appLog.currentScreen,
            breadcrumbs: appLog.snapshot()
        )
        Task { await reporter.report(report) }
    }

    /// Swift Error 를 그대로 넘겨 캡처하는 편의 메서드.
    func capture(_ error: Error, domain: String? = nil, type: AppErrorType = .runtime) {
        capture(type, message: String(describing: error), domain: domain, error: error)
    }

    // MARK: - 크래시 저장/복원

    /// 크래시 정보를 UserDefaults 에 동기 저장 (종료 직전 호출됨)
    fileprivate func persistCrash(name: String, reason: String, stack: [String]) {
        let payload: [String: Any] = [
            "message": "\(name): \(reason)",
            "stack": stack.joined(separator: "\n"),
        ]
        UserDefaults.standard.set(payload, forKey: pendingKey)
        UserDefaults.standard.synchronize()
    }

    /// 지난 실행에서 저장된 크래시를 백엔드로 전송 후 제거
    private func flushPendingCrash() {
        guard let payload = UserDefaults.standard.dictionary(forKey: pendingKey) else { return }
        UserDefaults.standard.removeObject(forKey: pendingKey)

        let message = payload["message"] as? String ?? "Unknown crash"
        let stack = payload["stack"] as? String
        let report = AppErrorReport(
            type: .crash,
            message: message,
            domain: "uncaught",
            stackTrace: stack,
            context: nil
        )
        Task { await reporter.report(report) }
    }

    private func installHandlers() {
        NSSetUncaughtExceptionHandler { exception in
            ErrorReporter.shared.persistCrash(
                name: exception.name.rawValue,
                reason: exception.reason ?? "",
                stack: exception.callStackSymbols
            )
        }

        // Swift fatalError/precondition 등은 시그널로 떨어진다 (주로 SIGABRT/SIGTRAP/SIGILL)
        for sig in [SIGABRT, SIGSEGV, SIGILL, SIGFPE, SIGBUS, SIGTRAP] {
            signal(sig) { received in
                ErrorReporter.shared.persistCrash(
                    name: "Signal \(received)",
                    reason: "Fatal signal \(received)",
                    stack: Thread.callStackSymbols
                )
                // 기본 핸들러로 되돌려 정상 종료(크래시 리포트 유지)
                signal(received, SIG_DFL)
                raise(received)
            }
        }
    }
}
