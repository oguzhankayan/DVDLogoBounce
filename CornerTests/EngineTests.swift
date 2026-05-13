import XCTest
import CoreGraphics
@testable import Corner

final class MotionIntegratorTests: XCTestCase {

    private let bounds = CGRect(x: 0, y: 0, width: 1000, height: 600)

    func testNoImpactWhenWellInside() {
        var e = LogoEntity(id: 0, position: CGPoint(x: 500, y: 300),
                           velocity: CGVector(dx: 100, dy: 50), halfSize: CGSize(width: 60, height: 40))
        let impact = MotionIntegrator.step(&e, dt: 1.0 / 60.0, bounds: bounds)
        XCTAssertNil(impact)
        XCTAssertEqual(e.position.x, 500 + 100 / 60.0, accuracy: 1e-6)
        XCTAssertEqual(e.position.y, 300 + 50 / 60.0, accuracy: 1e-6)
    }

    func testReflectsOffRightWallAndSnapsInside() {
        var e = LogoEntity(id: 0, position: CGPoint(x: 990, y: 300),
                           velocity: CGVector(dx: 600, dy: 0), halfSize: CGSize(width: 40, height: 40))
        let impact = MotionIntegrator.step(&e, dt: 1.0 / 60.0, bounds: bounds)
        XCTAssertNotNil(impact)
        XCTAssertEqual(impact?.horizontal, .right)
        XCTAssertNil(impact?.vertical)
        XCTAssertLessThan(e.velocity.dx, 0, "should bounce back to the left")
        XCTAssertLessThanOrEqual(e.position.x + e.halfSize.width, bounds.maxX + 1e-6)
        XCTAssertEqual(e.colorIndex, 1)
    }

    func testSpeedIsConservedOnBounce() {
        var e = LogoEntity(id: 0, position: CGPoint(x: 10, y: 12),
                           velocity: CGVector(angle: .pi * 0.75, magnitude: 400), halfSize: CGSize(width: 30, height: 30))
        let speedBefore = e.velocity.magnitude
        _ = MotionIntegrator.step(&e, dt: 1.0 / 30.0, bounds: bounds)
        XCTAssertEqual(e.velocity.magnitude, speedBefore, accuracy: 1e-3)
    }

    func testExactCornerWhenBothEdgesCross() {
        // Heading into the top‑right corner from just inside it.
        var e = LogoEntity(id: 0, position: CGPoint(x: bounds.maxX - 41, y: bounds.maxY - 41),
                           velocity: CGVector(dx: 600, dy: 600), halfSize: CGSize(width: 40, height: 40))
        let impact = MotionIntegrator.step(&e, dt: 1.0 / 30.0, bounds: bounds)
        XCTAssertEqual(impact?.horizontal, .right)
        XCTAssertEqual(impact?.vertical, .top)
        XCTAssertTrue(impact?.isExactCorner == true)
    }

    func testHugeLogoIsCentredNotNaN() {
        var e = LogoEntity(id: 0, position: CGPoint(x: 100, y: 100),
                           velocity: CGVector(dx: 50, dy: 50), halfSize: CGSize(width: 800, height: 50))
        _ = MotionIntegrator.step(&e, dt: 1.0 / 60.0, bounds: bounds)
        XCTAssertEqual(e.position.x, bounds.midX, accuracy: 1e-6)
        XCTAssertTrue(e.position.x.isFinite && e.position.y.isFinite)
    }
}

final class CornerHitDetectorTests: XCTestCase {

    func testNoneForNoImpact() {
        let d = CornerHitDetector(closeCallTolerance: 20)
        XCTAssertEqual(d.classify(nil), .none)
    }

    func testPerfectCorner() {
        let d = CornerHitDetector(closeCallTolerance: 20)
        let impact = WallImpact(horizontal: .left, vertical: .bottom,
                                gapToNearestVerticalWall: 0, gapToNearestHorizontalWall: 0,
                                nearestVerticalWall: .bottom, nearestHorizontalWall: .left, speedAtImpact: 300)
        XCTAssertEqual(d.classify(impact), .perfectCorner(.bottomLeft))
    }

    func testCloseCallWithinTolerance() {
        let d = CornerHitDetector(closeCallTolerance: 25)
        let impact = WallImpact(horizontal: .right, vertical: nil,
                                gapToNearestVerticalWall: 12, gapToNearestHorizontalWall: 0,
                                nearestVerticalWall: .top, nearestHorizontalWall: .right, speedAtImpact: 300)
        XCTAssertEqual(d.classify(impact), .closeCall(.topRight))
    }

