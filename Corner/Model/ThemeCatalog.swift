import Foundation
import CoreGraphics

/// The built‑in theme library. Pure data — no rendering — so it can be unit
/// tested and previewed cheaply. `ThemeEngine` turns the chosen `Theme` into
/// SwiftUI / SpriteKit objects.
public enum ThemeCatalog {

    public static func theme(for id: ThemeID) -> Theme {
        switch id {
        case .dvd:           return dvd
        case .classicDVD:    return classicDVD
        case .neon:          return neon
        case .synthwave:     return synthwave
        case .minimalWhite:  return minimalWhite
        case .retroCRT:      return retroCRT
        case .vhs:           return vhs
        }
    }

    public static var all: [Theme] { ThemeID.allCases.map(theme(for:)) }

    // MARK: - Classic DVD (the original mark, the bundled `newlogo` vector)

    /// Same look as `classicDVD` (deep near‑black, no glow/trail, the standard
    /// colour cycle) but the bouncing shape is the original logo SVG rather than
    /// the "your word" badge.
    public static let dvd = Theme(
        id: .dvd,
        name: ThemeID.dvd.displayName,
        tagline: ThemeID.dvd.tagline,
        background: BackgroundStyle(kind: .solid, stops: [RGBA(hex: "#04050A")], vignette: 0.30, grain: 0.02),
        logo: LogoAppearance(shape: .vectorOutline, vectorResource: "newlogo", baseEdge: 320,
                             tintFollowsCollision: true, fixedColor: .white, fillOpacity: 1),
        glow: .none,
        trail: .none,
        particles: ParticleSpec(
            bounceBurst: .init(count: 7, speed: 60, speedJitter: 30, lifetime: 0.35, size: 3),
            cornerBurst: .init(count: 90, speed: 300, speedJitter: 140, lifetime: 1.0, size: 4),
            ambient: .none
        ),
        postEffect: .none,
        audio: ThemeAudioSet(bounce: .bounceSoft, logoCollision: .logoCollision,
                             cornerHit: .cornerHit, nearMiss: .nearMiss, suggestedAmbient: .roomTone),
        collisionPalette: [
            RGBA(hex: "#FFFFFF"), RGBA(hex: "#1FB6FF"), RGBA(hex: "#FF2EC4"),
            RGBA(hex: "#FFD23F"), RGBA(hex: "#7CFF6B"), RGBA(hex: "#FF7A3D"),
            RGBA(hex: "#A06BFF"), RGBA(hex: "#28E0C8"),
        ]
    )

    // MARK: - Classic (the badge with your word — the default)

    public static let classicDVD = Theme(
        id: .classicDVD,
        name: ThemeID.classicDVD.displayName,
        tagline: ThemeID.classicDVD.tagline,
        background: BackgroundStyle(kind: .solid, stops: [RGBA(hex: "#04050A")], vignette: 0.30, grain: 0.02),
        logo: LogoAppearance(shape: .discBadge, wordmark: "CORNER", baseEdge: 300,
                             tintFollowsCollision: true, fixedColor: .white, fillOpacity: 1),
        // No glow: a small glow on a detailed mark just reads as a faint duplicate
        // sitting behind it. The original DVD screensaver has none anyway.
        glow: .none,
        trail: .none,
        particles: ParticleSpec(
            bounceBurst: .init(count: 7, speed: 60, speedJitter: 30, lifetime: 0.35, size: 3),
            cornerBurst: .init(count: 90, speed: 300, speedJitter: 140, lifetime: 1.0, size: 4),
            ambient: .none
        ),
        postEffect: .none,
        audio: ThemeAudioSet(bounce: .bounceSoft, logoCollision: .logoCollision,
                             cornerHit: .cornerHit, nearMiss: .nearMiss, suggestedAmbient: .roomTone),
        collisionPalette: [
            RGBA(hex: "#FFFFFF"), RGBA(hex: "#1FB6FF"), RGBA(hex: "#FF2EC4"),
            RGBA(hex: "#FFD23F"), RGBA(hex: "#7CFF6B"), RGBA(hex: "#FF7A3D"),
            RGBA(hex: "#A06BFF"), RGBA(hex: "#28E0C8"),
        ]
    )

