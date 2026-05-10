import SwiftUI

/// The top‑level layout: a live screensaver, an optional menu over it, and a
/// first‑launch onboarding cover. Everything fades; nothing slams.
struct RootView: View {
    @EnvironmentObject private var router: Router

    var body: some View {
        ZStack {
            ScreensaverView()

            if router.isMenuPresented {
                MenuOverlay()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal: .opacity))
                    .zIndex(10)
            }

            if router.inOnboarding {
                OnboardingView()
                    .transition(.opacity)
                    .zIndex(20)
            }
        }
        .animation(.easeInOut(duration: 0.42), value: router.isMenuPresented)
        .animation(.easeInOut(duration: 0.55), value: router.inOnboarding)
        .ignoresSafeArea()
    }
}

#Preview("Screensaver") {
    RootView().injecting(.preview(themeID: .synthwave))
}
