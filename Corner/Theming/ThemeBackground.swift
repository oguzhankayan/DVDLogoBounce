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

/// A small swatch used in the theme gallery / pickers — shows the theme's
/// background and a miniature of the (tinted) CVC logo. The glow is drawn as a
/// blurred copy *inside* the clipped rounded rect so it never spills past the
/// swatch edge (which read as "cut off").
struct ThemeSwatch: View {
    var theme: Theme
    var size: CGFloat = 64
    /// Overrides the badge word for `.discBadge` themes (so the picker can show
    /// the user's actual logo text). `nil` ⇒ the theme's own default.
    var wordmark: String? = nil

    private var w: CGFloat { size * 1.6 }
    private var tint: Color {
        (theme.logo.tintFollowsCollision ? theme.collisionColor(at: 1) : theme.logo.fixedColor).color
    }

    var body: some View {
        ZStack {
            ThemeBackground(style: theme.background, override: nil, dimForChrome: false)
            // Soft contained glow.
            logoMark
                .blur(radius: size * 0.16)
                .opacity(0.35 + 0.6 * theme.glow.intensity)
            logoMark
        }
        .frame(width: w, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
    }

    @ViewBuilder private var logoMark: some View {
        switch theme.logo.shape {
        case .vectorOutline:
            VectorOutlineMark(resource: theme.logo.vectorResource, tint: tint)
                .frame(width: w * 0.62, height: size * 0.5)
        case .discBadge:
            DiscBadgeMark(text: wordmark ?? theme.logo.wordmark, tint: tint, scale: size / 104)
        default:
            Circle().fill(tint).frame(width: size * 0.34, height: size * 0.34)
        }
    }
}

/// A small static rendition of the `.discBadge` mark (theme swatches / pickers):
/// a bold condensed‑italic wordmark above a flat ellipse with a punched hole.
struct DiscBadgeMark: View {
    let text: String
    let tint: Color
    var scale: CGFloat = 1

    var body: some View {
        let display = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "CORNER" : text
        VStack(spacing: 4 * scale) {
            Text(display.uppercased())
                .font(.system(size: 28 * scale, weight: .black).width(.condensed))
                .italic()
                .minimumScaleFactor(0.3)
                .lineLimit(1)
            ZStack {
                Ellipse().fill(tint)
                Ellipse().fill(Color.white).frame(width: 14 * scale, height: 6.5 * scale).blendMode(.destinationOut)
            }
            .compositingGroup()
            .frame(width: 76 * scale, height: 20 * scale)
        }
        .foregroundStyle(tint)
        .fixedSize()
    }
}

/// Tiny reusable static fill of a bundled flat SVG (theme swatches / pickers).
/// The SVG's coordinate space is already y‑down, so it maps straight into SwiftUI.
struct VectorOutlineMark: View {
    let resource: String?
    let tint: Color

    var body: some View {
        GeometryReader { geo in
            if let name = resource, let parsed = SVGOutline.load(named: name),
               geo.size.width > 0, geo.size.height > 0,
               case let bb = parsed.path.boundingBoxOfPath, bb.width > 0, bb.height > 0 {
                let k = min(geo.size.width / bb.width, geo.size.height / bb.height)
                var t = CGAffineTransform(translationX: -bb.minX, y: -bb.minY)
                    .concatenating(CGAffineTransform(scaleX: k, y: k))
                let scaled = parsed.path.copy(using: &t) ?? parsed.path
                Path(scaled)
                    .fill(tint, style: FillStyle(eoFill: true))
                    .frame(width: bb.width * k, height: bb.height * k)
                    .frame(width: geo.size.width, height: geo.size.height)
            } else {
                Circle().fill(tint).padding(geo.size.width * 0.3)
            }
        }
    }
}
