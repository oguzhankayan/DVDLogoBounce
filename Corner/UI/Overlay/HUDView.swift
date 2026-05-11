import SwiftUI

/// The minimal, auto‑hiding on‑screen display: a corner‑count pill top‑leading,
/// a live "time since last perfect corner" line, and a tiny controls hint
/// bottom‑trailing. Non‑interactive — it never steals focus.
struct HUDView: View {
    var visible: Bool
    var lastEvent: CornerHitEvent?
    @EnvironmentObject private var statistics: StatisticsStore

    @State private var now = Date()
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Counter pill (top‑leading)
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(.white.opacity(0.9))
                        .frame(width: 10, height: 10)
                    Text("CORNER")
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .tracking(4)
                }
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(Format.count(statistics.stats.totalCornerHits))
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .contentTransition(.numericText())
                    Text("perfect corners")
                        .font(.system(.callout, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
                Text("Last · \(lastCornerLine)")
                    .font(.system(.callout, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                if statistics.stats.sessionCornerHits > 0 {
                    Text("This session · \(statistics.stats.sessionCornerHits)")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 24)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.black.opacity(0.5))
                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(.white.opacity(0.12), lineWidth: 1))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            // Controls hint (bottom‑trailing)
            HStack(spacing: 14) {
                Label("Pause", systemImage: "playpause.fill")
                Text("·").foregroundStyle(.white.opacity(0.4))
                Label("Menu", systemImage: "line.3.horizontal")
            }
            .font(.system(.footnote, design: .rounded).weight(.semibold))
            .foregroundStyle(.white.opacity(0.7))
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(Capsule().fill(Color.black.opacity(0.5)).overlay(Capsule().strokeBorder(.white.opacity(0.10), lineWidth: 1)))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(visible ? 1 : 0)
        .animation(.easeInOut(duration: 0.5), value: visible)
        .onReceive(ticker) { now = $0 }
    }

    private var lastCornerLine: String {
        if let last = statistics.stats.lastCornerHit {
            return Format.duration(now.timeIntervalSince(last)) + " ago"
        }
        return "no perfect corner yet"
    }
}
