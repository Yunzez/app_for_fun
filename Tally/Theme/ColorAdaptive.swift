import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Color {
    /// Light/dark adaptive `Color` built from sRGB hex components (no alpha).
    /// Use only inside `ThemePalette` definitions — never in views directly.
    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        #if canImport(UIKit)
        Color(uiColor: UIColor { @Sendable trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(rgbHex: dark)
                : UIColor(rgbHex: light)
        })
        #elseif canImport(AppKit)
        Color(nsColor: NSColor(name: nil) { @Sendable appearance in
            let darkNames: [NSAppearance.Name] = [
                .darkAqua,
                .vibrantDark,
                .accessibilityHighContrastDarkAqua,
                .accessibilityHighContrastVibrantDark
            ]
            let isDark = appearance.bestMatch(from: darkNames) != nil
            return isDark ? NSColor(rgbHex: dark) : NSColor(rgbHex: light)
        })
        #endif
    }
}

#if canImport(UIKit)
private extension UIColor {
    convenience init(rgbHex: UInt32) {
        let r = CGFloat((rgbHex >> 16) & 0xFF) / 255
        let g = CGFloat((rgbHex >> 8) & 0xFF) / 255
        let b = CGFloat(rgbHex & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
#elseif canImport(AppKit)
private extension NSColor {
    convenience init(rgbHex: UInt32) {
        let r = CGFloat((rgbHex >> 16) & 0xFF) / 255
        let g = CGFloat((rgbHex >> 8) & 0xFF) / 255
        let b = CGFloat(rgbHex & 0xFF) / 255
        self.init(srgbRed: r, green: g, blue: b, alpha: 1)
    }
}
#endif
