import Foundation
import Combine

/// The single source of truth for everything the user can tune. Observed by the
/// SwiftUI screens *and* by the SpriteKit engine (via `ScreensaverViewModel`).
///
/// Persistence is handled by injecting a `SettingsPersisting` (see Persistence/
/// `SettingsStore`). During `init` and `apply(_:)` a guard suppresses the save
/// side‑effect so loading a snapshot doesn't immediately re‑write it.
@MainActor
public final class AppSettings: ObservableObject {

    // MARK: Ranges (shared by the Settings UI)

    public static let speedRange: ClosedRange<Double> = 0.2...3.0
    public static let logoScaleRange: ClosedRange<Double> = 0.4...2.6
    public static let logoCountRange: ClosedRange<Int> = 1...12
    public static let unitRange: ClosedRange<Double> = 0...1
    public static let autoHideDelayRange: ClosedRange<TimeInterval> = 4...20
    public static let volumeRange: ClosedRange<Double> = 0...1

    // MARK: Visual

    @Published public var themeID: ThemeID { didSet { persist() } }
    @Published public private(set) var displayMode: DisplayMode { didSet { persist() } }
    @Published public var logoCount: Int { didSet { clamp(&logoCount, Self.logoCountRange); persist() } }
    @Published public var speed: Double { didSet { clamp(&speed, Self.speedRange); persist() } }
    @Published public var logoScale: Double { didSet { clamp(&logoScale, Self.logoScaleRange); persist() } }
    @Published public var trailIntensity: Double { didSet { clamp(&trailIntensity, Self.unitRange); persist() } }
    @Published public var glowIntensity: Double { didSet { clamp(&glowIntensity, Self.unitRange); persist() } }
    @Published public var motionBlur: Double { didSet { clamp(&motionBlur, Self.unitRange); persist() } }
    /// "Screensaver density" — scales ambient particle counts & bounce bursts.
    @Published public var particleDensity: Double { didSet { clamp(&particleDensity, Self.unitRange); persist() } }
    @Published public var interLogoCollisions: Bool { didSet { persist() } }
    @Published public var customBackgroundEnabled: Bool { didSet { persist() } }
    @Published public var customBackgroundColor: RGBA { didSet { persist() } }

    // MARK: Corner‑hit payoff

    @Published public var cornerFlashEnabled: Bool { didSet { persist() } }
    @Published public var cornerParticlesEnabled: Bool { didSet { persist() } }
    /// tvOS has no haptics — this is the screen‑pulse "vibration simulation".
    @Published public var screenShakeEnabled: Bool { didSet { persist() } }
    @Published public var cornerSoundEnabled: Bool { didSet { persist() } }
    @Published public var closeCallEffectsEnabled: Bool { didSet { persist() } }
    /// The on‑screen corner counter / "time since last perfect corner" HUD.
    @Published public var hudEnabled: Bool { didSet { persist() } }

    // MARK: Audio

    @Published public var soundEffectsEnabled: Bool { didSet { persist() } }
    @Published public var ambientMode: AmbientMode { didSet { persist() } }
    @Published public var sfxVolume: Double { didSet { clamp(&sfxVolume, Self.volumeRange); persist() } }
    @Published public var ambientVolume: Double { didSet { clamp(&ambientVolume, Self.volumeRange); persist() } }

    // MARK: Experience / UX

    @Published public var autoHideUI: Bool { didSet { persist() } }
    @Published public var autoHideDelay: TimeInterval { didSet { clamp(&autoHideDelay, Self.autoHideDelayRange); persist() } }
    @Published public var reduceMotion: Bool { didSet { persist() } }
    /// Streamer / "ambient" mode: never auto‑hide *into* a menu, never flash —
    /// just the screensaver, forever, until the user explicitly opens the menu.
    @Published public var streamerModeEnabled: Bool { didSet { persist() } }
    @Published public var hasCompletedOnboarding: Bool { didSet { persist() } }

    // MARK: Persistence plumbing

    private let store: SettingsPersisting
    private var isApplyingSnapshot = false
    private var saveCancellable: AnyCancellable?
    private let saveSubject = PassthroughSubject<Void, Never>()

