import XCTest
@testable import KaribTruckCore

final class ExportTests: XCTestCase {

    private func sample() -> Journal {
        var k = KaribTruck()
        k.recordTemperature(enclosureID: "frigo", celsius: 3.5, at: "2026-08-18T07:00:00Z")
        k.recordTemperature(enclosureID: "vitrine-chaude", celsius: 61.0, at: "2026-08-18T07:01:00Z")
        k.recordNonConformity(severity: "majeure", what: "coupure, elec \"40min\"",
                              action: "jeter", at: "2026-08-18T18:30:00Z")
        return k.journal
    }

    func testCsvHasHeaderAndOneRowPerEntry() {
        let csv = InspectionExport.csv(sample())
        let lines = csv.split(separator: "\n", omittingEmptySubsequences: true)
        XCTAssertEqual(lines.count, 1 + 3)  // en-tête + 3 entrées
        XCTAssertTrue(lines[0].hasPrefix("index,timestamp,kind,status"))
    }

    func testCsvEscapesCommasAndQuotes() {
        let csv = InspectionExport.csv(sample())
        // Le champ "what" contient une virgule et des guillemets → doit être quoté/doublé.
        XCTAssertTrue(csv.contains("\"\"40min\"\""))
    }

    func testCsvContainsHashes() {
        let j = sample()
        let csv = InspectionExport.csv(j)
        for e in j.entries {
            XCTAssertTrue(csv.contains(e.hash), "le CSV doit inclure le hash de chaque entrée")
        }
    }

    func testSummaryReportsAlertsAndIntegrity() {
        let j = sample()
        let s = InspectionExport.summary(j)
        XCTAssertTrue(s.contains("Alertes : 1"))
        XCTAssertTrue(s.contains("vérifiée ✓"))
        XCTAssertTrue(s.contains(j.headHash))
    }
}
