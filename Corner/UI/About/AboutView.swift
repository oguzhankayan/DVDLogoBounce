import SwiftUI

/// The "About" page — also the app's quiet statement of intent: this is an
/// ambient visualiser and a customizable retro screensaver, not a prank.
struct AboutView: View {
    @EnvironmentObject private var settings: AppSettings

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                ScreenTitle(title: "About Corner", subtitle: "A premium retro bouncing screensaver experience for Apple TV.")

                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What this is")
                            .font(.system(.title2, design: .rounded).weight(.bold))
                        Text("""
                        Corner is an ambient visualiser inspired by the bouncing DVD‑logo screensaver — \
                        rebuilt for big modern TVs. Leave it running for nostalgia, for relaxation, for the \
                        soft hum of a synth pad, or for the small, genuine thrill of a perfect corner hit. \
                        It is not a joke app: there are eight hand‑tuned themes, deep customization, multiple \
                        display modes, an ambient audio system, on‑device statistics, and a careful, quiet UI.
                        """)
                        .font(.system(.title3, design: .rounded))
                        .foregroundStyle(.secondary)
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Honest pricing").font(.system(.title2, design: .rounded).weight(.bold))
                        Label("Paid once, up front — no subscription.", systemImage: "checkmark.seal.fill")
                        Label("No ads. Ever.", systemImage: "checkmark.seal.fill")
                        Label("No account. No sign‑in.", systemImage: "checkmark.seal.fill")
                        Label("No analytics, no tracking — your statistics never leave this Apple TV.", systemImage: "checkmark.seal.fill")
                    }
                    .font(.system(.title3, design: .rounded))
                    .foregroundStyle(.secondary)
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tips").font(.system(.title2, design: .rounded).weight(.bold))
                        bullet("Press the Menu button anytime to open this menu; press it again to return to the screensaver.")
                        bullet("Press Play/Pause to freeze the bounce.")
                        bullet("Turn on Streamer / ambient mode (in Customize) for a clean stream background — no flashes, no banners.")
                        bullet("Use Shuffle layout on the menu to re‑roll the starting positions.")
                    }
                    .font(.system(.title3, design: .rounded))
                    .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    InfoChip(text: "Version \(version)", systemImage: "number")
                    InfoChip(text: "Current theme: \(settings.resolvedTheme.name)", systemImage: "paintpalette")
                    InfoChip(text: "tvOS · SwiftUI · SpriteKit", systemImage: "tv")
                }

                Text("“Corner” · also explored: Bounce TV · Retro Bounce · Pixel Drift · Neon Bounce · Infinite Bounce · VHS Drift")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.tertiary)

                Color.clear.frame(height: 40)
            }
            .padding(.horizontal, 90)
            .padding(.vertical, 70)
            .frame(maxWidth: 1200, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: "circle.fill").font(.system(size: 7)).foregroundStyle(.tertiary)
            Text(text)
        }
    }
}

#Preview("About") {
    AboutView().injecting(.preview(themeID: .glassmorphism))
}
