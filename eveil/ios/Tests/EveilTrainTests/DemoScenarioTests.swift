// DemoScenarioTests.swift — le mode démo montre ce qu'il annonce, pour chaque mot.
//
// Le bouton « Mot entier » doit accrocher le fourgon, « Sans la fin » le laisser
// en gare, « Une syllabe en moins » laisser un wagon éteint — sur le VRAI chemin
// de l'app (traqueur en flux, blocs de 20 ms), pour tous les mots FR et EN.

import Foundation
import TrainPracticeUI
import WordEndCore
import XCTest

final class DemoScenarioTests: XCTestCase {
    private func lexicon(_ locale: String) throws -> Lexicon {
        // …/eveil/ios/Tests/EveilTrainTests/DemoScenarioTests.swift → …/eveil/lexique/
        let eveil = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        return try Lexicon.decode(Data(contentsOf: eveil.appendingPathComponent("lexique/\(locale).json")))
    }

    /// Même découpage que `ListeningController.listenDemo` : blocs de 20 ms, puis arrêt.
    private func streamedVerdict(_ samples: [Double], for word: TargetWord) -> Verdict? {
        let tracker = StreamingTracker(target: word, config: DetectorConfig())
        var verdict: Verdict?
        let step = WordEnd.analysisRate / 50
        var start = 0
        while start < samples.count {
            for case let .ended(v, _, _) in tracker.push(Array(samples[start..<min(start + step, samples.count)])) {
                verdict = v
            }
            start += step
        }
        for case let .ended(v, _, _) in tracker.stop() { verdict = v }
        return verdict
    }

    func testEveryScenarioShowsWhatItsButtonSays() throws {
        let expected: [DemoScenario: VerdictKind] = [
            .complete: .complete, .missingEnd: .missingFinalConsonant, .fewerSyllables: .fewerSyllables,
        ]
        var checked = 0
        for locale in ["fr-FR", "en-US"] {
            for word in try lexicon(locale).words {
                for scenario in DemoScenario.allCases where scenario.isAvailable(for: word) {
                    let samples = try XCTUnwrap(scenario.samples(for: word))
                    let verdict = try XCTUnwrap(streamedVerdict(samples, for: word), "\(word.id) · \(scenario)")
                    XCTAssertEqual(verdict.kind, expected[scenario], "\(word.id) · \(scenario) · \(verdict.reasons)")
                    checked += 1
                }
            }
        }
        XCTAssertGreaterThanOrEqual(checked, 50, "trop peu de cas vérifiés")
    }

    func testScenarioAvailability() throws {
        let douche = try XCTUnwrap(try lexicon("fr-FR").word(id: "fr.douche"))
        XCTAssertTrue(DemoScenario.missingEnd.isAvailable(for: douche))
        XCTAssertFalse(DemoScenario.fewerSyllables.isAvailable(for: douche))   // une seule syllabe
        XCTAssertEqual(DemoScenario.complete.spec(for: douche), "d50 u190 S180")
        XCTAssertEqual(DemoScenario.missingEnd.spec(for: douche), "d50 u250")
    }
}
