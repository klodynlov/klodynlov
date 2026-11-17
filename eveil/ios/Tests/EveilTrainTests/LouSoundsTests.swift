// Les gestes de Lou pour un mot (miroir de `eveil/outils/gestes/test_sons_mots.py`, mêmes cas).

import Foundation
@testable import TrainPracticeUI
import WordEndCore
import XCTest

final class LouSoundsTests: XCTestCase {
    func testSameCasesAsPython() {
        let cases: [String: [[String]]] = [
            "ʒy": [["j", "u"]],
            "po": [["p", "o"]],
            "vwa.tyʁ": [["v", "oi"], ["t", "u", "r"]],
            "ʒi.ʁaf": [["j", "i"], ["r", "a", "f"]],
            "nɥaʒ": [["n", "ui", "a", "j"]],
            "ʃjɛ̃": [["ch", "ill", "in"]],
            "ɡʁə.nuj": [["g", "r", "e"], ["n", "ou", "ill"]],
            "flœʁ": [["f", "l", "eu ouvert", "r"]],
            "ʃə.val": [["ch", "e"], ["v", "a", "l"]],
            "bwat": [["b", "oi", "t"]],
            "kwɛ̃": [["k", "oin"]],
            "ˈwi": [["i"]],
        ]
        for (ipa, expected) in cases {
            XCTAssertEqual(LouSounds.keys(ipa: ipa), expected, ipa)
        }
    }

    func testEveryFrenchTrainWordHasGesturesForEachWagon() throws {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("lexique/fr-FR.json")
        let lexicon = try Lexicon.decode(Data(contentsOf: url))
        for word in lexicon.words {
            let keys = LouSounds.keys(for: word, locale: "fr-FR")
            XCTAssertEqual(keys.count, word.wagons.count, word.id)
            XCTAssertTrue(keys.allSatisfy { !$0.isEmpty }, word.id)
        }
        let en = TargetWord.bookWord(id: "en.x", text: "fish", ipa: "fɪʃ", wagons: ["fi"])
        XCTAssertEqual(LouSounds.keys(for: en, locale: "en-US"), [])        // pas de gestes en anglais
    }
}
