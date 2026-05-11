import Foundation
import Combine

/// Owns the all‑time + session `Statistics`, persists them to `UserDefaults`,
/// and publishes changes for the stats screen / HUD.
///
/// All mutating entry points are `@MainActor` because the SpriteKit engine drives
/// them from `SKScene.update(_:)`, which runs on the main thread.
@MainActor
public final class StatisticsStore: ObservableObject {

    @Published public private(set) var stats: Statistics

    private let storage: JSONUserDefaultsStorage<Statistics>?
    private var saveCancellable: AnyCancellable?
    private let saveSubject = PassthroughSubject<Void, Never>()
    /// Pending wall‑bounce count, flushed periodically so we don't write to disk
    /// dozens of times per second.
    private var pendingWallBounces = 0
    private var pendingRunTime: TimeInterval = 0

    public init(persisted: Bool = true, defaults: UserDefaults = .standard) {
        if persisted {
            let storage = JSONUserDefaultsStorage<Statistics>(key: DefaultsKey.statistics, defaults: defaults)
            self.storage = storage
            var loaded = storage.load() ?? Statistics()
            loaded.startNewSession()
            stats = loaded
        } else {
            storage = nil
            stats = Statistics()
        }

        saveCancellable = saveSubject
            .throttle(for: .seconds(2), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] in self?.flush() }
    }

    // MARK: Recording

    /// Records a corner hit (or close call) and returns the event back for the
    /// caller's convenience (so the UI can react to the same value).
    @discardableResult
    public func record(_ event: CornerHitEvent) -> CornerHitEvent {
        var s = stats
        s.record(event)
        stats = s
        scheduleSave(force: !event.isCloseCall)   // a perfect hit is worth a sooner write
        return event
    }

    public func recordWallBounce() {
        pendingWallBounces += 1
        if pendingWallBounces >= 25 { scheduleSave(force: false) }
    }

    public func addRunTime(_ seconds: TimeInterval) {
        guard seconds > 0, seconds.isFinite else { return }
        pendingRunTime += seconds
        if pendingRunTime >= 5 { scheduleSave(force: false) }
    }

    /// Begin a brand‑new run (called when the screensaver (re)starts).
    public func startNewSession() {
        var s = stats
        s.startNewSession()
        stats = s
        scheduleSave(force: true)
    }

    public func resetAllStatistics() {
        var fresh = Statistics()
        fresh.firstLaunch = stats.firstLaunch   // keep the "owned since" date
        fresh.startNewSession()
        stats = fresh
        pendingWallBounces = 0
        pendingRunTime = 0
        flush()
    }

    /// Force a write — call from scene‑phase changes / app backgrounding.
    public func checkpoint() { flush() }

    // MARK: Internals

    private func scheduleSave(force: Bool) {
        if force { flush() } else { saveSubject.send(()) }
    }

    private func flush() {
        if pendingWallBounces > 0 || pendingRunTime > 0 {
            var s = stats
            s.recordWallBounce(count: pendingWallBounces)
            s.addRunTime(pendingRunTime)
            pendingWallBounces = 0
            pendingRunTime = 0
            stats = s
        }
        storage?.save(stats)
    }
}
