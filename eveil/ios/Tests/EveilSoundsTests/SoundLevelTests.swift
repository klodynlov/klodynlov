// SoundLevelTests.swift — tous les bruitages au même niveau perçu (sauf les doux, voulus doux).
//
// Deux mesures : la sonie pondérée K que le mastering égalise (relue sur le son FINI,
// après limiteur et fondus), et le RMS actif NON pondéré recalculé indépendamment —
// celui-ci doit rester dans ±3 dB de la moyenne pour tous les effets « normaux ».

import EveilSounds
import XCTest

final class SoundLevelTests: XCTestCase {
    private static let soft: Set<SoundEffect> = [.whooshSoft, .flutter]

    func testLoudnessIsMatched() {
        var table = "effet         sonie(dB)  RMS actif(dB)  RMS total(dB)  crête  durée(s)\n"
        var active: [SoundEffect: Double] = [:]
        for effect in SoundEffect.allCases {
            let x = Renders.sound(effect)
            let loudness = SoundLevels.loudness(x)
            let expected = SoundLevels.target + SoundLevels.offset(effect)
            XCTAssertEqual(loudness, expected, accuracy: 1.5, "\(effect) : sonie \(loudness) dB")
            active[effect] = AudioAnalysis.activeRMSDB(x)
            table += effect.rawValue.padding(toLength: 13, withPad: " ", startingAt: 0)
            table += String(format: " %8.1f  %13.1f  %13.1f  %5.2f  %7.2f\n", loudness,
                            active[effect] ?? 0, AudioAnalysis.rmsDB(x), x.map(abs).max() ?? 0,
                            Double(x.count) / SoundSynth.sampleRate)
        }
        let normal = active.filter { !Self.soft.contains($0.key) }
        let mean = normal.values.reduce(0, +) / Double(normal.count)
        for (effect, level) in normal {
            XCTAssertEqual(level, mean, accuracy: 3, "\(effect) : RMS actif \(level) dB, moyenne \(mean) dB")
        }
        for effect in Self.soft {
            XCTAssertLessThan(active[effect] ?? 0, mean - 4, "\(effect) doit rester doux")
            XCTAssertGreaterThan(active[effect] ?? -99, mean - 14, "\(effect) doit rester audible")
        }
        print(table + String(format: "moyenne RMS actif (hors doux) : %.1f dB\n", mean))
    }

    func testVariantsKeepTheSameLevel() {
        for effect in [SoundEffect.ding, .buzz, .beeBuzz, .tweet, .pop] {
            for variant in 0..<6 {
                let loudness = SoundLevels.loudness(Renders.sound(effect, variant))
                XCTAssertEqual(loudness, SoundLevels.target, accuracy: 1.5, "\(effect) v\(variant)")
            }
        }
    }
}
