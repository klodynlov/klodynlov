// Lexicon.swift — lexiques cibles (FR/EN) et mots personnels de la famille.
// Portage de `eveil/reference/wordend/lexicon.py`. Les fichiers JSON
// (`eveil/lexique/*.json`) sont la source unique, partagée avec Python.

import Foundation

public struct Contrast: Codable, Equatable, Sendable {
    public var text: String
    public var ipa: String
    public var picturable: Bool
}

public struct CabooseSound: Codable, Equatable, Sendable {
    public var label: String
    public var icon: String
    public var cue: String
}

/// Un mot cible : ce que l'enfant VOIT (wagons = syllabes orales, fourgon =
/// consonne finale) et ce que le détecteur ATTEND (noyaux, consonne finale).
public struct TargetWord: Codable, Equatable, Sendable, Identifiable, TargetShape {
    public var id: String
    public var text: String
    public var ipa: String?
    public var level: Int?
    public var wagons: [String]
    public var caboose: String?
    public var nuclei: Int
    public var coda: String?
    public var contrast: Contrast?
    public var notes: String?
    public var custom: Bool?
}

/// Ce que la voix modèle dit pour UN wagon : le texte (repli) et sa prononciation (API).
public struct VoiceSegment: Equatable, Sendable {
    public var text: String
    public var ipa: String?

    public init(text: String, ipa: String?) {
        self.text = text
        self.ipa = ipa
    }
}

/// Les syllabes d'une transcription (« ka.niʃ » → ["ka", "niʃ"]), accents retirés.
public func ipaSyllables(_ ipa: String) -> [String] {
    let clean = ipa.filter { $0 != "ˈ" && $0 != "ˌ" }
    return clean.split(separator: ".").map(String.init).filter { !$0.isEmpty }
}

public extension TargetWord {
    /// Le mot modèle, wagon par wagon : « mi · nou(ch) » (miroir de `voice_segments`).
    ///
    /// Demande de l'utilisateur (28/09/2026) : une voix « qui suit les syllabes ». Chaque
    /// wagon s'allume pendant que la voix dit SA syllabe ; la dernière garde la consonne
    /// finale (« nuʃ ») : la voix finit le mot, le fourgon s'accroche à la fin. La
    /// prononciation vient de l'API ; sans API (mots de la famille), la voix lit les
    /// wagons écrits, sans consonne finale.
    var voiceSegments: [VoiceSegment] {
        let syllables = ipa.map(ipaSyllables) ?? []
        guard syllables.count == wagons.count else {
            return wagons.map { VoiceSegment(text: $0, ipa: nil) }
        }
        var out = zip(wagons, syllables).map { VoiceSegment(text: $0.0, ipa: $0.1) }
        if let caboose, !out.isEmpty {
            out[out.count - 1].text += caboose
        }
        return out
    }
}

public extension TargetWord {
    /// Chaque wagon SEUL, pour l'entendre quand l'enfant le touche (28/09/2026) : la
    /// dernière syllabe sans la consonne finale — elle est dans le fourgon (miroir de
    /// `wagon_segments`).
    var wagonSegments: [VoiceSegment] {
        let syllables = ipa.map(ipaSyllables) ?? []
        guard syllables.count == wagons.count else {
            return wagons.map { VoiceSegment(text: $0, ipa: nil) }
        }
        var out = zip(wagons, syllables).map { VoiceSegment(text: $0.0, ipa: $0.1) }
        if let coda, let sound = Lexicon.codaIPA[coda], let last = out.last?.ipa, last.hasSuffix(sound) {
            out[out.count - 1].ipa = String(last.dropLast(sound.count))
        }
        return out
    }

    /// Le fourgon seul : sa consonne (« ch » → /ʃ/, « sse » → /s/).
    var cabooseSegment: VoiceSegment? {
        guard let coda, let caboose, let sound = Lexicon.codaIPA[coda] else { return nil }
        return VoiceSegment(text: caboose, ipa: sound)
    }
}

public extension TargetWord {
    /// Un mot des livres des sons (28/09/2026) : ses wagons sont ses syllabes orales écrites, sans
    /// fourgon (le son travaillé peut être au début, au milieu ou à la fin). `id` = son dessin.
    static func bookWord(id: String, text: String, ipa: String?, wagons: [String]) -> TargetWord {
        TargetWord(id: id, text: text, ipa: ipa, level: 1, wagons: wagons, caboose: nil, nuclei: wagons.count,
                   coda: nil, contrast: nil, notes: nil, custom: nil)
    }
}

public struct Lexicon: Codable, Equatable, Sendable {
    public var schema: String
    public var locale: String
    public var status: String
    public var clinicalTarget: String?
    public var principles: [String]?
    public var cabooseSounds: [String: CabooseSound]
    public var words: [TargetWord]

