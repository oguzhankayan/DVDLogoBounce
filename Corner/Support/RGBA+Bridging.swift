import SwiftUI
import SpriteKit

extension Color {
    init(_ rgba: RGBA) {
        self.init(.sRGB, red: rgba.red, green: rgba.green, blue: rgba.blue, opacity: rgba.opacity)
    }
}

extension RGBA {
    var color: Color { Color(self) }

    /// `SKColor` is a typealias for `UIColor` on tvOS.
    var skColor: SKColor {
        SKColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(opacity))
    }

    /// A foreground colour guaranteed to read against `self` as a background.
    var autoContrastingForeground: RGBA {
        luminance > 0.55 ? RGBA(hex: "#0A0A0C") : RGBA(hex: "#FAFAFA")
    }
}

extension SKColor {
    var rgba: RGBA {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return RGBA(red: Double(r), green: Double(g), blue: Double(b), opacity: Double(a))
    }
}
