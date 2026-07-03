import UIKit

extension UIColor {
    convenience init(hex: String) {
        var hex = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hex.hasPrefix("#") { hex.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        let r = CGFloat((rgb >> 16) & 0xFF) / 255
        let g = CGFloat((rgb >> 8) & 0xFF) / 255
        let b = CGFloat(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }

    // Named colors from Assets.xcassets/Colors/ (with code fallback for previews / tests)
    // This service is light-mode only — no dark mode support.
    static let tcBackground    = UIColor(named: "Background")      ?? .white
    static let tcSurface       = UIColor(named: "Surface")         ?? UIColor(red: 0.953, green: 0.957, blue: 0.965, alpha: 1)
    static let tcTextPrimary   = UIColor(named: "TextPrimary")     ?? UIColor(red: 0.063, green: 0.094, blue: 0.157, alpha: 1) // #101828
    static let tcTextSecondary = UIColor(named: "TextSecondary")   ?? UIColor(red: 0.400, green: 0.439, blue: 0.518, alpha: 1) // #667085
    static let tcBadgeBg       = UIColor(named: "BadgeBackground") ?? UIColor(red: 0.063, green: 0.094, blue: 0.157, alpha: 1) // #101828
    static let tcBadgeText     = UIColor(named: "BadgeText")       ?? .white
    static let tcSeparator     = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
    static let tcInk           = UIColor(hex: "#121212") // 디자인 기준 잉크 블랙 (버튼/보더/텍스트)
    static let tcFieldBorder   = UIColor(hex: "#E5E7EB") // 폼 밑줄/보더
    static let tcPlaceholder   = UIColor(hex: "#B0B0B0") // placeholder 텍스트
}
