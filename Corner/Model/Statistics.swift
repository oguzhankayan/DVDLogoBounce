import Foundation
import CoreGraphics

/// A single perfect (or close‑call) corner event, surfaced to the UI for the
/// flash / particle / sound payoff and recorded into `Statistics`.
public struct CornerHitEvent: Hashable, Sendable {
    public var corner: ScreenCorner
    public var date: Date
    /// Logo speed at impact in points/sec (magnitude). Used to scale the burst.
    public var speed: CGFloat
    /// Index of the logo within the scene (for multi mode).
    public var logoIndex: Int
    /// True for a near miss recorded as a "close call" rather than a perfect hit.
    public var isCloseCall: Bool
    /// Theme that was active when it happened (for the stats timeline).
    public var themeID: ThemeID

    public init(corner: ScreenCorner, date: Date = Date(), speed: CGFloat,
                logoIndex: Int = 0, isCloseCall: Bool = false, themeID: ThemeID) {
        self.corner = corner
        self.date = date
        self.speed = speed
        self.logoIndex = logoIndex
        self.isCloseCall = isCloseCall
        self.themeID = themeID
    }
}

/// Persisted, all‑time statistics plus the live session counters. `sessionStreak`
/// here means "perfect corner hits during the current run"; `longestSession`
/// is the best such run ever. (We deliberately keep this small and on‑device —
/// no accounts, no tracking.)
public struct Statistics: Codable, Hashable, Sendable {
    // All‑time
    public var totalCornerHits: Int
    public var totalCloseCalls: Int
    public var totalWallBounces: Int
    public var totalRunTime: TimeInterval
    public var firstLaunch: Date
    public var lastCornerHit: Date?
    public var perCorner: [ScreenCorner: Int]
    /// Best number of corner hits achieved in a single session.
    public var longestSession: Int
    /// Best gap, in seconds, ever survived between two corner hits while running
    /// (i.e. "the longest you've ever waited and still been rewarded"). Mostly a
    /// fun stat. Optional because you need ≥ 2 hits to have a gap.
    public var longestDryGap: TimeInterval?

    // Live session (not necessarily persisted between launches, but Codable so we
    // can checkpoint it for crash resilience).
    public var sessionCornerHits: Int
    public var sessionCloseCalls: Int
    public var sessionStarted: Date

    public init(
        totalCornerHits: Int = 0,
        totalCloseCalls: Int = 0,
        totalWallBounces: Int = 0,
        totalRunTime: TimeInterval = 0,
        firstLaunch: Date = Date(),
        lastCornerHit: Date? = nil,
        perCorner: [ScreenCorner: Int] = [:],
        longestSession: Int = 0,
        longestDryGap: TimeInterval? = nil,
        sessionCornerHits: Int = 0,
        sessionCloseCalls: Int = 0,
        sessionStarted: Date = Date()
    ) {
        self.totalCornerHits = totalCornerHits
        self.totalCloseCalls = totalCloseCalls
        self.totalWallBounces = totalWallBounces
        self.totalRunTime = totalRunTime
        self.firstLaunch = firstLaunch
        self.lastCornerHit = lastCornerHit
        self.perCorner = perCorner
        self.longestSession = longestSession
        self.longestDryGap = longestDryGap
        self.sessionCornerHits = sessionCornerHits
        self.sessionCloseCalls = sessionCloseCalls
        self.sessionStarted = sessionStarted
    }

    public func count(for corner: ScreenCorner) -> Int { perCorner[corner] ?? 0 }

    public var timeSinceLastCornerHit: TimeInterval? {
        guard let last = lastCornerHit else { return nil }
        return max(0, Date().timeIntervalSince(last))
    }

    /// Begin a fresh run: zero the session counters, keep all‑time totals.
    public mutating func startNewSession(now: Date = Date()) {
        sessionCornerHits = 0
        sessionCloseCalls = 0
        sessionStarted = now
    }

    /// Fold a corner event into the statistics.
    public mutating func record(_ event: CornerHitEvent) {
        if event.isCloseCall {
            totalCloseCalls += 1
            sessionCloseCalls += 1
            return
        }
        if let last = lastCornerHit {
            let gap = event.date.timeIntervalSince(last)
            if gap > 0 { longestDryGap = max(longestDryGap ?? 0, gap) }
        }
        totalCornerHits += 1
        sessionCornerHits += 1
        longestSession = max(longestSession, sessionCornerHits)
        lastCornerHit = event.date
        perCorner[event.corner, default: 0] += 1
    }

    public mutating func recordWallBounce(count: Int = 1) {
        totalWallBounces += max(0, count)
    }

    public mutating func addRunTime(_ seconds: TimeInterval) {
        guard seconds > 0, seconds.isFinite else { return }
        totalRunTime += seconds
    }
}

// `[ScreenCorner: Int]` is Codable because `ScreenCorner` has a `String` raw
// value, so the synthesised conformance above is sufficient.
