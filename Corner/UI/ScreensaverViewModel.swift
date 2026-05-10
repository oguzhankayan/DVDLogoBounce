import SwiftUI
import SpriteKit
import Combine

/// Owns the live `BounceScene`, bridges its events to `StatisticsStore` /
/// `AudioController`, and republishes the bits of state SwiftUI overlays need
/// (pause state, the corner‑hit flash trigger, a "last event" ticker for the HUD).
@MainActor
final class ScreensaverViewModel: ObservableObject, BounceSceneDelegate {

    let scene: BounceScene

    @Published var isPaused: Bool = false
    /// Bumped on every perfect corner hit; `CornerFlashView` keys its animation
    /// off this. Carries which corner so the flash can originate there.
    @Published private(set) var cornerFlash: CornerFlash?
    /// A short, transient banner the HUD can show ("PERFECT CORNER", "so close…").
    @Published private(set) var transientBanner: TransientBanner?
    /// Last corner event (perfect or close) for the HUD's recent line.
    @Published private(set) var lastCornerEvent: CornerHitEvent?

    private let settings: AppSettings
    private let statistics: StatisticsStore
    private let audio: AudioController

    /// Placement seed for this run.
    private(set) var seed: UInt64 = .random(in: 1...UInt64.max)
    private var hasStarted = false
    private var bannerClearWorkItem: DispatchWorkItem?

    struct CornerFlash: Equatable {
        var id: Int
        var corner: ScreenCorner
        var color: RGBA
    }
    struct TransientBanner: Equatable {
        enum Kind { case perfectCorner, closeCall }
        var id: Int
        var kind: Kind
        var corner: ScreenCorner
    }

    init(settings: AppSettings, statistics: StatisticsStore, audio: AudioController,
         initialSeed: UInt64? = nil, sceneSize: CGSize = CGSize(width: 1920, height: 1080)) {
        self.settings = settings
        self.statistics = statistics
        self.audio = audio
        if let initialSeed { self.seed = initialSeed }
        let config = SceneConfigFactory.makeConfig(from: settings, seed: self.seed)
        self.scene = BounceScene.make(size: sceneSize, config: config)
        self.scene.sceneDelegate = self
    }

    // MARK: Lifecycle

    /// Call from `onAppear`. Starts a fresh statistics session and preloads audio.
    func start(reduceMotion: Bool) {
        if !hasStarted {
            hasStarted = true
            statistics.startNewSession()
        }
        refresh(reduceMotion: reduceMotion)
        audio.resumeAmbient()
    }

    /// Re‑derive the scene config + audio from the current settings. Cheap; safe
    /// to call on every settings change.
    func refresh(reduceMotion: Bool) {
        let theme = settings.resolvedTheme
        let config = SceneConfigFactory.makeConfig(from: settings, seed: seed, reduceMotionOverride: reduceMotion)
        scene.apply(config)
        audio.apply(settings: settings, theme: theme)
        audio.preload(for: theme)
    }

    /// Re‑seed and rebuild (e.g. a "shuffle" action, or entering daily‑seed mode).
    func reseed(_ newSeed: UInt64? = nil, reduceMotion: Bool) {
        seed = newSeed ?? .random(in: 1...UInt64.max)
        refresh(reduceMotion: reduceMotion)
    }

    func setPaused(_ paused: Bool) {
        isPaused = paused
        if paused { audio.pauseAmbient() } else { audio.resumeAmbient() }
    }

    func appWillResignActive() {
        audio.pauseAmbient()
        statistics.checkpoint()
    }
    func appDidBecomeActive() {
        if !isPaused { audio.resumeAmbient() }
    }

    // MARK: BounceSceneDelegate

    nonisolated func bounceScene(_ scene: BounceScene, didProduce event: SceneEvent) {
        // The scene drives `update(_:)` on the main thread, so hopping is cheap;
        // this keeps us correct under strict concurrency regardless.
        Task { @MainActor in self.handle(event) }
    }

    private func handle(_ event: SceneEvent) {
        let theme = settings.resolvedTheme
        switch event {
        case .wallBounce:
            audio.playBounce(for: theme)
            statistics.recordWallBounce()
        case .logoCollision:
            audio.playLogoCollision(for: theme)
        case .closeCall(let e):
            statistics.record(e)
            lastCornerEvent = e
            audio.playCloseCall(for: theme)
            if settings.closeCallEffectsEnabled { showBanner(.init(id: Int.random(in: .min ... .max), kind: .closeCall, corner: e.corner)) }
        case .perfectCorner(let e):
            statistics.record(e)
            lastCornerEvent = e
            audio.playCornerHit(for: theme)
            if settings.cornerFlashIsActive {
                cornerFlash = CornerFlash(id: Int.random(in: .min ... .max), corner: e.corner,
                                          color: theme.collisionColor(at: max(0, e.logoIndex)))
            }
            showBanner(.init(id: Int.random(in: .min ... .max), kind: .perfectCorner, corner: e.corner))
        case .runTimeElapsed(let s):
            statistics.addRunTime(s)
        }
    }

    private func showBanner(_ banner: TransientBanner) {
        guard !settings.streamerModeEnabled else { return }
        transientBanner = banner
        bannerClearWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            if self?.transientBanner?.id == banner.id { self?.transientBanner = nil }
        }
        bannerClearWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + (banner.kind == .perfectCorner ? 2.6 : 1.4), execute: work)
    }
}
