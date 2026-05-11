import SpriteKit
import UIKit

/// Builds SpriteKit emitters entirely in code (no `.sks` files) so themes can
/// describe particles as plain data. One soft round texture is generated once and
/// shared by everything.
enum ParticleFactory {

    /// A small, soft, premultiplied‑white radial dot. Tinted per‑particle via
    /// `particleColorBlendFactor`.
    static let softDot: SKTexture = {
        let dim: CGFloat = 32
        let size = CGSize(width: dim, height: dim)
        let format = UIGraphicsImageRendererFormat.preferred()
        format.opaque = false
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let cg = ctx.cgContext
            let space = CGColorSpaceCreateDeviceRGB()
            let colors = [UIColor.white.cgColor,
                          UIColor.white.withAlphaComponent(0.55).cgColor,
                          UIColor.white.withAlphaComponent(0.0).cgColor] as CFArray
            guard let grad = CGGradient(colorsSpace: space, colors: colors, locations: [0, 0.45, 1]) else { return }
            let c = CGPoint(x: dim / 2, y: dim / 2)
            cg.drawRadialGradient(grad, startCenter: c, startRadius: 0, endCenter: c, endRadius: dim / 2, options: [])
        }
        let t = SKTexture(image: image)
        t.filteringMode = .linear
        return t
    }()

    private static func textureBaseDimension() -> CGFloat { 32 }

    // MARK: One‑shot bursts

    /// A burst fired at `point` (scene coords). `logoColor` is used when the
    /// theme's burst follows the logo; otherwise a random colour from the burst's
    /// own palette is chosen for this burst.
    static func makeBurst(_ burst: ParticleSpec.Burst, at point: CGPoint, logoColor: RGBA, densityScale: CGFloat) -> SKEmitterNode? {
        let count = max(0, Int((CGFloat(burst.count) * densityScale).rounded()))
        guard count > 0 else { return nil }

        let e = SKEmitterNode()
        e.particleTexture = softDot
        e.position = point
        e.numParticlesToEmit = count
        e.particleBirthRate = CGFloat(count) / 0.06              // dump them out fast
        e.particleLifetime = CGFloat(burst.lifetime)
        e.particleLifetimeRange = CGFloat(burst.lifetime) * 0.4
        e.particleSpeed = burst.speed
        e.particleSpeedRange = burst.speedJitter
        e.emissionAngle = 0
        e.emissionAngleRange = burst.spreadDegrees * .pi / 180
        e.particlePositionRange = CGVector(dx: 6, dy: 6)
        e.particleAlpha = 0.95
        e.particleAlphaRange = 0.1
        e.particleAlphaSpeed = -0.95 / CGFloat(max(0.1, burst.lifetime))
        let scale = max(burst.size, 1) / textureBaseDimension()
        e.particleScale = scale
        e.particleScaleRange = scale * 0.4
        e.particleScaleSpeed = -scale * 0.5
        e.yAcceleration = burst.gravity
        e.particleBlendMode = .add
        e.particleColorBlendFactor = 1
        e.particleColor = (burst.followsLogoColor ? logoColor : (burst.colors.randomElement() ?? logoColor)).skColor
        e.particleRotationRange = .pi
        e.particleRotationSpeed = 2

        // Self‑destruct shortly after the last particle dies.
        e.run(.sequence([.wait(forDuration: burst.lifetime + 0.4), .removeFromParent()]))
        return e
    }

    /// A bigger, slightly slower variant for a perfect corner hit, with a ring
    /// of "spark" lines layered on top for extra punch. Returns one container
    /// node holding both.
    static func makeCornerCelebration(_ burst: ParticleSpec.Burst, at point: CGPoint, logoColor: RGBA, densityScale: CGFloat) -> SKNode? {
        guard let main = makeBurst(burst, at: point, logoColor: logoColor, densityScale: densityScale) else { return nil }
        let container = SKNode()
        container.addChild(main)

        // A short‑lived expanding ring.
        let ring = SKShapeNode(circleOfRadius: 8)
        ring.position = point
        ring.lineWidth = 6
        ring.strokeColor = (burst.followsLogoColor ? logoColor : (burst.colors.first ?? logoColor)).skColor
        ring.fillColor = .clear
        ring.glowWidth = 8
        ring.blendMode = .add
        let grow = SKAction.group([
            .scale(to: 18, duration: 0.55),
            .fadeOut(withDuration: 0.55)
        ])
        grow.timingMode = .easeOut
        ring.run(.sequence([grow, .removeFromParent()]))
        container.addChild(ring)
        return container
    }

    // MARK: Ambient field

    /// A long‑lived ambient emitter sized to the playfield. The scene re‑creates
    /// it on theme / size changes.
    static func makeAmbientField(_ field: ParticleSpec.AmbientField, sceneSize: CGSize, densityScale: CGFloat) -> SKEmitterNode? {
        let count = max(0, Int((CGFloat(field.count) * densityScale).rounded()))
        guard count > 0, sceneSize.width > 1, sceneSize.height > 1 else { return nil }

        let e = SKEmitterNode()
        e.particleTexture = softDot
        e.particleColorBlendFactor = 1
        e.particleColor = (field.colors.first ?? .white).skColor
        e.particleBlendMode = .add
        e.particleAlpha = CGFloat(field.opacity)
        e.particleAlphaRange = CGFloat(field.opacity) * 0.5
        let scale = field.size / textureBaseDimension()
        e.particleScale = scale
        e.particleScaleRange = field.sizeJitter / textureBaseDimension()

        // Cycle through the field's colours over a particle's life if it has more
        // than one (gentle hue drift).
        if field.colors.count > 1 {
            let seq = SKKeyframeSequence(keyframeValues: field.colors.map { $0.skColor },
                                         times: field.colors.indices.map { NSNumber(value: Double($0) / Double(field.colors.count - 1)) })
            e.particleColorSequence = seq
        }

        switch field.motion {
        case .fall:
            e.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height + field.size)
            e.particlePositionRange = CGVector(dx: sceneSize.width, dy: 0)
            e.emissionAngle = -.pi / 2
            e.emissionAngleRange = 0.08
            e.particleSpeed = field.speed
            e.particleSpeedRange = field.speed * 0.5
            e.particleLifetime = (sceneSize.height + field.size * 2) / max(1, field.speed)
            e.particleAlphaSpeed = -CGFloat(field.opacity) / e.particleLifetime
        case .rise:
            e.position = CGPoint(x: sceneSize.width / 2, y: -field.size)
            e.particlePositionRange = CGVector(dx: sceneSize.width, dy: 0)
            e.emissionAngle = .pi / 2
            e.emissionAngleRange = 0.10
            e.particleSpeed = field.speed
            e.particleSpeedRange = field.speed * 0.5
            e.particleLifetime = (sceneSize.height + field.size * 2) / max(1, field.speed)
            e.particleAlphaSpeed = -CGFloat(field.opacity) / e.particleLifetime
        case .drift:
            e.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
            e.particlePositionRange = CGVector(dx: sceneSize.width, dy: sceneSize.height)
            e.emissionAngle = 0
            e.emissionAngleRange = .pi * 2
            e.particleSpeed = field.speed
            e.particleSpeedRange = field.speed
            e.particleLifetime = 8
            e.particleLifetimeRange = 4
            e.particleAlphaSpeed = 0
            e.particleScaleSpeed = 0
            // Fade in then out so drifting dots don't pop.
            e.particleAlphaSequence = SKKeyframeSequence(keyframeValues: [0, CGFloat(field.opacity), CGFloat(field.opacity), 0],
                                                         times: [0, 0.15, 0.85, 1])
        case .twinkle:
            e.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
            e.particlePositionRange = CGVector(dx: sceneSize.width, dy: sceneSize.height)
            e.emissionAngle = 0
            e.emissionAngleRange = .pi * 2
            e.particleSpeed = field.speed
            e.particleSpeedRange = field.speed * 0.5
            e.particleLifetime = 1.6
            e.particleLifetimeRange = 0.8
            e.particleAlphaSequence = SKKeyframeSequence(keyframeValues: [0, CGFloat(field.opacity), 0],
                                                         times: [0, 0.5, 1])
        }
        e.particleBirthRate = CGFloat(count) / max(0.1, e.particleLifetime)
        // Pre‑warm so it isn't empty for the first second.
        e.advanceSimulationTime(e.particleLifetime)
        e.zPosition = 0
        return e
    }
}
