// BehaviourTests.swift — propriétés pédagogiques et de sûreté, miroir des
// tests Python (`test_policy.py`, `test_streaming.py`, `test_lexicon_bench.py`).

import Foundation
import XCTest
@testable import WordEndCore

private func sample(_ kind: VerdictKind) -> Verdict {
    Verdict(kind: kind, heardNuclei: 1, expectedNuclei: 2, codaExpected: true, codaHeard: false,
            codaPlace: nil, codaMs: 0, epenthesis: false, snrDb: 30, reasons: [])
}

private func synth(_ name: String, seed: Int = 5, snr: Double? = nil) -> [Double] {
    var u = Utterance(spec: Synth.library[name]!)
    u.seed = seed
    if let snr { u.snrDb = snr }
    return Synth.synthesize(u)
}

final class FeedbackPolicyTests: XCTestCase {
    func testPointingOnlyOnConfidentMissing() {
        for kind in VerdictKind.allCases {
            for attempt in 1...FeedbackPolicy.maxAttempts {
                let fb = FeedbackPolicy.feedback(for: sample(kind), wagons: 2, hasCaboose: true, attempt: attempt)
                if fb.caboose == .pointed || fb.mascot == .pointCaboose {
                    XCTAssertEqual(kind, .missingFinalConsonant)
                }
            }
        }
    }

    func testUnsureIsNeutral() {
        for kind in [VerdictKind.unsure, .noSpeech, .fewerSyllables] {
            for attempt in 1...FeedbackPolicy.maxAttempts {
                let fb = FeedbackPolicy.feedback(for: sample(kind), wagons: 2, hasCaboose: true, attempt: attempt)
                XCTAssertTrue(MessageKey.neutral.contains(fb.message), "\(kind)")
                XCTAssertEqual(fb.caboose, .waiting)
            }
        }
    }

    func testFewerSyllablesNeverDesignatesAWagon() {
        let fb = FeedbackPolicy.feedback(for: sample(.fewerSyllables), wagons: 3, hasCaboose: true, attempt: 1)
        XCTAssertEqual(fb.litWagons, [false, false, false])
        XCTAssertEqual(fb.mascot, .modelWord)
    }

    func testNoFailureLoop() {
        for kind in VerdictKind.allCases {
            let fb = FeedbackPolicy.feedback(for: sample(kind), wagons: 2, hasCaboose: true,
                                             attempt: FeedbackPolicy.maxAttempts)
            XCTAssertTrue(fb.advance, "\(kind)")
        }
    }

    func testMessagesExistInBothLanguages() {
        for key in MessageKey.allCases {
            XCTAssertFalse(key.defaultText(locale: "fr-FR").isEmpty)
            XCTAssertFalse(key.defaultText(locale: "en-US").isEmpty)
        }
    }

    func testSessionPolicy() {
        let p = SessionPolicy()
        XCTAssertEqual(p.nextStep(wordsDone: 0, sessionSeconds: 0, todaySeconds: 0), .continue)
        XCTAssertEqual(p.nextStep(wordsDone: p.wordsPerSession, sessionSeconds: 60, todaySeconds: 60), .endSession)
        XCTAssertEqual(p.nextStep(wordsDone: 0, sessionSeconds: 0, todaySeconds: p.dailyBudgetSeconds), .restToday)
    }
}

final class LexicalGuardTests: XCTestCase {
    func testAsrCanOnlyMakeVerdictsMoreCautious() {
        for kind in VerdictKind.allCases {
            for evidence in LexicalEvidence.allCases {
                let out = applyLexical(sample(kind), evidence)
                if out.kind != kind {
                    XCTAssertEqual(out.kind, .unsure)
                    XCTAssertEqual(evidence, .inconsistent)
                    XCTAssertTrue(out.reasons.contains("other_word_suspected"))
                }
            }
            XCTAssertEqual(applyLexical(sample(kind), .consistent).kind, kind)
        }
    }
}

final class LexiconTests: XCTestCase {
    private func load(_ locale: String) throws -> Lexicon {
        // …/eveil/ios/WordEndCore/Tests/WordEndCoreTests/BehaviourTests.swift → …/eveil/lexique/
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("lexique/\(locale).json")
        return try Lexicon.decode(Data(contentsOf: url))
    }

