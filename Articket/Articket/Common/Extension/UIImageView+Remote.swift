import UIKit

private final class RemoteImageCache: NSCache<NSString, UIImage> {
    static let shared: RemoteImageCache = {
        let c = RemoteImageCache()
        c.countLimit = 100
        c.totalCostLimit = 50 * 1024 * 1024
        return c
    }()
}

private enum AssociatedKey {
    static var task = "remoteImageTask"
    // 로드 세대 토큰. 셀 재사용/재로드 시 값이 바뀌어, 진행 중이던 이전 요청·재시도가
    // 뒤늦게 엉뚱한 이미지를 그리거나 재시도를 이어가는 것을 막는다.
    static var token = "remoteImageToken"
}

extension UIImageView {
    /// 포스터 미제공(URL 없음/로드 실패) 시 쓰는 공용 플레이스홀더 — 회색 배경 + 사진 아이콘(3:4 비율).
    static let posterPlaceholder: UIImage = {
        let size = CGSize(width: 120, height: 160)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            UIColor(hex: "#EEEFF1").setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let cfg = UIImage.SymbolConfiguration(pointSize: 32, weight: .regular)
            if let icon = UIImage(systemName: "photo", withConfiguration: cfg)?
                .withTintColor(UIColor(hex: "#C4C7CC"), renderingMode: .alwaysOriginal) {
                icon.draw(in: CGRect(x: (size.width - icon.size.width) / 2,
                                     y: (size.height - icon.size.height) / 2,
                                     width: icon.size.width, height: icon.size.height))
            }
        }
    }()

    /// 공연 포스터 전용 로드 — URL 없음/실패 시 공용 포스터 플레이스홀더를 보여준다.
    func loadPoster(urlString: String?, placeholder: UIColor? = UIColor(hex: "#EEEFF1")) {
        loadImage(urlString: urlString, placeholder: placeholder, fallbackImage: UIImageView.posterPlaceholder)
    }

    /// 원격 이미지 로드. 일시적 네트워크 실패는 자동 재시도한다.
    /// - Parameters:
    ///   - urlString: 이미지 URL. nil/빈 문자열이면 fallbackImage(있으면)를 표시.
    ///   - placeholder: 로딩 중·실패 시 깔아둘 배경색. nil이면 배경을 건드리지 않음(하위호환 기본값).
    ///   - retryCount: 실패 시 재시도 횟수. 취소로 인한 실패는 재시도하지 않음.
    ///   - fallbackImage: URL 없음/재시도 소진 시 표시할 대체 이미지(포스터 결손 등). nil이면 빈칸 유지.
    func loadImage(urlString: String?, placeholder: UIColor? = nil, retryCount: Int = 2, fallbackImage: UIImage? = nil) {
        cancelImageLoad()

        let token = UUID()
        objc_setAssociatedObject(self, &AssociatedKey.token, token, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        image = nil
        if let placeholder { backgroundColor = placeholder }

        guard let urlString, !urlString.isEmpty, let url = URL(string: urlString) else {
            image = fallbackImage
            return
        }

        if let cached = RemoteImageCache.shared.object(forKey: urlString as NSString) {
            image = cached
            return
        }

        attemptLoad(url: url, key: urlString, token: token, remaining: retryCount, fallbackImage: fallbackImage)
    }

    private func attemptLoad(url: URL, key: String, token: UUID, remaining: Int, fallbackImage: UIImage?) {
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self else { return }

            if let data, let img = UIImage(data: data) {
                RemoteImageCache.shared.setObject(img, forKey: key as NSString, cost: data.count)
                DispatchQueue.main.async {
                    // 대입 직전에 세대 확인 — 셀이 재사용돼 다른 URL을 로드 중이면 덮어쓰지 않는다
                    guard self.currentToken == token else { return }
                    self.image = img
                }
                return
            }

            // 명시적 취소(cancelImageLoad/재로드)는 재시도 대상이 아니다
            if let urlErr = error as? URLError, urlErr.code == .cancelled { return }
            // 이미 다른 로드로 교체됐거나 재시도 소진이면 종료
            guard self.currentToken == token, remaining > 0 else {
                // 재시도까지 소진했으면 대체 이미지 표시(있을 때)
                if remaining <= 0, let fallbackImage {
                    DispatchQueue.main.async {
                        guard self.currentToken == token else { return }
                        self.image = fallbackImage
                    }
                }
                return
            }

            // 짧은 고정 백오프 후 재시도 — 순간적 연결 끊김을 흡수한다
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                guard let self, self.currentToken == token else { return }
                self.attemptLoad(url: url, key: key, token: token, remaining: remaining - 1, fallbackImage: fallbackImage)
            }
        }
        objc_setAssociatedObject(self, &AssociatedKey.task, task, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        task.resume()
    }

    private var currentToken: UUID? {
        objc_getAssociatedObject(self, &AssociatedKey.token) as? UUID
    }

    func cancelImageLoad() {
        (objc_getAssociatedObject(self, &AssociatedKey.task) as? URLSessionDataTask)?.cancel()
        // 세대 토큰을 비워, 대기 중이던 재시도 클로저가 스스로 중단하게 한다
        objc_setAssociatedObject(self, &AssociatedKey.token, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
