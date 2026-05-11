import Foundation
import CoreGraphics

// MARK: - Theme

/// A complete visual + audio personality for the screensaver. Themes are pure
/// value types so they can be diffed, previewed, and unit‑tested; the rendering
/// layers (`ThemeEngine`, `BounceScene`) translate them into SwiftUI / SpriteKit.
public struct Theme: Identifiable, Hashable, Sendable {
    public var id: ThemeID
    public var name: String
    public var tagline: String

    public var background: BackgroundStyle
    public var logo: LogoAppearance
    public var glow: GlowSpec
    public var trail: TrailSpec
    public var particles: ParticleSpec
    public var postEffect: PostEffect
    public var audio: ThemeAudioSet

    /// Colours the logo cycles through on each wall bounce. Always non‑empty.
    public var collisionPalette: [RGBA]

    public init(
        id: ThemeID,
        name: String,
        tagline: String,
        background: BackgroundStyle,
        logo: LogoAppearance,
        glow: GlowSpec,
        trail: TrailSpec,
        particles: ParticleSpec,
        postEffect: PostEffect,
        audio: ThemeAudioSet,
        collisionPalette: [RGBA]
    ) {
        self.id = id
        self.name = name
        self.tagline = tagline
        self.background = background
        self.logo = logo
        self.glow = glow
        self.trail = trail
        self.particles = particles
        self.postEffect = postEffect
        self.audio = audio
        self.collisionPalette = collisionPalette.isEmpty ? [.white] : collisionPalette
    }

    public func collisionColor(at index: Int) -> RGBA {
        collisionPalette[((index % collisionPalette.count) + collisionPalette.count) % collisionPalette.count]
    }
}

// MARK: - Background

public struct BackgroundStyle: Hashable, Sendable {
    public enum Kind: String, Hashable, Sendable {
        case solid, linearGradient, radialGradient
    }
    public var kind: Kind
    /// Gradient stops bottom→top (linear) or centre→edge (radial). For `.solid`
    /// only the first stop is used.
    public var stops: [RGBA]
    /// 0 = no vignette, 1 = heavy. Adds a soft dark frame for "TV depth".
    public var vignette: Double
    /// 0…1 film‑grain / noise opacity layered over everything.
    public var grain: Double

    public init(kind: Kind, stops: [RGBA], vignette: Double = 0.25, grain: Double = 0) {
        self.kind = kind
        self.stops = stops.isEmpty ? [.black] : stops
        self.vignette = vignette.clamped(to: 0...1)
        self.grain = grain.clamped(to: 0...1)
    }

    public var baseColor: RGBA { stops.first ?? .black }
}

// MARK: - Logo

public struct LogoAppearance: Hashable, Sendable {
    public enum Shape: String, Hashable, Sendable {
        /// The classic oval‑ish badge with a wordmark inside.
        case badge
        /// A bold standalone wordmark, no enclosing shape.
        case wordmark
        /// A glyph / monogram inside a rounded square.
        case monogram
        /// A hollow ring (Minimal / abstract).
        case ring
        /// A chunky pixel block (Matrix / 8‑bit).
        case pixelBlock
        /// A vector silhouette loaded from a bundled flat SVG (`vectorResource`),
        /// rasterised crisp at TV scale and tinted with the cycling collision colour.
        case vectorOutline
        /// The "[WORD] over a disc" badge — a bold condensed wordmark (from
        /// `wordmark`, normally the user's custom text) above a flat ellipse with a
        /// centre hole. The DVD‑screensaver *form*, with your own word.
        case discBadge
    }

