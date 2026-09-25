// WordDeck.swift — quels mots, dans quel ordre, séance après séance.
//
// Premier essai sur iPad (25/09/2026) : « plus de mots pour le train ». Avant,
// chaque séance repartait du premier mot et ne proposait que le niveau 1 : on
// revoyait toujours les six mêmes. Désormais :
// - tous les niveaux jusqu'au niveau choisi par l'adulte (espace des grands) ;
// - un ordre FIXE qui mêle les niveaux (deux faciles, un plus long…), sans tirage
//   au hasard (docs/EVEIL.md § 4.6) ;
// - un curseur mémorisé : la séance suivante reprend où l'autre s'est arrêtée.

import Foundation
import WordEndCore

public enum WordDeck {
    /// Clé du curseur (position dans la liste ordonnée) et du niveau maximal.
    public static let cursorKey = "eveil.deckCursor"
    public static let maxLevelKey = "eveil.maxLevel"

    /// Motif de mélange des niveaux : 1, 1, 2, 1, 3, 2, puis on recommence.
    static let pattern = [1, 1, 2, 1, 3, 2]

    /// Tous les mots jusqu'à `maxLevel`, niveaux entremêlés selon `pattern`, chaque
    /// mot une seule fois ; ordre déterministe (celui du lexique à niveau égal).
    public static func ordered(_ words: [TargetWord], maxLevel: Int) -> [TargetWord] {
        var queues: [Int: [TargetWord]] = [:]
        for word in words where (word.level ?? 1) <= maxLevel {
            queues[word.level ?? 1, default: []].append(word)
        }
        var out: [TargetWord] = []
        var step = 0
        while queues.values.contains(where: { !$0.isEmpty }) {
            let wanted = pattern[step % pattern.count]
            step += 1
            // Le niveau voulu s'il reste des mots, sinon le plus proche qui en a encore.
            let level = queues.keys.sorted { abs($0 - wanted) < abs($1 - wanted) || (abs($0 - wanted) == abs($1 - wanted) && $0 < $1) }
                .first { !(queues[$0]?.isEmpty ?? true) }
            guard let level else { break }
            out.append(queues[level]!.removeFirst())
        }
        return out
    }
}

/// Les lexiques livrés dans l'app (`fr-FR.json`, `en-US.json` du paquet de l'app).
public enum BundledLexicon {
    public static func load(_ locale: String, bundle: Bundle = .main) -> Lexicon? {
        guard let url = bundle.url(forResource: locale, withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? Lexicon.decode(data)
    }

    /// Les mots d'une langue ; à défaut de lexique (aperçus, tests), « douche ».
    public static func words(locale: String, bundle: Bundle = .main) -> [TargetWord] {
        if let words = load(locale, bundle: bundle)?.words, !words.isEmpty { return words }
        let fallback = try? customWord(text: locale.hasPrefix("fr") ? "douche" : "fish",
                                       wagons: [locale.hasPrefix("fr") ? "dou" : "fi"], coda: "S", locale: locale)
        return fallback.map { [$0] } ?? []
    }
}
