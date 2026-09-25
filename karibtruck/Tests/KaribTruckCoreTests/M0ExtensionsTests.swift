import XCTest
@testable import KaribTruckCore

/// Champs optionnels et lectures ajoutés pour l'app (checklists détaillées,
/// photo d'étiquette, composés polaires, filtres de période). Invariant clé :
/// les clés optionnelles absentes ne changent PAS la sérialisation — la chaîne
/// de la fixture (partagée avec l'oracle) reste identique (cf. FacadeTests).
final class M0ExtensionsTests: XCTestCase {

    // MARK: - Checklists

    func testCompleteChecklistHasNoStatusNorMissing() {
        var k = KaribTruck()
        let e = k.recordChecklistRun(checklist: "ouverture", done: 8, total: 8,
                                     operator: "klody", at: "2026-09-25T10:00:00Z")
        XCTAssertNil(e.payload["missing"])
        XCTAssertNil(e.payload["status"])
        XCTAssertTrue(k.alerts.isEmpty)
    }

    func testIncompleteChecklistIsSealedAsAlertWithMissingItems() {
        var k = KaribTruck()
        let e = k.recordChecklistRun(checklist: "fermeture", done: 7, total: 9,
                                     operator: "klody",
                                     missing: ["Sol nettoyé", "Eaux usées vidangées"],
                                     at: "2026-09-25T22:00:00Z")
        XCTAssertEqual(e.payload["missing"], "Sol nettoyé ; Eaux usées vidangées")
        XCTAssertEqual(e.payload["status"], "alert")
        XCTAssertEqual(k.alerts.count, 1)
        XCTAssertTrue(k.isValid)
    }

    func testChecklistPresets() {
        let ids = ChecklistTemplate.defaultsM0.map(\.id)
        XCTAssertEqual(ids, ["ouverture", "fermeture", "nettoyage"])
        XCTAssertEqual(Set(ids).count, ids.count, "slugs uniques (clés du journal)")
        for t in ChecklistTemplate.defaultsM0 {
            XCTAssertFalse(t.items.isEmpty)
            XCTAssertEqual(Set(t.items).count, t.items.count, "points uniques dans \(t.id)")
            for item in t.items {
                XCTAssertFalse(item.contains(KaribTruck.listSeparator),
                               "un point ne doit pas contenir le séparateur")
            }
        }
    }

    // MARK: - Réception

    func testReceptionPhotoHashIsSealedOnlyWhenPresent() {
        var k = KaribTruck()
        let without = k.recordReception(supplier: "A", lot: "L1", dlc: "2026-10-01",
                                        product: "poulet", at: "2026-09-25T08:00:00Z")
        let sha = String(repeating: "ab", count: 32)
        let with = k.recordReception(supplier: "A", lot: "L2", dlc: "2026-10-01",
                                     product: "poulet", photoSHA256: sha,
                                     at: "2026-09-25T08:01:00Z")
        XCTAssertNil(without.payload["photo_sha256"])
        XCTAssertEqual(with.payload["photo_sha256"], sha)
    }

    func testReplacingPhotoHashIsDetected() {
        var k = KaribTruck()
        k.recordReception(supplier: "A", lot: "L1", dlc: "2026-10-01", product: "poulet",
                          photoSHA256: String(repeating: "ab", count: 32),
                          at: "2026-09-25T08:00:00Z")
        var entries = k.journal.entries
        let e = entries[0]
        var forged = e.payload
        forged["photo_sha256"] = String(repeating: "cd", count: 32)
        entries[0] = JournalEntry(index: e.index, timestamp: e.timestamp, kind: e.kind,
                                  payload: forged, previousHash: e.previousHash, hash: e.hash)
        XCTAssertThrowsError(try Journal(entries: entries).verify()) { error in
            XCTAssertEqual(error as? JournalError, .badHash(atIndex: 0))
        }
    }

    // MARK: - Huile de friture

    func testOilWithoutMeasureHasNoStatus() {
        var k = KaribTruck()
        let e = k.recordFryingOilCheck(fryer: "friteuse-1", action: "controle",
                                       quality: "bonne", changed: false,
                                       at: "2026-09-25T12:00:00Z")
        XCTAssertNil(e.payload["status"])
        XCTAssertNil(e.payload["polar_percent"])
    }

