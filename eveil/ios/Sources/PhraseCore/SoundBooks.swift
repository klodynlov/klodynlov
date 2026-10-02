// SoundBooks.swift — les livres des sons : un livre par son (le modèle ; données générées).
//
// Demande de l'utilisateur (28/09/2026) : « au niveau d'OrthoPicto, voire plus ». OrthoPicto
// propose un livre par son ; ici chaque livre est CALCULÉ (eveil/outils/livres) à partir des
// mots dessinés qui contiennent le son — au début, au milieu, à la fin — avec le wagon où il
// est et les lettres qui l'écrivent, une image sonore et une idée de jeu pour l'adulte.
// Les données sont dans `SoundBooksData.swift` (généré).
//
// Les PHRASES d'un livre (suite, 28/09/2026) : comme les pages d'OrthoPicto, des phrases
// illustrées que l'enfant reconstruit avec les pictos — niveau 2 « qui + fait quoi + quoi »,
// niveau 3 « qui + fait quoi + où » — choisies (eveil/outils/livres/phrases.py) pour porter le
// son, avec les lettres du son dans chaque wagon et les trois pictos à proposer par wagon.

import Foundation

public enum SoundPosition: String, Sendable {
    case start, middle, end
}

/// Un mot d'un livre : son dessin, ses wagons, le wagon du son et ses lettres.
public struct SoundBookWord: Identifiable, Hashable, Sendable {
    public let id: String
    public let drawing: String
    public let text: String
    /// API avec les points de syllabe (une syllabe par wagon).
    public let ipa: String
    public let wagons: [String]
    public let targetWagon: Int
    public let letters: String
    public let position: SoundPosition
}

/// Les lettres du son dans le texte d'un wagon : début et longueur, en caractères.
public struct SoundMark: Hashable, Sendable {
    public let start: Int
    public let length: Int

    /// La plage de ces lettres dans `text`, si elle y tient.
    public func range(in text: String) -> Range<String.Index>? {
        guard start >= 0, length > 0, start + length <= text.count else { return nil }
        let lower = text.index(text.startIndex, offsetBy: start)
        return lower..<text.index(lower, offsetBy: length)
    }
}

/// Une phrase d'un livre : niveau 2 (qui + fait quoi + quoi) ou 3 (qui + fait quoi + où).
public struct SoundBookSentence: Identifiable, Hashable, Sendable {
    public let level: Int
    public let cards: [PhraseCard]
    /// Par wagon : où colorer le son dans son texte (`nil` : il n'y est pas).
    public let marks: [SoundMark?]
    /// Par wagon : les pictos proposés, dans l'ordre d'affichage ; la bonne carte est parmi eux.
    public let choices: [[PhraseCard]]
    /// La phrase telle que la référence Python l'écrit (parité avec `PhraseGrammar`).
    public let text: String

    public var id: String { cards.map(\.id).joined(separator: " ") }
}

public struct SoundBook: Identifiable, Sendable {
    public let locale: String
    /// Le son, en API (« ʃ »).
    public let sound: String
    /// Son étiquette (« ch »).
    public let label: String
    /// L'image sonore (« Le train à vapeur : chhh ! »).
    public let image: String
    /// Une idée de jeu, hors écran, pour l'adulte.
    public let game: String
    public let words: [SoundBookWord]
    /// Les phrases du livre, niveau 2 puis niveau 3.
    public let sentences: [SoundBookSentence]

    public var id: String { "\(locale).\(sound)" }

    /// Les phrases d'un niveau (2 ou 3), dans l'ordre du livre.
    public func sentences(level: Int) -> [SoundBookSentence] { sentences.filter { $0.level == level } }
}

public enum SoundBooks {
    public static func books(locale: String) -> [SoundBook] {
        let wanted = locale.hasPrefix("fr") ? "fr-FR" : "en-US"
        return all.filter { $0.locale == wanted }
    }

    public static func book(id: String) -> SoundBook? { all.first { $0.id == id } }

    /// La phrase de couverture : « Le livre du « ch » ».
    public static func title(_ book: SoundBook) -> String {
        book.locale.hasPrefix("fr") ? "Le livre du « \(book.label) »" : "The “\(book.label)” book"
    }
}
