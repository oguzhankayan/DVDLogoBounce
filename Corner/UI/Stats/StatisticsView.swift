import SwiftUI

/// The statistics screen — the long‑tail reason to keep the app installed.
/// Leads with the two numbers people actually care about (perfect corners, and
/// how long since the last one), then the per‑corner picture, then a plain list,
/// then the reset button. Each block is (invisibly) focusable so the remote can
/// scroll the page and the menu keeps capturing the Menu button — without that,
/// focus strands after the page transition and Menu quits the app.
struct StatisticsView: View {
    @EnvironmentObject private var statistics: StatisticsStore
    @EnvironmentObject private var settings: AppSettings
    @State private var now = Date()
    @State private var confirmingReset = false
    @FocusState private var focused: Int?
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        let s = statistics.stats
        let accent = settings.resolvedTheme.collisionColor(at: 1).color
        ScrollView {
            VStack(alignment: .leading, spacing: 44) {
                ScreenTitle(title: "Statistics",
                            subtitle: "Owned since \(Self.day.string(from: s.firstLaunch)). Everything here stays on this Apple TV.")

                HStack(alignment: .top, spacing: 80) {
                    bigStat(Format.count(s.totalCornerHits), "perfect corners", accent)
                    bigStat(s.lastCornerHit.map { Format.duration(now.timeIntervalSince($0)) } ?? "none yet",
                            "since the last one", accent.opacity(0.85))
                }
                .scrollBlock($focused, 0)

                VStack(alignment: .leading, spacing: 18) {
                    SectionHeader(title: "By corner", subtitle: "Which corner gives it up the most.")
                    HStack(spacing: 22) {
                        let maxCount = max(1, ScreenCorner.allCases.map { s.count(for: $0) }.max() ?? 1)
                        ForEach(ScreenCorner.allCases) { corner in
                            CornerBar(corner: corner, count: s.count(for: corner), maxCount: maxCount, accent: accent)
                        }
                    }
                }
                .scrollBlock($focused, 1)

                VStack(alignment: .leading, spacing: 18) {
                    SectionHeader(title: "Lifetime")
                    GlassCard(cornerRadius: 20, padding: 6) {
                        VStack(spacing: 0) {
                            row("This session", Format.count(s.sessionCornerHits))
                            sep
                            row("Best session ever", Format.count(s.longestSession))
                            sep
                            row("Close calls", Format.count(s.totalCloseCalls))
                            sep
                            row("Wall bounces", Format.count(s.totalWallBounces))
                            sep
                            row("Total run time", Format.duration(s.totalRunTime))
                            sep
                            row("Longest dry spell rewarded", s.longestDryGap.map { Format.duration($0) } ?? "none yet")
                            if let last = s.lastCornerHit {
                                sep
                                row("Last perfect corner", Self.dateTime.string(from: last))
                            }
                        }
                    }
                }
                .scrollBlock($focused, 2)

                HStack {
                    Button(role: confirmingReset ? .destructive : nil) {
                        if confirmingReset {
                            statistics.resetAllStatistics(); confirmingReset = false
                        } else {
                            confirmingReset = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { confirmingReset = false }
                        }
                    } label: {
                        Label(confirmingReset ? "Press again to erase all statistics" : "Reset statistics",
                              systemImage: confirmingReset ? "exclamationmark.triangle.fill" : "trash")
                            .font(.system(.headline, design: .rounded).weight(.semibold))
                    }
                    .buttonStyle(CardButtonStyle(cornerRadius: 18, accent: confirmingReset ? .red : .white))
                    .focused($focused, equals: 3)
                    Spacer()
                }

                Color.clear.frame(height: 40)
            }
            .padding(.horizontal, 90)
            .padding(.vertical, 70)
            .frame(maxWidth: 1400, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .onAppear { DispatchQueue.main.async { focused = 0 } }
        .onReceive(ticker) { now = $0 }
    }

    private func bigStat(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.system(size: 96, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
                .minimumScaleFactor(0.35)
                .lineLimit(1)
                .contentTransition(.numericText())
            Text(label.uppercased())
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.system(.title3, design: .rounded))
            Spacer(minLength: 24)
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
    }

    private var sep: some View {
        Rectangle().fill(.white.opacity(0.06)).frame(height: 1).padding(.horizontal, 18)
    }

    private static let day: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none; return f
    }()
    private static let dateTime: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .short; return f
    }()
}

/// Makes a non‑interactive block invisibly focusable so the remote can scroll
/// past it (and a parent `onExitCommand` keeps capturing the Menu button).
private extension View {
    func scrollBlock(_ binding: FocusState<Int?>.Binding, _ index: Int) -> some View {
        self.focusable().focusEffectDisabled().focused(binding, equals: index)
    }
}

private struct CornerBar: View {
    var corner: ScreenCorner
    var count: Int
    var maxCount: Int
    var accent: Color

    var body: some View {
        VStack(spacing: 10) {
            Text(Format.count(count))
                .font(.system(.title3, design: .rounded).weight(.bold))
                .monospacedDigit()
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
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.black.opacity(0.40))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(.white.opacity(0.07), lineWidth: 1))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("Statistics") {
    StatisticsView().injecting(.preview(themeID: .neon))
}
