import SwiftUI
import SpriteKit
import UIKit

/// Hosts the live `BounceScene` and the lightweight, auto‑hiding chrome that
/// sits over it: the HUD, the corner‑hit flash, the transient "perfect corner"
/// banner, and a paused overlay. Owns the Siri Remote command handling for the
/// screensaver state (Menu opens the menu, Play/Pause toggles motion, any swipe
/// reveals the HUD briefly).
struct ScreensaverView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var statistics: StatisticsStore
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var vm: ScreensaverViewModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var hudVisible = true
    @State private var hudHideWork: DispatchWorkItem?
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            SpriteView(scene: vm.scene,
                       transition: nil,
                       isPaused: vm.isPaused,
                       options: [.shouldCullNonVisibleNodes],
                       debugOptions: [])
                .ignoresSafeArea()
                .accessibilityHidden(true)

            CornerFlashView(flash: vm.cornerFlash)
                .allowsHitTesting(false)
                .ignoresSafeArea()

            if showHUD {
                HUDView(visible: hudVisible, lastEvent: vm.lastCornerEvent)
                    .environmentObject(statistics)
                    .allowsHitTesting(false)
                    .padding(72)
                    .transition(.opacity)
            }

            if let banner = vm.transientBanner, !settings.streamerModeEnabled {
                CornerBannerView(banner: banner)
                    .allowsHitTesting(false)
                    .id(banner.id)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }

            if vm.isPaused {
                pausedOverlay.transition(.opacity)
            }
        }
        .ignoresSafeArea()
        // Only focusable when it's the active layer. When the menu or onboarding
        // is up, a focusable full‑screen view underneath them steals directional
        // input from their controls (focus "vanishes" when you press an arrow).
        .focusable(!router.isMenuPresented && !router.inOnboarding)
        .focused($focused)
        .onExitCommand { router.handleExitCommand() }
        .onPlayPauseCommand { vm.setPaused(!vm.isPaused) }
        .onMoveCommand { _ in pokeHUD() }
        .onAppear {
            vm.start(reduceMotion: reduceMotion)
            // This *is* the screensaver, so don't let tvOS dim the screen or
            // bring up its own screensaver over it. (Restored when backgrounded.)
            UIApplication.shared.isIdleTimerDisabled = true
            if !router.inOnboarding { focused = true }
            pokeHUD()
        }
        .onChange(of: settings.snapshot) { _, _ in vm.refresh(reduceMotion: reduceMotion) }
        .onChange(of: reduceMotion) { _, _ in vm.refresh(reduceMotion: reduceMotion) }
        .onChange(of: router.isMenuPresented) { _, presented in
            if presented { vm.setPaused(false) } else { focused = true; pokeHUD() }
        }
        .onChange(of: router.inOnboarding) { _, inOnboarding in
            if !inOnboarding { focused = true; pokeHUD() }
        }
        // A perfect corner flashes the HUD (you want to see the new total); a
        // "so close" near‑miss shows only its own banner — no counter, no controls.
        .onChange(of: vm.transientBanner) { _, banner in
            if banner?.kind == .perfectCorner { pokeHUD() }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                vm.appDidBecomeActive()
                UIApplication.shared.isIdleTimerDisabled = true
            case .inactive, .background:
                vm.appWillResignActive()
                UIApplication.shared.isIdleTimerDisabled = false
            @unknown default:
                break
            }
        }
        .animation(.easeInOut(duration: 0.45), value: vm.isPaused)
        .animation(.easeInOut(duration: 0.3), value: vm.transientBanner)
    }

    private var showHUD: Bool {
        settings.hudEnabled && !settings.streamerModeEnabled && !router.isMenuPresented && !router.inOnboarding
    }

    private func pokeHUD() {
        withAnimation(.easeInOut(duration: 0.35)) { hudVisible = true }
        hudHideWork?.cancel()
        guard settings.autoHideUI else { return }
        let work = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.9)) { hudVisible = false }
        }
        hudHideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + max(4, settings.autoHideDelay), execute: work)
    }

    private var pausedOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            GlassCard(cornerRadius: 32, padding: 48) {
                VStack(spacing: 14) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 56, weight: .bold))
                    Text("Paused")
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                    Text("Press Play/Pause to resume · Press Menu for options")
                        .font(.system(.title3, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
    }
}

// MARK: - Transient corner banner

struct CornerBannerView: View {
    let banner: ScreensaverViewModel.TransientBanner
    @State private var appear = false

    private var isPerfect: Bool { banner.kind == .perfectCorner }

    var body: some View {
        VStack(spacing: 10) {
            Text(isPerfect ? "PERFECT CORNER" : "so close…")
                .font(.system(size: isPerfect ? 40 : 30, weight: .heavy, design: .rounded))
                .tracking(isPerfect ? 6 : 2)
            HStack(spacing: 10) {
                Image(systemName: banner.corner.symbolName)
                Text(banner.corner.displayName)
            }
            .font(.system(.title3, design: .rounded).weight(.semibold))
            .foregroundStyle(.white.opacity(0.65))
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 40)
        .background {
            Capsule().fill(Color.black.opacity(0.55))
                .overlay(Capsule().strokeBorder(.white.opacity(isPerfect ? 0.4 : 0.14), lineWidth: 1))
        }
        .shadow(color: .white.opacity(isPerfect ? 0.25 : 0), radius: 30)
        .scaleEffect(appear ? 1 : 0.9)
        .opacity(appear ? 1 : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 90)
        .onAppear { withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) { appear = true } }
    }
}

#Preview {
    ScreensaverView().injecting(.preview(themeID: .neon))
}
