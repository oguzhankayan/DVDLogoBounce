import Foundation
import CoreGraphics

/// Pure physics state for one bouncing logo. Lives in `BounceScene`; mirrored
/// each frame onto a `LogoNode` for rendering. All maths are in SpriteKit scene
/// coordinates (origin bottom‑left, y up).
public struct LogoEntity: Equatable, Sendable {
    public let id: Int
    /// Centre of the logo.
    public var position: CGPoint
    /// Velocity in points / second (direction carries the heading; magnitude is
    /// the *current* speed, which the integrator keeps constant on bounces).
    public var velocity: CGVector
    /// Half extents of the logo's collision box (already scaled).
    public var halfSize: CGSize
    /// Increments on every wall contact; used to index the theme palette.
    public var colorIndex: Int

    public init(id: Int, position: CGPoint, velocity: CGVector, halfSize: CGSize, colorIndex: Int = 0) {
        self.id = id
        self.position = position
        self.velocity = velocity
        self.halfSize = halfSize
        self.colorIndex = colorIndex
    }

    public var speed: CGFloat { velocity.magnitude }
    /// Radius used for logo‑to‑logo (circle) collisions.
    public var collisionRadius: CGFloat { min(halfSize.width, halfSize.height) * 0.92 }

    public var boundingRect: CGRect {
        CGRect(x: position.x - halfSize.width, y: position.y - halfSize.height,
               width: halfSize.width * 2, height: halfSize.height * 2)
    }
}

/// The geometric result of advancing one logo by `dt` against the playfield.
public struct WallImpact: Equatable, Sendable {
    public enum HorizontalWall: Sendable { case left, right }
    public enum VerticalWall: Sendable { case bottom, top }

    /// Wall the logo's x‑extent struck this step (`nil` if none).
    public var horizontal: HorizontalWall?
    /// Wall the logo's y‑extent struck this step (`nil` if none).
    public var vertical: VerticalWall?
    /// Smallest distance (points) between the *y* extent and a y‑wall, measured
    /// after the step — i.e. "how close to a corner were we on the other axis".
    public var gapToNearestVerticalWall: CGFloat
    /// Smallest distance (points) between the *x* extent and an x‑wall.
    public var gapToNearestHorizontalWall: CGFloat
    /// Nearest vertical / horizontal wall (regardless of contact) — used to name
    /// the corner for a close call.
    public var nearestVerticalWall: VerticalWall
    public var nearestHorizontalWall: HorizontalWall
    /// Speed magnitude at the moment of impact.
    public var speedAtImpact: CGFloat

    public var hitHorizontal: Bool { horizontal != nil }
    public var hitVertical: Bool { vertical != nil }
    public var hitAnything: Bool { hitHorizontal || hitVertical }
    public var isExactCorner: Bool { hitHorizontal && hitVertical }
}

/// Advances logo physics. Stateless on purpose — easy to unit test.
public enum MotionIntegrator {

    /// Advance `entity` by `dt` seconds inside `bounds`, reflecting off the walls
    /// and keeping speed constant. Mutates `entity` in place; returns the impact
    /// description for this step (`nil` if nothing was touched).
    @discardableResult
    public static func step(_ entity: inout LogoEntity, dt: CGFloat, bounds: CGRect) -> WallImpact? {
        guard dt > 0 else { return nil }
        let hw = entity.halfSize.width
        let hh = entity.halfSize.height
        let speed = entity.velocity.magnitude

        var pos = CGPoint(x: entity.position.x + entity.velocity.dx * dt,
                          y: entity.position.y + entity.velocity.dy * dt)
        var vel = entity.velocity

        // --- X axis ---
        var hWall: WallImpact.HorizontalWall?
        let minTravelX = bounds.minX + hw
        let maxTravelX = bounds.maxX - hw
        if minTravelX <= maxTravelX {
            if pos.x < minTravelX {
                pos.x = minTravelX + (minTravelX - pos.x).clamped(to: 0...(maxTravelX - minTravelX))
                vel.dx = abs(vel.dx)
                hWall = .left
            } else if pos.x > maxTravelX {
                pos.x = maxTravelX - (pos.x - maxTravelX).clamped(to: 0...(maxTravelX - minTravelX))
                vel.dx = -abs(vel.dx)
                hWall = .right
            }
        } else {
            pos.x = bounds.midX            // logo wider than playfield: just centre it
        }

        // --- Y axis ---
        var vWall: WallImpact.VerticalWall?
        let minTravelY = bounds.minY + hh
        let maxTravelY = bounds.maxY - hh
        if minTravelY <= maxTravelY {
            if pos.y < minTravelY {
                pos.y = minTravelY + (minTravelY - pos.y).clamped(to: 0...(maxTravelY - minTravelY))
                vel.dy = abs(vel.dy)
                vWall = .bottom
            } else if pos.y > maxTravelY {
                pos.y = maxTravelY - (pos.y - maxTravelY).clamped(to: 0...(maxTravelY - minTravelY))
                vel.dy = -abs(vel.dy)
                vWall = .top
            }
        } else {
            pos.y = bounds.midY
        }

        // Keep speed exactly constant (floating point drift / clamp side‑effects).
        if speed > 0, vel.magnitude > 0 { vel = vel.with(magnitude: speed) }

        entity.position = pos
        entity.velocity = vel
        if hWall != nil { entity.colorIndex &+= 1 }
        if vWall != nil { entity.colorIndex &+= 1 }

        guard hWall != nil || vWall != nil else { return nil }

        // Gaps & nearest walls (computed on the resolved position).
        let distLeft = (pos.x - hw) - bounds.minX
        let distRight = bounds.maxX - (pos.x + hw)
        let distBottom = (pos.y - hh) - bounds.minY
        let distTop = bounds.maxY - (pos.y + hh)

        return WallImpact(
            horizontal: hWall,
            vertical: vWall,
            gapToNearestVerticalWall: max(0, min(distBottom, distTop)),
            gapToNearestHorizontalWall: max(0, min(distLeft, distRight)),
            nearestVerticalWall: distBottom <= distTop ? .bottom : .top,
            nearestHorizontalWall: distLeft <= distRight ? .left : .right,
            speedAtImpact: speed
        )
    }
}