    public var shape: Shape
    /// Word shown for `.badge` / `.wordmark` styles.
    public var wordmark: String
    /// Resource name (no extension) of the bundled `.svg` used by `.vectorOutline`.
    public var vectorResource: String?
    /// Single character for `.monogram`.
    public var monogram: Character
    /// PostScript font name; `nil` ⇒ a heavy system rounded font.
    public var fontName: String?
    /// Base size in points at logo‑scale 1.0 (the longest edge of the logo box).
    public var baseEdge: CGFloat
    /// Corner radius as a fraction of the short edge (badge / monogram).
    public var cornerRadiusFraction: CGFloat
    /// Stroke width in points (ring / outlined styles); 0 ⇒ filled only.
    public var strokeWidth: CGFloat
    /// If true, the fill/stroke colour is the cycling collision colour; otherwise
    /// the logo keeps `fixedColor` and only the *glow* cycles.
    public var tintFollowsCollision: Bool
    public var fixedColor: RGBA
    /// Foreground (text / glyph) colour. `nil` ⇒ auto‑contrast against the fill.
    public var foregroundColor: RGBA?
    /// 0…1, how "filled" vs "outline" the badge looks.
    public var fillOpacity: Double

    public init(
        shape: Shape,
        wordmark: String = "CORNER",
        vectorResource: String? = nil,
        monogram: Character = "C",
        fontName: String? = nil,
        baseEdge: CGFloat = 280,
        cornerRadiusFraction: CGFloat = 0.5,
        strokeWidth: CGFloat = 0,
        tintFollowsCollision: Bool = true,
        fixedColor: RGBA = .white,
        foregroundColor: RGBA? = nil,
        fillOpacity: Double = 1
    ) {
        self.shape = shape
        self.wordmark = wordmark
        self.vectorResource = vectorResource
        self.monogram = monogram
        self.fontName = fontName
        self.baseEdge = baseEdge
        self.cornerRadiusFraction = cornerRadiusFraction.clamped(to: 0...0.5)
        self.strokeWidth = max(0, strokeWidth)
        self.tintFollowsCollision = tintFollowsCollision
        self.fixedColor = fixedColor
        self.foregroundColor = foregroundColor
        self.fillOpacity = fillOpacity.clamped(to: 0...1)
    }
}

// MARK: - Glow

public struct GlowSpec: Hashable, Sendable {
    /// Theme‑relative glow strength (further scaled by the user's glow setting).
    public var intensity: Double
    /// Blur radius in points at `intensity == 1`.
    public var radius: CGFloat
    /// `nil` ⇒ glow uses the logo's current colour.
    public var color: RGBA?
    /// Additive (bloom‑like) vs normal blending.
    public var additive: Bool

    public init(intensity: Double, radius: CGFloat, color: RGBA? = nil, additive: Bool = true) {
        self.intensity = intensity.clamped(to: 0...1)
        self.radius = max(0, radius)
        self.color = color
        self.additive = additive
    }

    public static let none = GlowSpec(intensity: 0, radius: 0)
}

// MARK: - Trail

public struct TrailSpec: Hashable, Sendable {
    public enum Kind: String, Hashable, Sendable {
        /// No trail.
        case none
        /// Discrete fading "ghost" copies of the logo.
        case ghosts
        /// A continuous fading ribbon following the logo centre.
        case ribbon
        /// A sparse stream of small particles dropped along the path.
        case particles
    }
    public var kind: Kind
    /// Theme‑relative density (further scaled by the user's trail setting).
    public var intensity: Double
    /// How long a ghost / ribbon segment lives, in seconds, at intensity 1.
    public var lifetime: TimeInterval
    /// Max number of simultaneous ghosts at intensity 1.
    public var maxGhosts: Int
    /// If true the trail inherits the logo's cycling colour, else `tint`.
    public var tintFollowsLogo: Bool
    public var tint: RGBA

    public init(
        kind: Kind,
        intensity: Double = 0.6,
        lifetime: TimeInterval = 0.7,
        maxGhosts: Int = 14,
        tintFollowsLogo: Bool = true,
        tint: RGBA = .white
    ) {
        self.kind = kind
        self.intensity = intensity.clamped(to: 0...1)
        self.lifetime = max(0.05, lifetime)
        self.maxGhosts = max(0, maxGhosts)
        self.tintFollowsLogo = tintFollowsLogo
        self.tint = tint
    }

    public static let none = TrailSpec(kind: .none, intensity: 0, maxGhosts: 0)
}

// MARK: - Particles (collision / corner bursts + ambient)

