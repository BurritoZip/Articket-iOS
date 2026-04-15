import UIKit

extension UIColor {
    // Named colors from Assets.xcassets/Colors/ (with code fallback for previews / tests)
    // This service is light-mode only — no dark mode support.
    static let tcBackground    = UIColor(named: "Background")      ?? .white
    static let tcSurface       = UIColor(named: "Surface")         ?? UIColor(red: 0.953, green: 0.957, blue: 0.965, alpha: 1)
    static let tcTextPrimary   = UIColor(named: "TextPrimary")     ?? UIColor(red: 0.063, green: 0.094, blue: 0.157, alpha: 1) // #101828
    static let tcTextSecondary = UIColor(named: "TextSecondary")   ?? UIColor(red: 0.400, green: 0.439, blue: 0.518, alpha: 1) // #667085
    static let tcBadgeBg       = UIColor(named: "BadgeBackground") ?? UIColor(red: 0.063, green: 0.094, blue: 0.157, alpha: 1) // #101828
    static let tcBadgeText     = UIColor(named: "BadgeText")       ?? .white
    static let tcSeparator     = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
}
