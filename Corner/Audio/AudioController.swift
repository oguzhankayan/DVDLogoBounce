import Foundation
import AVFoundation

/// Owns all sound: a small pool of `AVAudioPlayer`s per SFX (so rapid bounces
/// overlap cleanly) and one looping `AVAudioPlayer` for the ambient bed, which
/// fades in (and the previous one hard‑stops) when the ambient mode changes.
///
/// Everything degrades gracefully: a missing audio file just leaves that channel
/// silent (logged once in debug). The audio session uses the `.ambient` category
/// so the app never interrupts whatever the user might already be playing.
@MainActor
public final class AudioController: ObservableObject {

    // Mirrors the relevant slice of `AppSettings` so the engine callbacks don't
    // need a reference to settings.
    public private(set) var sfxEnabled: Bool = true
    public private(set) var sfxVolume: Float = 0.6
    public private(set) var ambientVolume: Float = 0.4
    public private(set) var cornerSoundEnabled: Bool = true
    public private(set) var closeCallEnabled: Bool = true
    private(set) var currentAmbient: AmbientMode = .silent

    private let bundle: Bundle
    private let enabled: Bool                // master kill‑switch (e.g. previews)

    private var sfxPools: [SoundEffectID: SFXPool] = [:]
    private var loggedMissing: Set<String> = []

    private var ambientPlayer: AVAudioPlayer?
    private var sessionActive = false

    public init(bundle: Bundle = .main, enabled: Bool = true) {
        self.bundle = bundle
        self.enabled = enabled
    }

    // MARK: Configuration

    /// Apply the audio‑relevant settings for the active theme. Resolves
    /// `.matchTheme` to the theme's suggested bed.
    public func apply(settings: AppSettings, theme: Theme) {
        sfxEnabled = settings.soundEffectsEnabled
        sfxVolume = Float(settings.sfxVolume)
        ambientVolume = Float(settings.ambientVolume)
        cornerSoundEnabled = settings.cornerSoundEnabled
        closeCallEnabled = settings.closeCallEffectsEnabled

        for pool in sfxPools.values { pool.setVolume(sfxVolume) }
        let wanted = settings.effectiveAmbientMode(for: theme)
        setAmbientMode(wanted)
        refreshSessionActivation()
    }

    /// Pre‑warm the SFX a theme will use (call when a theme becomes active so the
    /// first bounce isn't late).
    public func preload(for theme: Theme) {
        guard enabled else { return }
        let ids: Set<SoundEffectID> = [theme.audio.bounce, theme.audio.logoCollision,
                                       theme.audio.cornerHit, theme.audio.nearMiss,
                                       .uiFocus, .uiSelect, .uiBack]
        for id in ids { _ = pool(for: id) }
    }

    // MARK: SFX entry points (called from the scene delegate / UI)

    public func playBounce(for theme: Theme) { guard sfxEnabled else { return }; play(theme.audio.bounce, volumeScale: 0.85) }
    public func playLogoCollision(for theme: Theme) { guard sfxEnabled else { return }; play(theme.audio.logoCollision, volumeScale: 0.9) }
    public func playCloseCall(for theme: Theme) { guard sfxEnabled, closeCallEnabled else { return }; play(theme.audio.nearMiss, volumeScale: 0.8) }
    public func playCornerHit(for theme: Theme) {
        guard sfxEnabled, cornerSoundEnabled else { return }
        play(theme.audio.cornerHit, volumeScale: 1.0)
    }
    public func playUIFocus()  { guard sfxEnabled else { return }; play(.uiFocus,  volumeScale: 0.4) }
    public func playUISelect() { guard sfxEnabled else { return }; play(.uiSelect, volumeScale: 0.6) }
    public func playUIBack()   { guard sfxEnabled else { return }; play(.uiBack,   volumeScale: 0.55) }

    private func play(_ id: SoundEffectID, volumeScale: Float) {
        guard enabled, let pool = pool(for: id) else { return }
        pool.play(volume: sfxVolume * volumeScale)
    }

