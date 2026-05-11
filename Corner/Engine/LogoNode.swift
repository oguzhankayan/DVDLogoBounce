import SpriteKit
import CoreImage
import UIKit

/// Renders one `LogoAppearance` as a SpriteKit node tree:
///
/// ```
/// LogoNode (position == logo centre)
///  ├─ glowEffect : SKEffectNode  (Gaussian‑blurred, optionally additive)
///  │    └─ glowSprite : SKSpriteNode(texture: capturedCrispTexture)   ← tinted
///  └─ crispContent : SKNode
///       ├─ paddingFrame : SKShapeNode(clear)   ← gives the blur & texture room
///       └─ <shape / label nodes for the chosen style>                 ← tinted
/// ```
///
/// The crisp content is real vector geometry (so it stays sharp at any TV size);
/// the glow is a blurred bitmap copy, which is also reused as the trail‑ghost
/// texture. The collision box (`logicalHalfSize`) is derived from the geometry,
/// independent of the invisible padding.
final class LogoNode: SKNode {

    private(set) var appearance: LogoAppearance
    private(set) var scaleFactor: CGFloat
    private(set) var currentColor: RGBA
    /// Half extents of the *visible* logo, post‑scale. The scene copies this onto
    /// the matching `LogoEntity`.
    private(set) var logicalHalfSize: CGSize = .zero

    private let glowEffect = SKEffectNode()
    private let glowSprite = SKSpriteNode()
    private let crispContent = SKNode()
    private let paddingFrame = SKShapeNode()

    /// Vector nodes whose fill / stroke track the cycling colour.
    private var tintTargets: [TintTarget] = []
    private(set) var crispTexture: SKTexture?

    private var glowSpec: GlowSpec = .none
    private var glowUserIntensity: CGFloat = 1

    private enum TintTarget {
        case fill(SKShapeNode)
        case stroke(SKShapeNode)
        case label(SKLabelNode)
        /// A white silhouette sprite tinted via `colorBlendFactor` (vector logos).
        case sprite(SKSpriteNode)
    }

