import SpriteKit

// MARK: - Scene events

/// Everything the scene wants the SwiftUI layer to know about. The view model
/// routes these to `StatisticsStore`, `AudioController`, and the flash overlay.
public enum SceneEvent: Equatable, Sendable {
    case wallBounce(logoIndex: Int)
    case logoCollision(a: Int, b: Int)
    case closeCall(CornerHitEvent)
    case perfectCorner(CornerHitEvent)
    /// Run‑time accounting, emitted roughly twice a second.
    case runTimeElapsed(seconds: TimeInterval)
}

public protocol BounceSceneDelegate: AnyObject {
    /// Called from the scene's `update(_:)` (main thread). Implementations that
    /// touch main‑actor state should hop with `Task { @MainActor in ... }`.
    func bounceScene(_ scene: BounceScene, didProduce event: SceneEvent)
}

// MARK: - BounceScene

/// The SpriteKit scene that does the bouncing. Pure rendering + physics glue —
/// it owns no persistence and no audio; it just integrates `LogoEntity` state
/// each frame, mirrors it onto `LogoNode`s, and reports `SceneEvent`s.
///
/// Layer stack (all inside `worldNode`, which is what the optional post‑effect
/// wraps and what a corner‑hit shake nudges):
///
/// ```
/// scene
///  └─ postEffectNode? ─ worldNode
///                         ├─ backgroundLayer  (gradient/solid + vignette + grain)
///                         ├─ ambientLayer      (theme ambient particle field)
///                         ├─ trailLayer        (fading ghosts + motion‑blur smears)
///                         ├─ logoLayer         (the LogoNodes)
///                         └─ burstLayer        (collision / corner particle bursts)
/// ```
public final class BounceScene: SKScene {

    public weak var sceneDelegate: BounceSceneDelegate?
    public private(set) var sceneConfig: SceneConfig = .preview

    // Layers
    private let worldNode = SKNode()
    private let backgroundLayer = SKNode()
    private let ambientLayer = SKNode()
    private let trailLayer = SKNode()
    private let logoLayer = SKNode()
    private let burstLayer = SKNode()
    private var postEffectNode: PostEffectNode?

    // Simulation
    private var entities: [LogoEntity] = []
    private var logoNodes: [LogoNode] = []
    private var detector = CornerHitDetector(closeCallTolerance: 26)
    private lazy var trail = TrailController(layer: trailLayer)
    private var rng = SeededRandom(seed: 1)

    // Timing / lifecycle
    private var lastUpdateTime: TimeInterval = 0
    private var hasLaidOut = false
    private var needsRebuild = false
    private var pendingTextureCapture = false
    private var frameCounter: UInt64 = 0
    private var runTimeAccumulator: TimeInterval = 0

    private var playfield: CGRect { CGRect(origin: .zero, size: size) }

    // MARK: Init

    public override init(size: CGSize) {
        super.init(size: size)
        commonInit()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    public static func make(size: CGSize = CGSize(width: 1920, height: 1080), config: SceneConfig) -> BounceScene {
        let scene = BounceScene(size: size)
        scene.sceneConfig = config
        return scene
    }

    private func commonInit() {
        scaleMode = .resizeFill
        anchorPoint = .zero
        backgroundColor = sceneConfig.backgroundBaseColor.skColor

        worldNode.position = .zero
        backgroundLayer.zPosition = -100
        ambientLayer.zPosition = -50
        trailLayer.zPosition = -10
        logoLayer.zPosition = 0
        burstLayer.zPosition = 10
        worldNode.addChild(backgroundLayer)
        worldNode.addChild(ambientLayer)
        worldNode.addChild(trailLayer)
        worldNode.addChild(logoLayer)
        worldNode.addChild(burstLayer)
        addChild(worldNode)
    }

    // MARK: Configuration

    /// Push a fresh configuration. Safe to call before the scene is on screen.
    public func apply(_ newConfig: SceneConfig) {
        sceneConfig = newConfig
        backgroundColor = newConfig.backgroundBaseColor.skColor
        if hasLaidOut, size.width > 1, size.height > 1 {
            rebuildEverything()
        } else {
            needsRebuild = true
        }
    }

    // MARK: SKScene lifecycle

    public override func didMove(to view: SKView) {
        super.didMove(to: view)
        hasLaidOut = true
        view.ignoresSiblingOrder = true
        view.isAsynchronous = true
        if size.width > 1, size.height > 1 { rebuildEverything() }
    }

    public override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard hasLaidOut, size.width > 1, size.height > 1, size != oldSize else { return }
        rebuildEverything()
    }

