import SwiftUI

/// The dramatic (but tasteful) flash on a perfect corner hit: a colour‑tinted
/// bloom anchored at the corner that was struck, plus a barely‑there full‑screen
/// lift. Keyed off `CornerFlash.id` so each hit retriggers it. Honours the
/// user's "screen flash" toggle upstream (this view is only created when on).
struct CornerFlashView: View {
    let flash: ScreensaverViewModel.CornerFlash?

    @State private var phase: CGFloat = 0       // 0 hidden → 1 peak
    @State private var lastID: Int?

    private var bloomColor: Color {
        let c = flash?.color ?? .white
        return c.mixed(with: .white, t: 0.6).color
    }

    var body: some View {
        GeometryReader { geo in
            let anchor = unitPoint(for: flash?.corner ?? .topLeft)
            ZStack {
                // Faint whole‑screen lift.
                Color.white.opacity(0.18 * Double(phase)).ignoresSafeArea()

                // Corner bloom.
                RadialGradient(colors: [bloomColor.opacity(0.95 * Double(phase)),
                                        bloomColor.opacity(0.35 * Double(phase)),
                                        .clear],
                               center: anchor,
                               startRadius: 0,
                               endRadius: max(geo.size.width, geo.size.height) * 0.95)
                    .ignoresSafeArea()
                    .blendMode(.screen)
            }
        }
        .ignoresSafeArea()
        .onChange(of: flash?.id) { _, newID in
            guard let newID, newID != lastID else { return }
            lastID = newID
            phase = 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                withAnimation(.easeOut(duration: 0.6)) { phase = 0 }
            }
        }
    }

    private func unitPoint(for corner: ScreenCorner) -> UnitPoint {
        switch corner {
        case .topLeft:     return UnitPoint(x: 0.02, y: 0.02)
        case .topRight:    return UnitPoint(x: 0.98, y: 0.02)
        case .bottomLeft:  return UnitPoint(x: 0.02, y: 0.98)
        case .bottomRight: return UnitPoint(x: 0.98, y: 0.98)
        }
    }
}
