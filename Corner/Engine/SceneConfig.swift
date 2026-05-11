import Foundation
import CoreGraphics

/// An immutable snapshot of everything `BounceScene` needs to render a frame.
/// Built by `ScreensaverViewModel` from `AppSettings` + the resolved `Theme`
/// (and any accessibility tweaks already folded in), then handed to the scene.
/// Keeping this a plain value type means the scene never touches `@MainActor`
/// Combine objects directly and is trivial to drive from tests.
public struct SceneConfig: Equatable, Sendable {

    public var theme: Theme

    // Counts & motion
    public var logoCount: Int
    /// Multiplies the engine's reference speed. 1.0 == "classic" pace.
    public var speedMultiplier: CGFloat
    /// Multiplies the theme's base logo edge length.
    public var logoScale: CGFloat
    public var interLogoCollisions: Bool

    // Look
    /// Effective trail amount (already combined with the theme's own intensity).
    public var trailIntensity: CGFloat
    /// Effective glow amount (already combined with the theme's own intensity).
    public var glowIntensity: CGFloat
    /// 0…1 — drives a short ghosting smear independent of the trail.
    public var motionBlur: CGFloat
    /// 0…1 — scales ambient particle counts and bounce bursts.
    public var particleDensity: CGFloat
    /// `nil` ⇒ use the theme background; otherwise this colour replaces the
    /// theme's base background colour (gradients collapse to it).
    public var backgroundOverride: RGBA?

    // Corner‑hit payoff
    public var cornerParticlesEnabled: Bool
    public var screenShakeEnabled: Bool
    public var closeCallEffectsEnabled: Bool
    /// How close (in points) the *trailing* edge must be to its wall, at the
    /// moment of a single‑axis bounce, to count as a "close call".
    public var cornerCloseCallTolerance: CGFloat

    // Misc
    public var reduceMotion: Bool
    /// Deterministic placement seed.
    public var seed: UInt64

    public init(
        theme: Theme,
        logoCount: Int,
        speedMultiplier: CGFloat,
        logoScale: CGFloat,
        interLogoCollisions: Bool,
        trailIntensity: CGFloat,
        glowIntensity: CGFloat,
        motionBlur: CGFloat,
        particleDensity: CGFloat,
        backgroundOverride: RGBA?,
        cornerParticlesEnabled: Bool,
        screenShakeEnabled: Bool,
        closeCallEffectsEnabled: Bool,
        cornerCloseCallTolerance: CGFloat,
        reduceMotion: Bool,
        seed: UInt64
    ) {
        self.theme = theme
        self.logoCount = max(1, logoCount)
        self.speedMultiplier = max(0.01, speedMultiplier)
        self.logoScale = max(0.1, logoScale)
        self.interLogoCollisions = interLogoCollisions
        self.trailIntensity = trailIntensity.clamped(to: 0...1)
        self.glowIntensity = glowIntensity.clamped(to: 0...1)
        self.motionBlur = motionBlur.clamped(to: 0...1)
        self.particleDensity = particleDensity.clamped(to: 0...1)
        self.backgroundOverride = backgroundOverride
        self.cornerParticlesEnabled = cornerParticlesEnabled
        self.screenShakeEnabled = screenShakeEnabled
        self.closeCallEffectsEnabled = closeCallEffectsEnabled
        self.cornerCloseCallTolerance = max(0, cornerCloseCallTolerance)
        self.reduceMotion = reduceMotion
        self.seed = seed
    }

    /// What a frame of the engine should look like at "speed 1": fast enough to
    /// feel alive on a 65" TV, slow enough to be ambient. Expressed as a fraction
    /// of the geometric mean of the screen dimensions, per second.
    public static let referenceSpeedFraction: CGFloat = 0.135

    public func referenceSpeed(forSceneSize size: CGSize) -> CGFloat {
        let base = (max(1, size.width) * max(1, size.height)).squareRoot()
        return base * Self.referenceSpeedFraction
    }

    /// Resolved background base colour.
    public var backgroundBaseColor: RGBA { backgroundOverride ?? theme.background.baseColor }

    /// A preview / placeholder config so SwiftUI previews and the default scene
    /// have something sensible before settings load.
    public static let preview = SceneConfig(
        theme: ThemeCatalog.classicDVD,
        logoCount: 1,
        speedMultiplier: 1.0,
        logoScale: 1.0,
        interLogoCollisions: false,
        trailIntensity: 0.35,
        glowIntensity: 0.5,
        motionBlur: 0.15,
        particleDensity: 0.5,
        backgroundOverride: nil,
        cornerParticlesEnabled: true,
        screenShakeEnabled: true,
        closeCallEffectsEnabled: true,
        cornerCloseCallTolerance: 26,
        reduceMotion: false,
        seed: 0xC0FFEE
    )
}