    // MARK: Frame loop

    public override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        frameCounter &+= 1

        var dt: CGFloat
        if lastUpdateTime <= 0 { dt = 1.0 / 60.0 } else { dt = CGFloat(currentTime - lastUpdateTime) }
        lastUpdateTime = currentTime
        dt = dt.clamped(to: (1.0 / 240.0)...(1.0 / 20.0))

        if needsRebuild, hasLaidOut, size.width > 1, size.height > 1 {
            needsRebuild = false
            rebuildEverything()
            return
        }
        guard hasLaidOut, !entities.isEmpty else { return }

        if pendingTextureCapture { tryCaptureTextures() }

        let bounds = playfield
        let emitMotionBlur = sceneConfig.motionBlur > 0.02 && !sceneConfig.reduceMotion && (frameCounter % 2 == 0)

        for i in entities.indices {
            // Trail uses the node's *current* (previous‑frame) position.
            trail.update(logoID: entities[i].id, node: logoNodes[i], position: logoNodes[i].position, dt: dt)
            if emitMotionBlur, let ghost = logoNodes[i].makeMotionBlurGhost(direction: entities[i].velocity, intensity: sceneConfig.motionBlur) {
                ghost.position = logoNodes[i].position
                trailLayer.addChild(ghost)
            }

            let impact = MotionIntegrator.step(&entities[i], dt: dt, bounds: bounds)
            switch detector.classify(impact) {
            case .none:
                break
            case .wallBounce:
                recolor(i, animated: true)
                spawnBounceBurst(at: entities[i].position, color: logoNodes[i].currentColor)
                sceneDelegate?.bounceScene(self, didProduce: .wallBounce(logoIndex: i))
            case .closeCall(let corner):
                recolor(i, animated: true)
                spawnBounceBurst(at: entities[i].position, color: logoNodes[i].currentColor)
                let event = CornerHitEvent(corner: corner, speed: entities[i].speed, logoIndex: i,
                                           isCloseCall: true, themeID: sceneConfig.theme.id)
                sceneDelegate?.bounceScene(self, didProduce: .closeCall(event))
            case .perfectCorner(let corner):
                recolor(i, animated: false)
                celebrateCorner(at: entities[i].position, color: logoNodes[i].currentColor)
                if sceneConfig.screenShakeEnabled { shakeWorld(intensity: 1.0) }
                let event = CornerHitEvent(corner: corner, speed: entities[i].speed, logoIndex: i,
                                           isCloseCall: false, themeID: sceneConfig.theme.id)
                sceneDelegate?.bounceScene(self, didProduce: .perfectCorner(event))
            }
        }

        if sceneConfig.interLogoCollisions, entities.count > 1 {
            for (a, b) in CollisionResolver.resolve(&entities) {
                recolor(a, animated: true)
                recolor(b, animated: true)
                let mid = CGPoint(x: (entities[a].position.x + entities[b].position.x) / 2,
                                  y: (entities[a].position.y + entities[b].position.y) / 2)
                spawnBounceBurst(at: mid, color: logoNodes[a].currentColor)
                sceneDelegate?.bounceScene(self, didProduce: .logoCollision(a: a, b: b))
            }
        }

        for i in entities.indices { logoNodes[i].position = entities[i].position }

