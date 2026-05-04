import UIKit

private final class RemoteImageCache: NSCache<NSString, UIImage> {
    static let shared: RemoteImageCache = {
        let c = RemoteImageCache()
        c.countLimit = 100
        c.totalCostLimit = 50 * 1024 * 1024
        return c
    }()
}

private enum AssociatedKey { static var task = "remoteImageTask" }

extension UIImageView {
    func loadImage(urlString: String?) {
        cancelImageLoad()
        image = nil
        guard let urlString, !urlString.isEmpty, let url = URL(string: urlString) else { return }
        if let cached = RemoteImageCache.shared.object(forKey: urlString as NSString) {
            image = cached
            return
        }
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let img = UIImage(data: data) else { return }
            RemoteImageCache.shared.setObject(img, forKey: urlString as NSString, cost: data.count)
            DispatchQueue.main.async { self?.image = img }
        }
        objc_setAssociatedObject(self, &AssociatedKey.task, task, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        task.resume()
    }

    func cancelImageLoad() {
        (objc_getAssociatedObject(self, &AssociatedKey.task) as? URLSessionDataTask)?.cancel()
    }
}
