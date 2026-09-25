// WavExportTests.swift — écouter les bruitages hors de l'app.
//
// `EVEIL_SOUNDS_DIR=/chemin swift test --filter EveilSoundsTests` écrit chaque effet
// (variante 0, plus quelques variantes de `ding`, `buzz`, `beeBuzz`, `tweet`, `pop`) en
// WAV 16 bits mono, et `niveaux.tsv` (durée, crête, sonie, RMS). Sans la variable, le
// test vérifie seulement l'en-tête WAV produit en mémoire.

import EveilSounds
import Foundation
import XCTest

final class WavExportTests: XCTestCase {
    /// Les fichiers à écrire : chaque effet, et des variantes pour les bestioles « chantantes ».
    static var takes: [(name: String, effect: SoundEffect, variant: Int)] {
        var list = SoundEffect.allCases.map { (name: $0.rawValue, effect: $0, variant: 0) }
        for v in 1...9 { list.append((name: "ding_v\(v)", effect: .ding, variant: v)) }
        for effect in [SoundEffect.buzz, .beeBuzz, .tweet, .pop] {
            for v in 1...3 { list.append((name: "\(effect.rawValue)_v\(v)", effect: effect, variant: v)) }
        }
        return list
    }

    func testWavHeaderIsValidPCM() {
        let x = Renders.sound(.pop)
        let data = AudioAnalysis.wav(x)
        XCTAssertEqual(data.count, 44 + 2 * x.count)
        XCTAssertEqual(String(decoding: data[0..<4], as: UTF8.self), "RIFF")
        XCTAssertEqual(String(decoding: data[8..<16], as: UTF8.self), "WAVEfmt ")
        XCTAssertEqual(String(decoding: data[36..<40], as: UTF8.self), "data")
        let rate = data[24..<28].enumerated().reduce(0) { $0 | Int($1.element) << (8 * $1.offset) }
        XCTAssertEqual(rate, 44_100)
    }

    func testExportWhenAsked() throws {
        guard let path = ProcessInfo.processInfo.environment["EVEIL_SOUNDS_DIR"], !path.isEmpty else { return }
        let dir = URL(fileURLWithPath: path, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        var table = "fichier\tdurée_s\tcrête\tsonie_dB\tRMS_actif_dB\tRMS_total_dB\n"
        for take in Self.takes {
            let x = Renders.sound(take.effect, take.variant)
            try AudioAnalysis.wav(x).write(to: dir.appendingPathComponent("\(take.name).wav"))
            let seconds = Double(x.count) / SoundSynth.sampleRate
            let peak = x.map { abs($0) }.max() ?? 0
            let loud = SoundLevels.loudness(x)
            table += String(format: "%@\t%.2f\t%.3f\t%.1f\t%.1f\t%.1f\n", take.name, seconds, peak, loud,
                            AudioAnalysis.activeRMSDB(x), AudioAnalysis.rmsDB(x))
        }
        try table.write(to: dir.appendingPathComponent("niveaux.tsv"), atomically: true, encoding: .utf8)
    }
}