        runTimeAccumulator += dt
        if runTimeAccumulator >= 0.5 {
            sceneDelegate?.bounceScene(self, didProduce: .runTimeElapsed(seconds: runTimeAccumulator))
            runTimeAccumulator = 0
        }
    }

    // MARK: Rebuild

    private func rebuildEverything() {
        guard size.width > 1, size.height > 1 else { needsRebuild = true; return }
        needsRebuild = false

        rebuildPostEffect()
        postEffectNode?.updateSize(size)
        rebuildBackground()
        rebuildAmbientField()

        detector.closeCallTolerance = max(sceneConfig.cornerCloseCallTolerance, size.width * 0.010)
        detector.detectCloseCalls = sceneConfig.closeCallEffectsEnabled

        trail.configure(spec: sceneConfig.theme.trail, userIntensity: sceneConfig.trailIntensity)
        trail.reset()

        rebuildLogos()

        burstLayer.removeAllChildren()
        lastUpdateTime = 0
        pendingTextureCapture = true
        tryCaptureTextures()
    }

    private func rebuildPostEffect() {
        let wanted = sceneConfig.theme.postEffect
        if wanted == .none {
            if let pe = postEffectNode {
                worldNode.removeFromParent()
                pe.removeFromParent()
                postEffectNode = nil
                worldNode.position = .zero
                addChild(worldNode)
            }
            return
        }
        if let pe = postEffectNode, pe.effect == wanted { pe.updateSize(size); return }
        // Need a (new) post‑effect node.
        postEffectNode?.removeFromParent()
        worldNode.removeFromParent()
        let pe = PostEffectNode(effect: wanted, sceneSize: size)
        worldNode.position = .zero
        pe.position = .zero
        pe.addChild(worldNode)
        addChild(pe)
        postEffectNode = pe
    }

    private func rebuildBackground() {
        backgroundLayer.removeAllChildren()
        let bg = sceneConfig.theme.background
        let baseColor = sceneConfig.backgroundBaseColor

        // Always a full‑scene base sprite so the post‑effect's texture frame
        // matches the screen and there are never uncovered edges.
        let base = SKSpriteNode(color: baseColor.skColor, size: size)
        base.anchorPoint = .zero
        base.position = .zero
        backgroundLayer.addChild(base)

        switch bg.kind {
        case .solid:
            break
        case .linearGradient, .radialGradient:
            let stops = sceneConfig.backgroundOverride == nil ? bg.stops : [baseColor, baseColor.mixed(with: .black, t: 0.4)]
            if let tex = BackgroundTextures.gradient(stops: stops, radial: bg.kind == .radialGradient, size: size) {
                let grad = SKSpriteNode(texture: tex, size: size)
                grad.anchorPoint = .zero
                grad.position = .zero
                backgroundLayer.addChild(grad)
            }
        }

        if bg.vignette > 0.001, let tex = BackgroundTextures.vignette(strength: CGFloat(bg.vignette), size: size) {
            let v = SKSpriteNode(texture: tex, size: size)
            v.anchorPoint = .zero
            v.position = .zero
            v.blendMode = .alpha
            v.zPosition = 1
            backgroundLayer.addChild(v)
        }
        if bg.grain > 0.001 {
            let g = SKSpriteNode(texture: BackgroundTextures.grain, size: size)
            g.anchorPoint = .zero
            g.position = .zero
            g.alpha = CGFloat(bg.grain).clamped(to: 0...0.3)
            g.blendMode = .add
            g.zPosition = 2
            backgroundLayer.addChild(g)
        }
    }

    private func rebuildAmbientField() {
        ambientLayer.removeAllChildren()
        guard sceneConfig.particleDensity > 0.001 else { return }
        let density = sceneConfig.reduceMotion ? sceneConfig.particleDensity * 0.4 : sceneConfig.particleDensity
        if let e = ParticleFactory.makeAmbientField(sceneConfig.theme.particles.ambient, sceneSize: size, densityScale: density) {
            ambientLayer.addChild(e)
        }
    }

    private func rebuildLogos() {
        logoLayer.removeAllChildren()
        entities.removeAll(keepingCapacity: true)
        logoNodes.removeAll(keepingCapacity: true)
        trail.reset()

        rng = SeededRandom(seed: sceneConfig.seed == 0 ? 0xC0FFEE : sceneConfig.seed)
        let count = max(1, sceneConfig.logoCount)
        let speedMag = sceneConfig.referenceSpeed(forSceneSize: size) * sceneConfig.speedMultiplier
            * (sceneConfig.reduceMotion ? 0.6 : 1.0)
        let appearance = sceneConfig.theme.logo

        // Cap the scale so a logo never exceeds ~90% of either screen dimension.
        let probe = LogoNode(appearance: appearance, scaleFactor: sceneConfig.logoScale,
                             color: sceneConfig.theme.collisionColor(at: 0),
                             glow: sceneConfig.theme.glow, glowUserIntensity: sceneConfig.glowIntensity)
        var scale = sceneConfig.logoScale
        let half = probe.logicalHalfSize
        let maxHalfW = size.width * 0.45
        let maxHalfH = size.height * 0.45
        if half.width > maxHalfW || half.height > maxHalfH {
            let f = min(maxHalfW / max(1, half.width), maxHalfH / max(1, half.height))
            scale *= f
            probe.rebuild(appearance: appearance, scaleFactor: scale, color: sceneConfig.theme.collisionColor(at: 0),
                          glow: sceneConfig.theme.glow, glowUserIntensity: sceneConfig.glowIntensity)
        }

        for k in 0..<count {
            let node = (k == 0) ? probe : LogoNode(appearance: appearance, scaleFactor: scale,
                                                   color: sceneConfig.theme.collisionColor(at: k),
                                                   glow: sceneConfig.theme.glow,
                                                   glowUserIntensity: sceneConfig.glowIntensity)
            let hw = node.logicalHalfSize.width
            let hh = node.logicalHalfSize.height
            let x = rng.cgFloat(in: (hw + 1)...(max(hw + 2, size.width - hw - 1)))
            let y = rng.cgFloat(in: (hh + 1)...(max(hh + 2, size.height - hh - 1)))
            // Stagger the colour index so multiple logos don't share a colour at t = 0.
            let entity = LogoEntity(id: k, position: CGPoint(x: x, y: y),
                                    velocity: CGVector(angle: rng.livelyHeading(), magnitude: speedMag),
                                    halfSize: node.logicalHalfSize, colorIndex: k)
            node.position = entity.position
            if appearance.tintFollowsCollision {
                node.setColor(sceneConfig.theme.collisionColor(at: k), animated: false)
            }
            logoLayer.addChild(node)
            entities.append(entity)
            logoNodes.append(node)
        }

        // Don't let logos start mutually overlapping when collisions are on.
        if sceneConfig.interLogoCollisions, entities.count > 1 {
            for _ in 0..<6 { _ = CollisionResolver.resolve(&entities) }
            // Clamp any that got pushed out, then sync.
            for i in entities.indices {
                entities[i].position.x = entities[i].position.x.clamped(to: (entities[i].halfSize.width)...(size.width - entities[i].halfSize.width))
                entities[i].position.y = entities[i].position.y.clamped(to: (entities[i].halfSize.height)...(size.height - entities[i].halfSize.height))
                logoNodes[i].position = entities[i].position
            }
        }
    }

    private func tryCaptureTextures() {
        guard let view else { return }
        var allGood = true
        for node in logoNodes where node.trailTexture == nil {
            if node.captureTexture(using: view) == nil { allGood = false }
        }
        pendingTextureCapture = !allGood
        if allGood {
            // Re‑apply trail config now that textures exist (it short‑circuits
            // without them).
            trail.configure(spec: sceneConfig.theme.trail, userIntensity: sceneConfig.trailIntensity)
        }
    }

    // MARK: Reactions

    private func recolor(_ i: Int, animated: Bool) {
        guard sceneConfig.theme.logo.tintFollowsCollision else { return }
        let color = sceneConfig.theme.collisionColor(at: entities[i].colorIndex)
        logoNodes[i].setColor(color, animated: animated)
    }

    private func spawnBounceBurst(at point: CGPoint, color: RGBA) {
        guard sceneConfig.particleDensity > 0.001 else { return }
        let density = sceneConfig.reduceMotion ? sceneConfig.particleDensity * 0.4 : sceneConfig.particleDensity
        if let e = ParticleFactory.makeBurst(sceneConfig.theme.particles.bounceBurst, at: point,
                                             logoColor: color, densityScale: density) {
            burstLayer.addChild(e)
        }
    }

    private func celebrateCorner(at point: CGPoint, color: RGBA) {
        guard sceneConfig.cornerParticlesEnabled else { return }
        let density = max(0.4, sceneConfig.reduceMotion ? sceneConfig.particleDensity * 0.5 : sceneConfig.particleDensity)
        if let node = ParticleFactory.makeCornerCelebration(sceneConfig.theme.particles.cornerBurst, at: point,
                                                            logoColor: color, densityScale: density) {
            burstLayer.addChild(node)
        }
    }

    private func shakeWorld(intensity: CGFloat) {
        guard !sceneConfig.reduceMotion else { return }
        let amp = (10 + 8 * intensity).clamped(to: 0...22)
        worldNode.removeAction(forKey: "shake")
        var actions: [SKAction] = []
        let steps = 7
        for k in 0..<steps {
            let decay = CGFloat(steps - k) / CGFloat(steps)
            let target = CGPoint(x: CGFloat.random(in: -amp...amp) * decay,
                                 y: CGFloat.random(in: -amp...amp) * decay)
            actions.append(.move(to: target, duration: 0.028))
        }
        actions.append(.move(to: .zero, duration: 0.05))
        let seq = SKAction.sequence(actions)
        seq.timingMode = .easeOut
        worldNode.run(seq, withKey: "shake")
    }
}
