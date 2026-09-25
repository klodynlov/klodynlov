// ListeningAndDeckTests.swift — les réglages nés du premier essai sur iPad (25/09/2026).
//
// « Le micro doit être plus réceptif » : une voix d'adulte est écartée par défaut
// (garde voulue), acceptée avec « Essai par un adulte » ; le diagnostic le dit en
// clair. « Plus de mots » : tous les niveaux, mêlés, chaque mot une fois. Et chaque
// mot du lexique a son bruit et ses petites bêtes.

import EveilDesign
import EveilSounds
import Foundation
@testable import TrainPracticeUI
import WordEndCore
import XCTest

final class ListeningAndDeckTests: XCTestCase {
    private func lexicon(_ locale: String) throws -> Lexicon {
        let eveil = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        return try Lexicon.decode(Data(contentsOf: eveil.appendingPathComponent("lexique/\(locale).json")))
    }

    /// Même chemin que l'app : blocs de 20 ms dans le traqueur en flux, puis arrêt.
    private func verdict(_ utterance: Utterance, word: TargetWord, config: DetectorConfig) -> Verdict? {
        let tracker = StreamingTracker(target: word, config: config, stream: ListeningSettings.streamingConfig())
        let x = Synth.synthesize(utterance)
        var out: Verdict?
        let step = WordEnd.analysisRate / 50
        var start = 0
        while start < x.count {
            for case let .ended(v, _, _) in tracker.push(Array(x[start..<min(start + step, x.count)])) { out = v }
            start += step
        }
        for case let .ended(v, _, _) in tracker.stop() { out = v }
        return out
    }

    func testAdultVoiceIsSetAsideByDefaultAndAcceptedInAdultTrial() throws {
        let douche = try XCTUnwrap(try lexicon("fr-FR").word(id: "fr.douche"))
        var adult = Utterance(spec: "d50 u190 S180")
        adult.f0Start = 120
        adult.f0End = 100
        adult.seed = 24

        let strict = try XCTUnwrap(verdict(adult, word: douche, config: ListeningSettings.detectorConfig(adultTrial: false)))
        XCTAssertEqual(strict.kind, .unsure)
        XCTAssertTrue(strict.reasons.contains("adult_voice_suspected"), "\(strict.reasons)")

        let trial = try XCTUnwrap(verdict(adult, word: douche, config: ListeningSettings.detectorConfig(adultTrial: true)))
        XCTAssertEqual(trial.kind, .complete, "\(trial.reasons)")

        // L'essai adulte ne lève QUE cette garde : une fin absente reste une fin absente.
        var adultShort = Utterance(spec: "d50 u250")
        adultShort.f0Start = 120
        adultShort.f0End = 100
        let short = try XCTUnwrap(verdict(adultShort, word: douche, config: ListeningSettings.detectorConfig(adultTrial: true)))
        XCTAssertEqual(short.kind, .missingFinalConsonant, "\(short.reasons)")

        // Une voix d'enfant passe dans les deux cas.
        let child = Utterance(spec: "d50 u190 S180")
        for adultTrial in [false, true] {
            let v = try XCTUnwrap(verdict(child, word: douche, config: ListeningSettings.detectorConfig(adultTrial: adultTrial)))
            XCTAssertEqual(v.kind, .complete)
        }
    }

    func testChildrenGetTenSecondsToStartSpeaking() {
        XCTAssertEqual(ListeningSettings.streamingConfig().maxWaitMs, 10_000)
        XCTAssertEqual(ListeningSettings.detectorConfig(adultTrial: false), DetectorConfig())   // référence intacte
    }

    func testDiagnosisExplainsTheAdultGuardInPlainWords() throws {
        let douche = try XCTUnwrap(try lexicon("fr-FR").word(id: "fr.douche"))
        var adult = Utterance(spec: "d50 u190 S180")
        adult.f0Start = 120
        adult.f0End = 100
        adult.seed = 24
        let v = try XCTUnwrap(verdict(adult, word: douche, config: DetectorConfig()))
        let d = ListeningDiagnosis(verdict: v, word: douche, locale: "fr-FR")
        XCTAssertEqual(d.tone, .caution)
        XCTAssertTrue(d.advice.contains { $0.contains("Essai par un adulte") }, "\(d.advice)")

        let ok = try XCTUnwrap(verdict(Utterance(spec: "d50 u190 S180"), word: douche, config: DetectorConfig()))
        let good = ListeningDiagnosis(verdict: ok, word: douche, locale: "fr-FR")
        XCTAssertEqual(good.tone, .good)
        XCTAssertTrue(good.details.contains { $0.contains("Fin « ch » : entendue") }, "\(good.details)")

        let silence = try XCTUnwrap(verdict(Utterance(spec: "_400"), word: douche, config: DetectorConfig()))
        XCTAssertEqual(silence.kind, .noSpeech)
        XCTAssertFalse(ListeningDiagnosis(verdict: silence, word: douche, locale: "en-US").advice.isEmpty)
    }

    func testDeckMixesLevelsAndKeepsEveryWordOnce() throws {
        for locale in ["fr-FR", "en-US"] {
            let words = try lexicon(locale).words
            let all = WordDeck.ordered(words, maxLevel: 3)
            XCTAssertEqual(Set(all.map(\.id)), Set(words.map(\.id)), locale)
            XCTAssertEqual(all.count, words.count, locale)
            XCTAssertEqual(all.prefix(2).map { $0.level ?? 1 }, [1, 1], locale)        // on commence facile
            XCTAssertTrue(all.prefix(6).contains { ($0.level ?? 1) >= 2 }, locale)     // et on varie vite
            let easy = WordDeck.ordered(words, maxLevel: 1)
            XCTAssertTrue(easy.allSatisfy { ($0.level ?? 1) == 1 }, locale)
            XCTAssertEqual(easy.count, words.filter { ($0.level ?? 1) == 1 }.count, locale)
        }
        XCTAssertGreaterThanOrEqual(try lexicon("fr-FR").words.count, 28)
    }

    func testEveryWordHasItsSoundAndCritters() throws {
        for locale in ["fr-FR", "en-US"] {
            for word in try lexicon(locale).words {
                XCTAssertNotNil(WordScene.table[word.id], "\(word.id) sans scène (bruit + bestioles)")
                XCTAssertNotNil(WordScene.hookSound(coda: word.coda), "\(word.id) : fourgon muet")
            }
        }
        XCTAssertEqual(WordScene.hookSound(coda: "S"), .steam)
        XCTAssertEqual(WordScene.hookSound(coda: "s"), .hiss)
        XCTAssertEqual(WordScene.sound(of: .fly), .buzz)       // la mouche fait « bzzz »
    }
}
