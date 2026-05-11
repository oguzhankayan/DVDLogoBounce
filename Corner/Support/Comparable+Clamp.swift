import Foundation
import CoreGraphics

extension Comparable {
    /// Clamp the value into a closed range.
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

extension FloatingPoint {
    /// Linear interpolation between `a` and `b` by fraction `self` (0…1, clamped).
    func lerp(_ a: Self, _ b: Self) -> Self {
        let t = Swift.min(Swift.max(self, 0), 1)
        return a + (b - a) * t
    }
}

/// Map a value from one closed range onto another (no clamping).
func remap<T: FloatingPoint>(_ value: T, from: ClosedRange<T>, to: ClosedRange<T>) -> T {
    let denom = from.upperBound - from.lowerBound
    guard denom != 0 else { return to.lowerBound }
    let fraction = (value - from.lowerBound) / denom
    return to.lowerBound + fraction * (to.upperBound - to.lowerBound)
}
