import SwiftUI

/// The "About" page — also the app's quiet statement of intent: an ambient
/// visualiser and a customizable retro screensaver, not a prank.
///
/// Nothing here is interactive, so each block is made (invisibly) focusable —
/// that's what lets the remote scroll the page and the menu capture the Menu
/// button. Without it, focus is stranded after the page transition and Menu
/// quits the app.
struct AboutView: View {
    @FocusState private var focused: Int?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                ScreenTitle(title: "About", subtitle: "Corner · Retro Screensaver · for Apple TV")

                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What this is")
                            .font(.system(.title2, design: .rounded).weight(.bold))
                        Text("""
                        The classic bouncing‑logo screensaver, scaled up for big modern TVs — with your \
                        own word on the badge. Leave it running for nostalgia, for relaxation, or for the \
                        small, real thrill of a perfect corner hit: six hand‑tuned themes, three display \
                        modes, on‑device statistics.
                        """)
                        .font(.system(.title3, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .scrollBlock($focused, 0)

                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Pricing").font(.system(.title2, design: .rounded).weight(.bold))
                        Label("Paid once, up front. No subscription.", systemImage: "checkmark.seal.fill")
                        Label("No ads.", systemImage: "checkmark.seal.fill")
                        Label("No account, no sign‑in.", systemImage: "checkmark.seal.fill")
                        Label("No analytics, no tracking. Your statistics never leave this Apple TV.", systemImage: "checkmark.seal.fill")
                    }
                    .font(.system(.title3, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                }
                .scrollBlock($focused, 1)

                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Tips").font(.system(.title2, design: .rounded).weight(.bold))
                        bullet("The bouncing badge shows the word from Customize → Logo. Make it your name, your channel, anything.")
                        bullet("Press Menu to open this menu; press it again to go back to the screensaver.")
                        bullet("Press Play/Pause to freeze the bounce.")
                        bullet("Streamer / ambient mode (in Customize) gives a clean stream background: no flashes, no banners.")
                        bullet("Shuffle layout re‑randomises where the logos start.")
                    }
                    .font(.system(.title3, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                }
                .scrollBlock($focused, 2)

                Color.clear.frame(height: 40)
            }
            .padding(.horizontal, 90)
            .padding(.vertical, 70)
            .frame(maxWidth: 1200, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .onAppear { DispatchQueue.main.async { focused = 0 } }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: "circle.fill").font(.system(size: 7)).foregroundStyle(.white.opacity(0.35))
            Text(text).multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Makes a non‑interactive block invisibly focusable so the remote can scroll
/// past it (and a parent `onExitCommand` keeps capturing the Menu button).
private extension View {
    func scrollBlock(_ binding: FocusState<Int?>.Binding, _ index: Int) -> some View {
        self.focusable().focusEffectDisabled().focused(binding, equals: index)
    }
}

#Preview("About") {
    AboutView().injecting(.preview(themeID: .vhs))
}
