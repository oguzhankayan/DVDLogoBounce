import Foundation
import CoreGraphics

/// A tiny, dependency‑free reader for the kind of *flat, single‑colour* SVGs an
/// illustrator exports for a logo: a handful of `<path>`, `<polygon>`, `<polyline>`
/// and `<rect>` elements with no transforms, gradients or strokes. It turns them
/// into one combined `CGPath` (in the SVG's own y‑down coordinate space) so the
/// renderer can rasterise a crisp, tintable silhouette at any TV resolution.
///
/// Out of scope on purpose: CSS, `<use>`, `transform=`, elliptical arcs (`A`/`a`
/// are degraded to a straight line — none of our assets use them). If you feed it
/// something fancier, ship a PDF asset instead.
enum SVGOutline {

    struct Parsed {
        /// Combined fill outline, in SVG user units, y pointing *down*.
        let path: CGPath
        /// The `viewBox` (or, if absent, the path's bounding box).
        let viewBox: CGRect
    }

    // MARK: Loading

    /// Parsed‑once cache: SwiftUI previews call `load` from view bodies that can
    /// recompute on every keystroke, and parsing is non‑trivial.
    private static var cache: [String: Parsed] = [:]
    private static var missing: Set<String> = []

    static func load(named name: String, in bundle: Bundle = .main) -> Parsed? {
        if let hit = cache[name] { return hit }
        if missing.contains(name) { return nil }
        guard let url = bundle.url(forResource: name, withExtension: "svg"),
              let text = try? String(contentsOf: url, encoding: .utf8),
              let parsed = parse(text) else { missing.insert(name); return nil }
        cache[name] = parsed
        return parsed
    }

    static func parse(_ svg: String) -> Parsed? {
        let combined = CGMutablePath()

        for tag in tagAttributes(in: svg, "path") {
            if isIgnoredFill(tag) { continue }   // skip white "background" rects, stroke-only paths
            guard let d = captures(in: tag, pattern: #"\bd\s*=\s*"([^"]*)""#).first else { continue }
            combined.addPath(parsePathData(d))
        }
        for tag in tagAttributes(in: svg, "polygon") + tagAttributes(in: svg, "polyline") {
            if isIgnoredFill(tag) { continue }
            guard let pts = captures(in: tag, pattern: #"\bpoints\s*=\s*"([^"]*)""#).first else { continue }
            let n = numbers(pts)
            guard n.count >= 4 else { continue }
            combined.move(to: CGPoint(x: n[0], y: n[1]))
            var i = 2
            while i + 1 < n.count { combined.addLine(to: CGPoint(x: n[i], y: n[i + 1])); i += 2 }
            combined.closeSubpath()
        }
        for tag in tagAttributes(in: svg, "rect") {
            if isIgnoredFill(tag) { continue }
            guard let w = attr(tag, "width"), let h = attr(tag, "height"), w > 0, h > 0 else { continue }
            let rect = CGRect(x: attr(tag, "x") ?? 0, y: attr(tag, "y") ?? 0, width: w, height: h)
            let rx = attr(tag, "rx") ?? attr(tag, "ry") ?? 0
            let ry = attr(tag, "ry") ?? rx
            if rx > 0 || ry > 0 {
                combined.addRoundedRect(in: rect, cornerWidth: rx, cornerHeight: ry)
            } else {
                combined.addRect(rect)
            }
        }

        guard !combined.isEmpty else { return nil }

        let vb: CGRect
        if let raw = captures(in: svg, pattern: #"\bviewBox\s*=\s*"([^"]*)""#).first {
            let n = numbers(raw)
            vb = n.count == 4 ? CGRect(x: n[0], y: n[1], width: n[2], height: n[3]) : combined.boundingBoxOfPath
        } else {
            vb = combined.boundingBoxOfPath
        }
        return Parsed(path: combined, viewBox: vb)
    }

    // MARK: Path data ("d") parser

    /// Supports `M m L l H h V v C c S s Q q T t Z z`. `A`/`a` are read but
    /// approximated by a line to the arc endpoint (no asset here uses arcs).
    static func parsePathData(_ d: String) -> CGPath {
        let path = CGMutablePath()
        var s = Scanner2(d)

        var current = CGPoint.zero          // current point
        var start = CGPoint.zero            // start of the current subpath
        var lastCubicCtrl: CGPoint?         // 2nd control point of the previous C/S
        var lastQuadCtrl: CGPoint?          // control point of the previous Q/T
        var cmd: Character = " "

        func n() -> CGFloat { s.number() ?? 0 }
        func pt(rel: Bool) -> CGPoint {
            var p = CGPoint(x: n(), y: n())
            if rel { p.x += current.x; p.y += current.y }
            return p
        }

        while true {
            s.skipSeparators()
            if let c = s.commandLetter() {
                cmd = c
            } else if s.peekIsNumberStart() {
                // Implicit repeat of the previous command (M⇒L, m⇒l per the spec).
                if cmd == "M" { cmd = "L" } else if cmd == "m" { cmd = "l" }
            } else {
                break
            }

            let rel = cmd.isLowercase
            switch Character(cmd.lowercased()) {

            case "m":
                let p = pt(rel: rel)
                path.move(to: p); current = p; start = p
                lastCubicCtrl = nil; lastQuadCtrl = nil

            case "l":
                let p = pt(rel: rel)
                path.addLine(to: p); current = p
                lastCubicCtrl = nil; lastQuadCtrl = nil

            case "h":
                var x = n(); if rel { x += current.x }
                let p = CGPoint(x: x, y: current.y)
                path.addLine(to: p); current = p
                lastCubicCtrl = nil; lastQuadCtrl = nil

            case "v":
                var y = n(); if rel { y += current.y }
                let p = CGPoint(x: current.x, y: y)
                path.addLine(to: p); current = p
                lastCubicCtrl = nil; lastQuadCtrl = nil

            case "c":
                let c1 = pt(rel: rel), c2 = pt(rel: rel), p = pt(rel: rel)
                path.addCurve(to: p, control1: c1, control2: c2)
                current = p; lastCubicCtrl = c2; lastQuadCtrl = nil

            case "s":
                let c2 = pt(rel: rel), p = pt(rel: rel)
                let c1 = lastCubicCtrl.map { CGPoint(x: 2 * current.x - $0.x, y: 2 * current.y - $0.y) } ?? current
                path.addCurve(to: p, control1: c1, control2: c2)
                current = p; lastCubicCtrl = c2; lastQuadCtrl = nil

            case "q":
                let c = pt(rel: rel), p = pt(rel: rel)
                path.addQuadCurve(to: p, control: c)
                current = p; lastQuadCtrl = c; lastCubicCtrl = nil

            case "t":
                let p = pt(rel: rel)
                let c = lastQuadCtrl.map { CGPoint(x: 2 * current.x - $0.x, y: 2 * current.y - $0.y) } ?? current
                path.addQuadCurve(to: p, control: c)
                current = p; lastQuadCtrl = c; lastCubicCtrl = nil

            case "a":
                _ = n(); _ = n(); _ = n(); _ = n(); _ = n()   // rx ry rot large-arc sweep
                let p = pt(rel: rel)
                path.addLine(to: p); current = p
                lastCubicCtrl = nil; lastQuadCtrl = nil

            case "z":
                path.closeSubpath(); current = start
                lastCubicCtrl = nil; lastQuadCtrl = nil

            default:
                return path   // unrecognised command — bail out with what we have
            }
        }
        return path
    }

    // MARK: - Regex / number helpers

    private static func captures(in text: String, pattern: String) -> [String] {
        guard let re = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive]) else { return [] }
        let ns = text as NSString
        return re.matches(in: text, range: NSRange(location: 0, length: ns.length)).compactMap { m in
            m.numberOfRanges > 1 && m.range(at: 1).location != NSNotFound ? ns.substring(with: m.range(at: 1)) : nil
        }
    }

