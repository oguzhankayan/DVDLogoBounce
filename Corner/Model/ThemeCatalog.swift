import Foundation
import CoreGraphics

/// The built‑in theme library. Pure data — no rendering — so it can be unit
/// tested and previewed cheaply. `ThemeEngine` turns the chosen `Theme` into
/// SwiftUI / SpriteKit objects.
public enum ThemeCatalog {

    public static func theme(for id: ThemeID) -> Theme {
        switch id {
        case .classicDVD:    return classicDVD
        case .neon:          return neon
        case .synthwave:     return synthwave
        case .minimalWhite:  return minimalWhite
        case .retroCRT:      return retroCRT
        case .glassmorphism: return glassmorphism
        case .matrix:        return matrix
        case .vhs:           return vhs
        }
    }

    public static var all: [Theme] { ThemeID.allCases.map(theme(for:)) }

    // MARK: - Classic DVD

    public static let classicDVD = Theme(
        id: .classicDVD,
        name: ThemeID.classicDVD.displayName,
        tagline: ThemeID.classicDVD.tagline,
        background: BackgroundStyle(kind: .solid, stops: [RGBA(hex: "#04050A")], vignette: 0.30, grain: 0.02),
        logo: LogoAppearance(shape: .badge, wordmark: "CORNER", baseEdge: 300,
                             cornerRadiusFraction: 0.5, tintFollowsCollision: true,
                             fixedColor: .white, foregroundColor: nil, fillOpacity: 1),
        glow: GlowSpec(intensity: 0.25, radius: 26, additive: true),
        trail: TrailSpec(kind: .ghosts, intensity: 0.20, lifetime: 0.42, maxGhosts: 6),
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
        logo: LogoAppearance(shape: .wordmark, wordmark: "CORNER", baseEdge: 360,
                             cornerRadiusFraction: 0, tintFollowsCollision: true,
                             fixedColor: RGBA(hex: "#19E3FF"), foregroundColor: nil, fillOpacity: 1),
        glow: GlowSpec(intensity: 0.92, radius: 60, additive: true),
        trail: TrailSpec(kind: .ribbon, intensity: 0.50, lifetime: 0.5, maxGhosts: 18),
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
        logo: LogoAppearance(shape: .badge, wordmark: "CORNER", baseEdge: 320,
                             cornerRadiusFraction: 0.2, tintFollowsCollision: true,
                             fixedColor: RGBA(hex: "#FF2D95"), foregroundColor: RGBA(hex: "#0B0320"),
                             fillOpacity: 1),
        glow: GlowSpec(intensity: 0.70, radius: 46, additive: true),
        trail: TrailSpec(kind: .ghosts, intensity: 0.55, lifetime: 0.7, maxGhosts: 16),
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
        logo: LogoAppearance(shape: .wordmark, wordmark: "CORNER", baseEdge: 340,
                             cornerRadiusFraction: 0, tintFollowsCollision: false,
                             fixedColor: RGBA(hex: "#F7F7F8"), foregroundColor: RGBA(hex: "#F7F7F8"),
                             fillOpacity: 1),
        glow: .none,
        trail: TrailSpec(kind: .ghosts, intensity: 0.15, lifetime: 0.35, maxGhosts: 5,
                         tintFollowsLogo: false, tint: RGBA(hex: "#F7F7F8")),
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
        logo: LogoAppearance(shape: .badge, wordmark: "CORNER", fontName: "Menlo-Bold", baseEdge: 300,
                             cornerRadiusFraction: 0.18, tintFollowsCollision: true,
                             fixedColor: RGBA(hex: "#39FF7A"), foregroundColor: RGBA(hex: "#021207"),
                             fillOpacity: 0.92),
        glow: GlowSpec(intensity: 0.60, radius: 40, additive: true),
        trail: TrailSpec(kind: .ghosts, intensity: 0.40, lifetime: 0.5, maxGhosts: 12),
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

    // MARK: - Glassmorphism

    public static let glassmorphism = Theme(
        id: .glassmorphism,
        name: ThemeID.glassmorphism.displayName,
        tagline: ThemeID.glassmorphism.tagline,
        background: BackgroundStyle(kind: .linearGradient, stops: [RGBA(hex: "#1B2440"), RGBA(hex: "#0A0E1C")],
                                    vignette: 0.30, grain: 0.0),
        logo: LogoAppearance(shape: .monogram, wordmark: "CORNER", monogram: "C", baseEdge: 240,
                             cornerRadiusFraction: 0.28, strokeWidth: 2, tintFollowsCollision: true,
                             fixedColor: .white, foregroundColor: RGBA(hex: "#F5F8FF"), fillOpacity: 0.18),
        glow: GlowSpec(intensity: 0.40, radius: 52, additive: false),
        trail: TrailSpec(kind: .ghosts, intensity: 0.30, lifetime: 0.6, maxGhosts: 10),
        particles: ParticleSpec(
            bounceBurst: .init(count: 6, speed: 50, speedJitter: 22, lifetime: 0.4, size: 3),
            cornerBurst: .init(count: 60, speed: 220, speedJitter: 90, lifetime: 1.0, size: 4,
                               followsLogoColor: false,
                               colors: [RGBA(hex: "#7DD3FC"), RGBA(hex: "#C4B5FD"), RGBA(hex: "#A7F3D0"), RGBA(hex: "#FBCFE8")]),
            ambient: .init(count: 50, motion: .drift, speed: 8, size: 4, sizeJitter: 2, opacity: 0.10,
                           colors: [RGBA(hex: "#FFFFFF"), RGBA(hex: "#9CC9FF")])
        ),
        postEffect: .none,
        audio: ThemeAudioSet(bounce: .bounceSoft, logoCollision: .logoCollision,
                             cornerHit: .cornerHit, nearMiss: .nearMiss, suggestedAmbient: .synthPad),
        collisionPalette: [
            RGBA(hex: "#7DD3FC"), RGBA(hex: "#C4B5FD"), RGBA(hex: "#A7F3D0"),
            RGBA(hex: "#FBCFE8"), RGBA(hex: "#FFFFFF"),
        ]
    )

    // MARK: - Matrix

    public static let matrix = Theme(
        id: .matrix,
        name: ThemeID.matrix.displayName,
        tagline: ThemeID.matrix.tagline,
        background: BackgroundStyle(kind: .solid, stops: [RGBA(hex: "#000B02")], vignette: 0.40, grain: 0.05),
        logo: LogoAppearance(shape: .pixelBlock, wordmark: "CORNER", fontName: "Menlo-Bold", baseEdge: 280,
                             cornerRadiusFraction: 0.06, tintFollowsCollision: true,
                             fixedColor: RGBA(hex: "#00FF41"), foregroundColor: RGBA(hex: "#001A06"),
                             fillOpacity: 1),
        glow: GlowSpec(intensity: 0.55, radius: 36, additive: true),
        trail: TrailSpec(kind: .ghosts, intensity: 0.50, lifetime: 0.8, maxGhosts: 14),
        particles: ParticleSpec(
            bounceBurst: .init(count: 8, speed: 80, speedJitter: 30, lifetime: 0.4, size: 2,
                               followsLogoColor: false,
                               colors: [RGBA(hex: "#00FF41"), RGBA(hex: "#39FF14"), RGBA(hex: "#76FF03")]),
            cornerBurst: .init(count: 90, speed: 280, speedJitter: 120, lifetime: 1.0, size: 3,
                               followsLogoColor: false,
                               colors: [RGBA(hex: "#00FF41"), RGBA(hex: "#B9F6CA"), RGBA(hex: "#39FF14")]),
            ambient: .init(count: 90, motion: .fall, speed: 44, size: 2, sizeJitter: 1, opacity: 0.18,
                           colors: [RGBA(hex: "#00FF41"), RGBA(hex: "#0A8F2A")])
        ),
        postEffect: .none,
        audio: ThemeAudioSet(bounce: .bounceMatrix, logoCollision: .logoCollision,
                             cornerHit: .cornerHit, nearMiss: .nearMiss, suggestedAmbient: .roomTone),
        collisionPalette: [
            RGBA(hex: "#00FF41"), RGBA(hex: "#39FF14"), RGBA(hex: "#00C853"),
            RGBA(hex: "#76FF03"), RGBA(hex: "#B9F6CA"),
        ]
    )

    // MARK: - VHS

    public static let vhs = Theme(
        id: .vhs,
        name: ThemeID.vhs.displayName,
        tagline: ThemeID.vhs.tagline,
        background: BackgroundStyle(kind: .linearGradient, stops: [RGBA(hex: "#1A0E1E"), RGBA(hex: "#06030A")],
                                    vignette: 0.45, grain: 0.12),
        logo: LogoAppearance(shape: .badge, wordmark: "CORNER", baseEdge: 300,
                             cornerRadiusFraction: 0.12, tintFollowsCollision: true,
                             fixedColor: RGBA(hex: "#F5E6D8"), foregroundColor: RGBA(hex: "#2A1A2E"),
                             fillOpacity: 0.95),
        glow: GlowSpec(intensity: 0.50, radius: 30, color: RGBA(hex: "#FFE9D6"), additive: false),
        trail: TrailSpec(kind: .ghosts, intensity: 0.45, lifetime: 0.55, maxGhosts: 12),
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
