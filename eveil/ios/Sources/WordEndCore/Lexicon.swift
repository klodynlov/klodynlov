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

public struct Lexicon: Codable, Equatable, Sendable {
    public var schema: String
    public var locale: String
    public var status: String
    public var clinicalTarget: String?
    public var principles: [String]?
    public var cabooseSounds: [String: CabooseSound]
    public var words: [TargetWord]

    public static let supportedCodas: Set<String> = ["S", "s"]   // v0 : /ʃ/ et /s/
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
    let label = caboose ?? coda.map { $0 == "S" ? (locale.hasPrefix("fr") ? "ch" : "sh") : "s" }
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
