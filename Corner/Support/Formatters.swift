import Foundation

enum Format {

    /// "12,408" — thousands‑separated integer.
    static func count(_ n: Int) -> String {
        countFormatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    /// "2h 14m", "8m 03s", "41s" — compact, large‑screen friendly elapsed time.
    static func duration(_ seconds: TimeInterval) -> String {
        let s = max(0, Int(seconds.rounded()))
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 { return "\(h)h \(String(format: "%02dm", m))" }
        if m > 0 { return "\(m)m \(String(format: "%02ds", sec))" }
        return "\(sec)s"
    }

    /// "just now", "3 minutes ago", "1 hour ago", "2 days ago", "—" for nil.
    static func relative(_ date: Date?, now: Date = Date()) -> String {
        guard let date else { return "—" }
        let delta = now.timeIntervalSince(date)
        if delta < 5 { return "just now" }
        return relativeFormatter.localizedString(for: date, relativeTo: now)
    }

    /// "Top‑Left · 3 min ago" style line used on the stats screen.
    static func cornerLine(_ event: CornerHitEvent, now: Date = Date()) -> String {
        "\(event.corner.displayName) · \(relative(event.date, now: now))"
    }

    /// A "live ticking" string for the HUD ("time since last perfect corner").
    /// Caller refreshes it on a timer.
    static func sinceLastCorner(_ stats: Statistics, now: Date = Date()) -> String {
        guard let last = stats.lastCornerHit else { return "No perfect corner yet" }
        return duration(now.timeIntervalSince(last))
    }

    private static let countFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .full
        return f
    }()
}
