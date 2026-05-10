import XCTest
@testable import Corner

final class ThemeCatalogTests: XCTestCase {

    func testEveryThemeIDResolvesToMatchingTheme() {
        for id in ThemeID.allCases {
            let theme = ThemeCatalog.theme(for: id)
            XCTAssertEqual(theme.id, id, "theme(for:) returned a mismatched id for \(id)")
            XCTAssertFalse(theme.name.isEmpty)
            XCTAssertFalse(theme.collisionPalette.isEmpty, "\(id) must have a non‑empty collision palette")
        }
    }

    func testAllReturnsOnePerID() {
        XCTAssertEqual(ThemeCatalog.all.count, ThemeID.allCases.count)
        XCTAssertEqual(Set(ThemeCatalog.all.map(\.id)).count, ThemeID.allCases.count)
    }

    func testCollisionColorWraps() {
        let t = ThemeCatalog.classicDVD
        let n = t.collisionPalette.count
        XCTAssertEqual(t.collisionColor(at: 0), t.collisionColor(at: n))
        XCTAssertEqual(t.collisionColor(at: 1), t.collisionColor(at: n + 1))
        XCTAssertEqual(t.collisionColor(at: -1), t.collisionColor(at: n - 1))
    }

    func testPostEffectThemesAreFlagged() {
        XCTAssertEqual(ThemeCatalog.retroCRT.postEffect, .crt)
        XCTAssertEqual(ThemeCatalog.vhs.postEffect, .vhs)
        XCTAssertTrue(ThemeID.retroCRT.usesPostEffect)
        XCTAssertTrue(ThemeID.vhs.usesPostEffect)
        XCTAssertFalse(ThemeID.classicDVD.usesPostEffect)
    }
}

final class RGBATests: XCTestCase {

    func testHexParsing() {
        XCTAssertEqual(RGBA(hex: "#FFFFFF"), .white)
        XCTAssertEqual(RGBA(hex: "000000"), .black)
        let half = RGBA(hex: "#808080")
        XCTAssertEqual(half.red, 128.0 / 255.0, accuracy: 1e-9)
        let short = RGBA(hex: "#0F0")
        XCTAssertEqual(short.green, 1, accuracy: 1e-9)
        XCTAssertEqual(short.red, 0, accuracy: 1e-9)
        let withAlpha = RGBA(hex: "#FF000080")
        XCTAssertEqual(withAlpha.red, 1, accuracy: 1e-9)
        XCTAssertEqual(withAlpha.opacity, 128.0 / 255.0, accuracy: 1e-9)
    }

    func testMixAndLuminance() {
        let mid = RGBA.black.mixed(with: .white, t: 0.5)
        XCTAssertEqual(mid.red, 0.5, accuracy: 1e-9)
        XCTAssertGreaterThan(RGBA.white.luminance, RGBA.black.luminance)
        XCTAssertEqual(RGBA.white.autoContrastingForeground.luminance < 0.5, true)
        XCTAssertEqual(RGBA.black.autoContrastingForeground.luminance > 0.5, true)
    }

    func testCodableRoundTrip() throws {
        let c = RGBA(hex: "#3D5BFF").withOpacity(0.4)
        let data = try JSONEncoder().encode(c)
        let back = try JSONDecoder().decode(RGBA.self, from: data)
        XCTAssertEqual(c, back)
    }
}

final class StatisticsTests: XCTestCase {

    func testRecordingPerfectCorner() {
        var s = Statistics(firstLaunch: Date(timeIntervalSince1970: 0))
        s.startNewSession(now: Date(timeIntervalSince1970: 100))
        let e1 = CornerHitEvent(corner: .topLeft, date: Date(timeIntervalSince1970: 110), speed: 300, themeID: .neon)
        s.record(e1)
        XCTAssertEqual(s.totalCornerHits, 1)
        XCTAssertEqual(s.sessionCornerHits, 1)
        XCTAssertEqual(s.count(for: .topLeft), 1)
        XCTAssertEqual(s.lastCornerHit, e1.date)

        let e2 = CornerHitEvent(corner: .topLeft, date: Date(timeIntervalSince1970: 200), speed: 300, themeID: .neon)
        s.record(e2)
        XCTAssertEqual(s.totalCornerHits, 2)
        XCTAssertEqual(s.longestSession, 2)
        XCTAssertEqual(s.longestDryGap ?? 0, 90, accuracy: 1e-6)
    }

