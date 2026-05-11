import Foundation

/// Stable identifiers for the built‑in themes. Raw values are persisted, so do
/// not rename them — only ever append new cases.
public enum ThemeID: String, CaseIterable, Codable, Identifiable, Sendable {
    case dvd
    case classicDVD
    case neon
    case synthwave
    case minimalWhite
    case retroCRT
    case vhs

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .dvd:            return "Classic DVD"
        case .classicDVD:     return "Classic"
        case .neon:           return "Neon"
        case .synthwave:      return "Synthwave"
        case .minimalWhite:   return "Minimal White"
        case .retroCRT:       return "Retro CRT"
        case .vhs:            return "VHS"
        }
    }

    public var tagline: String {
        switch self {
        case .dvd:            return "The one you know. Bounce, watch, wait for the corner."
        case .classicDVD:     return "Pure, patient, hypnotic. Your word on the disc."
        case .neon:           return "Cool glass and electric edges."
        case .synthwave:      return "Sunset grids and magenta haze."
        case .minimalWhite:   return "Negative space. Nothing else."
        case .retroCRT:       return "Curved glass, scanlines, soft bloom."
        case .vhs:            return "Tape wow, tracking lines, warm noise."
        }
    }

    /// Whether the theme leans on the optional fragment‑shader post effect.
    public var usesPostEffect: Bool {
        switch self {
        case .retroCRT, .vhs: return true
        default:              return false
        }
    }
}
