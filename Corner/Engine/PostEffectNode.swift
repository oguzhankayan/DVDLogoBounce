import SpriteKit
import simd

/// A full‑screen post‑process wrapper. The whole world is parented inside this
/// `SKEffectNode`; when `effect != .none` its `shader` runs over the rendered
/// frame (barrel + scanlines for CRT, chroma‑split + tape noise for VHS).
///
/// Render‑to‑texture every frame isn't free, so this node is only inserted into
/// the tree for themes that ask for it; everyone else keeps a direct path.
final class PostEffectNode: SKEffectNode {

    let effect: PostEffect
    private let resolutionUniform = SKUniform(name: "u_resolution", vectorFloat2: vector_float2(1920, 1080))

    init(effect: PostEffect, sceneSize: CGSize) {
        self.effect = effect
        super.init()
        shouldRasterize = false
        shouldEnableEffects = effect != .none
        guard effect != .none else { return }
        let uniforms = Self.makeUniforms(for: effect) + [resolutionUniform]
        shader = SKShader(source: Self.source(for: effect), uniforms: uniforms)
        updateSize(sceneSize)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    func updateSize(_ size: CGSize) {
        let w = Float(max(1, size.width))
        let h = Float(max(1, size.height))
        resolutionUniform.vectorFloat2Value = vector_float2(w, h)
    }

    // MARK: Uniform defaults

    private static func makeUniforms(for effect: PostEffect) -> [SKUniform] {
        switch effect {
        case .none: return []
        case .crt:
            return [
                SKUniform(name: "u_curvature", float: 0.10),
                SKUniform(name: "u_scanlineStrength", float: 0.22),
                SKUniform(name: "u_scanDensity", float: 1.0),
                SKUniform(name: "u_maskStrength", float: 0.10),
                SKUniform(name: "u_vignette", float: 0.55),
            ]
        case .vhs:
            return [
                SKUniform(name: "u_chroma", float: 1.0),
                SKUniform(name: "u_noise", float: 0.05),
                SKUniform(name: "u_desat", float: 0.22),
                SKUniform(name: "u_vignette", float: 0.45),
            ]
        }
    }

    // MARK: Shader source

    private static func source(for effect: PostEffect) -> String {
        switch effect {
        case .none: return passthrough
        case .crt:  return crt
        case .vhs:  return vhs
        }
    }

    private static let passthrough = """
    void main() { gl_FragColor = texture2D(u_texture, v_tex_coord); }
    """

    private static let crt = """
    void main() {
        vec2 uv = v_tex_coord;
        vec2 cc = uv - 0.5;
        float r2 = dot(cc, cc);
        // Gentle barrel distortion.
        vec2 suv = 0.5 + cc * (1.0 + r2 * u_curvature);
        if (suv.x < 0.0 || suv.x > 1.0 || suv.y < 0.0 || suv.y > 1.0) {
            gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
            return;
        }
        vec4 col = texture2D(u_texture, suv);

        // Scanlines.
        float scan = 0.5 + 0.5 * cos(suv.y * u_resolution.y * 3.14159265 * u_scanDensity * 0.5);
        col.rgb *= mix(1.0, 0.6 + 0.4 * scan, u_scanlineStrength);

        // Soft aperture‑grille mask.
        float m = mod(floor(suv.x * u_resolution.x), 3.0);
        vec3 mask = vec3(m < 0.5 ? 1.06 : 0.97,
                         (m > 0.5 && m < 1.5) ? 1.06 : 0.97,
                         m > 1.5 ? 1.06 : 0.97);
        col.rgb *= mix(vec3(1.0), mask, u_maskStrength);

        // Vignette + a touch of phosphor lift.
        col.rgb *= clamp(1.0 - r2 * u_vignette, 0.0, 1.0);
        col.rgb = pow(max(col.rgb, vec3(0.0)), vec3(0.94));
        gl_FragColor = vec4(col.rgb, 1.0);
    }
    """

    private static let vhs = """
    void main() {
        vec2 uv = v_tex_coord;
        float t = u_time;

        // Subtle continuous wobble + a slow scrolling tracking line.
        float wob = sin(uv.y * 90.0 + t * 3.1) * 0.0014 + sin(uv.y * 11.0 - t * 1.6) * 0.0026;
        float lineY = fract(t * 0.06);
        float nearLine = 1.0 - smoothstep(0.0, 0.05, abs(uv.y - lineY));
        vec2 off = vec2(wob + nearLine * 0.02 * sin(t * 47.0), 0.0);

        // Chroma split.
        float ca = u_chroma * (0.0026 + nearLine * 0.010);
        float cr = texture2D(u_texture, clamp(uv + off + vec2(ca, 0.0), 0.0, 1.0)).r;
        float cg = texture2D(u_texture, clamp(uv + off, 0.0, 1.0)).g;
        float cb = texture2D(u_texture, clamp(uv + off - vec2(ca, 0.0), 0.0, 1.0)).b;
        vec3 col = vec3(cr, cg, cb);

        // Tape noise.
        float n = fract(sin(dot(uv * vec2(t + 1.3, t + 2.7), vec2(12.9898, 78.233))) * 43758.5453);
        col += (n - 0.5) * u_noise;
        col += nearLine * 0.05;

        // Gentle scanlines + warm desaturation.
        col *= 0.93 + 0.07 * cos(uv.y * u_resolution.y * 3.14159265);
        float luma = dot(col, vec3(0.299, 0.587, 0.114));
        col = mix(col, vec3(luma), u_desat);
        col *= vec3(1.05, 1.0, 0.95);

        // Vignette.
        vec2 cc = uv - 0.5;
        col *= clamp(1.0 - dot(cc, cc) * u_vignette, 0.0, 1.0);
        gl_FragColor = vec4(max(col, vec3(0.0)), 1.0);
    }
    """
}