    func testCloseCallsDoNotAffectCornerCount() {
        var s = Statistics()
        s.record(CornerHitEvent(corner: .bottomRight, speed: 200, isCloseCall: true, themeID: .vhs))
        XCTAssertEqual(s.totalCornerHits, 0)
        XCTAssertEqual(s.totalCloseCalls, 1)
        XCTAssertEqual(s.sessionCloseCalls, 1)
    }

    func testCodableRoundTrip() throws {
        var s = Statistics()
        s.record(CornerHitEvent(corner: .topRight, speed: 250, themeID: .matrix))
        s.recordWallBounce(count: 7)
        s.addRunTime(123)
        let data = try JSONEncoder().encode(s)
        let back = try JSONDecoder().decode(Statistics.self, from: data)
        XCTAssertEqual(back.totalCornerHits, 1)
        XCTAssertEqual(back.totalWallBounces, 7)
        XCTAssertEqual(back.count(for: .topRight), 1)
        XCTAssertEqual(back.totalRunTime, 123, accuracy: 1e-6)
    }
}

@MainActor
final class AppSettingsTests: XCTestCase {

    func testDefaultsLoadWhenStoreEmpty() {
        let s = AppSettings(store: InMemorySettingsStore())
        XCTAssertEqual(s.themeID, AppSettings.Snapshot.defaults.themeID)
        XCTAssertEqual(s.logoCount, AppSettings.Snapshot.defaults.logoCount)
        XCTAssertFalse(s.hasCompletedOnboarding)
    }

    func testApplyModeSeedsValues() {
        let s = AppSettings(store: InMemorySettingsStore())
        s.applyMode(.chaos)
        XCTAssertEqual(s.displayMode, .chaos)
        XCTAssertEqual(s.logoCount, DisplayMode.chaos.seed.logoCount)
        XCTAssertTrue(s.interLogoCollisions)
        s.applyMode(.cinematic)
        XCTAssertEqual(s.displayMode, .cinematic)
        XCTAssertEqual(s.logoCount, DisplayMode.cinematic.seed.logoCount)
        XCTAssertFalse(s.interLogoCollisions)
    }

    func testValuesAreClamped() {
        let s = AppSettings(store: InMemorySettingsStore())
        s.speed = 99
        XCTAssertEqual(s.speed, AppSettings.speedRange.upperBound, accuracy: 1e-9)
        s.logoCount = -5
        XCTAssertEqual(s.logoCount, AppSettings.logoCountRange.lowerBound)
        s.glowIntensity = 5
        XCTAssertEqual(s.glowIntensity, 1, accuracy: 1e-9)
    }

    func testSnapshotRoundTripThroughStore() {
        let store = InMemorySettingsStore()
        let s1 = AppSettings(store: store)
        s1.themeID = .synthwave
        s1.applyMode(.multi)
        s1.glowIntensity = 0.8
        s1.hasCompletedOnboarding = true
        // Persist immediately (bypass the debounce used in production).
        store.save(s1.snapshot)

        let s2 = AppSettings(store: store)
        XCTAssertEqual(s2.themeID, .synthwave)
        XCTAssertEqual(s2.displayMode, .multi)
        XCTAssertEqual(s2.glowIntensity, 0.8, accuracy: 1e-9)
        XCTAssertTrue(s2.hasCompletedOnboarding)
    }

    func testEffectiveAmbientResolvesMatchTheme() {
        let s = AppSettings(store: InMemorySettingsStore())
        s.ambientMode = .matchTheme
        let theme = ThemeCatalog.vhs
        XCTAssertEqual(s.effectiveAmbientMode(for: theme), theme.audio.suggestedAmbient)
        s.ambientMode = .silent
        XCTAssertEqual(s.effectiveAmbientMode(for: theme), .silent)
    }
}
