import SwiftUI

/// A horizontal gallery of large theme preview cards. Selecting one updates
/// `AppSettings.themeID` and the screensaver restyles immediately.
struct ThemeGalleryView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var audio: AudioController
    @FocusState private var focusedTheme: ThemeID?

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            ScreenTitle(title: "Themes", subtitle: "Each restyles the logo, glow, background, particles, trails and sound.")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 28) {
                    ForEach(ThemeCatalog.all) { theme in
                        ThemeCardView(theme: theme, isSelected: theme.id == settings.themeID) {
                            audio.playUISelect()
                            settings.themeID = theme.id
                        }
                        .focused($focusedTheme, equals: theme.id)
                    }
                }
                .padding(.horizontal, 90)
                .padding(.vertical, 24)
            }

            if let focused = focusedTheme.map({ ThemeCatalog.theme(for: $0) }) {
                HStack(spacing: 14) {
                    Text(focused.name).font(.system(.title2, design: .rounded).weight(.bold))
                    Text("·").foregroundStyle(.tertiary)
                    Text(focused.tagline).font(.system(.title3, design: .rounded)).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 90)
                .transition(.opacity)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 70)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear { if focusedTheme == nil { focusedTheme = settings.themeID } }
        .animation(.easeInOut(duration: 0.25), value: focusedTheme)
        .onChange(of: focusedTheme) { _, new in if new != nil { audio.playUIFocus() } }
    }
}

// MARK: - Theme card

private struct ThemeCardView: View {
    var theme: Theme
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                ThemePreview(theme: theme)
                    .frame(width: 360, height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(alignment: .topTrailing) {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.white, theme.collisionColor(at: 1).color)
                                .padding(12)
                                .shadow(radius: 6)
                        }
                    }
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.name).font(.system(size: 24, weight: .heavy, design: .rounded))
                    Text(theme.tagline)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .frame(height: 38, alignment: .top)
                }
                .padding(.top, 14)
                .frame(width: 360, alignment: .leading)
            }
        }
        .buttonStyle(CardButtonStyle(cornerRadius: 26, accent: theme.collisionColor(at: 1).color))
    }
}

/// A small static mock of what a theme looks like — gradient/solid background,
/// vignette, a glowing badge, and (for shader themes) a hint of scanlines.
private struct ThemePreview: View {
    var theme: Theme

    var body: some View {
        ZStack {
            backgroundView
            if theme.background.vignette > 0.001 {
                RadialGradient(colors: [.clear, .clear, .black.opacity(min(0.7, theme.background.vignette))],
                               center: .center, startRadius: 0, endRadius: 260)
            }
            // The "logo"
            logoView
                .shadow(color: theme.collisionColor(at: 1).color.opacity(theme.glow.intensity),
                        radius: 18 * theme.glow.intensity + 4)
                .offset(x: -40, y: 28)
            if theme.postEffect != .none {
                ScanlineOverlay()
            }
        }
    }

    @ViewBuilder private var backgroundView: some View {
        switch theme.background.kind {
        case .solid:
            theme.background.baseColor.color
        case .linearGradient:
            LinearGradient(colors: theme.background.stops.map { $0.color }, startPoint: .bottom, endPoint: .top)
        case .radialGradient:
            ZStack {
                theme.background.stops.last?.color
                RadialGradient(colors: theme.background.stops.map { $0.color }, center: .center, startRadius: 0, endRadius: 280)
            }
        }
    }

    @ViewBuilder private var logoView: some View {
        let color = theme.logo.tintFollowsCollision ? theme.collisionColor(at: 1) : theme.logo.fixedColor
        switch theme.logo.shape {
        case .wordmark:
            Text(theme.logo.wordmark.uppercased())
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(color.color)
        case .badge:
            Text(theme.logo.wordmark.uppercased())
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle((theme.logo.foregroundColor ?? color.autoContrastingForeground).color)
                .padding(.vertical, 12).padding(.horizontal, 22)
                .background(Capsule().fill(color.color.opacity(theme.logo.fillOpacity)))
        case .monogram:
            Text(String(theme.logo.monogram))
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle((theme.logo.foregroundColor ?? .white).color)
                .frame(width: 70, height: 70)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(color.color.opacity(theme.logo.fillOpacity)))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(color.color, lineWidth: theme.logo.strokeWidth > 0 ? 2 : 0))
        case .ring:
            Circle().strokeBorder(color.color, lineWidth: 7).frame(width: 64, height: 64)
        case .pixelBlock:
            Text(String(theme.logo.wordmark.prefix(1)))
                .font(.system(size: 30, weight: .heavy, design: .monospaced))
                .foregroundStyle((theme.logo.foregroundColor ?? .black).color)
                .frame(width: 64, height: 64)
                .background(Rectangle().fill(color.color))
        }
    }
}

private struct ScanlineOverlay: View {
    var body: some View {
        GeometryReader { geo in
            let lines = Int(geo.size.height / 3)
            VStack(spacing: 2) {
                ForEach(0..<max(1, lines), id: \.self) { _ in
                    Color.black.opacity(0.12).frame(height: 1)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview("Themes") {
    ThemeGalleryView().injecting(.preview(themeID: .matrix))
}
