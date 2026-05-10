import CoreGraphics
import Foundation

// Lightweight vector maths used by the motion integrator & collision resolver.
// SpriteKit gives us `CGVector` for velocities and `CGPoint` for positions.

extension CGVector {
    init(angle: CGFloat, magnitude: CGFloat) {
        self.init(dx: cos(angle) * magnitude, dy: sin(angle) * magnitude)
    }

    var magnitude: CGFloat { (dx * dx + dy * dy).squareRoot() }
    var magnitudeSquared: CGFloat { dx * dx + dy * dy }
    var angle: CGFloat { atan2(dy, dx) }

    var normalized: CGVector {
        let m = magnitude
        guard m > 1e-9 else { return CGVector(dx: 1, dy: 0) }
        return CGVector(dx: dx / m, dy: dy / m)
    }

    func scaled(by k: CGFloat) -> CGVector { CGVector(dx: dx * k, dy: dy * k) }
    func with(magnitude m: CGFloat) -> CGVector { normalized.scaled(by: m) }

    static func + (l: CGVector, r: CGVector) -> CGVector { CGVector(dx: l.dx + r.dx, dy: l.dy + r.dy) }
    static func - (l: CGVector, r: CGVector) -> CGVector { CGVector(dx: l.dx - r.dx, dy: l.dy - r.dy) }
    static func * (v: CGVector, k: CGFloat) -> CGVector { v.scaled(by: k) }
    static func * (k: CGFloat, v: CGVector) -> CGVector { v.scaled(by: k) }
    static prefix func - (v: CGVector) -> CGVector { CGVector(dx: -v.dx, dy: -v.dy) }

    func dot(_ o: CGVector) -> CGFloat { dx * o.dx + dy * o.dy }

    /// Reflect this vector about a (unit) normal.
    func reflected(normal n: CGVector) -> CGVector {
        let nn = n.normalized
        return self - nn.scaled(by: 2 * dot(nn))
    }
}

extension CGPoint {
    static func + (p: CGPoint, v: CGVector) -> CGPoint { CGPoint(x: p.x + v.dx, y: p.y + v.dy) }
    static func - (a: CGPoint, b: CGPoint) -> CGVector { CGVector(dx: a.x - b.x, dy: a.y - b.y) }

    func distance(to p: CGPoint) -> CGFloat { (self - p).magnitude }
}

extension CGSize {
    var aspect: CGFloat { height == 0 ? 1 : width / height }
}

/// Wrap a phase into 0..<period (handy for time‑based animation parameters).
func wrap(_ value: CGFloat, period: CGFloat) -> CGFloat {
    guard period > 0 else { return 0 }
    let m = value.truncatingRemainder(dividingBy: period)
    return m < 0 ? m + period : m
}
