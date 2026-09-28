// SoundBooks.swift — les livres des sons : un livre par son (le modèle ; données générées).
//
// Demande de l'utilisateur (28/09/2026) : « au niveau d'OrthoPicto, voire plus ». OrthoPicto
// propose un livre par son ; ici chaque livre est CALCULÉ (eveil/outils/livres) à partir des
// mots dessinés qui contiennent le son — au début, au milieu, à la fin — avec le wagon où il
// est et les lettres qui l'écrivent, une image sonore et une idée de jeu pour l'adulte.
// Les données sont dans `SoundBooksData.swift` (généré).

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

    public var id: String { "\(locale).\(sound)" }
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
