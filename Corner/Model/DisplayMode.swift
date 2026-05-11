import Foundation
import CoreGraphics

/// High‑level "what's on screen" mode. Each mode is a curated starting point —
/// the user can still tweak individual sliders afterwards; switching mode just
/// re‑seeds the relevant settings.
public enum DisplayMode: String, CaseIterable, Codable, Identifiable, Sendable {
    /// One logo. The purest, most meditative experience.
    case single
    /// A handful of logos that pass through each other (or collide, per setting).
    case multi
    /// Many fast logos, hard collisions on, heavier particles. Controlled chaos.
    case chaos

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .single:    return "Single"
        case .multi:     return "Multi"
        case .chaos:     return "Chaos"
        }
    }

    public var detail: String {
        switch self {
        case .single:    return "One logo. Pure and patient."
        case .multi:     return "A few logos sharing the screen."
        case .chaos:     return "Many fast logos, hard collisions, more sparks."
        }
    }

    /// The settings this mode seeds when selected.
    public struct Seed: Sendable {
        public var logoCount: Int
        public var speed: Double            // multiplier (1.0 == reference speed)
        public var trailIntensity: Double
        public var motionBlur: Double
        public var interLogoCollisions: Bool
        public var particleDensity: Double
    }

    public var seed: Seed {
        switch self {
        case .single:
            return Seed(logoCount: 1, speed: 1.0, trailIntensity: 0,
                        motionBlur: 0, interLogoCollisions: false, particleDensity: 0.5)
        case .multi:
            return Seed(logoCount: 5, speed: 1.05, trailIntensity: 0,
                        motionBlur: 0, interLogoCollisions: true, particleDensity: 0.6)
        case .chaos:
            return Seed(logoCount: 11, speed: 1.7, trailIntensity: 0,
                        motionBlur: 0.12, interLogoCollisions: true, particleDensity: 0.95)
        }
    }
}

/// The four screen corners — used for the per‑corner counter & statistics.
public enum ScreenCorner: String, CaseIterable, Codable, Identifiable, Sendable {
    case topLeft, topRight, bottomLeft, bottomRight

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .topLeft:     return "Top‑Left"
        case .topRight:    return "Top‑Right"
        case .bottomLeft:  return "Bottom‑Left"
        case .bottomRight: return "Bottom‑Right"
        }
    }

    public var symbolName: String {
        switch self {
        case .topLeft:     return "arrow.up.left"
        case .topRight:    return "arrow.up.right"
        case .bottomLeft:  return "arrow.down.left"
        case .bottomRight: return "arrow.down.right"
        }
    }

    /// Resolve the corner from the sign of the velocity at the moment of a
    /// double‑axis collision (the logo was heading *into* that corner).
    public static func from(velocityX vx: CGFloat, velocityY vy: CGFloat, yAxisIsUp: Bool) -> ScreenCorner {
        let goingRight = vx >= 0
        let goingUp = yAxisIsUp ? vy >= 0 : vy < 0
        switch (goingRight, goingUp) {
        case (false, true):  return .topLeft
        case (true,  true):  return .topRight
        case (false, false): return .bottomLeft
        case (true,  false): return .bottomRight
        }
    }
}