    private func pool(for id: SoundEffectID) -> SFXPool? {
        if let existing = sfxPools[id] { return existing }
        let resource = SoundResource.name(for: id)
        guard let url = SoundResource.url(forResourceNamed: resource, in: bundle) else {
            warnMissing(resource)
            return nil
        }
        guard let pool = SFXPool(url: url) else { warnMissing(resource); return nil }
        sfxPools[id] = pool
        return pool
    }

    // MARK: Ambient bed

    public func setAmbientMode(_ mode: AmbientMode) {
        guard mode != currentAmbient else {
            ambientPlayer?.volume = ambientVolume
            return
        }
        currentAmbient = mode
        guard enabled else { return }

        guard let name = SoundResource.ambientName(for: mode),
              let url = SoundResource.url(forResourceNamed: name, in: bundle),
              let player = try? AVAudioPlayer(contentsOf: url) else {
            setAmbientPlayer(nil)
            if let n = SoundResource.ambientName(for: mode) { warnMissing(n) }
            return
        }
        player.numberOfLoops = -1
        player.volume = 0
        player.prepareToPlay()
        player.play()
        setAmbientPlayer(player)
        refreshSessionActivation()
    }

    public func pauseAmbient()  { ambientPlayer?.pause() }
    public func resumeAmbient() { if currentAmbient != .silent { ambientPlayer?.play() } }

    /// Swap the looping bed: the new one fades in over `fade` seconds (handled
    /// internally by `AVAudioPlayer.setVolume(_:fadeDuration:)`, so there's no
    /// timer to manage); the previous one is hard‑stopped — bed changes are rare
    /// and a tiny cut under a fade‑in is inaudible.
    private func setAmbientPlayer(_ newPlayer: AVAudioPlayer?, fade: TimeInterval = 0.7) {
        ambientPlayer?.stop()
        ambientPlayer = newPlayer
        guard let newPlayer else { return }
        newPlayer.volume = 0
        newPlayer.setVolume(ambientVolume, fadeDuration: fade)
    }

    // MARK: Session

    private func refreshSessionActivation() {
        let needed = enabled && (sfxEnabled || currentAmbient != .silent)
        guard needed != sessionActive else {
            if needed { try? AVAudioSession.sharedInstance().setActive(true) }
            return
        }
        let session = AVAudioSession.sharedInstance()
        if needed {
            try? session.setCategory(.ambient, mode: .default, options: [])
            try? session.setActive(true)
            sessionActive = true
        } else {
            try? session.setActive(false, options: [.notifyOthersOnDeactivation])
            sessionActive = false
        }
    }

    // MARK: Debug

    private func warnMissing(_ resource: String) {
        #if DEBUG
        if !loggedMissing.contains(resource) {
            loggedMissing.insert(resource)
            print("[Corner] Audio resource \"\(resource)\" not found in bundle — that channel will be silent.")
        }
        #endif
    }
}

// MARK: - SFX pool

/// A tiny round‑robin pool of `AVAudioPlayer`s sharing one file so overlapping
/// triggers (multi‑logo bounces) don't cut each other off.
private final class SFXPool {
    private var players: [AVAudioPlayer]
    private var index = 0

    init?(url: URL, size: Int = 4) {
        guard let first = try? AVAudioPlayer(contentsOf: url) else { return nil }
        first.prepareToPlay()
        var made = [first]
        for _ in 1..<max(1, size) {
            if let p = try? AVAudioPlayer(contentsOf: url) { p.prepareToPlay(); made.append(p) }
        }
        players = made
    }

    func setVolume(_ v: Float) { for p in players { p.volume = v } }

    func play(volume: Float) {
        guard !players.isEmpty else { return }
        // Prefer a free player; otherwise steal the next in rotation.
        let chosen = players.first(where: { !$0.isPlaying }) ?? {
            let p = players[index]; index = (index + 1) % players.count; return p
        }()
        chosen.volume = max(0, min(1, volume))
        chosen.currentTime = 0
        chosen.play()
    }
}
