// EarGamesTests.swift — les jeux d'écoute : des manches justes, dans un ordre fixe, jamais « faux ».

#if canImport(SwiftUI)
import EveilDesign
import PhraseCore
@testable import TrainPracticeUI
import XCTest

final class EarGamesTests: XCTestCase {
    func testLotoRoundsAreFairAndCoverEveryItem() {
        var targets = Set<String>()
        for r in 0..<EarGames.lotoItems.count {
            let round = EarGames.lotoRound(r)
            XCTAssertEqual(round.choices.count, 3)
            XCTAssertEqual(Set(round.choices).count, 3, "images en double à la manche \(r)")
            let sounds = round.choices.compactMap { EarGames.lotoItem($0)?.sound }
            XCTAssertEqual(Set(sounds).count, 3, "deux images font le même bruit à la manche \(r)")
            targets.insert(round.choices[round.answer])
        }
        XCTAssertEqual(targets.count, EarGames.lotoItems.count, "chaque bruit est cherché à son tour")
        XCTAssertEqual(EarGames.lotoRound(4), EarGames.lotoRound(4), "rien n'est tiré au hasard")
    }

    func testTheAnswerMoves() {
        let places = Set((0..<9).map { EarGames.lotoRound($0).answer })
        XCTAssertEqual(places, [0, 1, 2], "la bonne image change de place")
    }

    func testFindRoundsUseDrawnNouns() {
        for count in 2...4 {
            var targets = Set<String>()
            for r in 0..<EarGames.findNouns.count {
                let round = EarGames.findRound(r, count: count)
                XCTAssertEqual(round.choices.count, count)
                XCTAssertEqual(Set(round.choices).count, count)
                for id in round.choices {
                    let noun = PhraseLexicon.noun(id)
                    XCTAssertNotNil(noun, id)
                    XCTAssertTrue(PictoLibrary.isDrawn(noun?.drawing ?? ""), "\(id) : pas de dessin")
                }
                targets.insert(round.choices[round.answer])
            }
            XCTAssertEqual(targets.count, EarGames.findNouns.count)
        }
    }

    func testEveryLotoItemIsDrawnAndNamed() {
        for item in EarGames.lotoItems {
            XCTAssertTrue(PictoLibrary.isDrawn(item.drawing), item.drawing)
            XCTAssertFalse(item.fr.isEmpty || item.en.isEmpty)
        }
        XCTAssertEqual(Set(EarGames.lotoItems.map(\.sound)).count, EarGames.lotoItems.count, "un bruit par image")
    }

    /// Jamais « non », jamais « faux » : on nomme ce que l'enfant a touché.
    func testTheVoiceNeverSaysWrong() {
        for text in [EarGames.thatIs("le chat", locale: "fr-FR"), EarGames.yes("la vache", locale: "fr-FR"),
                     EarGames.thatIs("the cat", locale: "en-US")] {
            let lower = text.lowercased()
            for banned in ["non", "faux", "pas ça", "no", "wrong"] {
                XCTAssertFalse(lower.split(separator: " ").contains { $0.hasPrefix(banned) && $0.count <= banned.count + 1 },
                               "« \(text) » contient « \(banned) »")
            }
        }
        XCTAssertEqual(EarGames.thatIs("le chat", locale: "fr-FR"), "Ça, c'est le chat.")
        let peche = PhraseLexicon.noun("peche")!
        XCTAssertEqual(EarGames.findQuestion(peche, locale: "fr-FR"), "Où est la pêche ?")
        XCTAssertEqual(EarGames.findQuestion(peche, locale: "en-US"), "Where is the peach?")
    }
}
#endif
