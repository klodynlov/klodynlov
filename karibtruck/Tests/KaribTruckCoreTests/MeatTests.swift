import XCTest
@testable import KaribTruckCore

/// Traçabilité viande : mentions d'origine (format du décret), limites de
/// température par état, fournées liées aux lots, garde-fous, rappel, affiche.
final class MeatTests: XCTestCase {

    // MARK: - Mentions d'origine

    func testOriginSameCountry() {
        let o = MeatOrigin(born: "France", raised: "France", slaughtered: "France")
        XCTAssertEqual(o.label(for: .boeuf), "Origine : France")
        XCTAssertEqual(MeatOrigin(raised: "France", slaughtered: "France").label(for: .volaille), "Origine : France")
    }

    func testOriginBeefDifferentCountries() {
        XCTAssertEqual(MeatOrigin(born: "Irlande", raised: "Irlande", slaughtered: "France").label(for: .boeuf),
                       "Né et élevé : Irlande et abattu : France")
        XCTAssertEqual(MeatOrigin(born: "Irlande", raised: "France", slaughtered: "France").label(for: .boeuf),
                       "Né et élevé : Irlande, France et abattu : France")
        // Naissance non saisie = même pays que l'élevage.
        XCTAssertEqual(MeatOrigin(born: nil, raised: "Uruguay", slaughtered: "Uruguay").label(for: .boeuf),
                       "Origine : Uruguay")
    }

    func testOriginOtherSpeciesDifferentCountries() {
        XCTAssertEqual(MeatOrigin(raised: "Brésil", slaughtered: "Brésil").label(for: .volaille), "Origine : Brésil")
        XCTAssertEqual(MeatOrigin(raised: "Espagne", slaughtered: "France").label(for: .porc),
                       "Élevé : Espagne et abattu : France")
        // Le pays de naissance ne compte que pour le bœuf.
        XCTAssertEqual(MeatOrigin(born: "Irlande", raised: "France", slaughtered: "France").label(for: .ovin),
                       "Origine : France")
    }

    func testOriginDisplayScope() {
        XCTAssertTrue(MeatSpecies.boeuf.originDisplayRequired)
        XCTAssertTrue(MeatSpecies.porc.originDisplayRequired)
        XCTAssertTrue(MeatSpecies.ovin.originDisplayRequired)
        XCTAssertTrue(MeatSpecies.volaille.originDisplayRequired)
        XCTAssertFalse(MeatSpecies.caprin.originDisplayRequired)
    }

    // MARK: - Limites de température à réception

    func testReceptionThresholds() {
        func limit(_ s: MeatSpecies, _ st: MeatState) -> Double {
            MeatRules.receptionThreshold(species: s, state: st).limitCelsius
        }
        XCTAssertEqual(limit(.volaille, .fraiche), 4.0)
        XCTAssertEqual(limit(.porc, .fraiche), 7.0)
        XCTAssertEqual(limit(.boeuf, .fraiche), 7.0)
        XCTAssertEqual(limit(.boeuf, .hachee), 2.0)
        XCTAssertEqual(limit(.porc, .abats), 3.0)
        XCTAssertEqual(limit(.volaille, .abats), 4.0)
        XCTAssertEqual(limit(.caprin, .preparee), 4.0)
        XCTAssertEqual(limit(.volaille, .surgelee), -15.0)
        for s in MeatSpecies.allCases {
            for st in MeatState.allCases {
                XCTAssertEqual(MeatRules.receptionThreshold(species: s, state: st).rule, .max, "froid = max")
            }
        }
    }

    // MARK: - Réception

    private func receive(_ k: inout KaribTruck, _ species: MeatSpecies = .volaille,
                         state: MeatState = .fraiche, lot: String = "L-100", dlc: String = "2026-09-30",
                         celsius: Double = 3.0, at: String = "2026-09-25T12:00:00Z") -> MeatLot {
        let (entry, _) = try! k.recordMeatReception(
            species: species, state: state, product: "Cuisses", supplier: "Antilles Frais",
            lot: lot, dlc: dlc, agrement: "FR 97.213.001 CE",
            origin: MeatOrigin(raised: "France", slaughtered: "France"), celsius: celsius, at: at)
        return k.meatLot(entry.hash)!
    }

