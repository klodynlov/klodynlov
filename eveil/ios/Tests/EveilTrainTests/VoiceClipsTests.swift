// La voix préparée (Supertonic 3, F5, 17/11/2026) : la clé de l'app est celle du générateur
// (`eveil/outils/voix/generer.py`), et ce que le train dit le plus souvent a son fichier.

import Foundation
@testable import TrainPracticeUI
import WordEndAudio
import WordEndCore
import XCTest

final class VoiceClipsTests: XCTestCase {
    private func lexicon(_ locale: String) throws -> Lexicon {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("lexique/\(locale).json")
        return try Lexicon.decode(Data(contentsOf: url))
    }

    func testTheManifestShipsWithItsFiles() throws {
        XCTAssertEqual(VoiceClips.voiceName, "Supertonic 3, style F5")
        XCTAssertGreaterThan(VoiceClips.count, 300)
        XCTAssertEqual(VoiceClips.key(locale: "fr-FR", pace: "word", text: "douche", ipa: "duʃ"), "fr-FR|word|douche|duʃ")
        XCTAssertEqual(VoiceClips.key(locale: "fr-FR", pace: "word", text: "Encore !", ipa: nil), "fr-FR|word|Encore !|")
    }

    /// Les mêmes clés que `PracticeView` : mot entier (API sans points), syllabes du modèle et des wagons.
    func testMostTrainUtterancesHaveTheirFile() throws {
        for locale in ["fr-FR", "en-US"] {
            var asked = 0, found = 0
            for w in try lexicon(locale).words where w.level == 1 {
                let whole = w.ipa.map { $0.replacingOccurrences(of: ".", with: "") }
                var keys = [("word", w.text, whole)]
                keys += w.voiceSegments.map { ("syllable", $0.text, $0.ipa) }
                keys += w.wagonSegments.map { ("syllable", $0.text, $0.ipa) }
                for (pace, text, ipa) in keys {
                    asked += 1
                    if let url = VoiceClips.url(locale: locale, pace: pace, text: text, ipa: ipa) {
                        found += 1
                        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), url.path)
                    }
                }
            }
            XCTAssertGreaterThan(Double(found) / Double(asked), 0.6, "\(locale) : \(found)/\(asked)")
        }
        XCTAssertNotNil(VoiceClips.url(locale: "fr-FR", pace: "word", text: "Encore !", ipa: nil))
    }

    /// Une seule voix par mot : `covers` est vrai seulement si le mot entier ET toutes ses syllabes ont leur fichier.
    func testOneVoicePerWord() throws {
        var covered = 0
        let words = try lexicon("fr-FR").words
        for w in words where VoiceClips.covers(w, locale: "fr-FR") {
            covered += 1
            let whole = w.ipa!.replacingOccurrences(of: ".", with: "")
            XCTAssertNotNil(VoiceClips.url(locale: "fr-FR", pace: "word", text: w.text, ipa: whole), w.id)
            for s in w.voiceSegments + w.wagonSegments {
                XCTAssertNotNil(VoiceClips.url(locale: "fr-FR", pace: "syllable", text: s.text, ipa: s.ipa), w.id)
            }
        }
        XCTAssertGreaterThan(covered, words.count / 2)
        let family = try customWord(text: "Minouche", wagons: ["Mi", "nou"], coda: "S", locale: "fr-FR")
        XCTAssertFalse(VoiceClips.covers(family, locale: "fr-FR"))          // mots de la famille : voix de l'iPad
    }
}
