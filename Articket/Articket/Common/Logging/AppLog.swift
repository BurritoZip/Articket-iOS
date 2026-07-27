import Foundation

/// 진단 로깅 코어. 화면/액션/API 흔적을 메모리 링버퍼에 쌓고(스레드 안전, fire-and-forget),
/// 에러 시 ErrorReporter가 snapshot()을 리포트에 첨부한다. 절대 throw/블로킹하지 않는다.
final class AppLog: @unchecked Sendable {

    static let maxBreadcrumbs = 20
    static let shared = AppLog()

    private let lock = NSLock()
    private var ring: [Breadcrumb] = []
    private var _currentScreen: String?
    private let clock: @Sendable () -> Date

    init(clock: @escaping @Sendable () -> Date = { Date() }) {
        self.clock = clock
    }

    var currentScreen: String? {
        lock.lock(); defer { lock.unlock() }
        return _currentScreen
    }

    func screen(_ name: String) {
        lock.lock()
        _currentScreen = name
        appendLocked(kind: .screen, message: name, meta: nil)
        lock.unlock()
        Self.console("🧭 \(name)")
    }

    func action(_ label: String) {
        lock.lock()
        appendLocked(kind: .action, message: label, meta: nil)
        let scr = _currentScreen ?? "-"
        lock.unlock()
        Self.console("🖲️ \(scr) · \(label)")
    }

    func api(endpoint: String, method: String, status: Int?, ms: Int, error: String?) {
        var meta: [String: String] = ["method": method, "ms": String(ms)]
        meta["endpoint"] = String(endpoint.prefix(200))
        if let status { meta["status"] = String(status) }
        if let error { meta["error"] = String(error.prefix(300)) }
        lock.lock()
        appendLocked(kind: .api, message: "\(method) \(endpoint.prefix(80))", meta: meta)
        let scr = _currentScreen ?? "-"
        lock.unlock()
        let tail = status.map { " → \($0)" } ?? (error.map { " ✕ \($0)" } ?? "")
        Self.console("🌐 \(scr) · \(method) \(endpoint.prefix(80))\(tail) (\(ms)ms)")
    }

    func snapshot() -> [Breadcrumb] {
        lock.lock(); defer { lock.unlock() }
        return ring
    }

    func reset() {
        lock.lock(); ring.removeAll(); _currentScreen = nil; lock.unlock()
    }

    // lock 보유 상태에서만 호출.
    private func appendLocked(kind: Breadcrumb.Kind, message: String, meta: [String: String]?) {
        ring.append(Breadcrumb(time: clock(), kind: kind, screen: _currentScreen,
                               message: message, meta: meta))
        if ring.count > Self.maxBreadcrumbs {
            ring.removeFirst(ring.count - Self.maxBreadcrumbs)
        }
    }

    private static func console(_ line: String) {
        #if DEBUG
        print("[AppLog] \(line)")
        #endif
    }
}
