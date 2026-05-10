import Foundation
import CoreGraphics

/// The classification of a single integration step's wall contact. This is the
/// emotional core of the app, so it gets its own tiny, well‑tested type that is
/// kept separate from the geometry in `MotionIntegrator`.
public enum CornerOutcome: Equatable, Sendable {
    /// Nothing was touched.
    case none
    /// An ordinary single‑wall bounce.
    case wallBounce
    /// A single‑wall bounce where the *other* edge was within the close‑call
    /// tolerance of its wall — i.e. "ooh, so close." Names the corner it grazed.
    case closeCall(ScreenCorner)
    /// Both edges struck their walls on the same step. The payoff.
    case perfectCorner(ScreenCorner)

    public var isPerfectCorner: Bool { if case .perfectCorner = self { return true } else { return false } }
    public var isCloseCall: Bool { if case .closeCall = self { return true } else { return false } }
    public var corner: ScreenCorner? {
        switch self {
        case .closeCall(let c), .perfectCorner(let c): return c
        case .none, .wallBounce: return nil
        }
    }
}

public struct CornerHitDetector: Sendable {
    /// How close (points) the trailing edge must be to its wall on a single‑axis
    /// bounce for the step to register as a close call.
    public var closeCallTolerance: CGFloat
    /// Whether close calls are reported at all (the user can switch their effects
    /// off, in which case we don't even classify them).
    public var detectCloseCalls: Bool

    public init(closeCallTolerance: CGFloat, detectCloseCalls: Bool = true) {
        self.closeCallTolerance = max(0, closeCallTolerance)
        self.detectCloseCalls = detectCloseCalls
    }

    public func classify(_ impact: WallImpact?) -> CornerOutcome {
        guard let impact, impact.hitAnything else { return .none }

        if impact.isExactCorner, let h = impact.horizontal, let v = impact.vertical {
            return .perfectCorner(Self.corner(h: h, v: v))
        }

        if detectCloseCalls {
            if let h = impact.horizontal, impact.gapToNearestVerticalWall <= closeCallTolerance {
                return .closeCall(Self.corner(h: h, v: impact.nearestVerticalWall))
            }
            if let v = impact.vertical, impact.gapToNearestHorizontalWall <= closeCallTolerance {
                return .closeCall(Self.corner(h: impact.nearestHorizontalWall, v: v))
            }
        }
        return .wallBounce
    }

    static func corner(h: WallImpact.HorizontalWall, v: WallImpact.VerticalWall) -> ScreenCorner {
        switch (h, v) {
        case (.left, .top):     return .topLeft
        case (.right, .top):    return .topRight
        case (.left, .bottom):  return .bottomLeft
        case (.right, .bottom): return .bottomRight
        }
    }
}
