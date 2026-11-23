// PhraseCoreTests.swift — le train des phrases : parité avec la référence Python.
//
// `Resources/phrases-golden.json` est produit par `python3 -m phrases.generer`
// (eveil/outils) : des phrases (FR et EN, morceau par morceau) et des plateaux, calculés
// en Python ; `PhraseGrammar` et `PhraseLevels` doivent retrouver EXACTEMENT les mêmes.

import Foundation
import XCTest
@testable import PhraseCore

private struct Golden: Decodable {
    struct Card: Decodable {
        let role: String
        let id: String
        let preposition: String?

        var card: PhraseCard { PhraseCard(PhraseRole(rawValue: role)!, id, preposition: preposition ?? "") }
    }

    struct Text: Decodable {
        let sentence: String
        let chunks: [String]
    }

    struct Sentence: Decodable {
        let cards: [Card]
        let fr: Text
        let en: Text

        enum CodingKeys: String, CodingKey {
            case cards
            case fr = "fr-FR"
            case en = "en-US"
        }
    }

    struct Tray: Decodable {
        let level: Int
        let round: Int
        let role: String
        let verb: String?
        let cards: [Card]
    }

    struct NounPhrase: Decodable {
        let id: String
        let fr: String
        let en: String

        enum CodingKeys: String, CodingKey {
            case id
            case fr = "fr-FR"
            case en = "en-US"
        }
    }

    let sentences: [Sentence]
    let trays: [Tray]
    let noun_phrases: [NounPhrase]
    let counts: [String: Int]
}

final class PhraseCoreTests: XCTestCase {
    private func golden() throws -> Golden {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("Resources/phrases-golden.json")
        return try JSONDecoder().decode(Golden.self, from: Data(contentsOf: url))
    }

    func testSentencesMatchPython() throws {
        let g = try golden()
        XCTAssertGreaterThan(g.sentences.count, 30)
        for s in g.sentences {
            let cards = s.cards.map(\.card)
            XCTAssertEqual(PhraseGrammar.sentence(cards, locale: "fr-FR"), s.fr.sentence)
            XCTAssertEqual(PhraseGrammar.sentence(cards, locale: "en-US"), s.en.sentence)
            XCTAssertEqual(cards.map { PhraseGrammar.chunk($0, locale: "fr-FR") }, s.fr.chunks)
            XCTAssertEqual(cards.map { PhraseGrammar.chunk($0, locale: "en-US") }, s.en.chunks)
        }
    }

    func testTraysMatchPython() throws {
        let g = try golden()
        for t in g.trays {
            let role = try XCTUnwrap(PhraseRole(rawValue: t.role))
            let tray = PhraseLevels.tray(role, level: t.level, round: t.round, verb: t.verb ?? "")
            XCTAssertEqual(tray, t.cards.map(\.card), "\(t.role) niveau \(t.level) tour \(t.round) \(t.verb ?? "")")
        }
    }

    func testNounPhrasesMatchPython() throws {
        for n in try golden().noun_phrases {
            let noun = try XCTUnwrap(PhraseLexicon.noun(n.id))
            XCTAssertEqual(PhraseGrammar.nounPhrase(noun, locale: "fr-FR"), n.fr)
            XCTAssertEqual(PhraseGrammar.nounPhrase(noun, locale: "en-US"), n.en)
        }
    }

    func testLexiconCountsMatchPython() throws {
        let c = try golden().counts
        XCTAssertEqual(PhraseLexicon.nouns(.qui).count, c["qui"])
        XCTAssertEqual(PhraseLexicon.nouns(.quoi).count, c["quoi"])
        XCTAssertEqual(PhraseLexicon.nouns(.ou).count, c["ou"])
        XCTAssertEqual(PhraseLexicon.verbs.count, c["verbs"])
    }

    func testElisionAndCapitals() {
        let sentence = PhraseGrammar.sentence([PhraseCard(.qui, "autruche"), PhraseCard(.verbe, "dormir"),
                                               PhraseCard(.ou, "arbre", preposition: "derriere")], locale: "fr-FR")
        XCTAssertEqual(sentence, "L'autruche dort derrière l'arbre.")
        XCTAssertEqual(PhraseGrammar.sentence([PhraseCard(.qui, "lou"), PhraseCard(.verbe, "se_cacher")], locale: "en-US"),
                       "Lou hides.")
    }

    func testQuestionsUseWhatIsAlreadyChosen() {
        let chat = PhraseCard(.qui, "chat"), mange = PhraseCard(.verbe, "manger"), dort = PhraseCard(.verbe, "dormir")
        XCTAssertEqual(PhrasePrompts.question(for: .qui, cards: [], locale: "fr-FR"), "Qui ?")
        XCTAssertEqual(PhrasePrompts.question(for: .verbe, cards: [chat], locale: "fr-FR"), "Que fait le chat ?")
        XCTAssertEqual(PhrasePrompts.question(for: .quoi, cards: [chat, mange], locale: "fr-FR"), "Le chat mange quoi ?")
        XCTAssertEqual(PhrasePrompts.question(for: .ou, cards: [chat, dort], locale: "fr-FR"), "Le chat dort où ?")
        XCTAssertEqual(PhrasePrompts.question(for: .verbe, cards: [PhraseCard(.qui, "lou")], locale: "fr-FR"), "Que fait Lou ?")
        XCTAssertEqual(PhrasePrompts.question(for: .verbe, cards: [chat], locale: "en-US"), "What does the cat do?")
        XCTAssertEqual(PhrasePrompts.question(for: .quoi, cards: [chat, mange], locale: "en-US"), "The cat eats what?")
        XCTAssertEqual(PhrasePrompts.label(for: .ou, locale: "fr-FR"), "Où ?")
    }

    func testEveryCardHasADrawing() {
        for n in PhraseLexicon.nouns { XCTAssertFalse(n.drawing.isEmpty, n.id) }
        for v in PhraseLexicon.verbs {
            XCTAssertEqual(PhraseLexicon.drawing(of: PhraseCard(.verbe, v.id)), "verbe.\(v.id)")
            for o in v.objects { XCTAssertTrue(PhraseLexicon.noun(o)?.roles.contains(.quoi) ?? false, "\(v.id) → \(o)") }
        }
    }
}