    public static let supportedCodas: Set<String> = ["S", "s"]   // v0 : /ʃ/ et /s/
    /// La consonne que porte le fourgon, en API.
    public static let codaIPA: [String: String] = ["S": "ʃ", "s": "s"]
    public static let maxWagons = 4

    /// Décode un lexique (clés JSON en snake_case).
    public static func decode(_ data: Data) throws -> Lexicon {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(Lexicon.self, from: data)
    }

    public func word(id: String) -> TargetWord? { words.first { $0.id == id } }

    /// Contrôles de cohérence (vide = lexique sain).
    public func problems() -> [String] {
        var out: [String] = []
        var seen = Set<String>()
        let prefix = (locale.split(separator: "-").first.map(String.init) ?? locale) + "."
        for w in words {
            if !seen.insert(w.id).inserted { out.append("\(w.id): identifiant dupliqué") }
            if !w.id.hasPrefix(prefix) { out.append("\(w.id): préfixe attendu \(prefix)") }
            if !(1...Lexicon.maxWagons).contains(w.wagons.count) { out.append("\(w.id): nombre de wagons") }
            if w.wagons.count != w.nuclei { out.append("\(w.id): wagons ≠ noyaux") }
            if let c = w.coda, !Lexicon.supportedCodas.contains(c) { out.append("\(w.id): consonne finale hors v0") }
            if (w.coda == nil) != (w.caboose == nil) { out.append("\(w.id): fourgon et consonne finale") }
            if let c = w.coda, cabooseSounds[c] == nil { out.append("\(w.id): pas de symbole sonore") }
            if let c = w.contrast, c.text == w.text { out.append("\(w.id): contraste identique") }
            if let ipa = w.ipa, !ipa.isEmpty {
                let syllables = ipaSyllables(ipa)
                if syllables.count != w.wagons.count { out.append("\(w.id): syllabes de l'API ≠ wagons") }
                if let c = w.coda, let last = syllables.last, let sound = Lexicon.codaIPA[c], !last.hasSuffix(sound) {
                    out.append("\(w.id): l'API ne finit pas par la consonne du fourgon")
                }
            }
        }
        return out
    }
}

public enum LexiconError: Error, Equatable {
    case emptyWord
    case wagonCount
    case unsupportedCoda(String)
}

/// Mot personnel saisi par le parent (prénom du chat, du doudou…). Reste sur l'appareil.
public func customWord(text: String, wagons: [String], coda: String?, locale: String,
                       caboose: String? = nil) throws -> TargetWord {
    let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
    let wagons = wagons.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    guard !text.isEmpty else { throw LexiconError.emptyWord }
    guard (1...Lexicon.maxWagons).contains(wagons.count) else { throw LexiconError.wagonCount }
    if let coda, !Lexicon.supportedCodas.contains(coda) { throw LexiconError.unsupportedCoda(coda) }
    let given = (caboose?.isEmpty == false) ? caboose : nil          // "" ⇒ son par défaut
    let label = given ?? coda.map { $0 == "S" ? (locale.hasPrefix("fr") ? "ch" : "sh") : "s" }
    var slug = text.lowercased().filter { $0.isLetter || $0.isNumber }
    if slug.isEmpty { slug = "mot" }
    let lang = locale.split(separator: "-").first.map(String.init) ?? locale
    return TargetWord(id: "\(lang).perso.\(slug)", text: text, ipa: nil, level: nil, wagons: wagons,
                      caboose: label, nuclei: wagons.count, coda: coda, contrast: nil, notes: nil,
                      custom: true)
}

// MARK: - Formes acceptées (garde-fou lexical)

/// Minuscules sans diacritiques (« Bûche » → « buche »).
public func fold(_ text: String) -> String {
    text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
        .lowercased()
}

/// Formes qui prouvent que l'enfant a bien TENTÉ ce mot (complet ou tronqué).
public func acceptedForms(_ word: TargetWord) -> Set<String> {
    var forms: Set<String> = [fold(word.text), fold(word.wagons.joined())]
    if let c = word.contrast { forms.insert(fold(c.text)) }
    return forms.filter { !$0.isEmpty }
}

/// Compare une transcription on-device aux formes acceptées du mot.
public func lexicalEvidence(transcript: String, word: TargetWord) -> LexicalEvidence {
    let folded = fold(transcript)
    let tokens = folded.split { !($0.isASCII && ($0.isLetter || $0.isNumber)) }.map(String.init)
    guard !tokens.isEmpty else { return .notChecked }
    let forms = acceptedForms(word)
    if tokens.contains(where: forms.contains) || forms.contains(tokens.joined()) { return .consistent }
    return .inconsistent
}
