import Foundation
import CoreGraphics

/// Resolves logo‑to‑logo overlaps as equal‑mass elastic circle collisions, then
/// renormalises each logo to its pre‑collision speed so the "it never slows
/// down" feel is preserved. O(n²), but n ≤ 12.
public enum CollisionResolver {

    /// Mutates `entities` in place. Returns the index pairs that actually
    /// collided this step (for sparks / SFX). `restitution` < 1 only affects the
    /// separation impulse, not the constant‑speed renormalisation.
    @discardableResult
    public static func resolve(_ entities: inout [LogoEntity]) -> [(Int, Int)] {
        var collided: [(Int, Int)] = []
        guard entities.count > 1 else { return collided }

        for i in 0..<(entities.count - 1) {
            for j in (i + 1)..<entities.count {
                let a = entities[i]
                let b = entities[j]
                var delta = a.position - b.position             // points from b → a
                var dist = delta.magnitude
                let minDist = a.collisionRadius + b.collisionRadius
                guard dist < minDist else { continue }

                if dist < 1e-4 {
                    // Perfectly stacked — invent a deterministic separation axis.
                    delta = CGVector(dx: (a.id & 1 == 0) ? 1 : -1, dy: (b.id & 1 == 0) ? 1 : -1).normalized
                    dist = 0
                }
                let n = delta.normalized
                let overlap = minDist - dist

                // Push apart symmetrically.
                entities[i].position = entities[i].position + n.scaled(by: overlap * 0.5)
                entities[j].position = entities[j].position - n.scaled(by: overlap * 0.5)

                let va = a.velocity, vb = b.velocity
                let relAlongN = (va - vb).dot(n)
                // Only exchange momentum if they're approaching along the normal.
                guard relAlongN < 0 else {
                    collided.append((i, j))
                    continue
                }
                let aN = va.dot(n)
                let bN = vb.dot(n)
                var va2 = va + n.scaled(by: bN - aN)
                var vb2 = vb + n.scaled(by: aN - bN)
                // Constant‑speed aesthetic.
                if va.magnitude > 0 { va2 = va2.with(magnitude: va.magnitude) }
                if vb.magnitude > 0 { vb2 = vb2.with(magnitude: vb.magnitude) }
                entities[i].velocity = va2
                entities[j].velocity = vb2
                entities[i].colorIndex &+= 1
                entities[j].colorIndex &+= 1
                collided.append((i, j))
            }
        }
        return collided
    }
}
