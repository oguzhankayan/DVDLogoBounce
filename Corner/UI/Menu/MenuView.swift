import SwiftUI

// MARK: - Overlay container

/// The shallow menu overlay. Switches between the menu home and the four detail
/// pages, all over a frosted view of the still‑running screensaver tinted with
/// the active theme. Back‑button handling is centralised here.
struct MenuOverlay: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var router: Router

    var body: some View {
        let theme = settings.resolvedTheme
        ZStack {
            // Frost the live scene behind, then a soft theme‑tinted scrim.
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
            theme.background.baseColor.color.opacity(0.55).ignoresSafeArea()
            if theme.background.vignette > 0.001 {
                RadialGradient(colors: [.clear, .clear, .black.opacity(min(0.6, theme.background.vignette))],
                               center: .center, startRadius: 0, endRadius: 1500)
                    .ignoresSafeArea()
            }

            Group {
                switch router.menuPage {
                case .home:       MainMenuView()
                case .themes:     ThemeGalleryView()
                case .customize:  SettingsView()
                case .statistics: StatisticsView()
                case .about:      AboutView()
                }
            }
            .transition(.opacity)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .animation(.easeInOut(duration: 0.3), value: router.menuPage)
        .onExitCommand { router.handleExitCommand() }
    }
}

// MARK: - Menu home

struct MainMenuView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var statistics: StatisticsStore
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var audio: AudioController
    @EnvironmentObject private var vm: ScreensaverViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focus: Focusable?

    private enum Focusable: Hashable { case card(Router.MenuPage), shuffle, resume }

    var body: some View {
        let theme = settings.resolvedTheme
        VStack(alignment: .leading, spacing: 0) {
            // Wordmark + tagline
            VStack(alignment: .leading, spacing: 6) {
                Text("CORNER")
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .tracking(8)
                Text("A premium retro bouncing screensaver")
                    .font(.system(.title3, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 44)

            // Big horizontal cards
            HStack(spacing: 26) {
                MenuCard(title: "Themes", subtitle: theme.name, systemImage: "paintpalette.fill",
                         accent: theme.collisionColor(at: 1).color) { router.go(to: .themes) }
                    .focused($focus, equals: .card(.themes))
                MenuCard(title: "Customize", subtitle: "Speed · size · trails · glow", systemImage: "slider.horizontal.3",
                         accent: .white) { router.go(to: .customize) }
                    .focused($focus, equals: .card(.customize))
                MenuCard(title: "Statistics", subtitle: "\(Format.count(statistics.stats.totalCornerHits)) perfect corners", systemImage: "chart.bar.fill",
                         accent: .white) { router.go(to: .statistics) }
                    .focused($focus, equals: .card(.statistics))
                MenuCard(title: "About", subtitle: "What this is · monetization", systemImage: "info.circle.fill",
                         accent: .white) { router.go(to: .about) }
                    .focused($focus, equals: .card(.about))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 32)

            // Footer row
            HStack(spacing: 18) {
                Button {
                    audio.playUISelect()
                    vm.reseed(reduceMotion: reduceMotion)
                } label: {
                    Label("Shuffle layout", systemImage: "shuffle")
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                }
                .buttonStyle(CardButtonStyle(cornerRadius: 18))
                .focused($focus, equals: .shuffle)

                Button {
                    audio.playUIBack()
                    router.dismissMenu()
                } label: {
                    Label("Resume screensaver", systemImage: "play.fill")
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                }
                .buttonStyle(CardButtonStyle(cornerRadius: 18))
                .focused($focus, equals: .resume)

                Spacer()

                InfoChip(text: "\(settings.displayMode.displayName) mode", systemImage: "rectangle.3.group")
                InfoChip(text: settings.soundEffectsEnabled ? "Sound on" : "Sound off",
                         systemImage: settings.soundEffectsEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
            }
        }
        .padding(.horizontal, 90)
        .padding(.vertical, 80)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear { if focus == nil { focus = .card(.themes) } }
        .onChange(of: focus) { _, new in if new != nil { audio.playUIFocus() } }
    }
}

// MARK: - Menu card

private struct MenuCard: View {
    var title: String
    var subtitle: String
    var systemImage: String
    var accent: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: systemImage)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(accent)
                Spacer(minLength: 8)
                Text(title)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                Text(subtitle)
                    .font(.system(.callout, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(width: 300, height: 220, alignment: .leading)
        }
        .buttonStyle(CardButtonStyle(cornerRadius: 26, accent: accent))
    }
}

#Preview("Menu") {
    let env = AppEnvironment.preview(themeID: .synthwave)
    env.router.presentMenu()
    return MenuOverlay().injecting(env)
}