    // MARK: - Neon

    public static let neon = Theme(
        id: .neon,
        name: ThemeID.neon.displayName,
        tagline: ThemeID.neon.tagline,
        background: BackgroundStyle(kind: .radialGradient, stops: [RGBA(hex: "#0A0F1E"), RGBA(hex: "#02030A")],
                                    vignette: 0.35, grain: 0.0),
        logo: LogoAppearance(shape: .discBadge, wordmark: "CORNER", baseEdge: 300,
                             tintFollowsCollision: true, fixedColor: RGBA(hex: "#19E3FF"), fillOpacity: 1),
        // Wide, soft bloom rather than a tight halo (a tight one looks like a
        // second copy of the mark).
        glow: GlowSpec(intensity: 0.6, radius: 130, additive: true),
        trail: .none,
        particles: ParticleSpec(
            bounceBurst: .init(count: 10, speed: 95, speedJitter: 40, lifetime: 0.4, size: 3),
            cornerBurst: .init(count: 120, speed: 360, speedJitter: 160, lifetime: 1.1, size: 4),
            ambient: .init(count: 36, motion: .twinkle, speed: 6, size: 2, sizeJitter: 1, opacity: 0.12,
                           colors: [RGBA(hex: "#19E3FF"), RGBA(hex: "#FF2D95")])
        ),
        postEffect: .none,
        audio: ThemeAudioSet(bounce: .bounceNeon, logoCollision: .logoCollision,
                             cornerHit: .cornerHit, nearMiss: .nearMiss, suggestedAmbient: .synthPad),
        collisionPalette: [
            RGBA(hex: "#19E3FF"), RGBA(hex: "#FF2D95"), RGBA(hex: "#3D5BFF"),
            RGBA(hex: "#39FF88"), RGBA(hex: "#B14BFF"), RGBA(hex: "#FFB020"),
        ]
    )

    // MARK: - Synthwave

    public static let synthwave = Theme(
        id: .synthwave,
        name: ThemeID.synthwave.displayName,
        tagline: ThemeID.synthwave.tagline,
        background: BackgroundStyle(kind: .linearGradient,
                                    stops: [RGBA(hex: "#FF6A3D"), RGBA(hex: "#C2186E"),
                                            RGBA(hex: "#3B0A5C"), RGBA(hex: "#0B0320")],
                                    vignette: 0.25, grain: 0.03),
        logo: LogoAppearance(shape: .discBadge, wordmark: "CORNER", baseEdge: 300,
                             tintFollowsCollision: true, fixedColor: RGBA(hex: "#FF2D95"), fillOpacity: 1),
        glow: GlowSpec(intensity: 0.55, radius: 130, additive: true),
        trail: .none,
        particles: ParticleSpec(
            bounceBurst: .init(count: 8, speed: 80, speedJitter: 36, lifetime: 0.4, size: 3),
            cornerBurst: .init(count: 100, speed: 320, speedJitter: 140, lifetime: 1.05, size: 4),
            ambient: .init(count: 44, motion: .rise, speed: 14, size: 2, sizeJitter: 1.2, opacity: 0.16,
                           colors: [RGBA(hex: "#FF2D95"), RGBA(hex: "#22D3EE")])
        ),
        postEffect: .none,
        audio: ThemeAudioSet(bounce: .bounceNeon, logoCollision: .logoCollision,
                             cornerHit: .cornerHit, nearMiss: .nearMiss, suggestedAmbient: .synthPad),
        collisionPalette: [
            RGBA(hex: "#FF2D95"), RGBA(hex: "#22D3EE"), RGBA(hex: "#FFC857"),
            RGBA(hex: "#7C3AED"), RGBA(hex: "#FF6A3D"),
        ]
    )

    // MARK: - Minimal White