    func testWallBounceWhenFarFromCorner() {
        let d = CornerHitDetector(closeCallTolerance: 25)
        let impact = WallImpact(horizontal: nil, vertical: .top,
                                gapToNearestVerticalWall: 0, gapToNearestHorizontalWall: 300,
                                nearestVerticalWall: .top, nearestHorizontalWall: .left, speedAtImpact: 300)
        XCTAssertEqual(d.classify(impact), .wallBounce)
    }

    func testCloseCallsCanBeDisabled() {
        let d = CornerHitDetector(closeCallTolerance: 25, detectCloseCalls: false)
        let impact = WallImpact(horizontal: .left, vertical: nil,
                                gapToNearestVerticalWall: 1, gapToNearestHorizontalWall: 0,
                                nearestVerticalWall: .bottom, nearestHorizontalWall: .left, speedAtImpact: 300)
        XCTAssertEqual(d.classify(impact), .wallBounce)
    }
}

final class CollisionResolverTests: XCTestCase {

    func testOverlappingLogosAreSeparated() {
        let a = LogoEntity(id: 0, position: CGPoint(x: 100, y: 100),
                           velocity: CGVector(dx: 100, dy: 0), halfSize: CGSize(width: 40, height: 40))
        let b = LogoEntity(id: 1, position: CGPoint(x: 130, y: 100),
                           velocity: CGVector(dx: -100, dy: 0), halfSize: CGSize(width: 40, height: 40))
        var entities = [a, b]
        let pairs = CollisionResolver.resolve(&entities)
        XCTAssertEqual(pairs.count, 1)
        let dist = entities[0].position.distance(to: entities[1].position)
        XCTAssertGreaterThanOrEqual(dist, entities[0].collisionRadius + entities[1].collisionRadius - 1e-3)
        _ = a; _ = b
    }

    func testHeadOnSwapsVelocitiesAndKeepsSpeed() {
        var entities = [
            LogoEntity(id: 0, position: CGPoint(x: 100, y: 100), velocity: CGVector(dx: 200, dy: 0), halfSize: CGSize(width: 30, height: 30)),
            LogoEntity(id: 1, position: CGPoint(x: 150, y: 100), velocity: CGVector(dx: -200, dy: 0), halfSize: CGSize(width: 30, height: 30)),
        ]
        CollisionResolver.resolve(&entities)
        XCTAssertLessThan(entities[0].velocity.dx, 0)
        XCTAssertGreaterThan(entities[1].velocity.dx, 0)
        XCTAssertEqual(entities[0].velocity.magnitude, 200, accuracy: 1e-3)
        XCTAssertEqual(entities[1].velocity.magnitude, 200, accuracy: 1e-3)
    }
}

final class SeededRandomTests: XCTestCase {

    func testDeterministicForSameSeed() {
        var a = SeededRandom(seed: 12345)
        var b = SeededRandom(seed: 12345)
        for _ in 0..<50 { XCTAssertEqual(a.next(), b.next()) }
    }

    func testDifferentSeedsDiverge() {
        var a = SeededRandom(seed: 1)
        var b = SeededRandom(seed: 2)
        var sameCount = 0
        for _ in 0..<50 where a.next() == b.next() { sameCount += 1 }
        XCTAssertLessThan(sameCount, 3)
    }

    func testUnitInRange() {
        var g = SeededRandom(seed: 99)
        for _ in 0..<1000 {
            let u = g.unit()
            XCTAssertGreaterThanOrEqual(u, 0)
            XCTAssertLessThan(u, 1)
        }
    }

    func testLivelyHeadingAvoidsAxes() {
        var g = SeededRandom(seed: 7)
        for _ in 0..<500 {
            let h = g.livelyHeading()
            let v = CGVector(angle: h, magnitude: 1)
            XCTAssertGreaterThan(abs(v.dx), 0.05)
            XCTAssertGreaterThan(abs(v.dy), 0.05)
        }
    }

    func testDailySeedStableWithinDay() {
        let noonUTC = Date(timeIntervalSince1970: 1_699_963_200)
        let eveningUTC = noonUTC.addingTimeInterval(60 * 60 * 8)
        XCTAssertEqual(SeededRandom.dailySeed(reference: noonUTC), SeededRandom.dailySeed(reference: eveningUTC))
        let nextDayUTC = noonUTC.addingTimeInterval(60 * 60 * 26)
        XCTAssertNotEqual(SeededRandom.dailySeed(reference: noonUTC), SeededRandom.dailySeed(reference: nextDayUTC))
    }
}
