import XCTest
@testable import KaribTruckCore

/// Vecteurs de réponse connue générés par `tools/oracle.py` (implémentation de
/// référence indépendante, en Python). Si la sérialisation canonique ou le
/// chaînage Swift divergent d'un seul octet, ces égalités cassent → CI rouge.
/// `tools/check_sync.py` garantit en plus que ces constantes restent synchrones
/// avec l'oracle.
final class JournalTests: XCTestCase {

    // Fixture identique à FIXTURE dans tools/oracle.py.
    private func buildFixtureJournal() -> Journal {
        var j = Journal()
        j.append(kind: "enclosure.reading", timestamp: "2026-08-18T07:00:00Z", payload: [
            "enclosure": "frigo", "celsius": "3.5", "rule": "max", "limit": "4.0", "status": "ok"])
        j.append(kind: "enclosure.reading", timestamp: "2026-08-18T07:01:00Z", payload: [
            "enclosure": "vitrine-chaude", "celsius": "61.0", "rule": "min", "limit": "63.0", "status": "alert"])
        j.append(kind: "checklist.run", timestamp: "2026-08-18T07:05:00Z", payload: [
            "checklist": "ouverture", "done": "5", "total": "5", "operator": "klody"])
        j.append(kind: "reception", timestamp: "2026-08-18T07:10:00Z", payload: [
            "supplier": "Antilles Frais", "lot": "LOT-2208", "dlc": "2026-08-25", "product": "poulet"])
        j.append(kind: "frying-oil.check", timestamp: "2026-08-18T18:00:00Z", payload: [
            "fryer": "friteuse-1", "action": "controle", "quality": "bonne", "changed": "false"])
        j.append(kind: "nonconformity", timestamp: "2026-08-18T18:30:00Z", payload: [
            "severity": "majeure", "what": "coupure elec 40min", "action": "jeter produits frais vitrine"])
        j.append(kind: "market.schedule", timestamp: "2026-08-19T06:00:00Z", payload: [
            "date": "2026-08-20", "place": "Marche de Fort-de-France", "slot": "08:00-14:00"])
        return j
    }

    // Hashes attendus (générés par l'oracle).
    private let expectedHashes = [
        "dce752745f9dff285978024268802128e1d1341a38be47849fd8be674b3faf35",
        "31fa609a419b3c63424d29697c73eb23a83057a466eb8c6a32bfa5fac7d7713d",
        "6ea81a3da8ebb22ed9075b67735da20326a1250cc7e6884fabebd5a6713e4794",
        "d726e0f0d59dc9e42f80c516656aea4cc4d49a310e5de963401ddd1328dd6ae0",
        "3142f2e8932efdc6f0c5a1e8bc478c1bae4207f03c7caddf1a8b090b28b808c6",
        "fb63e881d1aebb946562409c472913bdd3a930f06400385cbfc1e4ed35c6b244",
        "0aa1eb54eebab18e1a5d506994fc198ee59676cd8e8e9c206a659629c1064ea0",
    ]

    func testKnownAnswerHashes() {
        let j = buildFixtureJournal()
        XCTAssertEqual(j.entries.count, expectedHashes.count)
        for (i, e) in j.entries.enumerated() {
            XCTAssertEqual(e.hash, expectedHashes[i], "hash de l'entrée \(i)")
        }
    }

    func testHeadHash() {
        XCTAssertEqual(buildFixtureJournal().headHash, expectedHashes.last)
    }

    func testGenesisAndChaining() {
        let j = buildFixtureJournal()
        XCTAssertEqual(j.entries[0].previousHash, Journal.genesisPrevHash)
        for i in 1..<j.entries.count {
            XCTAssertEqual(j.entries[i].previousHash, j.entries[i - 1].hash)
        }
    }

    func testEmptyJournalHeadIsGenesis() {
        XCTAssertEqual(Journal().headHash, Journal.genesisPrevHash)
        XCTAssertTrue(Journal().isValid)
    }

    func testValidChainVerifies() throws {
        XCTAssertNoThrow(try buildFixtureJournal().verify())
        XCTAssertTrue(buildFixtureJournal().isValid)
    }

    /// La sérialisation préfixée en longueur empêche l'injection de séparateur :
    /// {"ab":"c"} et {"a":"bc"} (mêmes octets naïvement concaténés) diffèrent.
    func testLengthPrefixingIsUnambiguous() {
        let h1 = Journal.computeHash(index: 0, timestamp: "t", kind: "k",
                                     previousHash: Journal.genesisPrevHash, payload: ["ab": "c"])
        let h2 = Journal.computeHash(index: 0, timestamp: "t", kind: "k",
                                     previousHash: Journal.genesisPrevHash, payload: ["a": "bc"])
        XCTAssertNotEqual(h1, h2)
    }

    /// L'ordre d'insertion des clés du payload ne change pas le hash (tri canonique).
    func testPayloadKeyOrderIndependence() {
        let a = Journal.computeHash(index: 0, timestamp: "t", kind: "k",
                                    previousHash: Journal.genesisPrevHash,
                                    payload: ["z": "1", "a": "2", "m": "3"])
        let b = Journal.computeHash(index: 0, timestamp: "t", kind: "k",
                                    previousHash: Journal.genesisPrevHash,
                                    payload: ["a": "2", "m": "3", "z": "1"])
        XCTAssertEqual(a, b)
    }
}
