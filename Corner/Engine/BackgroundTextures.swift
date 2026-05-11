import SpriteKit
import UIKit

/// Generates the (cached) bitmap textures the scene uses for its background:
/// a gradient fill, a soft radial vignette, and a tiny grain tile. All produced
/// with Core Graphics so nothing here needs a live `SKView`.
enum BackgroundTextures {

    /// `stops[0]` is the *bottom* of the screen, `stops[last]` the top (linear),
    /// or centre → edge (radial). Render size is capped for performance and the
    /// result is stretched to the real screen size by the sprite.
    static func gradient(stops: [RGBA], radial: Bool, size: CGSize) -> SKTexture? {
        guard size.width > 1, size.height > 1 else { return nil }
        let safeStops = stops.isEmpty ? [RGBA.black] : stops
        let maxDim: CGFloat = 1024
        let s = min(1, maxDim / max(size.width, size.height))
        let renderSize = CGSize(width: max(2, (size.width * s).rounded()),
                                height: max(2, (size.height * s).rounded()))
        let format = UIGraphicsImageRendererFormat.preferred()
        format.opaque = true
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: renderSize, format: format).image { ctx in
            let cg = ctx.cgContext
            let colors = safeStops.map { $0.skColor.cgColor } as CFArray
            let locations: [CGFloat] = safeStops.count == 1
                ? [0]
                : safeStops.indices.map { CGFloat($0) / CGFloat(safeStops.count - 1) }
            guard let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) else {
                cg.setFillColor(safeStops[0].skColor.cgColor)
                cg.fill(CGRect(origin: .zero, size: renderSize))
                return
            }
            if radial {
                let c = CGPoint(x: renderSize.width / 2, y: renderSize.height / 2)
                let r = max(renderSize.width, renderSize.height) * 0.74
                cg.drawRadialGradient(grad, startCenter: c, startRadius: 0, endCenter: c, endRadius: r,
                                      options: [.drawsAfterEndLocation])
            } else {
                cg.drawLinearGradient(grad,
                                      start: CGPoint(x: renderSize.width / 2, y: renderSize.height),
                                      end: CGPoint(x: renderSize.width / 2, y: 0),
                                      options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
            }
        }
        return SKTexture(image: image)
    }

    /// A transparent‑centre → translucent‑black‑edge overlay. `strength` ≈ how
    /// dark the corners get (0…1).
    static func vignette(strength: CGFloat, size: CGSize) -> SKTexture? {
        guard size.width > 1, size.height > 1, strength > 0.001 else { return nil }
        let maxDim: CGFloat = 768
        let s = min(1, maxDim / max(size.width, size.height))
        let renderSize = CGSize(width: max(2, (size.width * s).rounded()),
                                height: max(2, (size.height * s).rounded()))
        let format = UIGraphicsImageRendererFormat.preferred()
        format.opaque = false
        format.scale = 1
        let edgeAlpha = min(0.95, strength)
        let image = UIGraphicsImageRenderer(size: renderSize, format: format).image { ctx in
            let cg = ctx.cgContext
            let colors = [UIColor.black.withAlphaComponent(0).cgColor,
                          UIColor.black.withAlphaComponent(0).cgColor,
                          UIColor.black.withAlphaComponent(edgeAlpha).cgColor] as CFArray
            guard let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors,
                                        locations: [0, 0.55, 1]) else { return }
            let c = CGPoint(x: renderSize.width / 2, y: renderSize.height / 2)
            let r = (renderSize.width * renderSize.width + renderSize.height * renderSize.height).squareRoot() / 2
            cg.drawRadialGradient(grad, startCenter: c, startRadius: 0, endCenter: c, endRadius: r,
                                  options: [.drawsAfterEndLocation])
        }
        return SKTexture(image: image)
    }

    /// A small premultiplied‑white noise tile, scaled up by the sprite. Cheap
    /// "film grain"; the caller controls intensity via the sprite's alpha.
    static let grain: SKTexture = {
        let dim = 256
        var pixels = [UInt8](repeating: 0, count: dim * dim * 4)
        var g = SeededRandom(seed: 0xA11CE)
        for i in 0..<(dim * dim) {
            let v = UInt8(g.int(in: 90...255))
            pixels[i * 4 + 0] = v
            pixels[i * 4 + 1] = v
            pixels[i * 4 + 2] = v
            pixels[i * 4 + 3] = v   // premultiplied: a == rgb
        }
        let data = Data(pixels)
        let texture = SKTexture(data: data, size: CGSize(width: dim, height: dim))
        texture.filteringMode = .nearest
        return texture
    }()
}
