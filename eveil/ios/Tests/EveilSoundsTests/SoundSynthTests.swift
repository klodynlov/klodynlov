// SoundSynthTests.swift — chaque bruitage se calcule, reste fini, audible, sans saturer.

import EveilSounds
import XCTest

final class SoundSynthTests: XCTestCase {
    func testEveryEffectIsAudibleFiniteAndUnclipped() {
        for effect in SoundEffect.allCases {
            let x = SoundSynth.render(effect)
            let seconds = Double(x.count) / SoundSynth.sampleRate
            XCTAssertGreaterThanOrEqual(seconds, 0.05, "\(effect) trop court")
            XCTAssertLessThanOrEqual(seconds, 4.0, "\(effect) trop long")
            XCTAssertTrue(x.allSatisfy { $0.isFinite }, "\(effect) : NaN/Inf")
            let peak = x.map(abs).max() ?? 0
            XCTAssertLessThanOrEqual(peak, 0.99, "\(effect) sature")
            let rms = (x.reduce(0) { $0 + $1 * $1 } / Float(max(x.count, 1))).squareRoot()
            XCTAssertGreaterThan(rms, 0.005, "\(effect) inaudible")
        }
    }

    func testRenderingIsDeterministic() {
        for effect in SoundEffect.allCases {
            XCTAssertEqual(SoundSynth.render(effect, variant: 2), SoundSynth.render(effect, variant: 2), "\(effect)")
        }
    }

    /// Le contrat du mastering : ≤ 2,5 s, crête ≤ 0,9, fondus aux deux bouts (pas de clic).
    func testMasteringContract() {
        for effect in SoundEffect.allCases {
            for variant in [0, 1, 7, -3] {
                let x = Renders.sound(effect, variant)
                let label = "\(effect) v\(variant)"
                XCTAssertLessThanOrEqual(Double(x.count) / SoundSynth.sampleRate, 2.5, label)
                XCTAssertLessThanOrEqual(x.map(abs).max() ?? 0, 0.9, label)
                XCTAssertEqual(x.first, 0, label)
                XCTAssertEqual(x.last, 0, label)
                let onset = x.prefix(Int(0.0005 * SoundSynth.sampleRate)).map(abs).max() ?? 0
                XCTAssertLessThan(onset, 0.05, "\(label) : attaque sans fondu")
            }
        }
    }

    /// Rien d'agressif tout en haut : presque rien au-delà de 10 kHz (le « sss » du serpent,
    /// qui vit à 5–9 kHz, a droit à un peu plus).
    func testNoHarshTopEnd() {
        for effect in SoundEffect.allCases {
            let above = AudioAnalysis.bandFraction(Renders.sound(effect), 10_000, 30_000)
            XCTAssertLessThan(above, effect == .hiss ? 0.03 : 0.012, "\(effect) : \(above * 100) % au-delà de 10 kHz")
        }
    }

    /// Une autre variante donne un autre son (hauteur, hasard) — deux mouches ne sont pas jumelles.
    func testVariantsDiffer() {
        for effect in SoundEffect.allCases {
            XCTAssertNotEqual(Renders.sound(effect, 0), Renders.sound(effect, 1), "\(effect)")
        }
    }
}
