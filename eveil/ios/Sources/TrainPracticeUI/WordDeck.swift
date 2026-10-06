// WordDeck.swift — quels mots, dans quel ordre, séance après séance.
//
// Premier essai sur iPad (25/09/2026) : « plus de mots pour le train » → un ordre FIXE
// (sans tirage au hasard, docs/EVEIL.md § 4.6) et un curseur mémorisé : la séance suivante
// reprend où l'autre s'est arrêtée.
//
// Progression « quand il réussit » (conseil d'une orthophoniste, d'après la méthode de
// Borel-Maisonny : les mots d'une syllabe d'abord, puis deux, et ainsi de suite ; décision de
// l'utilisateur, 06/10/2026) — miroir de `reference/wordend/policy.py` (règle 8) :
// - l'enfant commence au niveau 1 (une syllabe) ; la séance ne propose QUE les mots du niveau ;
// - quand il a dit 6 mots différents du niveau en entier (verdict complet, fourgon accroché),
//   ou tous s'il y en a moins, le niveau suivant s'ouvre à la séance SUIVANTE : 2 syllabes,
//   puis groupes de consonnes, puis tous les mots mêlés (motif 1, 1, 2, 1, 3, 2) ;
// - le niveau ne redescend jamais tout seul ; l'adulte le règle (espace des grands), et le
//   compte repart de zéro ; rien n'est compté en démo ni en « Essai par un adulte » ;
// - aucun nombre n'est affiché : ce n'est pas un score.

import Foundation
import WordEndCore

public enum WordDeck {
    /// Clé du curseur des livres et des listes sans niveau (le petit train : `cursorKey(level:)`).
    public static let cursorKey = "eveil.deckCursor"
    /// Un curseur par niveau : revenir au niveau 1 reprend où on l'avait laissé.
    public static func cursorKey(level: Int) -> String { "eveil.deckCursor.level\(level)" }

    /// 1 syllabe · 2 syllabes · groupes de consonnes · tous mêlés.
    public static let levels = 1...4
    public static let mixedLevel = 4
    public static let unlockWords = 6
    /// Niveau 4 : deux faciles, un plus long…
    static let pattern = [1, 1, 2, 1, 3, 2]

    public static func clamp(_ level: Int) -> Int { min(levels.upperBound, max(levels.lowerBound, level)) }

    static func level(of word: TargetWord) -> Int { max(1, word.level ?? 1) }

    /// Les mots d'un niveau (niveau 4 : tous), dans l'ordre du lexique.
    public static func levelWords(_ words: [TargetWord], level: Int) -> [TargetWord] {
        level >= mixedLevel ? words : words.filter { Self.level(of: $0) == level }
    }

    /// Tous les mots, niveaux entremêlés selon `pattern`, chaque mot une seule fois ; ordre
    /// déterministe (celui du lexique à niveau égal). Le niveau voulu s'il reste des mots,
    /// sinon le plus proche qui en a encore (à égalité, le plus facile).
    public static func mixed(_ words: [TargetWord]) -> [TargetWord] {
        var queues: [Int: [TargetWord]] = [:]
        for word in words { queues[level(of: word), default: []].append(word) }
        var out: [TargetWord] = []
        var step = 0
        while queues.values.contains(where: { !$0.isEmpty }) {
            let wanted = pattern[step % pattern.count]
            step += 1
            let level = queues.keys.filter { !(queues[$0]?.isEmpty ?? true) }
                .min { (abs($0 - wanted), $0) < (abs($1 - wanted), $1) }
            guard let level else { break }
            out.append(queues[level]!.removeFirst())
        }
        return out
    }

    /// Les mots d'une séance : ceux du niveau, dans l'ordre du lexique ; au niveau 4 (ou si le
    /// niveau n'a aucun mot), tous les mots mêlés.
    public static func deck(_ words: [TargetWord], level: Int) -> [TargetWord] {
        let level = clamp(level)
        let own = level < mixedLevel ? levelWords(words, level: level) : []
        return own.isEmpty ? mixed(words) : own
    }

