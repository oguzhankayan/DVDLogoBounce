import SwiftUI

extension AppSettings {
    /// The fully‑resolved theme for the current `themeID`.
    var resolvedTheme: Theme { ThemeCatalog.theme(for: themeID) }
}

/// Renders a `BackgroundStyle` as a SwiftUI view — used behind the menu, the
/// settings screens, onboarding, etc. so the chrome always matches the active
/// theme. (The screensaver itself renders its background in SpriteKit.)
struct ThemeBackground: View {
    var style: BackgroundStyle
    /// Optional flat colour override (mirrors `AppSettings.customBackgroundColor`).
    var override: RGBA?
    /// Dim the whole thing a touch so foreground UI stays readable.
    var dimForChrome: Bool = true

    var body: some View {
        ZStack {
            base
            if style.vignette > 0.001 {
                RadialGradient(
                    colors: [.clear, .clear, Color.black.opacity(min(0.92, style.vignette))],
                    center: .center, startRadius: 0, endRadius: 1400
                )
                .ignoresSafeArea()
            }
            if dimForChrome {
                Color.black.opacity(0.28).ignoresSafeArea()
            }
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var base: some View {
        if let override {
            override.color.ignoresSafeArea()
        } else {
            switch style.kind {
            case .solid:
                style.baseColor.color.ignoresSafeArea()
            case .linearGradient:
                LinearGradient(colors: style.stops.map { $0.color },
                               startPoint: .bottom, endPoint: .top)
                    .ignoresSafeArea()
            case .radialGradient:
                ZStack {
                    style.stops.last?.color.ignoresSafeArea()
                    RadialGradient(colors: style.stops.map { $0.color },
                                   center: .center, startRadius: 0, endRadius: 1600)
                        .ignoresSafeArea()
                }
            }
        }
    }
}

/// A small swatch used in the theme gallery / pickers.
struct ThemeSwatch: View {
    var theme: Theme
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            ThemeBackground(style: theme.background, override: nil, dimForChrome: false)
                .frame(width: size * 1.6, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.18, style: .continuous))
            Circle()
                .fill(theme.collisionColor(at: 1).color)
                .frame(width: size * 0.34, height: size * 0.34)
                .shadow(color: theme.collisionColor(at: 1).color.opacity(theme.glow.intensity), radius: size * 0.18)
        }
        .frame(width: size * 1.6, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
    }
}
