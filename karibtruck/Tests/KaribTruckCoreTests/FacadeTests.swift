import XCTest
@testable import KaribTruckCore

/// Preuve de bout en bout : la façade métier, appelée avec les mêmes données que
/// la fixture, reproduit **exactement** la même chaîne (donc le même hash de
/// tête que l'oracle). Cela valide au passage le formatage des nombres
/// (3.5 → "3.5", 4 → "4.0", 63 → "63.0") et des booléens (false → "false").
final class FacadeTests: XCTestCase {

    private static let expectedHead =
        "0aa1eb54eebab18e1a5d506994fc198ee59676cd8e8e9c206a659629c1064ea0"

    func testFacadeReproducesFixtureChain() {
        var k = KaribTruck()  // presets M0 : frigo (max 4.0) + vitrine chaude (min 63.0)

        let s0 = k.recordTemperature(enclosureID: "frigo", celsius: 3.5, at: "2026-08-18T07:00:00Z")
        let s1 = k.recordTemperature(enclosureID: "vitrine-chaude", celsius: 61.0, at: "2026-08-18T07:01:00Z")
        k.recordChecklistRun(checklist: "ouverture", done: 5, total: 5, operator: "klody", at: "2026-08-18T07:05:00Z")
        k.recordReception(supplier: "Antilles Frais", lot: "LOT-2208", dlc: "2026-08-25", product: "poulet", at: "2026-08-18T07:10:00Z")
        k.recordFryingOilCheck(fryer: "friteuse-1", action: "controle", quality: "bonne", changed: false, at: "2026-08-18T18:00:00Z")
        k.recordNonConformity(severity: "majeure", what: "coupure elec 40min", action: "jeter produits frais vitrine", at: "2026-08-18T18:30:00Z")
        k.recordMarketSchedule(date: "2026-08-20", place: "Marche de Fort-de-France", slot: "08:00-14:00", at: "2026-08-19T06:00:00Z")

        XCTAssertEqual(s0, .ok)      // 3.5 ≤ 4.0 → conforme
        XCTAssertEqual(s1, .alert)   // 61.0 < 63.0 → alerte
        XCTAssertEqual(k.journal.entries.count, 7)
        XCTAssertEqual(k.journal.headHash, Self.expectedHead)
        XCTAssertTrue(k.isValid)
    }

    func testAlertsCollection() {
        var k = KaribTruck()
        k.recordTemperature(enclosureID: "frigo", celsius: 3.0, at: "2026-08-18T07:00:00Z")   // ok
        k.recordTemperature(enclosureID: "frigo", celsius: 9.0, at: "2026-08-18T09:00:00Z")   // alerte
        k.recordTemperature(enclosureID: "vitrine-chaude", celsius: 70.0, at: "2026-08-18T09:01:00Z") // ok
        XCTAssertEqual(k.alerts.count, 1)
        XCTAssertEqual(k.alerts.first?.payload["enclosure"], "frigo")
    }

    func testUnknownEnclosureIsAlertedNotLost() {
        var k = KaribTruck()
        let status = k.recordTemperature(enclosureID: "chambre-froide", celsius: -18.0, at: "2026-08-18T07:00:00Z")
        XCTAssertEqual(status, .alert)
        XCTAssertEqual(k.journal.entries.count, 1)
        XCTAssertEqual(k.journal.entries[0].payload["rule"], "unknown")
    }

    func testNumberFormatting() {
        XCTAssertEqual(KaribTruck.num(4.0), "4.0")
        XCTAssertEqual(KaribTruck.num(3.5), "3.5")
        XCTAssertEqual(KaribTruck.num(63.0), "63.0")
        XCTAssertEqual(KaribTruck.num(-18.0), "-18.0")
    }
}
