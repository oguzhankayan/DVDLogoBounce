import SwiftUI

/// Constructs and holds the app‑lifetime singletons. Each is its own
/// `ObservableObject` and is injected into the SwiftUI environment separately so
/// views can observe exactly what they depend on.
@MainActor
final class AppEnvironment: ObservableObject {
    let settings: AppSettings
    let statistics: StatisticsStore
    let audio: AudioController
    let screensaver: ScreensaverViewModel
    let router: Router

    init(inMemory: Bool = false) {
        let settings = AppSettings(store: inMemory ? InMemorySettingsStore() : UserDefaultsSettingsStore())
        self.settings = settings
        let statistics = StatisticsStore(persisted: !inMemory)
        self.statistics = statistics
        let audio = AudioController(enabled: !inMemory)
        self.audio = audio
        self.screensaver = ScreensaverViewModel(settings: settings, statistics: statistics, audio: audio)
        self.router = Router(startInOnboarding: !settings.hasCompletedOnboarding)
    }

    /// A fully in‑memory environment for SwiftUI previews / UI tests.
    static func preview(themeID: ThemeID = .neon, onboarding: Bool = false) -> AppEnvironment {
        let env = AppEnvironment(inMemory: true)
        env.settings.themeID = themeID
        env.settings.hasCompletedOnboarding = !onboarding
        env.router.inOnboarding = onboarding
        return env
    }
}

extension View {
    /// Injects every app‑level `ObservableObject` from an `AppEnvironment`.
    func injecting(_ env: AppEnvironment) -> some View {
        self
            .environmentObject(env.settings)
            .environmentObject(env.statistics)
            .environmentObject(env.audio)
            .environmentObject(env.screensaver)
            .environmentObject(env.router)
    }
}
