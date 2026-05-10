import Foundation
import CoreGraphics

/// A tiny, fast, deterministic PRNG (SplitMix64). Used so that a given *seed*
/// always produces the same starting positions / headings — which powers the
/// "daily impossible seed" idea and makes the engine reproducible in tests.
public struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64

    public init(seed: UInt64) {
        // Avoid the all‑zero state.
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// Uniform Double in [0, 1).
    public mutating func unit() -> Double {
        Double(next() >> 11) * (1.0 / 9007199254740992.0)   // 53‑bit mantissa
    }

    /// Uniform Double in [a, b).
    public mutating func double(in range: ClosedRange<Double>) -> Double {
        range.lowerBound + unit() * (range.upperBound - range.lowerBound)
    }

    public mutating func cgFloat(in range: ClosedRange<CGFloat>) -> CGFloat {
        CGFloat(double(in: Double(range.lowerBound)...Double(range.upperBound)))
    }

    public mutating func int(in range: ClosedRange<Int>) -> Int {
        Int.random(in: range, using: &self)
    }

    public mutating func bool() -> Bool { next() & 1 == 1 }

    /// A heading angle that isn't too close to purely horizontal/vertical (which
    /// looks dull and makes corner hits nearly impossible). Returns radians.
    public mutating func livelyHeading() -> CGFloat {
        // Pick within a band away from the axes, then drop into a random quadrant.
        let base = cgFloat(in: 0.30...(CGFloat.pi / 2 - 0.30))
        let quadrant = int(in: 0...3)
        return base + CGFloat(quadrant) * (.pi / 2)
    }
}

public extension SeededRandom {
    /// A stable seed for "today" (UTC day number). Same everywhere on a given day.
    static func dailySeed(reference: Date = Date()) -> UInt64 {
        let day = Int(reference.timeIntervalSince1970 / 86_400)
        // Mix the day number a little so consecutive days feel unrelated.
        var g = SeededRandom(seed: UInt64(bitPattern: Int64(day)) &* 0xD1B54A32D192ED03 &+ 0x1234567)
        return g.next()
    }
}
