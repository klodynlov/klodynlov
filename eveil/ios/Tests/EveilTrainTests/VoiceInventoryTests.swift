// La voix du petit train pour toutes les activités (demande de l'utilisateur, 17/11/2026).
//
// L'inventaire de ce que chaque activité peut dire est calculé ICI, par les fonctions de l'app
// (`ColoringVoice.lines`, `EarGames.voiceLines`, `PhrasePrompts.voiceLines`, `PhraseGrammar.voiceChunks`,
// `BookSentenceView.voiceLines`) : `eveil/outils/voix/generer.py` ne recopie aucune règle de texte, il lit
// `eveil/outils/voix/inventaire_activites.json`, que ce test écrit :
//
//     cd eveil/ios && EVEIL_VOICE_INVENTORY=../outils/voix/inventaire_activites.json \
//         swift test --filter VoiceInventoryTests/testExportTheInventory
//
// Puis chaque texte doit avoir son fichier de voix préparée, sauf les exceptions listées (et justifiées)
// plus bas ; et la phrase libre du train des phrases, jamais rendue entière, se compose de ses wagons.

import ColoringUI
import Foundation
import PhraseCore
@testable import TrainPracticeUI
import WordEndAudio
import XCTest

/// Ce que chaque activité peut dire, par langue (en plus du petit train, que `generer.py` inventorie déjà).
enum VoiceInventory {
    static let locales = ["fr-FR", "en-US"]

    /// Activité → textes, dans un ordre stable. Les clés sont celles du JSON lu par `generer.py`.
    static func all(locale: String) -> [String: [String]] {
        [
            "coloriage": ColoringVoice.lines(locale: locale),
            "ecoute": EarGames.voiceLines(locale: locale),
            "phrases_questions": PhrasePrompts.voiceLines(locale: locale),
            "phrases_morceaux": PhraseGrammar.voiceChunks(locale: locale),
            "livres": BookSentenceView.voiceLines(locale: locale),
        ]
    }

    static func json() throws -> Data {
        var root: [String: Any] = [
            "_note": "ÉCRIT PAR VoiceInventoryTests (eveil/ios) : ne pas modifier à la main. Tout ce que les activités "
                + "(coloriage, jeux d'écoute, train des phrases, livres des sons) peuvent dire ; lu par generer.py.",
        ]
        for locale in locales { root[locale] = all(locale: locale) }
        root["_composition"] = Dictionary(uniqueKeysWithValues: locales.map { ($0, compositionSample(locale: $0)) })
        return try JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys,
                                                                           .withoutEscapingSlashes])
    }

    /// Toutes les phrases libres d'un niveau (le train des phrases : chaque wagon, toutes ses cartes).
    static func freeSentences(level: Int) -> [[PhraseCard]] {
        var sentences: [[PhraseCard]] = [[]]
        for role in PhraseLevels.roles(level: level) {
            sentences = sentences.flatMap { p in PhraseGrammar.allCards(role, level: level, after: p).map { p + [$0] } }
        }
        return sentences
    }

    /// Un échantillon fixe de phrases libres (8 par niveau) pour MESURER la composition
    /// (`eveil/outils/voix/composer.py`) : la phrase, ses morceaux, et « sujet + verbe » d'un bloc + le reste.
    static func compositionSample(locale: String) -> [[String: Any]] {
        var out: [[String: Any]] = []
        for level in PhraseLevels.levels {
            let all = freeSentences(level: level)
            for k in 0..<8 {
                let cards = all[(k * all.count) / 8 + (k * 7) % max(1, all.count / 8)]
                let phrase = PhraseGrammar.sentence(cards, locale: locale)
                let head = String(PhraseGrammar.sentence(Array(cards.prefix(2)), locale: locale).dropLast())
                let bloc = cards.count > 2 ? [head] + PhraseGrammar.sentenceParts(Array(cards.dropFirst(2)), locale: locale)
                                           : [phrase]
                out.append(["niveau": level, "phrase": phrase,
                            "morceaux": PhraseGrammar.sentenceParts(cards, locale: locale), "bloc": bloc])
            }
        }
        return out
    }

    static var committedURL: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("outils/voix/inventaire_activites.json")
    }

    /// Les textes qui n'ont PAS de fichier, et pourquoi (voix de l'iPad pour ceux-là ; une phrase libre
    /// qui contient un de ces wagons se dit toute entière avec la voix de l'iPad). Clé : « langue|texte ».
    /// La liste est versionnée à côté de l'inventaire (`exceptions_activites.json`, écrite par `generer.py` :
    /// ce que Whisper a entendu après toutes les prises) ; ce sont les phrases à écouter (`page_activites.py`).
    static let exceptions: [String: String] = {
        let url = committedURL.deletingLastPathComponent().appendingPathComponent("exceptions_activites.json")
        guard let data = try? Data(contentsOf: url),
              let list = try? JSONSerialization.jsonObject(with: data) as? [String: String] else { return [:] }
        return list
    }()
}