    func testReceptionSealsOriginAgrementAndTemperature() throws {
        var k = KaribTruck()
        let (e, status) = try k.recordMeatReception(
            species: .porc, state: .fraiche, product: "Échine", supplier: "Boucherie du Lamentin",
            lot: "P-77", dlc: "2026-10-01", agrement: " FR 97.213.001 CE ",
            origin: MeatOrigin(raised: "Espagne", slaughtered: "France"), celsius: 6.0,
            at: "2026-09-25T12:00:00Z")
        XCTAssertEqual(status, .ok)
        XCTAssertEqual(e.kind, "meat.reception")
        XCTAssertEqual(e.payload["origin"], "Élevé : Espagne et abattu : France")
        XCTAssertEqual(e.payload["agrement"], "FR 97.213.001 CE")
        XCTAssertEqual(e.payload["limit"], "7.0")
        XCTAssertNil(e.payload["born"], "pas de naissance hors bœuf")
        XCTAssertTrue(k.isValid)
    }

    func testWarmReceptionIsAlert() throws {
        var k = KaribTruck()
        let (_, status) = try k.recordMeatReception(
            species: .boeuf, state: .hachee, product: "Steak haché", supplier: "X", lot: "H1",
            dlc: "2026-09-27", agrement: "", origin: MeatOrigin(born: "France", raised: "France", slaughtered: "France"),
            celsius: 3.5, at: "2026-09-25T12:00:00Z")
        XCTAssertEqual(status, .alert)
        XCTAssertEqual(k.alerts.count, 1)
        XCTAssertNil(k.journal.entries[0].payload["agrement"], "estampille vide non écrite")
    }

    func testIncompleteOriginIsRefused() {
        var k = KaribTruck()
        XCTAssertThrowsError(try k.recordMeatReception(
            species: .volaille, state: .fraiche, product: "Poulet", supplier: "X", lot: "1",
            dlc: "2026-09-30", agrement: "", origin: MeatOrigin(raised: "France", slaughtered: " "),
            celsius: 2.0, at: "2026-09-25T12:00:00Z")) { XCTAssertEqual($0 as? MeatError, .incompleteOrigin) }
        XCTAssertTrue(k.journal.entries.isEmpty, "rien d'écrit sur refus")
    }

    // MARK: - Fournées et garde-fous

    func testPreparationLinksLots() throws {
        var k = KaribTruck()
        let poulet = receive(&k, lot: "V-1")
        let porc = receive(&k, .porc, lot: "P-1")
        let prep = try k.recordMeatPreparation(name: "Colombo", lots: [poulet.id, porc.id], day: "2026-09-25",
                                               dlc: "2026-09-25", operator: "Klody", at: "2026-09-25T14:00:00Z")
        XCTAssertEqual(KaribTruck.lotIDs(of: prep), [poulet.id, porc.id])
        XCTAssertEqual(k.meatLot(poulet.id)?.preparations.map(\.hash), [prep.hash])
        XCTAssertEqual(k.meatLot(porc.id)?.preparations.count, 1)
        XCTAssertTrue(k.isValid)
    }

    func testPreparationGuards() {
        var k = KaribTruck()
        let lot = receive(&k, lot: "V-1", dlc: "2026-09-26")
        let day = "2026-09-25"
        XCTAssertThrowsError(try k.recordMeatPreparation(name: "X", lots: [], day: day, dlc: day,
                                                         operator: "k", at: "2026-09-25T14:00:00Z")) {
            XCTAssertEqual($0 as? MeatError, .noLot)
        }
        XCTAssertThrowsError(try k.recordMeatPreparation(name: "X", lots: ["inconnu"], day: day, dlc: day,
                                                         operator: "k", at: "2026-09-25T14:00:00Z")) {
            XCTAssertEqual($0 as? MeatError, .unknownLot("inconnu"))
        }
        // DLC le 26 : utilisable le 26 (inclus), refusé le 27.
        XCTAssertNoThrow(try k.recordMeatPreparation(name: "X", lots: [lot.id], day: "2026-09-26", dlc: "2026-09-26",
                                                     operator: "k", at: "2026-09-26T14:00:00Z"))
        XCTAssertThrowsError(try k.recordMeatPreparation(name: "X", lots: [lot.id], day: "2026-09-27", dlc: "2026-09-27",
                                                         operator: "k", at: "2026-09-27T14:00:00Z")) {
            XCTAssertEqual($0 as? MeatError, .lotExpired(lot.id))
        }
        let before = k.journal.entries.count
        XCTAssertNoThrow(try k.closeMeatLot(lot.id, reason: .termine, at: "2026-09-26T20:00:00Z"))
        XCTAssertThrowsError(try k.recordMeatPreparation(name: "X", lots: [lot.id], day: "2026-09-26", dlc: "2026-09-26",
                                                         operator: "k", at: "2026-09-26T21:00:00Z")) {
            XCTAssertEqual($0 as? MeatError, .lotClosed(lot.id))
        }
        XCTAssertEqual(k.journal.entries.count, before + 1, "seule la clôture a été écrite")
    }