    init(appearance: LogoAppearance, scaleFactor: CGFloat, color: RGBA, glow: GlowSpec, glowUserIntensity: CGFloat) {
        self.appearance = appearance
        self.scaleFactor = scaleFactor
        self.currentColor = color
        super.init()

        glowEffect.shouldRasterize = true
        glowEffect.shouldEnableEffects = true
        glowEffect.alpha = 0
        glowEffect.zPosition = -1
        glowSprite.colorBlendFactor = 1
        glowEffect.addChild(glowSprite)
        addChild(glowEffect)

        paddingFrame.fillColor = .clear
        paddingFrame.strokeColor = .clear
        paddingFrame.lineWidth = 0
        crispContent.addChild(paddingFrame)
        addChild(crispContent)

        rebuild(appearance: appearance, scaleFactor: scaleFactor, color: color, glow: glow, glowUserIntensity: glowUserIntensity)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    // MARK: Build

    func rebuild(appearance: LogoAppearance, scaleFactor: CGFloat, color: RGBA, glow: GlowSpec, glowUserIntensity: CGFloat) {
        self.appearance = appearance
        self.scaleFactor = max(0.05, scaleFactor)
        self.currentColor = color
        self.glowSpec = glow
        self.glowUserIntensity = glowUserIntensity.clamped(to: 0...1)

        // Tear down old geometry (keep paddingFrame).
        for child in crispContent.children where child !== paddingFrame { child.removeFromParent() }
        tintTargets.removeAll(keepingCapacity: true)
        crispTexture = nil
        glowSprite.texture = nil
        glowEffect.alpha = 0

        let built = LogoNode.buildGeometry(for: appearance, scale: self.scaleFactor)
        logicalHalfSize = CGSize(width: built.size.width / 2, height: built.size.height / 2)
        for node in built.nodes { crispContent.addChild(node) }
        tintTargets = built.tintTargets

        // Padding so the captured texture / blur isn't clipped.
        let pad = max(built.size.width, built.size.height) * 0.7
        let frame = CGRect(x: -built.size.width / 2 - pad, y: -built.size.height / 2 - pad,
                           width: built.size.width + pad * 2, height: built.size.height + pad * 2)
        paddingFrame.path = CGPath(rect: frame, transform: nil)

        applyColor(color, fraction: 1)
        configureGlowFilter()
    }

    /// Build the captured texture used by the glow sprite *and* by trail ghosts.
    /// Call once the node is attached to an `SKView`. Returns the texture (or
    /// `nil` if the view couldn't render it yet).
    @discardableResult
    func captureTexture(using view: SKView) -> SKTexture? {
        guard crispTexture == nil else { return crispTexture }
        guard let tex = view.texture(from: crispContent) else { return nil }
        crispTexture = tex
        glowSprite.texture = tex
        glowSprite.size = tex.size()
        configureGlowFilter()
        updateGlowVisuals()
        return tex
    }

    var trailTexture: SKTexture? { crispTexture }

    // MARK: Colour

    func setColor(_ rgba: RGBA, animated: Bool, duration: TimeInterval = 0.22) {
        let from = currentColor
        currentColor = rgba
        removeAction(forKey: "tint")
        guard animated, duration > 0 else {
            applyColor(rgba, fraction: 1)
            updateGlowVisuals()
            return
        }
        let action = SKAction.customAction(withDuration: duration) { [weak self] _, elapsed in
            guard let self else { return }
            let t = (Double(elapsed) / duration).clamped(to: 0...1)
            let mixed = from.mixed(with: rgba, t: t)
            self.applyColor(mixed, fraction: t)
        }
        run(action, withKey: "tint")
    }

    private func applyColor(_ rgba: RGBA, fraction: Double) {
        for target in tintTargets {
            switch target {
            case .fill(let n):   n.fillColor = rgba.withOpacity(rgba.opacity * appearance.fillOpacity).skColor
            case .stroke(let n): n.strokeColor = rgba.skColor
            case .label(let n):
                if appearance.foregroundColor == nil { n.fontColor = rgba.autoContrastingForeground.skColor }
            case .sprite(let n):
                n.colorBlendFactor = 1
                n.color = rgba.skColor
                n.alpha = appearance.fillOpacity
            }
        }
        // Glow follows the logo colour unless the theme pins it.
        if appearance.tintFollowsCollision || glowSpec.color != nil {
            glowSprite.color = (glowSpec.color ?? rgba).skColor
        }
        _ = fraction
    }

    // MARK: Glow

    func setGlowUserIntensity(_ value: CGFloat) {
        glowUserIntensity = value.clamped(to: 0...1)
        configureGlowFilter()
        updateGlowVisuals()
    }

    private var effectiveGlow: CGFloat { CGFloat(glowSpec.intensity) * glowUserIntensity }

    private func configureGlowFilter() {
        let g = effectiveGlow
        guard g > 0.001, glowSpec.radius > 0 else {
            glowEffect.filter = nil
            glowEffect.shouldEnableEffects = false
            return
        }
        let blur = max(1, glowSpec.radius * g)
        let f = CIFilter(name: "CIGaussianBlur")
        f?.setValue(blur, forKey: "inputRadius")
        glowEffect.filter = f
        glowEffect.shouldEnableEffects = true
        glowSprite.blendMode = glowSpec.additive ? .add : .alpha
    }

    private func updateGlowVisuals() {
        let g = effectiveGlow
        glowEffect.alpha = (crispTexture == nil) ? 0 : (0.15 + 0.85 * g) * (g > 0.001 ? 1 : 0)
        // A subtle "breathing" so a static glow doesn't look dead. Disabled when
        // glow is off; cheap (one repeating scale action on the sprite).
        glowSprite.removeAction(forKey: "breathe")
        guard g > 0.001 else { return }
        let amp = 0.04 + 0.05 * g
        let up = SKAction.scale(to: 1 + amp, duration: 1.6)
        let down = SKAction.scale(to: 1 - amp * 0.5, duration: 1.6)
        up.timingMode = .easeInEaseOut
        down.timingMode = .easeInEaseOut
        glowSprite.run(.repeatForever(.sequence([up, down])), withKey: "breathe")
    }

    /// Optional motion‑blur smear: a short‑lived stretched ghost the scene asks
    /// for when `motionBlur` > 0 (kept here so it shares the texture).
    func makeMotionBlurGhost(direction: CGVector, intensity: CGFloat) -> SKSpriteNode? {
        guard let tex = crispTexture, intensity > 0.02 else { return nil }
        let ghost = SKSpriteNode(texture: tex)
        ghost.size = tex.size()
        ghost.colorBlendFactor = 1
        ghost.color = currentColor.skColor
        ghost.alpha = 0.18 * intensity
        ghost.blendMode = glowSpec.additive ? .add : .alpha
        ghost.zPosition = -2
        let stretch = 1 + 0.6 * intensity
        ghost.xScale = direction.dx != 0 || direction.dy != 0 ? stretch : 1
        ghost.zRotation = direction.angle
        ghost.run(.sequence([.fadeOut(withDuration: 0.12 + 0.18 * intensity), .removeFromParent()]))
        return ghost
    }

    // MARK: Geometry builder

    private struct BuiltGeometry {
        var nodes: [SKNode]
        var tintTargets: [TintTarget]
        var size: CGSize       // visible logo size, post‑scale
    }

    private static func heavyFont(_ name: String?) -> String {
        // A bold, condensed‑ish system face reads well from across a room.
        name ?? "AvenirNextCondensed-Heavy"
    }

    private static func buildGeometry(for a: LogoAppearance, scale: CGFloat) -> BuiltGeometry {
        let edge = max(40, a.baseEdge * scale)
        switch a.shape {

        case .wordmark:
            let label = SKLabelNode(fontNamed: heavyFont(a.fontName))
            label.text = a.wordmark.uppercased()
            label.fontSize = edge * 0.5
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.fontColor = (a.foregroundColor ?? a.fixedColor).skColor
            let w = label.frame.width + edge * 0.08
            let h = label.frame.height + edge * 0.06
            var targets: [TintTarget] = []
            if a.foregroundColor == nil { targets.append(.label(label)) }
            return BuiltGeometry(nodes: [label], tintTargets: targets, size: CGSize(width: max(w, edge * 0.6), height: h))

        case .badge:
            // Classic wide oval / pill badge with a wordmark inside.
            let boxW = edge
            let boxH = edge * 0.62
            let radius = min(boxW, boxH) * a.cornerRadiusFraction
            let shape = SKShapeNode(rect: CGRect(x: -boxW / 2, y: -boxH / 2, width: boxW, height: boxH), cornerRadius: radius)
            shape.lineWidth = a.strokeWidth
            shape.fillColor = a.fixedColor.skColor
            shape.strokeColor = a.strokeWidth > 0 ? a.fixedColor.skColor : .clear
            let label = SKLabelNode(fontNamed: heavyFont(a.fontName))
            label.text = a.wordmark.uppercased()
            label.fontSize = boxH * 0.5
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.fontColor = (a.foregroundColor ?? a.fixedColor.autoContrastingForeground).skColor
            // Fit the wordmark inside the badge.
            let maxLabelWidth = boxW * 0.84
            if label.frame.width > maxLabelWidth { label.xScale = maxLabelWidth / label.frame.width; label.yScale = label.xScale }
            var targets: [TintTarget] = [a.fillOpacity > 0.01 ? .fill(shape) : .stroke(shape)]
            if a.strokeWidth > 0 { targets.append(.stroke(shape)) }
            if a.foregroundColor == nil { targets.append(.label(label)) }
            return BuiltGeometry(nodes: [shape, label], tintTargets: targets, size: CGSize(width: boxW, height: boxH))

        case .monogram:
            let side = edge * 0.72
            let radius = side * a.cornerRadiusFraction
            let shape = SKShapeNode(rect: CGRect(x: -side / 2, y: -side / 2, width: side, height: side), cornerRadius: radius)
            shape.lineWidth = a.strokeWidth
            shape.fillColor = a.fixedColor.withOpacity(a.fixedColor.opacity * a.fillOpacity).skColor
            shape.strokeColor = a.fixedColor.skColor
            let label = SKLabelNode(fontNamed: heavyFont(a.fontName))
            label.text = String(a.monogram).uppercased()
            label.fontSize = side * 0.62
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.fontColor = (a.foregroundColor ?? .white).skColor
            var targets: [TintTarget] = []
            if a.fillOpacity > 0.01 { targets.append(.fill(shape)) }
            if a.strokeWidth > 0 { targets.append(.stroke(shape)) }
            if a.foregroundColor == nil { targets.append(.label(label)) }
            return BuiltGeometry(nodes: [shape, label], tintTargets: targets, size: CGSize(width: side, height: side))

        case .ring:
            let r = edge * 0.4
            let stroke = a.strokeWidth > 0 ? a.strokeWidth : edge * 0.07
            let shape = SKShapeNode(circleOfRadius: r)
            shape.lineWidth = stroke
            shape.fillColor = .clear
            shape.strokeColor = a.fixedColor.skColor
            let outerInset = stroke / 2
            let side = (r + outerInset) * 2
            return BuiltGeometry(nodes: [shape], tintTargets: [.stroke(shape)], size: CGSize(width: side, height: side))

        case .pixelBlock:
            // A chunky block with a monospaced glyph — deliberately hard‑edged.
            let side = edge * 0.74
            let shape = SKShapeNode(rect: CGRect(x: -side / 2, y: -side / 2, width: side, height: side), cornerRadius: side * a.cornerRadiusFraction)
            shape.lineWidth = max(2, side * 0.04)
            shape.fillColor = a.fixedColor.withOpacity(a.fixedColor.opacity * a.fillOpacity).skColor
            shape.strokeColor = a.fixedColor.skColor
            let label = SKLabelNode(fontNamed: heavyFont(a.fontName ?? "Menlo-Bold"))
            label.text = String(a.wordmark.prefix(1)).uppercased()
            label.fontSize = side * 0.6
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.fontColor = (a.foregroundColor ?? .black).skColor
            var targets: [TintTarget] = [.fill(shape), .stroke(shape)]
            if a.foregroundColor == nil { targets.append(.label(label)) }
            return BuiltGeometry(nodes: [shape, label], tintTargets: targets, size: CGSize(width: side, height: side))

        case .vectorOutline:
            if let name = a.vectorResource, let g = outlineGeometry(named: name, longestEdge: edge) {
                return g
            }
            // Asset missing / unparseable — degrade to a plain wordmark so the
            // screensaver still runs instead of showing nothing.
            let label = SKLabelNode(fontNamed: heavyFont(a.fontName))
            label.text = a.wordmark.uppercased()
            label.fontSize = edge * 0.5
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.fontColor = (a.foregroundColor ?? a.fixedColor).skColor
            var targets: [TintTarget] = []
            if a.foregroundColor == nil { targets.append(.label(label)) }
            return BuiltGeometry(nodes: [label], tintTargets: targets,
                                 size: CGSize(width: max(label.frame.width, edge * 0.6), height: label.frame.height))

        case .discBadge:
            return discBadgeGeometry(text: a.wordmark, fontName: a.fontName, longestEdge: edge)
        }
    }

    /// "[WORD] over a disc" — the DVD‑screensaver *form* with an arbitrary word.
    /// Rendered once to a high‑res white silhouette texture (so the donut needs no
    /// fill‑rule gymnastics and the text stays crisp), then the sprite is scaled so
    /// its longest side equals `edge` — the word's width can't be known up front.
    /// Rendered‑once badge textures (the bitmap depends only on text + font; the
    /// sprite is scaled afterwards), so a theme switch or a re‑seed doesn't redraw.
    private static var discBadgeCache: [String: (texture: SKTexture, ratio: CGSize)] = [:]

    private static func discBadgeGeometry(text: String, fontName: String?, longestEdge edge: CGFloat) -> BuiltGeometry {
        let display = (text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "CORNER" : text).uppercased()
        let cacheKey = "\(display)|\(fontName ?? "")"
        if let cached = discBadgeCache[cacheKey] {
            let k = edge / max(cached.ratio.width, cached.ratio.height)
            let pointSize = CGSize(width: cached.ratio.width * k, height: cached.ratio.height * k)
            let sprite = SKSpriteNode(texture: cached.texture)
            sprite.size = pointSize
            sprite.colorBlendFactor = 1
            return BuiltGeometry(nodes: [sprite], tintTargets: [.sprite(sprite)], size: pointSize)
        }
        let renderFont: CGFloat = 220
        // Heavy + *condensed* (so the word doesn't run absurdly wide) + a touch of
        // obliqueness — evokes the DVD‑logo lettering without copying it. Custom
        // `fontName` (if a theme sets one) overrides the system condensed face.
        let font = fontName.flatMap { UIFont(name: $0, size: renderFont) }
            ?? UIFont.systemFont(ofSize: renderFont, weight: .black, width: .condensed)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.white, .obliqueness: 0.14]
        let str = NSAttributedString(string: display, attributes: attrs)
        let wm = str.size()
        // Trim the font's leading: uppercase glyphs are `capHeight` tall, but the
        // line box (`wm.height`) includes empty ascender/descender space — keeping
        // it would pad the hitbox with invisible pixels (so a "perfect corner"
        // would fire while there's still a visible gap). Draw flush to the cap.
        let topPad = max(0, font.ascender - font.capHeight)
        let bottomTrim = max(0, -font.descender)   // uppercase has no descenders
        let wmW = max(1, ceil(wm.width + renderFont * 0.10))   // a hair of slant slack
        let wmH = max(1, ceil(wm.height - topPad - bottomTrim))

        // A flat‑ish ellipse below the word, a bit wider than it, with a centre hole.
        let discW = max(wmW * 0.96, renderFont * 0.6) + renderFont * 0.2
        let discH = max(wmH * 0.6, renderFont * 0.3)
        let holeW = discW * 0.20, holeH = discH * 0.46
        let gap = wmH * 0.14   // breathing room between the word and the disc

        let texW = max(wmW, discW), texH = wmH + gap + discH
        // Super‑sample (and mip‑map below) so thin parts of a condensed glyph don't
        // shimmer/alias while the badge moves on a 4K panel — most visible under a
        // strong additive glow. Capped so a long word can't blow up the bitmap.
        let supersample = max(1, min(3, 2400 / max(texW, texH)))
        let fmt = UIGraphicsImageRendererFormat.preferred()
        fmt.scale = supersample
        fmt.opaque = false
        let image = UIGraphicsImageRenderer(size: CGSize(width: texW, height: texH), format: fmt).image { ctx in
            let c = ctx.cgContext
            // Shift up by `topPad` so the cap‑top of the glyphs lands at y == 0.
            str.draw(at: CGPoint(x: (texW - wmW) / 2, y: -topPad))
            let disc = CGRect(x: (texW - discW) / 2, y: wmH + gap, width: discW, height: discH)
            let hole = CGRect(x: (texW - holeW) / 2, y: wmH + gap + (discH - holeH) / 2, width: holeW, height: holeH)
            c.addEllipse(in: disc)
            c.addEllipse(in: hole)
            c.setFillColor(UIColor.white.cgColor)
            c.fillPath(using: .evenOdd)
        }

        let texture = SKTexture(image: image)
        texture.usesMipmaps = true
        discBadgeCache[cacheKey] = (texture, CGSize(width: texW, height: texH))

        let k = edge / max(texW, texH)
        let pointSize = CGSize(width: texW * k, height: texH * k)
        let sprite = SKSpriteNode(texture: texture)
        sprite.size = pointSize
        sprite.colorBlendFactor = 1
        return BuiltGeometry(nodes: [sprite], tintTargets: [.sprite(sprite)], size: pointSize)
    }

