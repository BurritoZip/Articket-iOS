import UIKit

// 타임테이블 잠금화면 이미지를 앱 Documents에 보관
struct TimetableWallpaperStorage {

    static let fileName = "timetable_wallpaper.png"
    static let wallpaperFileName = "wallpaper.jpg"
    static let cardFileName = "timetable_card.png"

    private static var documents: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static var fileURL: URL { documents.appendingPathComponent(fileName) }
    static var wallpaperURL: URL { documents.appendingPathComponent(wallpaperFileName) }
    static var cardURL: URL { documents.appendingPathComponent(cardFileName) }

    static func save(_ image: UIImage) {
        guard let data = image.pngData() else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    static func load() -> UIImage? {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    static func exists() -> Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }

    static func saveWallpaper(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }
        try? data.write(to: wallpaperURL, options: .atomic)
    }

    static func loadWallpaper() -> UIImage? {
        guard let data = try? Data(contentsOf: wallpaperURL) else { return nil }
        return UIImage(data: data)
    }

    static func saveCard(_ image: UIImage) {
        guard let data = image.pngData() else { return }
        try? data.write(to: cardURL, options: .atomic)
    }

    static func loadCard() -> UIImage? {
        guard let data = try? Data(contentsOf: cardURL) else { return nil }
        return UIImage(data: data)
    }
}
