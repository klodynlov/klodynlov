// SentenceTrainTests.swift — le train des phrases : chaque carte a son dessin, chaque verbe
// son mouvement, chaque lieu les prépositions qu'il dessine.

#if canImport(SwiftUI)
@testable import EveilDesign
import PhraseCore
import XCTest

final class SentenceTrainTests: XCTestCase {
    func testEveryVerbHasAMotionAndAPicto() {
        for v in PhraseLexicon.verbs {
            XCTAssertTrue(SentenceMotion.verbs.contains(v.id), "\(v.id) : pas de mouvement dans la scène")
            XCTAssertTrue(PictoLibrary.isDrawn(v.drawing), "\(v.id) : pas de picto")
        }
        XCTAssertEqual(Set(SentenceMotion.verbs), Set(PhraseLexicon.verbs.map(\.id)))
    }

    func testEveryNounIsDrawn() {
        for n in PhraseLexicon.nouns {
            XCTAssertTrue(PictoLibrary.isDrawn(n.drawing), "\(n.id) : dessin \(n.drawing) introuvable")
        }
    }

    /// Un lieu propose exactement les prépositions que son dessin sait placer (ses ancres).
    func testPlacesOfferTheirDrawnAnchors() throws {
        for place in PhraseLexicon.nouns(.ou) {
            let drawing = try XCTUnwrap(PictoLibrary.drawing(place.drawing), place.id)
            XCTAssertEqual(Set(drawing.anchors.keys.map(\.rawValue)), Set(place.prepositions), place.id)
        }
    }

    /// Chaque plateau de chaque niveau se remplit (au moins un choix), et la phrase complète se dit.
    func testEveryLevelCanBeCompleted() {
        for level in PhraseLevels.levels {
            let roles = PhraseLevels.roles(level: level)
            for round in 0..<6 {
                var cards: [PhraseCard] = []
                for role in roles {
                    let tray = PhraseLevels.tray(role, level: level, round: round, verb: cards.count > 1 ? cards[1].key : "")
                    XCTAssertFalse(tray.isEmpty, "niveau \(level), \(role), tour \(round)")
                    guard let first = tray.first else { break }
                    cards.append(first)
                }
                let sentence = PhraseGrammar.sentence(cards, locale: "fr-FR")
                XCTAssertTrue(sentence.hasSuffix("."), sentence)
                XCTAssertEqual(cards.count, roles.count)
            }
        }
    }
}
#endif
