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
}
