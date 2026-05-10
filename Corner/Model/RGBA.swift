import Foundation

/// A platform‑agnostic colour value used throughout the model layer so that
/// `Theme` and friends stay free of UIKit / SwiftUI imports and remain trivially
/// testable. Bridged to `SwiftUI.Color` / `SKColor` in the Theming layer.
public struct RGBA: Codable, Hashable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var opacity: Double

    public init(red: Double, green: Double, blue: Double, opacity: Double = 1) {
        self.red = red.clamped(to: 0...1)
        self.green = green.clamped(to: 0...1)
        self.blue = blue.clamped(to: 0...1)
        self.opacity = opacity.clamped(to: 0...1)
    }

    /// Accepts `#RGB`, `#RGBA`, `#RRGGBB`, `#RRGGBBAA` (with or without `#`).
    public init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        if s.count == 3 || s.count == 4 {
            s = s.map { "\($0)\($0)" }.joined()
        }
        var value: UInt64 = 0
        Scanner(string: s).scanHexInt64(&value)
        let hasAlpha = s.count == 8
        let r, g, b, a: Double
        if hasAlpha {
            r = Double((value >> 24) & 0xFF) / 255
            g = Double((value >> 16) & 0xFF) / 255
            b = Double((value >> 8) & 0xFF) / 255
            a = Double(value & 0xFF) / 255
        } else {
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >> 8) & 0xFF) / 255
            b = Double(value & 0xFF) / 255
            a = 1
        }
        self.init(red: r, green: g, blue: b, opacity: a)
    }

    public var hexString: String {
        let r = Int((red * 255).rounded())
        let g = Int((green * 255).rounded())
        let b = Int((blue * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    public func withOpacity(_ value: Double) -> RGBA {
        RGBA(red: red, green: green, blue: blue, opacity: value)
    }

    /// Linear interpolation in (gamma) RGB space — perfectly adequate for the
    /// soft cross‑fades and collision colour cycling we use.
    public func mixed(with other: RGBA, t: Double) -> RGBA {
        let t = t.clamped(to: 0...1)
        return RGBA(
            red: red + (other.red - red) * t,
            green: green + (other.green - green) * t,
            blue: blue + (other.blue - blue) * t,
            opacity: opacity + (other.opacity - opacity) * t
        )
    }

    /// Perceived luminance (Rec. 709). Used to keep logo text readable on any
    /// background tint the user picks.
    public var luminance: Double {
        0.2126 * red + 0.7152 * green + 0.0722 * blue
    }

    public static let white = RGBA(red: 1, green: 1, blue: 1)
    public static let black = RGBA(red: 0, green: 0, blue: 0)
    public static let clear = RGBA(red: 0, green: 0, blue: 0, opacity: 0)
}