public struct ParticleSpec: Hashable, Sendable {
    /// Particles emitted on an ordinary wall bounce (small, quick).
    public var bounceBurst: Burst
    /// Particles emitted on a perfect corner hit (big, dramatic).
    public var cornerBurst: Burst
    /// A continuous, very subtle ambient particle field (e.g. Matrix rain,
    /// Synthwave dust). `count == 0` ⇒ disabled.
    public var ambient: AmbientField

    public init(bounceBurst: Burst, cornerBurst: Burst, ambient: AmbientField) {
        self.bounceBurst = bounceBurst
        self.cornerBurst = cornerBurst
        self.ambient = ambient
    }

    public struct Burst: Hashable, Sendable {
        public var count: Int
        public var speed: CGFloat            // points / sec
        public var speedJitter: CGFloat
        public var lifetime: TimeInterval
        public var size: CGFloat             // points
        public var spreadDegrees: CGFloat    // cone width; 360 = omnidirectional
        public var gravity: CGFloat          // points / sec², negative = up
        public var followsLogoColor: Bool
        public var colors: [RGBA]            // used when !followsLogoColor

        public init(count: Int, speed: CGFloat, speedJitter: CGFloat = 0,
                    lifetime: TimeInterval, size: CGFloat, spreadDegrees: CGFloat = 360,
                    gravity: CGFloat = 0, followsLogoColor: Bool = true, colors: [RGBA] = [.white]) {
            self.count = max(0, count)
            self.speed = speed
            self.speedJitter = max(0, speedJitter)
            self.lifetime = max(0.05, lifetime)
            self.size = max(0.5, size)
            self.spreadDegrees = spreadDegrees.clamped(to: 0...360)
            self.gravity = gravity
            self.followsLogoColor = followsLogoColor
            self.colors = colors.isEmpty ? [.white] : colors
        }
        public static let none = Burst(count: 0, speed: 0, lifetime: 0.1, size: 1)
    }

    public struct AmbientField: Hashable, Sendable {
        public enum Motion: String, Hashable, Sendable { case drift, fall, rise, twinkle }
        public var count: Int
        public var motion: Motion
        public var speed: CGFloat
        public var size: CGFloat
        public var sizeJitter: CGFloat
        public var opacity: Double
        public var colors: [RGBA]

        public init(count: Int, motion: Motion = .drift, speed: CGFloat = 12,
                    size: CGFloat = 3, sizeJitter: CGFloat = 1.5, opacity: Double = 0.18,
                    colors: [RGBA] = [.white]) {
            self.count = max(0, count)
            self.motion = motion
            self.speed = speed
            self.size = max(0.5, size)
            self.sizeJitter = max(0, sizeJitter)
            self.opacity = opacity.clamped(to: 0...1)
            self.colors = colors.isEmpty ? [.white] : colors
        }
        public static let none = AmbientField(count: 0)
    }
}

// MARK: - Post effect (full‑screen fragment shader)

public enum PostEffect: String, Hashable, Sendable {
    case none
    /// Barrel distortion + scanlines + vignette + soft bloom.
    case crt
    /// Tracking lines, chroma shift, tape noise, slight wobble.
    case vhs
}

// MARK: - Per‑theme audio mapping

public struct ThemeAudioSet: Hashable, Sendable {
    /// SFX played on an ordinary wall bounce.
    public var bounce: SoundEffectID
    /// SFX played on a logo‑to‑logo collision.
    public var logoCollision: SoundEffectID
    /// SFX played on a perfect corner hit.
    public var cornerHit: SoundEffectID
    /// SFX played on a close‑call grazing miss.
    public var nearMiss: SoundEffectID
    /// Ambient bed this theme suggests when the user picks "match theme".
    public var suggestedAmbient: AmbientMode

    public init(bounce: SoundEffectID, logoCollision: SoundEffectID,
                cornerHit: SoundEffectID, nearMiss: SoundEffectID,
                suggestedAmbient: AmbientMode) {
        self.bounce = bounce
        self.logoCollision = logoCollision
        self.cornerHit = cornerHit
        self.nearMiss = nearMiss
        self.suggestedAmbient = suggestedAmbient
    }
}
