import Foundation
import Network

// MARK: - NetworkMonitor
// 네트워크 연결 상태를 전역에서 감시한다.
//
// 앱 전반이 오프라인/서버 오류를 "~를 불러오지 못했습니다" 한 문구로 뭉뚱그려, 사용자가
// 자기 연결 문제인지 앱 문제인지 구분할 수 없었다. 연결 상태를 한 곳에서 감시해
// 오프라인일 때 전역 배너로 원인을 알린다.

@MainActor
final class NetworkMonitor {

    static let shared = NetworkMonitor()

    /// 연결 상태가 바뀔 때 발행. object로 Bool(연결됨 여부)을 실어 보낸다.
    static let statusDidChange = Notification.Name("networkStatusDidChange")

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    /// 현재 연결 여부. 감시 시작 전에는 낙관적으로 true(연결됨)로 둔다 —
    /// 시작 직후 잠깐 배너가 깜빡이는 것을 막기 위함.
    private(set) var isConnected = true

    private var didStart = false

    private init() {}

    func start() {
        guard !didStart else { return }
        didStart = true

        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            // NWPathMonitor 콜백은 백그라운드 큐 → UI/상태는 메인에서 갱신
            Task { @MainActor in
                self?.updateStatus(connected)
            }
        }
        monitor.start(queue: queue)
    }

    private func updateStatus(_ connected: Bool) {
        guard connected != isConnected else { return }   // 실제 전이일 때만 발행
        isConnected = connected
        NotificationCenter.default.post(
            name: Self.statusDidChange,
            object: connected
        )
    }
}
