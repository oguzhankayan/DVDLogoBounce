import Foundation

/// Maps logical `SoundEffectID`s and `AmbientMode`s to bundled resource names.
/// (See `Resources/Sounds/README.md` for the file specs — the bundle ships
/// without the binaries; missing files just leave that channel silent.)
enum SoundResource {

    static func name(for id: SoundEffectID) -> String {
        switch id {
        case .bounceSoft:    return "bounce_soft"
        case .bounceNeon:    return "bounce_neon"
        case .bounceCRT:     return "bounce_crt"
        case .bounceMatrix:  return "bounce_matrix"
        case .logoCollision: return "logo_collision"
        case .cornerHit:     return "corner_hit"
        case .cornerHitCRT:  return "corner_hit_crt"
        case .nearMiss:      return "near_miss"
        case .uiFocus:       return "ui_focus"
        case .uiSelect:      return "ui_select"
        case .uiBack:        return "ui_back"
        }
    }

    /// `nil` ⇒ no ambient bed (Silent).
    static func ambientName(for mode: AmbientMode) -> String? {
        switch mode {
        case .silent, .matchTheme: return nil   // `.matchTheme` is resolved upstream
        case .vhsHum:   return "ambient_vhs_hum"
        case .synthPad: return "ambient_synth"
        case .roomTone: return "ambient_room"
        }
    }

    /// Candidate extensions, in preference order.
    static let extensions = ["caf", "m4a", "aac", "wav", "mp3"]

    static func url(forResourceNamed name: String, in bundle: Bundle = .main) -> URL? {
        for ext in extensions {
            if let u = bundle.url(forResource: name, withExtension: ext) { return u }
            if let u = bundle.url(forResource: name, withExtension: ext, subdirectory: "Sounds") { return u }
        }
        return nil
    }
}