final class VoiceInventoryTests: XCTestCase {
    func testExportTheInventory() throws {
        let data = try VoiceInventory.json()
        if let path = ProcessInfo.processInfo.environment["EVEIL_VOICE_INVENTORY"], !path.isEmpty {
            try (data + Data("\n".utf8)).write(to: URL(fileURLWithPath: path))
        }
        // Le fichier versionné (celui que lit generer.py) est à jour : sinon, relancer la commande d'en-tête.
        let committed = try Data(contentsOf: VoiceInventory.committedURL)
        let a = try JSONSerialization.jsonObject(with: committed) as? NSDictionary
        let b = try JSONSerialization.jsonObject(with: data) as? NSDictionary
        XCTAssertEqual(a, b, "inventaire_activites.json périmé : relancer avec EVEIL_VOICE_INVENTORY")
    }

    /// Ce que chaque activité dit vraiment (quelques témoins), et sans doublon.
    func testTheInventoryHasWhatTheActivitiesSay() {
        let fr = VoiceInventory.all(locale: "fr-FR")
        XCTAssertTrue(fr["coloriage"]!.contains("Colorie le soleil en jaune !"))
        XCTAssertTrue(fr["coloriage"]!.contains("En jaune !"))
        XCTAssertTrue(fr["coloriage"]!.contains("bleu nuit"))
        XCTAssertTrue(fr["coloriage"]!.contains("Je t'aide à colorier !"))
        XCTAssertTrue(fr["ecoute"]!.contains("Qui fait ce bruit ?"))
        XCTAssertTrue(fr["ecoute"]!.contains("Oui ! C'est la vache !"))
        XCTAssertTrue(fr["ecoute"]!.contains("Ça, c'est le chat."))
        XCTAssertTrue(fr["ecoute"]!.contains("Où est la pêche ?"))
        XCTAssertTrue(fr["phrases_questions"]!.contains("Qui ?"))
        XCTAssertTrue(fr["phrases_questions"]!.contains("Que fait le chat ?"))
        XCTAssertTrue(fr["phrases_questions"]!.contains("Le chat mange quoi ?"))
        XCTAssertTrue(fr["phrases_questions"]!.contains("Le chat dort où ?"))
        XCTAssertTrue(fr["phrases_morceaux"]!.contains("le chat"))
        XCTAssertTrue(fr["phrases_morceaux"]!.contains("mange"))
        XCTAssertTrue(fr["phrases_morceaux"]!.contains("dans la boîte"))
        XCTAssertTrue(fr["livres"]!.contains("Écoute !"))
        XCTAssertTrue(fr["livres"]!.contains("À toi !"))
        let en = VoiceInventory.all(locale: "en-US")
        XCTAssertTrue(en["phrases_questions"]!.contains("What does the cat do?"))
        XCTAssertTrue(en["coloriage"]!.contains("Yellow!"))
        for locale in VoiceInventory.locales {
            for (activity, texts) in VoiceInventory.all(locale: locale) {
                XCTAssertEqual(Set(texts).count, texts.count, "\(locale) \(activity) : doublon")
                XCTAssertFalse(texts.contains(""), "\(locale) \(activity) : texte vide")
            }
            // Chaque phrase d'un livre est dans l'inventaire, entière.
            let books = Set(VoiceInventory.all(locale: locale)["livres"]!)
            for book in SoundBooks.books(locale: locale) {
                for s in book.sentences { XCTAssertTrue(books.contains(s.text), s.text) }
            }
        }
    }

    /// Chaque texte de l'inventaire a son fichier de voix préparée (débit « phrase »), sauf les exceptions.
    func testEveryActivityLineHasItsPreparedVoice() {
        let known = Set(VoiceInventory.locales.flatMap { locale in
            VoiceInventory.all(locale: locale).values.joined().map { "\(locale)|\($0)" }
        })
        for (key, reason) in VoiceInventory.exceptions {
            XCTAssertTrue(known.contains(key), "exception hors inventaire : \(key)")
            XCTAssertFalse(reason.isEmpty, "exception sans raison : \(key)")
        }
        for locale in VoiceInventory.locales {
            var missing: [String] = []
            var total = 0
            for (activity, texts) in VoiceInventory.all(locale: locale).sorted(by: { $0.key < $1.key }) {
                for text in texts {
                    total += 1
                    let found = VoiceClips.url(locale: locale, pace: "sentence", text: text, ipa: nil) != nil
                    let excused = VoiceInventory.exceptions["\(locale)|\(text)"] != nil
                    if !found && !excused { missing.append("\(activity) « \(text) »") }
                    if found && excused { XCTFail("\(locale) « \(text) » a son fichier : retirer l'exception") }
                }
            }
            XCTAssertTrue(missing.isEmpty, "\(locale) : \(missing.count)/\(total) sans fichier, p. ex. \(missing.prefix(8))")
        }
    }