    /// Combien de mots différents dire en entier pour ouvrir le niveau suivant.
    public static func unlockTarget(_ words: [TargetWord], level: Int) -> Int {
        min(unlockWords, levelWords(words, level: level).count)
    }

    /// Le niveau qui suit `level` et qui a des mots (le niveau 4 en a toujours).
    public static func nextLevel(_ words: [TargetWord], after level: Int) -> Int {
        levels.first { $0 > level && ($0 == mixedLevel || !levelWords(words, level: $0).isEmpty) } ?? mixedLevel
    }
}

/// Où en est l'enfant : son niveau, et les mots de ce niveau déjà dits en entier.
/// Le niveau ne change qu'en début de séance (`startSession`) ou par l'adulte (`setByAdult`) ;
/// à chaque changement, le compte repart de zéro.
public struct LevelProgress: Equatable, Sendable {
    public private(set) var level: Int
    public private(set) var said: Set<String>

    public init(level: Int = 1, said: Set<String> = []) {
        self.level = WordDeck.clamp(level)
        self.said = said
    }

    /// Un essai au petit train. Seul un verdict COMPLET d'un mot du niveau compte, et jamais en
    /// démo ni en « Essai par un adulte » (`counted: false`).
    public mutating func record(_ word: TargetWord, kind: VerdictKind, counted: Bool = true) {
        guard counted, kind == .complete, level < WordDeck.mixedLevel, WordDeck.level(of: word) == level else { return }
        said.insert(word.id)
    }

    /// Le niveau suivant s'ouvrira à la prochaine séance.
    public func ready(_ words: [TargetWord]) -> Bool {
        guard level < WordDeck.mixedLevel else { return false }
        let own = Set(WordDeck.levelWords(words, level: level).map(\.id))
        let target = WordDeck.unlockTarget(words, level: level)
        return target > 0 && said.intersection(own).count >= target
    }

    /// Début de séance : ouvre le niveau suivant s'il est gagné. Rend le niveau à jouer.
    @discardableResult
    public mutating func startSession(_ words: [TargetWord]) -> Int {
        if ready(words) {
            level = WordDeck.nextLevel(words, after: level)
            said = []
        }
        return level
    }

    /// L'adulte choisit le niveau (espace des grands) : le compte repart de zéro.
    public mutating func setByAdult(_ level: Int) {
        self.level = WordDeck.clamp(level)
        said = []
    }
}

/// La progression, gardée sur l'iPad (une par langue : les mots ne sont pas les mêmes).
public enum TrainLevelStore {
    static func levelKey(_ locale: String) -> String { "eveil.trainLevel.\(locale)" }
    static func saidKey(_ locale: String) -> String { "eveil.trainLevelSaid.\(locale)" }

    public static func load(locale: String, defaults: UserDefaults = .standard) -> LevelProgress {
        let level = defaults.object(forKey: levelKey(locale)) == nil ? 1 : defaults.integer(forKey: levelKey(locale))
        return LevelProgress(level: level, said: Set(defaults.stringArray(forKey: saidKey(locale)) ?? []))
    }

    public static func save(_ progress: LevelProgress, locale: String, defaults: UserDefaults = .standard) {
        defaults.set(progress.level, forKey: levelKey(locale))
        defaults.set(progress.said.sorted(), forKey: saidKey(locale))
    }

    /// Un mot dit en entier au petit train (l'appelant écarte la démo et l'essai par un adulte).
    public static func recordSaid(_ word: TargetWord, locale: String, defaults: UserDefaults = .standard) {
        var p = load(locale: locale, defaults: defaults)
        p.record(word, kind: .complete)
        save(p, locale: locale, defaults: defaults)
    }

    /// Début de séance : le niveau à jouer (le suivant s'il a été gagné).
    public static func startSession(_ words: [TargetWord], locale: String, defaults: UserDefaults = .standard) -> Int {
        var p = load(locale: locale, defaults: defaults)
        let level = p.startSession(words)
        save(p, locale: locale, defaults: defaults)
        return level
    }

    public static func setByAdult(_ level: Int, locale: String, defaults: UserDefaults = .standard) {
        var p = load(locale: locale, defaults: defaults)
        p.setByAdult(level)
        save(p, locale: locale, defaults: defaults)
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