    func testLotClosesOnlyOnce() throws {
        var k = KaribTruck()
        let lot = receive(&k)
        try k.closeMeatLot(lot.id, reason: .jete, note: "odeur", at: "2026-09-25T20:00:00Z")
        XCTAssertThrowsError(try k.closeMeatLot(lot.id, reason: .termine, at: "2026-09-25T21:00:00Z")) {
            XCTAssertEqual($0 as? MeatError, .lotClosed(lot.id))
        }
        XCTAssertEqual(k.meatLot(lot.id)?.closure?.payload["reason"], "jete")
        XCTAssertEqual(k.meatLot(lot.id)?.closure?.payload["note"], "odeur")
        XCTAssertTrue(k.openMeatLots.isEmpty)
    }

    // MARK: - Rappel

    func testSearchFindsLotAndItsPreparations() throws {
        var k = KaribTruck()
        let a = receive(&k, lot: "LOT-2509-A")
        _ = receive(&k, .porc, lot: "P-99")
        try k.recordMeatPreparation(name: "Poulet boucané", lots: [a.id], day: "2026-09-25", dlc: "2026-09-25",
                                    operator: "k", at: "2026-09-25T14:00:00Z")
        let found = k.searchMeatLots("2509-a")
        XCTAssertEqual(found.map(\.id), [a.id])
        XCTAssertEqual(found.first?.preparations.first?.payload["name"], "Poulet boucané")
        XCTAssertEqual(k.searchMeatLots("antilles").count, 2, "recherche par fournisseur")
        XCTAssertEqual(k.searchMeatLots("fr 97.213").count, 2, "recherche par estampille")
        XCTAssertTrue(k.searchMeatLots("  ").isEmpty)
    }

    // MARK: - Affiche origine

    func testOriginBoardShowsLotsInService() throws {
        var k = KaribTruck()
        let v1 = receive(&k, lot: "V-1", dlc: "2026-09-30")
        _ = try k.recordMeatReception(species: .volaille, state: .surgelee, product: "Poulet entier", supplier: "Import",
                                      lot: "BR-1", dlc: "2027-03-01", agrement: "",
                                      origin: MeatOrigin(raised: "Brésil", slaughtered: "Brésil"),
                                      celsius: -19, at: "2026-09-25T12:10:00Z")
        let perime = receive(&k, .porc, lot: "P-old", dlc: "2026-09-20")
        _ = perime
        // Lot de bœuf clos aujourd'hui mais servi dans une fournée du jour : reste affiché.
        let (b, _) = try k.recordMeatReception(species: .boeuf, state: .fraiche, product: "Paleron", supplier: "X",
                                               lot: "B-1", dlc: "2026-09-28", agrement: "",
                                               origin: MeatOrigin(born: "Irlande", raised: "Irlande", slaughtered: "France"),
                                               celsius: 5, at: "2026-09-25T12:20:00Z")
        try k.recordMeatPreparation(name: "Ragoût", lots: [b.hash], day: "2026-09-25", dlc: "2026-09-25",
                                    operator: "k", at: "2026-09-25T13:00:00Z")
        try k.closeMeatLot(b.hash, reason: .termine, at: "2026-09-25T15:00:00Z")
        try k.closeMeatLot(v1.id, reason: .termine, at: "2026-09-25T15:01:00Z")

        let board = k.originBoard(day: "2026-09-25")
        XCTAssertEqual(board.map(\.species), [.volaille, .boeuf], "porc périmé et poulet V-1 clos non affichés")
        XCTAssertEqual(board[0].origins, ["Origine : Brésil"])
        XCTAssertEqual(board[1].origins, ["Né et élevé : Irlande et abattu : France"])
        // Le lendemain, le bœuf clos n'est plus en service.
        XCTAssertEqual(k.originBoard(day: "2026-09-26").map(\.species), [.volaille])
    }

    func testFixtureChainUntouchedByMeatModule() {
        // Les types viande n'ajoutent rien aux entrées existantes (cf. FacadeTests).
        var k = KaribTruck()
        k.recordReception(supplier: "Antilles Frais", lot: "LOT-2208", dlc: "2026-08-25", product: "poulet",
                          at: "2026-08-18T07:10:00Z")
        XCTAssertTrue(k.meatLots.isEmpty, "une réception générique n'est pas un lot de viande")
    }
}
