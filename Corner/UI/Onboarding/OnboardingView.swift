import SwiftUI

/// First launch, one screen: the screensaver is already running behind a dim
/// scrim, and a single panel lets the viewer pick a look and start. No tour, no
/// pages — the product explains itself by being visible the whole time.
struct OnboardingView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var audio: AudioController
    @EnvironmentObject private var router: Router

    @FocusState private var focus: Focus?
    private enum Focus: Hashable { case name, theme(ThemeID), start }

    var body: some View {
        let accent = settings.resolvedTheme.collisionColor(at: 1).color
        ZStack {
            // A *light* frost: the bouncing badge stays visible behind the text,
            // just softened. (One purposeful glass surface, at half strength.)
            Rectangle().fill(.ultraThinMaterial).opacity(0.5).ignoresSafeArea()
            Color.black.opacity(0.22).ignoresSafeArea()
            LinearGradient(colors: [settings.resolvedTheme.background.baseColor.color.opacity(0.3), .clear],
                           startPoint: .leading, endPoint: .center)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 0)

                HStack(spacing: 16) {
                    Image(systemName: "play.fill").font(.system(size: 22, weight: .black))
                    Text("CORNER")
                        .font(.system(size: 64, weight: .heavy, design: .rounded))
                        .tracking(10)
                }
                Text("RETRO SCREENSAVER")
                    .font(.system(.headline, design: .rounded).weight(.bold)).tracking(6)
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.top, 6)
                Text("Leave it running for ambiance, nostalgia, and the perfect corner hit.")
                    .font(.system(.title3, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 640, alignment: .leading)
                    .padding(.top, 12)

                Text("YOUR NAME ON THE DISC")
                    .font(.system(.subheadline, design: .rounded).weight(.bold)).tracking(3)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 36).padding(.bottom, 12)
                HStack {
                    TextField("Your name", text: $settings.customLogoText)
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .focused($focus, equals: .name)
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 16).padding(.horizontal, 22)
                .frame(maxWidth: 560, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.black.opacity(0.4))
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(focus == .name ? accent : .white.opacity(0.14), lineWidth: focus == .name ? 2 : 1))
                }
                .focusSection()

                Text("CHOOSE A LOOK")
                    .font(.system(.subheadline, design: .rounded).weight(.bold)).tracking(3)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 36).padding(.bottom, 14)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 18) {
                        ForEach(ThemeCatalog.all) { theme in
                            Button {
                                audio.playUISelect()
                                settings.themeID = theme.id
                            } label: {
                                VStack(spacing: 10) {
                                    ThemeSwatch(theme: theme, size: 104, wordmark: settings.customLogoText)
                                        .overlay(alignment: .topTrailing) {
                                            if theme.id == settings.themeID {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 22))
                                                    .foregroundStyle(.white, theme.collisionColor(at: 1).color)
                                                    .padding(7)
                                            }
                                        }
                                    Text(theme.name).font(.system(.headline, design: .rounded).weight(.semibold))
                                }
                            }
                            .buttonStyle(CardButtonStyle(cornerRadius: 22, accent: theme.collisionColor(at: 1).color))
                            .focused($focus, equals: .theme(theme.id))
                        }
                    }
                    // Breathing room so the focused (scaled + glowing) swatch
                    // isn't clipped against the scroll view's edges.
                    .padding(.vertical, 18)
                    .padding(.leading, 28)
                    .padding(.trailing, 100)
                    // Treat the whole row as one focus section so pressing Down
                    // from *any* swatch reaches "Start watching", not just the
                    // one that happens to sit above the button.
                    .focusSection()
                }
                .frame(height: 234)

                Button { finish() } label: {
                    Text("Start watching").frame(minWidth: 240)
                }
                .buttonStyle(PrimaryButtonStyle(accent: accent))
                .focused($focus, equals: .start)
                .padding(.top, 36)
                .focusSection()

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 110)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .onAppear { focus = .name }   // the first thing: your word
        .onChange(of: focus) { _, new in if new != nil { audio.playUIFocus() } }
        .onExitCommand { finish() }   // Menu = "just start it"
    }

    private func finish() {
        audio.playUISelect()
        settings.hasCompletedOnboarding = true
        router.completeOnboarding()
    }
}

#Preview("Onboarding") {
    OnboardingView().injecting(.preview(themeID: .neon, onboarding: true))
}
