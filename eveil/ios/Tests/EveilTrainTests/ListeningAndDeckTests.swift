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

    // Niveaux (06/10/2026) : miroir de `reference/wordend/test_policy.py` (TestLevels).

    func testLevelOneIsOneSyllableWordsInLexiconOrder() throws {
        for locale in ["fr-FR", "en-US"] {
            let words = try lexicon(locale).words
            let deck = WordDeck.deck(words, level: 1)
            XCTAssertFalse(deck.isEmpty, locale)
            XCTAssertTrue(deck.allSatisfy { $0.level == 1 && $0.wagons.count == 1 }, locale)
            XCTAssertEqual(deck.map(\.id), words.filter { $0.level == 1 }.map(\.id), locale)
        }
        let fr = try lexicon("fr-FR").words
        for level in 1...3 { XCTAssertTrue(WordDeck.deck(fr, level: level).allSatisfy { $0.level == level }) }
        XCTAssertTrue(WordDeck.deck(fr, level: 2).allSatisfy { $0.wagons.count == 2 })
    }

    func testLevelFourMixesEveryWordOnce() throws {
        for locale in ["fr-FR", "en-US"] {
            let words = try lexicon(locale).words
            let all = WordDeck.deck(words, level: 4)
            XCTAssertEqual(Set(all.map(\.id)), Set(words.map(\.id)), locale)
            XCTAssertEqual(all.count, words.count, locale)
            XCTAssertEqual(all.map(\.id), WordDeck.mixed(words).map(\.id), locale)
        }
        let fr = try lexicon("fr-FR").words
        XCTAssertEqual(WordDeck.deck(fr, level: 4).prefix(6).map { $0.level ?? 1 }, [1, 1, 2, 1, 3, 2])
        XCTAssertGreaterThanOrEqual(fr.count, 28)
    }

    func testSixDifferentWordsOpenTheNextLevelAtTheNextSession() throws {
        let fr = try lexicon("fr-FR").words
        let ones = WordDeck.levelWords(fr, level: 1)
        var p = LevelProgress()
        XCTAssertEqual(p.level, 1)
        for w in ones.prefix(WordDeck.unlockWords - 1) {
            p.record(w, kind: .complete)
            p.record(w, kind: .complete)                  // le même mot deux fois : une seule fois
        }
        XCTAssertFalse(p.ready(fr))
        XCTAssertEqual(p.startSession(fr), 1)
        p.record(ones[WordDeck.unlockWords - 1], kind: .complete)
        XCTAssertTrue(p.ready(fr))
        XCTAssertEqual(p.level, 1)                        // rien ne change pendant la séance
        XCTAssertEqual(p.startSession(fr), 2)
        XCTAssertTrue(p.said.isEmpty)
    }

    func testOnlyACountedCompleteVerdictOfTheLevelCounts() throws {
        let fr = try lexicon("fr-FR").words
        var p = LevelProgress()
        for kind in VerdictKind.allCases where kind != .complete {
            for w in fr { p.record(w, kind: kind) }
        }
        for w in fr { p.record(w, kind: .complete, counted: false) }   // démo, essai par un adulte
        for w in fr where w.level != 1 { p.record(w, kind: .complete) }
        XCTAssertTrue(p.said.isEmpty)
        XCTAssertEqual(p.startSession(fr), 1)
    }

    func testWholePathNeverGoesDownAndTheAdultDecides() throws {
        let en = try lexicon("en-US").words
        XCTAssertEqual(WordDeck.unlockTarget(Array(WordDeck.levelWords(en, level: 1).prefix(3)), level: 1), 3)   // moins de 6 : tous
        var p = LevelProgress()
        var seen = [p.level]
        for _ in 0..<6 {
            for w in WordDeck.levelWords(en, level: p.level) { p.record(w, kind: .complete) }
            seen.append(p.startSession(en))
        }
        XCTAssertEqual(Array(seen.prefix(4)), [1, 2, 3, 4])
        XCTAssertTrue(seen.dropFirst(3).allSatisfy { $0 == 4 })
        var q = LevelProgress(level: 3)
        for _ in 0..<3 {
            for w in en { q.record(w, kind: .fewerSyllables) }
            XCTAssertEqual(q.startSession(en), 3)          // jamais vers le bas tout seul
        }
        q.setByAdult(1)
        XCTAssertEqual(q.level, 1)
        q.setByAdult(9)
        XCTAssertEqual(q.level, 4)
        XCTAssertEqual(WordDeck.nextLevel(WordDeck.levelWords(en, level: 1), after: 1), 4)   // niveaux vides sautés
    }

    func testTheStoreKeepsOneProgressPerLanguage() throws {
        let suite = "eveil.tests.levels.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let fr = try lexicon("fr-FR").words
        XCTAssertEqual(TrainLevelStore.load(locale: "fr-FR", defaults: defaults).level, 1)   // on commence au niveau 1
        for w in WordDeck.levelWords(fr, level: 1).prefix(WordDeck.unlockWords) {
            TrainLevelStore.recordSaid(w, locale: "fr-FR", defaults: defaults)
        }
        XCTAssertEqual(TrainLevelStore.load(locale: "fr-FR", defaults: defaults).level, 1)
        XCTAssertEqual(TrainLevelStore.startSession(fr, locale: "fr-FR", defaults: defaults), 2)
        XCTAssertEqual(TrainLevelStore.load(locale: "en-US", defaults: defaults).level, 1)
        TrainLevelStore.setByAdult(1, locale: "fr-FR", defaults: defaults)
        XCTAssertEqual(TrainLevelStore.startSession(fr, locale: "fr-FR", defaults: defaults), 1)
        XCTAssertNotEqual(WordDeck.cursorKey(level: 1), WordDeck.cursorKey(level: 2))
    }

    func testOneSyllableFirstEverySound() throws {
        // « Commencer avec des mots d'une syllabe, comme mur, vert, ne plus se focaliser sur les ch ou ss »,
        // puis « des mots comme jus, peau » (06/10/2026) : jus, peau d'abord, syllabes ouvertes ; des mots sans fourgon (jugés sur leurs syllabes) et des
        // mots à fourgon mêlés ; un fourgon seulement pour « ch » et « s » (ce que juge le détecteur).
        let fr = try lexicon("fr-FR").words
        let one = WordDeck.deck(fr, level: 1)
        XCTAssertEqual(one.prefix(2).map(\.text), ["jus", "peau"])      // « des mots comme jus, peau »
        XCTAssertTrue(one.contains { $0.text == "mur" } && one.contains { $0.text == "vert" })
        XCTAssertTrue(one.prefix(12).allSatisfy { $0.coda == nil })     // syllabes ouvertes d'abord
        XCTAssertGreaterThan(one.filter { $0.coda == nil }.count, one.filter { $0.coda != nil }.count)
        XCTAssertTrue(one.contains { $0.coda != nil })
        for locale in ["fr-FR", "en-US"] {
            for w in try lexicon(locale).words {
                if let coda = w.coda {
                    XCTAssertTrue(["S", "s"].contains(coda), w.id)
                } else {
                    XCTAssertNil(w.caboose, w.id)
                    XCTAssertTrue(PictoLibrary.isDrawn(w.drawing ?? ""), "\(w.id) : dessin \(w.drawing ?? "-") introuvable")
                }
            }
        }
    }

    func testEveryWordHasItsSoundAndCritters() throws {
        for locale in ["fr-FR", "en-US"] {
            for word in try lexicon(locale).words where word.coda != nil {   // les mots à fourgon
                XCTAssertNotNil(WordScene.table[word.id], "\(word.id) sans scène (bruit + bestioles)")
                XCTAssertNotNil(WordScene.hookSound(coda: word.coda), "\(word.id) : fourgon muet")
            }
        }
        XCTAssertEqual(WordScene.hookSound(coda: "S"), .steam)
        XCTAssertEqual(WordScene.hookSound(coda: "s"), .hiss)
        XCTAssertEqual(WordScene.sound(of: .fly), .buzz)       // la mouche fait « bzzz »
    }
}
