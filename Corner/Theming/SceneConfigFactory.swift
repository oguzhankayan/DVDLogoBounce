import Foundation
import CoreGraphics

/// Builds the immutable `SceneConfig` the SpriteKit engine consumes from the
/// live `AppSettings` + the resolved `Theme`. This is also where accessibility
/// preferences (Reduce Motion) get *blended in* once, so the engine only ever
/// sees finished numbers.
enum SceneConfigFactory {

    /// - Parameters:
    ///   - settings: the user's live settings.
    ///   - seed: deterministic placement seed (e.g. `SeededRandom.dailySeed()`
    ///     for the "daily seed", or a random value for a normal session).
    ///   - reduceMotionOverride: pass the system Reduce‑Motion flag; combined
    ///     with the in‑app `reduceMotion` toggle.
    @MainActor
    static func makeConfig(from settings: AppSettings,
                           seed: UInt64,
                           reduceMotionOverride: Bool = false) -> SceneConfig {
        var theme = settings.resolvedTheme
        // The bouncing badge shows the user's word; non‑badge themes ignore it.
        let name = settings.customLogoText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty { theme.logo.wordmark = name }
        let reduceMotion = settings.reduceMotion || reduceMotionOverride

        // Effective trail / glow combine the *theme's* intensity with the user's
        // slider so that, e.g., the slider does nothing on a theme whose trail is
        // off, and a glow‑heavy theme still respects a user who wants it dimmed.
        let trail = CGFloat(settings.trailIntensity)
        let glow = CGFloat(settings.glowIntensity)

        return SceneConfig(
            theme: theme,
            logoCount: settings.logoCount,
            speedMultiplier: CGFloat(settings.speed) * (reduceMotion ? 0.7 : 1.0),
            logoScale: CGFloat(settings.logoScale),
            interLogoCollisions: settings.interLogoCollisions && settings.logoCount > 1,
            trailIntensity: trail,
            glowIntensity: glow,
            motionBlur: reduceMotion ? 0 : CGFloat(settings.motionBlur),
            particleDensity: CGFloat(settings.particleDensity) * (reduceMotion ? 0.5 : 1.0),
            backgroundOverride: settings.customBackgroundEnabled ? settings.customBackgroundColor : nil,
            cornerParticlesEnabled: settings.cornerParticlesEnabled,
            screenShakeEnabled: settings.screenShakeEnabled && !settings.streamerModeEnabled && !reduceMotion,
            closeCallEffectsEnabled: settings.closeCallEffectsEnabled,
            // ~1.2% of the screen width feels right; let the engine widen it
            // further for very large displays.
            cornerCloseCallTolerance: 22,
            reduceMotion: reduceMotion,
            seed: seed
        )
    }
}
