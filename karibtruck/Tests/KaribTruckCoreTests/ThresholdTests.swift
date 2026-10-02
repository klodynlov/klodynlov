import XCTest
@testable import KaribTruckCore

/// Le piège métier : froid (max) et chaud (min) ont des règles opposées.
/// La limite est inclusive (à la limite = conforme).
final class ThresholdTests: XCTestCase {

    func testColdRuleMax() {
        let t = Threshold(rule: .max, limitCelsius: 4.0)
        XCTAssertEqual(t.evaluate(3.9), .ok)
        XCTAssertEqual(t.evaluate(4.0), .ok)     // borne incluse
        XCTAssertEqual(t.evaluate(4.1), .alert)
        XCTAssertEqual(t.evaluate(9.0), .alert)
    }

    func testHotRuleMin() {
        let t = Threshold(rule: .min, limitCelsius: 63.0)
        XCTAssertEqual(t.evaluate(63.1), .ok)
        XCTAssertEqual(t.evaluate(63.0), .ok)    // borne incluse
        XCTAssertEqual(t.evaluate(62.9), .alert)
        XCTAssertEqual(t.evaluate(20.0), .alert) // vitrine tiède = danger
    }

    func testFreezerNegative() {
        let t = Threshold(rule: .max, limitCelsius: -18.0)
        XCTAssertEqual(t.evaluate(-20.0), .ok)
        XCTAssertEqual(t.evaluate(-18.0), .ok)
        XCTAssertEqual(t.evaluate(-15.0), .alert)
    }

    func testPresetsWiring() {
        XCTAssertEqual(Enclosure.frigo.threshold.rule, .max)
        XCTAssertEqual(Enclosure.vitrineChaude.threshold.rule, .min)
        XCTAssertEqual(Enclosure.defaultsM0.count, 2)
    }
}