    public init(store: SettingsPersisting = InMemorySettingsStore()) {
        self.store = store
        let s = store.load() ?? .defaults

        themeID = s.themeID
        displayMode = s.displayMode
        logoCount = s.logoCount
        speed = s.speed
        logoScale = s.logoScale
        trailIntensity = s.trailIntensity
        glowIntensity = s.glowIntensity
        motionBlur = s.motionBlur
        particleDensity = s.particleDensity
        interLogoCollisions = s.interLogoCollisions
        customBackgroundEnabled = s.customBackgroundEnabled
        customBackgroundColor = s.customBackgroundColor
        cornerFlashEnabled = s.cornerFlashEnabled
        cornerParticlesEnabled = s.cornerParticlesEnabled
        screenShakeEnabled = s.screenShakeEnabled
        cornerSoundEnabled = s.cornerSoundEnabled
        closeCallEffectsEnabled = s.closeCallEffectsEnabled
        hudEnabled = s.hudEnabled
        soundEffectsEnabled = s.soundEffectsEnabled
        ambientMode = s.ambientMode
        sfxVolume = s.sfxVolume
        ambientVolume = s.ambientVolume
        autoHideUI = s.autoHideUI
        autoHideDelay = s.autoHideDelay
        reduceMotion = s.reduceMotion
        streamerModeEnabled = s.streamerModeEnabled
        hasCompletedOnboarding = s.hasCompletedOnboarding

        // Coalesce rapid slider changes into one disk write.
        saveCancellable = saveSubject
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)
            .sink { [weak self] in
                guard let self else { return }
                self.store.save(self.snapshot)
            }
    }

    // MARK: Snapshot

    public var snapshot: Snapshot {
        Snapshot(
            themeID: themeID, displayMode: displayMode, logoCount: logoCount,
            speed: speed, logoScale: logoScale, trailIntensity: trailIntensity,
            glowIntensity: glowIntensity, motionBlur: motionBlur,
            particleDensity: particleDensity, interLogoCollisions: interLogoCollisions,
            customBackgroundEnabled: customBackgroundEnabled,
            customBackgroundColor: customBackgroundColor,
            cornerFlashEnabled: cornerFlashEnabled,
            cornerParticlesEnabled: cornerParticlesEnabled,
            screenShakeEnabled: screenShakeEnabled,
            cornerSoundEnabled: cornerSoundEnabled,
            closeCallEffectsEnabled: closeCallEffectsEnabled,
            hudEnabled: hudEnabled, soundEffectsEnabled: soundEffectsEnabled,
            ambientMode: ambientMode, sfxVolume: sfxVolume, ambientVolume: ambientVolume,
            autoHideUI: autoHideUI, autoHideDelay: autoHideDelay,
            reduceMotion: reduceMotion, streamerModeEnabled: streamerModeEnabled,
            hasCompletedOnboarding: hasCompletedOnboarding
        )
    }

    public func apply(_ s: Snapshot) {
        isApplyingSnapshot = true
        themeID = s.themeID
        displayMode = s.displayMode
        logoCount = s.logoCount
        speed = s.speed
        logoScale = s.logoScale
        trailIntensity = s.trailIntensity
        glowIntensity = s.glowIntensity
        motionBlur = s.motionBlur
        particleDensity = s.particleDensity
        interLogoCollisions = s.interLogoCollisions
        customBackgroundEnabled = s.customBackgroundEnabled
        customBackgroundColor = s.customBackgroundColor
        cornerFlashEnabled = s.cornerFlashEnabled
        cornerParticlesEnabled = s.cornerParticlesEnabled
        screenShakeEnabled = s.screenShakeEnabled
        cornerSoundEnabled = s.cornerSoundEnabled
        closeCallEffectsEnabled = s.closeCallEffectsEnabled
        hudEnabled = s.hudEnabled
        soundEffectsEnabled = s.soundEffectsEnabled
        ambientMode = s.ambientMode
        sfxVolume = s.sfxVolume
        ambientVolume = s.ambientVolume
        autoHideUI = s.autoHideUI
        autoHideDelay = s.autoHideDelay
        reduceMotion = s.reduceMotion
        streamerModeEnabled = s.streamerModeEnabled
        hasCompletedOnboarding = s.hasCompletedOnboarding
        isApplyingSnapshot = false
        persist()
    }

    public func resetToDefaults() { apply(.defaults) }

    // MARK: Display mode

    /// Switch display mode and re‑seed the affected sliders. Tweaking individual
    /// sliders afterwards is fine — the mode just records the chosen preset.
    public func applyMode(_ mode: DisplayMode) {
        isApplyingSnapshot = true
        let seed = mode.seed
        logoCount = seed.logoCount
        speed = seed.speed
        trailIntensity = seed.trailIntensity
        motionBlur = seed.motionBlur
        interLogoCollisions = seed.interLogoCollisions
        particleDensity = seed.particleDensity
        isApplyingSnapshot = false
        displayMode = mode   // triggers a single persist()
    }

    // MARK: Derived

    /// Resolves `.matchTheme` against the active theme's suggestion.
    public func effectiveAmbientMode(for theme: Theme) -> AmbientMode {
        ambientMode == .matchTheme ? theme.audio.suggestedAmbient : ambientMode
    }

    /// In streamer mode we suppress the bright flash but keep particles.
    public var cornerFlashIsActive: Bool { cornerFlashEnabled && !streamerModeEnabled }

    // MARK: Helpers

    private func persist() {
        guard !isApplyingSnapshot else { return }
        saveSubject.send(())
    }

    private func clamp<T: Comparable>(_ value: inout T, _ range: ClosedRange<T>) {
        let c = value.clamped(to: range)
        if c != value { value = c }   // re‑enters didSet once with a settled value
    }

    // MARK: Codable snapshot

    public struct Snapshot: Codable, Hashable, Sendable {
        public var themeID: ThemeID
        public var displayMode: DisplayMode
        public var logoCount: Int
        public var speed: Double
        public var logoScale: Double
        public var trailIntensity: Double
        public var glowIntensity: Double
        public var motionBlur: Double
        public var particleDensity: Double
        public var interLogoCollisions: Bool
        public var customBackgroundEnabled: Bool
        public var customBackgroundColor: RGBA
        public var cornerFlashEnabled: Bool
        public var cornerParticlesEnabled: Bool
        public var screenShakeEnabled: Bool
        public var cornerSoundEnabled: Bool
        public var closeCallEffectsEnabled: Bool
        public var hudEnabled: Bool
        public var soundEffectsEnabled: Bool
        public var ambientMode: AmbientMode
        public var sfxVolume: Double
        public var ambientVolume: Double
        public var autoHideUI: Bool
        public var autoHideDelay: TimeInterval
        public var reduceMotion: Bool
        public var streamerModeEnabled: Bool
        public var hasCompletedOnboarding: Bool

        public static let defaults = Snapshot(
            themeID: .classicDVD,
            displayMode: .single,
            logoCount: 1,
            speed: 1.0,
            logoScale: 1.0,
            trailIntensity: 0.35,
            glowIntensity: 0.5,
            motionBlur: 0.15,
            particleDensity: 0.5,
            interLogoCollisions: false,
            customBackgroundEnabled: false,
            customBackgroundColor: RGBA(hex: "#05060A"),
            cornerFlashEnabled: true,
            cornerParticlesEnabled: true,
            screenShakeEnabled: true,
            cornerSoundEnabled: true,
            closeCallEffectsEnabled: true,
            hudEnabled: true,
            soundEffectsEnabled: true,
            ambientMode: .matchTheme,
            sfxVolume: 0.6,
            ambientVolume: 0.4,
            autoHideUI: true,
            autoHideDelay: 8,
            reduceMotion: false,
            streamerModeEnabled: false,
            hasCompletedOnboarding: false
        )

        // Tolerant decoding: any key added in a future build defaults sensibly.
        public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            let d = Snapshot.defaults
            func dec<T: Decodable>(_ key: CodingKeys, _ fallback: T) -> T {
                (try? c.decode(T.self, forKey: key)) ?? fallback
            }
            themeID = dec(.themeID, d.themeID)
            displayMode = dec(.displayMode, d.displayMode)
            logoCount = dec(.logoCount, d.logoCount)
            speed = dec(.speed, d.speed)
            logoScale = dec(.logoScale, d.logoScale)
            trailIntensity = dec(.trailIntensity, d.trailIntensity)
            glowIntensity = dec(.glowIntensity, d.glowIntensity)
            motionBlur = dec(.motionBlur, d.motionBlur)
            particleDensity = dec(.particleDensity, d.particleDensity)
            interLogoCollisions = dec(.interLogoCollisions, d.interLogoCollisions)
            customBackgroundEnabled = dec(.customBackgroundEnabled, d.customBackgroundEnabled)
            customBackgroundColor = dec(.customBackgroundColor, d.customBackgroundColor)
            cornerFlashEnabled = dec(.cornerFlashEnabled, d.cornerFlashEnabled)
            cornerParticlesEnabled = dec(.cornerParticlesEnabled, d.cornerParticlesEnabled)
            screenShakeEnabled = dec(.screenShakeEnabled, d.screenShakeEnabled)
            cornerSoundEnabled = dec(.cornerSoundEnabled, d.cornerSoundEnabled)
            closeCallEffectsEnabled = dec(.closeCallEffectsEnabled, d.closeCallEffectsEnabled)
            hudEnabled = dec(.hudEnabled, d.hudEnabled)
            soundEffectsEnabled = dec(.soundEffectsEnabled, d.soundEffectsEnabled)
            ambientMode = dec(.ambientMode, d.ambientMode)
            sfxVolume = dec(.sfxVolume, d.sfxVolume)
            ambientVolume = dec(.ambientVolume, d.ambientVolume)
            autoHideUI = dec(.autoHideUI, d.autoHideUI)
            autoHideDelay = dec(.autoHideDelay, d.autoHideDelay)
            reduceMotion = dec(.reduceMotion, d.reduceMotion)
            streamerModeEnabled = dec(.streamerModeEnabled, d.streamerModeEnabled)
            hasCompletedOnboarding = dec(.hasCompletedOnboarding, d.hasCompletedOnboarding)
        }

        public init(
            themeID: ThemeID, displayMode: DisplayMode, logoCount: Int, speed: Double,
            logoScale: Double, trailIntensity: Double, glowIntensity: Double,
            motionBlur: Double, particleDensity: Double, interLogoCollisions: Bool,
            customBackgroundEnabled: Bool, customBackgroundColor: RGBA,
            cornerFlashEnabled: Bool, cornerParticlesEnabled: Bool, screenShakeEnabled: Bool,
            cornerSoundEnabled: Bool, closeCallEffectsEnabled: Bool, hudEnabled: Bool,
            soundEffectsEnabled: Bool, ambientMode: AmbientMode, sfxVolume: Double,
            ambientVolume: Double, autoHideUI: Bool, autoHideDelay: TimeInterval,
            reduceMotion: Bool, streamerModeEnabled: Bool, hasCompletedOnboarding: Bool
        ) {
            self.themeID = themeID
            self.displayMode = displayMode
            self.logoCount = logoCount
            self.speed = speed
            self.logoScale = logoScale
            self.trailIntensity = trailIntensity
            self.glowIntensity = glowIntensity
            self.motionBlur = motionBlur
            self.particleDensity = particleDensity
            self.interLogoCollisions = interLogoCollisions
            self.customBackgroundEnabled = customBackgroundEnabled
            self.customBackgroundColor = customBackgroundColor
            self.cornerFlashEnabled = cornerFlashEnabled
            self.cornerParticlesEnabled = cornerParticlesEnabled
            self.screenShakeEnabled = screenShakeEnabled
            self.cornerSoundEnabled = cornerSoundEnabled
            self.closeCallEffectsEnabled = closeCallEffectsEnabled
            self.hudEnabled = hudEnabled
            self.soundEffectsEnabled = soundEffectsEnabled
            self.ambientMode = ambientMode
            self.sfxVolume = sfxVolume
            self.ambientVolume = ambientVolume
            self.autoHideUI = autoHideUI
            self.autoHideDelay = autoHideDelay
            self.reduceMotion = reduceMotion
            self.streamerModeEnabled = streamerModeEnabled
            self.hasCompletedOnboarding = hasCompletedOnboarding
        }
    }
}

/// Persistence seam for `AppSettings`. The concrete `UserDefaults` implementation
/// is `UserDefaultsSettingsStore` in the Persistence layer; the in‑memory one is
/// the default so previews and tests need no setup.
public protocol SettingsPersisting: AnyObject, Sendable {
    func load() -> AppSettings.Snapshot?
    func save(_ snapshot: AppSettings.Snapshot)
}

public final class InMemorySettingsStore: SettingsPersisting, @unchecked Sendable {
    private var stored: AppSettings.Snapshot?
    public init(_ initial: AppSettings.Snapshot? = nil) { stored = initial }
    public func load() -> AppSettings.Snapshot? { stored }
    public func save(_ snapshot: AppSettings.Snapshot) { stored = snapshot }
}