    /// La phrase libre (≈ 10 400 par langue) n'est pas rendue : elle se compose des fichiers de ses wagons.
    /// Toutes, à tous les niveaux, sauf celles qui contiennent un wagon en exception (voix de l'iPad, entière).
    func testEveryFreeSentenceIsComposedFromItsWagons() {
        for locale in VoiceInventory.locales {
            var count = 0, composed = 0
            for level in PhraseLevels.levels {
                for cards in VoiceInventory.freeSentences(level: level) {
                    count += 1
                    let parts = PhraseGrammar.sentenceParts(cards, locale: locale)
                    switch ModelVoicePlayer.plan(parts: parts, locale: locale,
                                                 whole: PhraseGrammar.sentence(cards, locale: locale), prepared: true) {
                    case .clip, .joined:
                        composed += 1
                    case .system:
                        let excused = parts.contains { VoiceInventory.exceptions["\(locale)|\($0)"] != nil }
                        XCTAssertTrue(excused, "\(locale) « \(PhraseGrammar.sentence(cards, locale: locale)) »")
                    }
                }
            }
            XCTAssertGreaterThan(count, 10_000, locale)
            XCTAssertGreaterThan(Double(composed) / Double(count), 0.9, "\(locale) : \(composed)/\(count)")
        }
    }

    /// Une seule voix par phrase : entière, sinon morceaux préparés, sinon tout par la voix de l'iPad.
    func testOneVoicePerSentence() {
        let parts = ["le chat", "mange", "la pêche"]
        XCTAssertEqual(ModelVoicePlayer.plan(parts: parts, locale: "fr-FR", whole: "Le chat mange la pêche.",
                                             prepared: false), .system("Le chat mange la pêche."))
        if case .system = ModelVoicePlayer.plan(parts: parts, locale: "fr-FR", whole: "Le chat mange la pêche.",
                                                prepared: true) {
            XCTFail("les trois wagons ont leur fichier : la phrase se compose")
        }
        // Un morceau sans fichier : toute la phrase par la voix de l'iPad (jamais deux voix).
        XCTAssertEqual(ModelVoicePlayer.plan(parts: ["le chat", "xyzzy"], locale: "fr-FR", prepared: true),
                       .system("le chat xyzzy"))
        // Une consigne en deux morceaux préparés : enchaînés.
        let intro = ColoringVoice.intro(locale: "fr-FR")
        if case let .joined(urls) = ModelVoicePlayer.plan(parts: [intro, "Colorie le soleil en jaune !"],
                                                           locale: "fr-FR", prepared: true) {
            XCTAssertEqual(urls.count, 2)
        } else {
            XCTFail("intro + consigne : deux fichiers enchaînés")
        }
    }

    /// L'enchaînement coupe le silence autour de chaque morceau et pose une pause courte.
    func testTheJoinerTrimsSilenceAndAddsAShortPause() {
        let rate = 24_000.0
        func clip(silenceBefore: Double, voice: Double, silenceAfter: Double) -> [Float] {
            [Float](repeating: 0, count: Int(rate * silenceBefore))
                + (0..<Int(rate * voice)).map { Float(0.5 * sin(Double($0) * 2 * .pi * 220 / rate)) }
                + [Float](repeating: 0, count: Int(rate * silenceAfter))
        }
        let a = clip(silenceBefore: 0.3, voice: 0.5, silenceAfter: 0.4)
        let range = ClipJoiner.voicedRange(a, rate: rate)
        XCTAssertEqual(Double(range.lowerBound) / rate, 0.3 - ClipJoiner.lead, accuracy: 0.011)
        XCTAssertEqual(Double(range.upperBound) / rate, 0.8 + ClipJoiner.tail, accuracy: 0.011)
        let joined = ClipJoiner.join([a, a], rate: rate)
        let expected = 2 * (0.5 + ClipJoiner.lead + ClipJoiner.tail) + ClipJoiner.gap
        XCTAssertEqual(Double(joined.count) / rate, expected, accuracy: 0.03)
        XCTAssertEqual(joined.first ?? 1, 0, accuracy: 1e-6)                     // pas de clic
        let wav = ClipJoiner.wav(joined, rate: 24_000)
        XCTAssertEqual(String(decoding: wav.prefix(4), as: UTF8.self), "RIFF")
        XCTAssertEqual(wav.count, 44 + joined.count * 2)
    }
}