    public static let minimalWhite = Theme(
        id: .minimalWhite,
        name: ThemeID.minimalWhite.displayName,
        tagline: ThemeID.minimalWhite.tagline,
        background: BackgroundStyle(kind: .solid, stops: [RGBA(hex: "#0B0B0D")], vignette: 0.10, grain: 0.0),
        logo: LogoAppearance(shape: .discBadge, wordmark: "CORNER", baseEdge: 300,
                             tintFollowsCollision: false, fixedColor: RGBA(hex: "#F7F7F8"), fillOpacity: 1),
        glow: .none,
        trail: .none,
        particles: ParticleSpec(
            bounceBurst: .none,
            cornerBurst: .init(count: 40, speed: 170, speedJitter: 70, lifetime: 0.9, size: 2,
                               followsLogoColor: false, colors: [RGBA(hex: "#FFFFFF")]),
            ambient: .none
        ),
        postEffect: .none,
        audio: ThemeAudioSet(bounce: .bounceSoft, logoCollision: .logoCollision,
                             cornerHit: .cornerHit, nearMiss: .nearMiss, suggestedAmbient: .roomTone),
        collisionPalette: [RGBA(hex: "#FFFFFF")]
    )

    // MARK: - Retro CRT

    public static let retroCRT = Theme(
        id: .retroCRT,
        name: ThemeID.retroCRT.displayName,
        tagline: ThemeID.retroCRT.tagline,
        background: BackgroundStyle(kind: .radialGradient, stops: [RGBA(hex: "#0A1A0F"), RGBA(hex: "#020703")],
                                    vignette: 0.50, grain: 0.08),
        logo: LogoAppearance(shape: .discBadge, wordmark: "CORNER", baseEdge: 300,
                             tintFollowsCollision: true, fixedColor: RGBA(hex: "#39FF7A"), fillOpacity: 0.95),
        glow: GlowSpec(intensity: 0.5, radius: 110, additive: true),
        trail: .none,
        particles: ParticleSpec(
            bounceBurst: .init(count: 6, speed: 60, speedJitter: 28, lifetime: 0.35, size: 3),
            cornerBurst: .init(count: 70, speed: 260, speedJitter: 120, lifetime: 1.0, size: 4),
            ambient: .none
        ),
        postEffect: .crt,
        audio: ThemeAudioSet(bounce: .bounceCRT, logoCollision: .logoCollision,
                             cornerHit: .cornerHitCRT, nearMiss: .nearMiss, suggestedAmbient: .roomTone),
        collisionPalette: [
            RGBA(hex: "#39FF7A"), RGBA(hex: "#FFB000"), RGBA(hex: "#34E0FF"), RGBA(hex: "#E8FFE8"),
        ]
    )

    // MARK: - VHS

    public static let vhs = Theme(
        id: .vhs,
        name: ThemeID.vhs.displayName,
        tagline: ThemeID.vhs.tagline,
        background: BackgroundStyle(kind: .linearGradient, stops: [RGBA(hex: "#1A0E1E"), RGBA(hex: "#06030A")],
                                    vignette: 0.45, grain: 0.12),
        logo: LogoAppearance(shape: .discBadge, wordmark: "CORNER", baseEdge: 300,
                             tintFollowsCollision: true, fixedColor: RGBA(hex: "#F5E6D8"), fillOpacity: 0.95),
        glow: GlowSpec(intensity: 0.42, radius: 90, color: RGBA(hex: "#FFE9D6"), additive: false),
        trail: .none,
        particles: ParticleSpec(
            bounceBurst: .init(count: 6, speed: 50, speedJitter: 24, lifetime: 0.35, size: 3),
            cornerBurst: .init(count: 60, speed: 220, speedJitter: 90, lifetime: 1.0, size: 4),
            ambient: .init(count: 24, motion: .twinkle, speed: 4, size: 2, sizeJitter: 1, opacity: 0.10,
                           colors: [RGBA(hex: "#FFFFFF")])
        ),
        postEffect: .vhs,
        audio: ThemeAudioSet(bounce: .bounceCRT, logoCollision: .logoCollision,
                             cornerHit: .cornerHitCRT, nearMiss: .nearMiss, suggestedAmbient: .vhsHum),
        collisionPalette: [
            RGBA(hex: "#5BBFB3"), RGBA(hex: "#D98EA0"), RGBA(hex: "#D9B65B"),
            RGBA(hex: "#6E8FD9"), RGBA(hex: "#F0E4D6"),
        ]
    )
}