    /// Cache so we only parse each SVG once per process.
    private static var outlineCache: [String: SVGOutline.Parsed] = [:]

    /// Rasterise a bundled flat SVG into a white, alpha‑shaped sprite scaled so its
    /// longest edge is `edge` points. The sprite is tinted later via `applyColor`.
    private static func outlineGeometry(named name: String, longestEdge edge: CGFloat) -> BuiltGeometry? {
        let parsed: SVGOutline.Parsed
        if let c = outlineCache[name] { parsed = c }
        else if let p = SVGOutline.load(named: name) { outlineCache[name] = p; parsed = p }
        else { return nil }

        // Scale to the actual ink, not the SVG canvas — exported logos often sit
        // inside a much larger viewBox (or a white background rect), and using
        // that would make the bouncing logo tiny with a huge invisible margin.
        let bb = parsed.path.boundingBoxOfPath
        guard bb.width > 0, bb.height > 0 else { return nil }
        let k = edge / max(bb.width, bb.height)
        let pointSize = CGSize(width: bb.width * k, height: bb.height * k)

        // Super‑sample for crisp edges on 4K panels, but cap the bitmap.
        let cap: CGFloat = 1600
        let supersample = max(1, min(3, cap / max(pointSize.width, pointSize.height)))
        let fmt = UIGraphicsImageRendererFormat.preferred()
        fmt.scale = supersample
        fmt.opaque = false

        let image = UIGraphicsImageRenderer(size: pointSize, format: fmt).image { ctx in
            let c = ctx.cgContext
            c.translateBy(x: -bb.minX * k, y: -bb.minY * k)
            c.scaleBy(x: k, y: k)
            c.addPath(parsed.path)
            c.setFillColor(UIColor.white.cgColor)
            c.fillPath(using: .evenOdd)
        }

        let texture = SKTexture(image: image)
        texture.usesMipmaps = true
        let sprite = SKSpriteNode(texture: texture)
        sprite.size = pointSize
        sprite.colorBlendFactor = 1
        return BuiltGeometry(nodes: [sprite], tintTargets: [.sprite(sprite)], size: pointSize)
    }
}
