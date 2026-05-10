import Foundation

/// Logical sound‑effect identifiers. The mapping to bundled files lives in
/// `SoundEffect` (Audio layer) so the catalogue can change without touching themes.
public enum SoundEffectID: String, CaseIterable, Codable, Sendable {
    case bounceSoft
    case bounceNeon
    case bounceCRT
    case bounceMatrix
    case logoCollision
    case cornerHit
    case cornerHitCRT
    case nearMiss
    case uiFocus
    case uiSelect
    case uiBack
}

/// The ambient audio bed the user can leave running.
public enum AmbientMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case silent
    case matchTheme
    case vhsHum
    case synthPad
    case roomTone

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .silent:     return "Silent"
        case .matchTheme: return "Match Theme"
        case .vhsHum:     return "VHS Hum"
        case .synthPad:   return "Synth Pad"
        case .roomTone:   return "Room Tone"
        }
    }

    public var detail: String {
        switch self {
        case .silent:     return "No ambient audio."
        case .matchTheme: return "Use the bed the current theme suggests."
        case .vhsHum:     return "Tape transport hum, faint head noise, gentle wow & flutter."
        case .synthPad:   return "A slow, warm, drifting pad. No melody."
        case .roomTone:   return "An almost‑silent dark‑room tone for a touch of presence."
        }
    }
}
