import XCTest
@testable import KaribTruckCore

/// Le cœur de la promesse « pro » : le journal est inviolable. Toute altération,
/// réordonnancement ou retrait d'une entrée est détecté par `verify()`.
final class TamperTests: XCTestCase {

    private func sample() -> Journal {
        var j = Journal()
        j.append(kind: "enclosure.reading", timestamp: "2026-08-18T07:00:00Z",
                 payload: ["enclosure": "frigo", "celsius": "3.5", "status": "ok"])
        j.append(kind: "enclosure.reading", timestamp: "2026-08-18T09:00:00Z",
                 payload: ["enclosure": "frigo", "celsius": "3.7", "status": "ok"])
        j.append(kind: "checklist.run", timestamp: "2026-08-18T22:00:00Z",
                 payload: ["checklist": "fermeture", "done": "4", "total": "4"])
        return j
    }

    func testTamperedValueIsDetected() {
        var j = sample()
        var e = j.entries
        // On falsifie un relevé (9.5 °C maquillé en 3.5) sans recalculer le hash.
        e[0] = JournalEntry(index: 0, timestamp: e[0].timestamp, kind: e[0].kind,
                            payload: ["enclosure": "frigo", "celsius": "9.5", "status": "ok"],
                            previousHash: e[0].previousHash, hash: e[0].hash)
        j = Journal(entries: e)
        XCTAssertThrowsError(try j.verify()) { error in
            XCTAssertEqual(error as? JournalError, .badHash(atIndex: 0))
        }
        XCTAssertFalse(j.isValid)
    }

    func testReorderingBreaksChain() {
        var j = sample()
        var e = j.entries
        e.swapAt(1, 2)
        j = Journal(entries: e)
        XCTAssertThrowsError(try j.verify()) { error in
            // Les index ne correspondent plus / le chaînage casse.
            guard let je = error as? JournalError else { return XCTFail("type d'erreur") }
            switch je {
            case .brokenChain, .badHash: break  // les deux sont des détections valides
            }
        }
    }

    func testDroppingEntryIsDetected() {
        var j = sample()
        var e = j.entries
        e.remove(at: 1)  // on efface le maillon du milieu
        j = Journal(entries: e)
        XCTAssertThrowsError(try j.verify())
    }

    func testRetroDatingIsDetected() {
        var j = sample()
        var e = j.entries
        // On tente de rétro-dater l'entrée 2 sans toucher au hash.
        e[2] = JournalEntry(index: 2, timestamp: "2026-08-01T00:00:00Z", kind: e[2].kind,
                            payload: e[2].payload, previousHash: e[2].previousHash, hash: e[2].hash)
        j = Journal(entries: e)
        XCTAssertThrowsError(try j.verify()) { error in
            XCTAssertEqual(error as? JournalError, .badHash(atIndex: 2))
        }
    }

    func testCorrectionByAppendKeepsChainValid() {
        // La bonne pratique : corriger par une entrée rectificative, pas par édition.
        var j = sample()
        j.append(kind: "correction", timestamp: "2026-08-18T22:05:00Z",
                 payload: ["targets": "index-2", "reason": "erreur de saisie", "field": "done", "value": "5"])
        XCTAssertNoThrow(try j.verify())
        XCTAssertEqual(j.entries.count, 4)
    }
}