    func testSharedLexiconsAreSound() throws {
        for locale in ["fr-FR", "en-US"] {
            let lex = try load(locale)
            XCTAssertEqual(lex.problems(), [], locale)
            XCTAssertGreaterThanOrEqual(lex.words.count, 10)
        }
    }

    func testTranscriptsAgainstAcceptedForms() throws {
        let douche = try XCTUnwrap(try load("fr-FR").word(id: "fr.douche"))
        XCTAssertEqual(lexicalEvidence(transcript: "Douche", word: douche), .consistent)
        XCTAssertEqual(lexicalEvidence(transcript: "doux", word: douche), .consistent)
        XCTAssertEqual(lexicalEvidence(transcript: "le bain", word: douche), .inconsistent)
        XCTAssertEqual(lexicalEvidence(transcript: "  ?! ", word: douche), .notChecked)
    }

    func testCustomFamilyWord() throws {
        let w = try customWord(text: "Minouche", wagons: ["Mi", "nou"], coda: "S", locale: "fr-FR")
        XCTAssertEqual(w.nuclei, 2)
        XCTAssertEqual(w.caboose, "ch")
        XCTAssertTrue(w.id.hasPrefix("fr.perso."))
        XCTAssertThrowsError(try customWord(text: "robot", wagons: ["ro", "bot"], coda: "t", locale: "fr-FR"))
    }
}

final class DetectorAndStreamingTests: XCTestCase {
    func testAsymmetryOverNoise() {
        for snr in [35.0, 15.0, 10.0] {
            let full = detect(synth("douche", seed: 1, snr: snr), target: Shape(nuclei: 1, coda: "S"))
            let cut = detect(synth("dou", seed: 1, snr: snr), target: Shape(nuclei: 1, coda: "S"))
            XCTAssertNotEqual(full.kind, .missingFinalConsonant, "snr \(snr)")
            XCTAssertNotEqual(cut.kind, .complete, "snr \(snr)")
        }
    }

    func testStreamingMatchesBatch() {
        for name in ["douche", "dou", "minouche", "minou"] {
            let target = Shape(nuclei: name.hasPrefix("mi") ? 2 : 1, coda: "S")
            let x = synth(name, seed: 31)
            let batch = detect(x, target: target)
            for chunk in [240, 1024, 4800] {
                let tracker = StreamingTracker(target: target)
                var events: [TrackerEvent] = []
                var i = 0
                while i < x.count && tracker.phase != .ended {
                    events += tracker.push(Array(x[i..<min(x.count, i + chunk)]))
                    i += chunk
                }
                guard case let .ended(verdict, _, cause)? = events.last else {
                    return XCTFail("\(name): pas de fin d'énoncé")
                }
                XCTAssertEqual(verdict.kind, batch.kind, "\(name) chunk \(chunk)")
                XCTAssertEqual(cause, .silence)
            }
        }
    }

    func testResampledInputKeepsVerdict() {
        var u = Utterance(spec: Synth.library["douche"]!)
        u.rate = 48_000
        u.seed = 10
        let v = detect(Synth.synthesize(u), target: Shape(nuclei: 1, coda: "S"), rate: 48_000)
        XCTAssertEqual(v.kind, .complete)
    }
}

#if canImport(Accelerate)
final class AccelerateParityTests: XCTestCase {
    func testVDSPMatchesPortableFFT() throws {
        let n = WordEnd.frameSize
        var rng = SplitMix64(seed: 3)
        let x = (0..<n).map { _ in rng.nextSigned() }
        let portable = RadixTwoFFT(size: n).powerSpectrum(x)
        let vdsp = try XCTUnwrap(AccelerateSpectrum(size: n)).powerSpectrum(x)
        XCTAssertEqual(portable.count, vdsp.count)
        for k in portable.indices {
            // précision Float : tolérance relative
            XCTAssertEqual(vdsp[k], portable[k], accuracy: 1e-3 * max(1.0, portable[k]), "bin \(k)")
        }
    }
}
#endif
