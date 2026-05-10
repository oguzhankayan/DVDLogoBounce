import SwiftUI

/// First‑launch onboarding: four calm pages over a frosted, already‑running
/// screensaver. Sets the user up with a theme and explains the corner hit, then
/// gets out of the way.
struct OnboardingView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var audio: AudioController
    @EnvironmentObject private var router: Router

    @State private var page = 0
    @FocusState private var focus: Focus?
    private enum Focus: Hashable { case theme(ThemeID), back, primary }

    private let lastPage = 3

    var body: some View {
        let theme = settings.resolvedTheme
        ZStack {
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
            theme.background.baseColor.color.opacity(0.6).ignoresSafeArea()
            RadialGradient(colors: [.clear, .clear, .black.opacity(0.5)], center: .center, startRadius: 0, endRadius: 1500)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 0)
                Group {
                    switch page {
                    case 0: welcomePage
                    case 1: themePage
                    case 2: cornerPage
                    default: customizePage
                    }
                }
                .frame(maxWidth: 1200, alignment: .leading)
                .transition(.asymmetric(insertion: .opacity.combined(with: .offset(x: 24)),
                                        removal: .opacity.combined(with: .offset(x: -24))))
                Spacer(minLength: 0)
                controls
            }
            .padding(.horizontal, 110)
            .padding(.vertical, 90)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .animation(.easeInOut(duration: 0.4), value: page)
        .onAppear { focus = .primary }
        .onExitCommand { if page > 0 { withAnimation { page -= 1 }; focus = .primary } }
    }

    // MARK: Pages

    private var welcomePage: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("CORNER")
                .font(.system(size: 96, weight: .heavy, design: .rounded))
                .tracking(12)
            Text("A premium retro bouncing screensaver for Apple TV.")
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
            Text("Leave it running for ambiance, nostalgia, relaxation — and the small, real thrill of a perfect corner hit.")
                .font(.system(.title3, design: .rounded))
                .foregroundStyle(.tertiary)
                .frame(maxWidth: 760, alignment: .leading)
        }
    }

    private var themePage: some View {
        VStack(alignment: .leading, spacing: 24) {
            stepHeader("Pick a look", "You can change this anytime — and there are eight.")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 22) {
                    ForEach(ThemeCatalog.all) { t in
                        Button {
                            audio.playUISelect()
                            settings.themeID = t.id
                        } label: {
                            VStack(spacing: 12) {
                                ThemeSwatch(theme: t, size: 96)
                                Text(t.name).font(.system(.headline, design: .rounded).weight(.semibold))
                            }
                            .padding(10)
                            .overlay {
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .strokeBorder(t.id == settings.themeID ? .white.opacity(0.7) : .clear, lineWidth: 2)
                            }
                        }
                        .buttonStyle(CardButtonStyle(cornerRadius: 22, accent: t.collisionColor(at: 1).color))
                        .focused($focus, equals: .theme(t.id))
                    }
                }
                .padding(.vertical, 16)
            }
        }
    }

    private var cornerPage: some View {
        VStack(alignment: .leading, spacing: 22) {
            stepHeader("The corner hit", "Sooner or later the logo will strike a corner exactly. That's the moment.")
            HStack(spacing: 26) {
                onboardFeature("Counts every one", "Your total perfect corners are tracked forever, on this Apple TV.", "number")
                onboardFeature("Celebrates it", "An optional flash, a burst of particles, a soft chime, a tiny screen shake.", "sparkles")
                onboardFeature("Remembers the wait", "“Time since last perfect corner”, session streaks, and a per‑corner breakdown.", "clock.fill")
            }
        }
    }

    private var customizePage: some View {
        VStack(alignment: .leading, spacing: 22) {
            stepHeader("Make it yours", "Then leave it running.")
            HStack(spacing: 26) {
                onboardFeature("Tune everything", "Speed, logo size and count, trails, glow, motion blur, density — all live.", "slider.horizontal.3")
                onboardFeature("Set the mood", "Soft collision sounds, a VHS hum, a synth pad — or complete silence.", "speaker.wave.2.fill")
                onboardFeature("Streamer mode", "A clean background for a stream — no flashes, no banners, just the bounce.", "dot.radiowaves.left.and.right")
            }
        }
    }

    // MARK: Controls

    private var controls: some View {
        HStack(spacing: 16) {
            // Progress dots
            HStack(spacing: 10) {
                ForEach(0...lastPage, id: \.self) { i in
                    Circle()
                        .fill(i == page ? Color.white : Color.white.opacity(0.25))
                        .frame(width: i == page ? 12 : 8, height: i == page ? 12 : 8)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: page)
                }
            }
            Spacer()
            if page > 0 {
                Button {
                    audio.playUIBack()
                    withAnimation { page -= 1 }
                } label: { Label("Back", systemImage: "chevron.left").font(.system(.title3, design: .rounded).weight(.semibold)) }
                .buttonStyle(CardButtonStyle(cornerRadius: 18))
                .focused($focus, equals: .back)
            } else {
                Button {
                    finish()
                } label: { Text("Skip").font(.system(.title3, design: .rounded).weight(.semibold)) }
                .buttonStyle(CardButtonStyle(cornerRadius: 18))
                .focused($focus, equals: .back)
            }
            Button {
                if page < lastPage { audio.playUISelect(); withAnimation { page += 1 } }
                else { finish() }
            } label: {
                Text(page < lastPage ? "Next" : "Start")
                    .frame(minWidth: 140)
            }
            .buttonStyle(PrimaryButtonStyle(accent: settings.resolvedTheme.collisionColor(at: 1).color))
            .focused($focus, equals: .primary)
        }
        .padding(.top, 24)
    }

    private func finish() {
        audio.playUISelect()
        settings.hasCompletedOnboarding = true
        router.completeOnboarding()
    }

    // MARK: Bits

    private func stepHeader(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 56, weight: .heavy, design: .rounded))
            Text(subtitle).font(.system(.title3, design: .rounded)).foregroundStyle(.secondary)
        }
    }

    private func onboardFeature(_ title: String, _ body: String, _ symbol: String) -> some View {
        GlassCard(cornerRadius: 24, padding: 24) {
            VStack(alignment: .leading, spacing: 14) {
                Image(systemName: symbol).font(.system(size: 34, weight: .semibold)).foregroundStyle(.white.opacity(0.92))
                Text(title).font(.system(size: 24, weight: .heavy, design: .rounded))
                Text(body).font(.system(.callout, design: .rounded)).foregroundStyle(.secondary)
            }
            .frame(width: 300, height: 220, alignment: .leading)
        }
    }
}

#Preview("Onboarding") {
    OnboardingView().injecting(.preview(themeID: .synthwave, onboarding: true))
}
