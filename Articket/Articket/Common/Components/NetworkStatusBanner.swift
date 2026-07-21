import UIKit
import SnapKit

// MARK: - NetworkStatusBanner
// 오프라인일 때 화면 상단(status bar 아래)에 내려오는 전역 배너.
//
// NetworkMonitor의 연결 상태 변화를 구독해, 끊기면 내려오고 복귀하면 잠깐 "연결됨"을
// 보인 뒤 사라진다. keyWindow에 직접 얹어 어느 화면 위에서도 동일하게 노출된다.
// (탭바·네비바보다 위, ToastView와 동일하게 window 레벨)

@MainActor
final class NetworkStatusBanner {

    static let shared = NetworkStatusBanner()
    private init() {}

    private var bannerView: UIView?
    private var dismissWorkItem: DispatchWorkItem?

    /// 감시 시작 + 상태 구독. 앱 시작 시 1회 호출.
    func startObserving() {
        NetworkMonitor.shared.start()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(statusChanged(_:)),
            name: NetworkMonitor.statusDidChange,
            object: nil
        )
        // 시작 시점에 이미 오프라인이면 바로 노출
        if !NetworkMonitor.shared.isConnected {
            showOffline()
        }
    }

    @objc private func statusChanged(_ note: Notification) {
        let connected = (note.object as? Bool) ?? true
        Task { @MainActor in
            if connected { showRecoveredThenHide() } else { showOffline() }
        }
    }

    // MARK: - Presentation

    private func showOffline() {
        dismissWorkItem?.cancel()
        let banner = bannerView ?? makeBanner()
        configure(banner, connected: false)
        present(banner)
    }

    private func showRecoveredThenHide() {
        // 배너가 떠 있던 경우에만 "다시 연결됨"을 잠깐 보여준 뒤 접는다.
        // 애초에 안 떠 있었으면(계속 온라인) 아무 것도 하지 않는다.
        guard let banner = bannerView else { return }
        configure(banner, connected: true)
        dismissWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.hide() }
        dismissWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: work)
    }

    private func present(_ banner: UIView) {
        guard let window = Self.keyWindow else { return }
        if banner.superview == nil {
            window.addSubview(banner)
            banner.snp.makeConstraints {
                $0.top.leading.trailing.equalToSuperview()
                // status bar 영역까지 덮되 콘텐츠는 safeArea 아래에 배치(배너 내부에서 처리)
            }
            // 초기 위치: 위로 숨김
            banner.transform = CGAffineTransform(translationX: 0, y: -200)
            window.layoutIfNeeded()
        }
        UIView.animate(withDuration: 0.3) { banner.transform = .identity }
    }

    private func hide() {
        guard let banner = bannerView else { return }
        UIView.animate(withDuration: 0.3) {
            banner.transform = CGAffineTransform(translationX: 0, y: -200)
        } completion: { [weak self] _ in
            banner.removeFromSuperview()
            self?.bannerView = nil
        }
    }

    // MARK: - View

    private func makeBanner() -> UIView {
        let container = UIView()

        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .white
        iconView.tag = 1

        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .white
        label.tag = 2

        let stack = UIStackView(arrangedSubviews: [iconView, label])
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center

        container.addSubview(stack)
        iconView.snp.makeConstraints { $0.size.equalTo(16) }
        stack.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(container.safeAreaLayoutGuide.snp.top).offset(6)
            $0.bottom.equalToSuperview().inset(10)
        }

        bannerView = container
        return container
    }

    private func configure(_ banner: UIView, connected: Bool) {
        let icon = banner.viewWithTag(1) as? UIImageView
        let label = banner.viewWithTag(2) as? UILabel
        if connected {
            banner.backgroundColor = UIColor(red: 0.20, green: 0.60, blue: 0.35, alpha: 1)
            icon?.image = UIImage(systemName: "wifi")
            label?.text = "네트워크에 다시 연결됐어요"
        } else {
            banner.backgroundColor = UIColor(red: 0.20, green: 0.20, blue: 0.22, alpha: 1)
            icon?.image = UIImage(systemName: "wifi.slash")
            label?.text = "인터넷 연결이 끊겼어요"
        }
    }

    private static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
