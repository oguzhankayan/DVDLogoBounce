import SwiftUI

/// The statistics screen — the long‑tail reason to keep the app installed.
/// All on‑device, no accounts, no tracking.
struct StatisticsView: View {
    @EnvironmentObject private var statistics: StatisticsStore
    @EnvironmentObject private var settings: AppSettings
    @State private var now = Date()
    @State private var confirmingReset = false
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private let columns = [GridItem(.adaptive(minimum: 280, maximum: 360), spacing: 24)]

    var body: some View {
        let s = statistics.stats
        let accent = settings.resolvedTheme.collisionColor(at: 1).color
        ScrollView {
            VStack(alignment: .leading, spacing: 36) {
                ScreenTitle(title: "Statistics", subtitle: "Owned since \(Self.day.string(from: s.firstLaunch)).")

                LazyVGrid(columns: columns, spacing: 24) {
                    StatTile(label: "Perfect corners", value: Format.count(s.totalCornerHits),
                             systemImage: "star.circle.fill", accent: accent)
                    StatTile(label: "Time since last perfect corner",
                             value: s.lastCornerHit.map { Format.duration(now.timeIntervalSince($0)) } ?? "—",
                             systemImage: "clock.fill", accent: accent)
                    StatTile(label: "This session", value: Format.count(s.sessionCornerHits),
                             systemImage: "bolt.circle.fill")
                    StatTile(label: "Best session ever", value: Format.count(s.longestSession),
                             systemImage: "trophy.fill")
                    StatTile(label: "Close calls", value: Format.count(s.totalCloseCalls),
                             systemImage: "scope")
                    StatTile(label: "Wall bounces", value: Format.count(s.totalWallBounces),
                             systemImage: "arrow.left.arrow.right")
                    StatTile(label: "Total run time", value: Format.duration(s.totalRunTime),
                             systemImage: "hourglass")
                    StatTile(label: "Longest dry spell rewarded",
                             value: s.longestDryGap.map { Format.duration($0) } ?? "—",
                             systemImage: "tortoise.fill")
                }

                // By‑corner breakdown
                VStack(alignment: .leading, spacing: 18) {
                    SectionHeader(title: "By corner", subtitle: "Which corner gives it up the most.")
                    HStack(spacing: 20) {
                        ForEach(ScreenCorner.allCases) { corner in
                            CornerBar(corner: corner,
                                      count: s.count(for: corner),
                                      maxCount: max(1, ScreenCorner.allCases.map { s.count(for: $0) }.max() ?? 1),
                                      accent: accent)
                        }
                    }
                }

                if let last = statistics.stats.lastCornerHit {
                    Text("Last perfect corner: \(Self.dateTime.string(from: last))")
                        .font(.system(.callout, design: .rounded))
                        .foregroundStyle(.tertiary)
                }

                // Reset
                HStack {
                    Button(role: confirmingReset ? .destructive : nil) {
                        if confirmingReset { statistics.resetAllStatistics(); confirmingReset = false }
                        else {
                            confirmingReset = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { confirmingReset = false }
                        }
                    } label: {
                        Label(confirmingReset ? "Tap again to erase all statistics" : "Reset statistics",
                              systemImage: confirmingReset ? "exclamationmark.triangle.fill" : "trash")
                            .font(.system(.headline, design: .rounded).weight(.semibold))
                    }
                    .buttonStyle(CardButtonStyle(cornerRadius: 18, accent: confirmingReset ? .red : .white))
                    Spacer()
                }
                Color.clear.frame(height: 40)
            }
            .padding(.horizontal, 90)
            .padding(.vertical, 70)
            .frame(maxWidth: 1400, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .onReceive(ticker) { now = $0 }
    }

    private static let day: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none; return f
    }()
    private static let dateTime: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .short; return f
    }()
}

private struct CornerBar: View {
    var corner: ScreenCorner
    var count: Int
    var maxCount: Int
    var accent: Color

    var body: some View {
        VStack(spacing: 10) {
            Text(Format.count(count)).font(.system(.title3, design: .rounded).weight(.bold)).monospacedDigit()
            GeometryReader { geo in
                let h = max(6, geo.size.height * CGFloat(count) / CGFloat(maxCount))
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.06))
                    RoundedRectangle(cornerRadius: 10).fill(accent.opacity(0.85)).frame(height: h)
                }
            }
            .frame(height: 120)
            Label(corner.displayName, systemImage: corner.symbolName)
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(.white.opacity(0.08), lineWidth: 1))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("Statistics") {
    let env = AppEnvironment.preview(themeID: .neon)
    return StatisticsView().injecting(env)
}