    func testOilPolarLimitIsInclusive() {
        var k = KaribTruck()
        let atLimit = k.recordFryingOilCheck(fryer: "f", action: "controle", quality: "a-surveiller",
                                             changed: false, polarPercent: 25.0,
                                             at: "2026-09-25T12:00:00Z")
        let over = k.recordFryingOilCheck(fryer: "f", action: "controle", quality: "a-changer",
                                          changed: false, polarPercent: 26.5,
                                          at: "2026-09-25T12:01:00Z")
        XCTAssertEqual(atLimit.payload["status"], "ok")
        XCTAssertEqual(atLimit.payload["polar_percent"], "25.0")
        XCTAssertEqual(atLimit.payload["limit"], "25.0")
        XCTAssertEqual(over.payload["status"], "alert")
        XCTAssertEqual(k.alerts.count, 1)
    }

    // MARK: - Lectures par période

    private func dayOfWork() -> KaribTruck {
        var k = KaribTruck()
        k.recordTemperature(enclosureID: "frigo", celsius: 3.0, at: "2026-09-24T23:59:59Z")
        k.recordTemperature(enclosureID: "frigo", celsius: 3.5, at: "2026-09-25T00:00:00Z")
        k.recordChecklistRun(checklist: "ouverture", done: 8, total: 8, operator: "k",
                             at: "2026-09-25T09:00:00Z")
        k.recordTemperature(enclosureID: "vitrine-chaude", celsius: 70.0, at: "2026-09-25T11:00:00Z")
        k.recordTemperature(enclosureID: "frigo", celsius: 5.0, at: "2026-09-25T16:00:00Z")
        k.recordTemperature(enclosureID: "frigo", celsius: 2.0, at: "2026-09-26T00:00:00Z")
        return k
    }

    func testEntriesInPeriodIsHalfOpen() {
        let k = dayOfWork()
        let day = k.entries(from: "2026-09-25T00:00:00Z", to: "2026-09-26T00:00:00Z")
        XCTAssertEqual(day.count, 4)   // borne basse incluse, borne haute exclue
        XCTAssertEqual(day.first?.timestamp, "2026-09-25T00:00:00Z")
        XCTAssertEqual(day.last?.timestamp, "2026-09-25T16:00:00Z")
    }

    func testLastReadingPerEnclosure() {
        let k = dayOfWork()
        let frigo = k.lastReading(enclosureID: "frigo",
                                  from: "2026-09-25T00:00:00Z", to: "2026-09-26T00:00:00Z")
        XCTAssertEqual(frigo?.payload["celsius"], "5.0")
        XCTAssertEqual(frigo?.payload["status"], "alert")
        let none = k.lastReading(enclosureID: "vitrine-chaude",
                                 from: "2026-09-26T00:00:00Z", to: "2026-09-27T00:00:00Z")
        XCTAssertNil(none)
    }

    func testLastChecklistRun() {
        let k = dayOfWork()
        XCTAssertNotNil(k.lastChecklistRun(checklist: "ouverture",
                                           from: "2026-09-25T00:00:00Z", to: "2026-09-26T00:00:00Z"))
        XCTAssertNil(k.lastChecklistRun(checklist: "fermeture",
                                        from: "2026-09-25T00:00:00Z", to: "2026-09-26T00:00:00Z"))
    }

    func testPeriodCsvKeepsChainLinks() {
        let k = dayOfWork()
        let day = k.entries(from: "2026-09-25T00:00:00Z", to: "2026-09-26T00:00:00Z")
        let csv = InspectionExport.csv(day)
        let lines = csv.split(separator: "\n")
        XCTAssertEqual(lines.count, 1 + day.count)
        // La 1re ligne de l'extrait pointe vers l'entrée d'avant la période :
        // l'extrait se raccroche au journal complet.
        XCTAssertTrue(csv.contains(k.journal.entries[0].hash))
        XCTAssertEqual(InspectionExport.csv(k.journal), InspectionExport.csv(k.journal.entries))
    }
}