    private static func attr(_ tagBody: String, _ name: String) -> CGFloat? {
        captures(in: tagBody, pattern: "\\b\(name)\\s*=\\s*\"([^\"]*)\"").first.flatMap { numbers($0).first }
    }

    /// The attribute strings of every `<tag …>` (or `<tag …/>`) element.
    private static func tagAttributes(in text: String, _ tag: String) -> [String] {
        captures(in: text, pattern: "<\(tag)\\b([^>]*)>")
    }

    /// True if the element shouldn't contribute ink: an explicit white fill
    /// (an exported "background" rectangle) or `fill="none"` (a stroke‑only path,
    /// which we can't render anyway).
    private static func isIgnoredFill(_ tagBody: String) -> Bool {
        guard let f = captures(in: tagBody, pattern: #"\bfill\s*=\s*"([^"]*)""#).first?
            .trimmingCharacters(in: .whitespaces).lowercased() else { return false }
        return f == "none" || f == "#fff" || f == "#ffffff" || f == "#ffffffff" || f == "white"
    }

    private static func numbers(_ s: String) -> [CGFloat] {
        var sc = Scanner2(s)
        var out: [CGFloat] = []
        while let v = sc.number() { out.append(v) }
        return out
    }

    /// Minimal forward scanner for SVG path / point data: whitespace‑ or
    /// comma‑separated numbers, single‑letter commands, with the usual quirks
    /// (`-` starts a new number, `.5.5` is two numbers, optional exponents).
    private struct Scanner2 {
        private let chars: [Character]
        private var i = 0
        init(_ s: String) { chars = Array(s) }

        private func isSep(_ c: Character) -> Bool { c == " " || c == "," || c == "\n" || c == "\t" || c == "\r" }

        mutating func skipSeparators() { while i < chars.count, isSep(chars[i]) { i += 1 } }

        mutating func commandLetter() -> Character? {
            skipSeparators()
            guard i < chars.count, chars[i].isLetter, chars[i] != "e", chars[i] != "E" else { return nil }
            defer { i += 1 }
            return chars[i]
        }

        func peekIsNumberStart() -> Bool {
            var j = i
            while j < chars.count, isSep(chars[j]) { j += 1 }
            guard j < chars.count else { return false }
            let c = chars[j]
            return c.isNumber || c == "." || c == "-" || c == "+"
        }

        mutating func number() -> CGFloat? {
            skipSeparators()
            guard i < chars.count else { return nil }
            let begin = i
            if chars[i] == "+" || chars[i] == "-" { i += 1 }
            var sawDigit = false, sawDot = false, sawExp = false
            while i < chars.count {
                let c = chars[i]
                if c.isNumber { sawDigit = true; i += 1 }
                else if c == "." && !sawDot && !sawExp { sawDot = true; i += 1 }
                else if (c == "e" || c == "E") && sawDigit && !sawExp {
                    sawExp = true; i += 1
                    if i < chars.count, chars[i] == "+" || chars[i] == "-" { i += 1 }
                }
                else { break }
            }
            guard sawDigit else { i = begin; return nil }
            return CGFloat(Double(String(chars[begin..<i])) ?? 0)
        }
    }
}
