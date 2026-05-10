import SpriteKit

/// Spawns and ages the fading "ghost" trail behind each logo. All ghosts live in
/// a single layer node behind the logos. A per‑logo budget caps how many are
/// alive at once so density scales smoothly with the user's trail slider.
///
/// (A node pool would shave a little allocation churn — noted in Docs/ROADMAP —
/// but at the counts involved here SpriteKit copes comfortably at 60 fps.)
final class TrailController {

    private unowned let layer: SKNode
    private var spec: TrailSpec = .none
    private var userIntensity: CGFloat = 0
    /// Seconds between ghost emissions per logo (smaller ⇒ denser).
    private var emitInterval: TimeInterval = 1.0 / 30.0
    private var lifetime: TimeInterval = 0.6
    private var ghostScale: CGFloat = 1
    private var maxPerLogo: Int = 0

    private struct LogoTrailState {
        var liveCount = 0
        var timeSinceEmit: TimeInterval = 0
    }
    private var states: [Int: LogoTrailState] = [:]

    init(layer: SKNode) { self.layer = layer }

    func configure(spec: TrailSpec, userIntensity: CGFloat) {
        self.spec = spec
        self.userIntensity = userIntensity.clamped(to: 0...1)
        let i = CGFloat(spec.intensity) * self.userIntensity
        switch spec.kind {
        case .none:
            maxPerLogo = 0
        case .ghosts:
            ghostScale = 1
            lifetime = spec.lifetime * Double(0.5 + 0.8 * i)
            emitInterval = TimeInterval(1.0 / (10.0 + 50.0 * Double(i)))
            maxPerLogo = Int((CGFloat(spec.maxGhosts) * i).rounded())
        case .ribbon:
            ghostScale = 0.62
            lifetime = spec.lifetime * Double(0.4 + 0.7 * i)
            emitInterval = TimeInterval(1.0 / (30.0 + 60.0 * Double(i)))
            maxPerLogo = Int((CGFloat(spec.maxGhosts) * 1.6 * i).rounded())
        case .particles:
            ghostScale = 0.22
            lifetime = spec.lifetime * Double(0.5 + 0.6 * i)
            emitInterval = TimeInterval(1.0 / (16.0 + 30.0 * Double(i)))
            maxPerLogo = Int((CGFloat(spec.maxGhosts) * 0.8 * i).rounded())
        }
        if maxPerLogo <= 0 { reset() }
    }

    func reset() {
        layer.removeAllChildren()
        states.removeAll(keepingCapacity: true)
    }

    func forget(logoID: Int) { states[logoID] = nil }

    /// Call once per frame for each logo, *before* moving the node, with the
    /// logo node's world position and its current colour.
    func update(logoID: Int, node: LogoNode, position: CGPoint, dt: TimeInterval) {
        guard maxPerLogo > 0, spec.kind != .none, let tex = node.trailTexture else { return }
        var state = states[logoID] ?? LogoTrailState()
        state.timeSinceEmit += dt
        if state.timeSinceEmit >= emitInterval, state.liveCount < maxPerLogo {
            state.timeSinceEmit = 0
            state.liveCount += 1
            emitGhost(texture: tex, at: position, color: trailColor(for: node), logoID: logoID, baseSize: node.frame.size)
        }
        states[logoID] = state
    }

    private func trailColor(for node: LogoNode) -> RGBA {
        spec.tintFollowsLogo ? node.currentColor : spec.tint
    }

    private func emitGhost(texture: SKTexture, at position: CGPoint, color: RGBA, logoID: Int, baseSize: CGSize) {
        let ghost = SKSpriteNode(texture: texture)
        ghost.size = texture.size()
        ghost.position = position
        ghost.setScale(ghostScale)
        ghost.colorBlendFactor = 1
        ghost.color = color.skColor
        ghost.alpha = (0.10 + 0.35 * CGFloat(spec.intensity) * userIntensity).clamped(to: 0...0.55)
        ghost.blendMode = .add
        layer.addChild(ghost)

        let fade = SKAction.group([
            .fadeOut(withDuration: lifetime),
            .scale(by: ghostScale > 0.4 ? 0.92 : 0.7, duration: lifetime)
        ])
        ghost.run(.sequence([fade, .removeFromParent(), .run { [weak self] in
            self?.states[logoID]?.liveCount -= 1
        }]))
    }
}
