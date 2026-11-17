// PhraseCore.swift — le train des phrases : lexique, grammaire, niveaux (Swift pur).
//
// Demande de l'utilisateur (28/09/2026) : une app « au niveau d'OrthoPicto, voire plus ».
// L'enfant construit une phrase simple avec des pictos — la locomotive porte « qui ? »,
// un wagon par morceau : « fait quoi ? », « quoi ? », « où ? » — puis la scène joue la
// phrase construite, n'importe laquelle (« la vache nage dans la baignoire » : on rit,
// on ne se trompe jamais).
//
// Portage LIGNE À LIGNE de la référence Python `eveil/outils/phrases` (grammaire.py,
// niveaux.py) ; le lexique est généré depuis `lexique.py` (`PhraseLexiconData.swift`) et
// les tests recalculent les phrases et les plateaux de `phrases-golden.json`.
// Aucune dépendance (Foundation seulement) : testable partout.

import Foundation

public enum PhraseRole: String, CaseIterable, Sendable {
    case qui, verbe, quoi, ou
}

public enum PhraseGender: String, Sendable {
    case masculine, feminine, plural, proper
}

/// Un nom : qui ? (sujet), quoi ? (complément), où ? (lieu).
public struct PhraseNoun: Identifiable, Hashable, Sendable {
    public let id: String
    /// Le picto : un mot du petit train (« fr.vache ») ou un dessin des pictos (« lieu.niche »).
    public let drawing: String
    public let gender: PhraseGender
    public let fr: String
    public let frIPA: String
    public let en: String
    public let enIPA: String
    public let roles: Set<PhraseRole>
    /// Le dessin regarde vers la gauche : la scène le retourne pour qu'il regarde l'objet.
    public let facesLeft: Bool
    /// Lieux : les prépositions dessinées (ancres du picto).
    public let prepositions: [String]
}

public struct PhraseVerb: Identifiable, Hashable, Sendable {
    public let id: String
    public let fr: String
    public let frIPA: String
    public let en: String
    public let enIPA: String
    public let transitive: Bool
    /// Aussi sans complément au niveau 1 (« Le chat mange. »).
    public let absolute: Bool
    /// Compléments naturels (niveau 2), dans l'ordre du plateau.
    public let objects: [String]
    /// Niveau 3 : prépositions naturelles avec ce verbe.
    public let prepositions: [String]
    /// Niveau 3 : lieux permis (vide = tous ceux qui ont la préposition).
    public let places: [String]

    /// L'identifiant de son picto.
    public var drawing: String { "verbe.\(id)" }
}

/// Un picto du plateau : un rôle, un identifiant, une préposition (« où ? » seulement).
public struct PhraseCard: Hashable, Identifiable, Sendable {
    public let role: PhraseRole
    public let key: String
    public let preposition: String

    public init(_ role: PhraseRole, _ key: String, preposition: String = "") {
        self.role = role
        self.key = key
        self.preposition = preposition
    }

    public var id: String { "\(role.rawValue):\(key):\(preposition)" }
}

public enum PhraseLexicon {
    public static let prepositions = ["dans", "sur", "sous", "devant", "derriere"]
    static let prepositionFR = ["dans": "dans", "sur": "sur", "sous": "sous", "devant": "devant", "derriere": "derrière"]
    static let prepositionEN = ["dans": "in", "sur": "on", "sous": "under", "devant": "in front of", "derriere": "behind"]

    public static func noun(_ id: String) -> PhraseNoun? { nouns.first { $0.id == id } }
    public static func verb(_ id: String) -> PhraseVerb? { verbs.first { $0.id == id } }
    public static func nouns(_ role: PhraseRole) -> [PhraseNoun] { nouns.filter { $0.roles.contains(role) } }

    /// Le picto d'une carte (pour le verbe : « verbe.manger » ; pour un lieu : le lieu).
    public static func drawing(of card: PhraseCard) -> String {
        card.role == .verbe ? "verbe.\(card.key)" : (noun(card.key)?.drawing ?? card.key)
    }
}

// MARK: - Grammaire (miroir de grammaire.py)

public enum PhraseGrammar {
    /// Voyelles (et h muet : aucun mot du lexique à h aspiré) : « l'autruche », « l'os ».
    static let vowels: Set<Character> = Set("aàâeéèêëiîïoôuûüyœh")

    static func french(_ locale: String) -> Bool { locale.hasPrefix("fr") }

    /// « le chat », « la vache », « l'autruche », « les ciseaux », « Lou » ; « the cat », « Lou ».
    public static func nounPhrase(_ n: PhraseNoun, locale: String) -> String {
        if french(locale) {
            if n.gender == .proper { return n.fr }
            if n.gender == .plural { return "les " + n.fr }
            if let first = n.fr.lowercased().first, vowels.contains(first) { return "l'" + n.fr }
            return (n.gender == .masculine ? "le " : "la ") + n.fr
        }
        return n.gender == .proper ? n.en : "the " + n.en
    }

    /// Le texte d'un wagon.
    public static func chunk(_ card: PhraseCard, locale: String) -> String {
        if card.role == .verbe {
            guard let v = PhraseLexicon.verb(card.key) else { return card.key }
            return french(locale) ? v.fr : v.en
        }
        guard let n = PhraseLexicon.noun(card.key) else { return card.key }
        let np = nounPhrase(n, locale: locale)
        if card.role == .ou {
            let table = french(locale) ? PhraseLexicon.prepositionFR : PhraseLexicon.prepositionEN
            return "\(table[card.preposition] ?? card.preposition) \(np)"
        }
        return np
    }

    /// Toutes les cartes d'un wagon à ce niveau, après les cartes `before` (le « quoi ? » et le « où ? »
    /// dépendent du verbe), dans l'ordre du plateau.
    public static func allCards(_ role: PhraseRole, level: Int, after before: [PhraseCard]) -> [PhraseCard] {
        let verb = before.last { $0.role == .verbe }?.key ?? ""
        return PhraseLevels.tray(role, level: level, verb: verb, size: Int.max)
    }

    /// Le texte de tous les wagons possibles dans cette langue (chacun a son fichier de voix préparée : la
    /// phrase libre se dit en les enchaînant, `ModelVoicePlayer.speak(parts:)`).
    public static func voiceChunks(locale: String) -> [String] {
        var out: [String] = []
        for level in PhraseLevels.levels {
            let roles = PhraseLevels.roles(level: level)
            let subjects = allCards(.qui, level: level, after: [])
            let verbs = allCards(.verbe, level: level, after: [])
            out += subjects.map { chunk($0, locale: locale) } + verbs.map { chunk($0, locale: locale) }
            for role in roles.dropFirst(2) {
                for v in verbs { out += allCards(role, level: level, after: [v]).map { chunk($0, locale: locale) } }
            }
        }
        var seen = Set<String>()
        return out.filter { seen.insert($0).inserted }
    }

    /// Les morceaux de la phrase, tels que la voix les enchaîne : le texte de chaque wagon (même clé que
    /// quand le wagon se dit seul).
    public static func sentenceParts(_ cards: [PhraseCard], locale: String) -> [String] {
        cards.map { chunk($0, locale: locale) }
    }

    /// La phrase entière : majuscule au début, point à la fin.
    public static func sentence(_ cards: [PhraseCard], locale: String) -> String {
        let text = cards.map { chunk($0, locale: locale) }.joined(separator: " ")
        guard let first = text.first else { return "." }
        return first.uppercased() + text.dropFirst() + "."
    }
}

// MARK: - Niveaux et plateau (miroir de niveaux.py)

public enum PhraseLevels {
    public static let levels = [1, 2, 3]
    public static let traySize = 6

    /// Les wagons d'un niveau : 1 = qui + fait quoi ; 2 = + quoi ; 3 = + où.
    public static func roles(level: Int) -> [PhraseRole] {
        switch level {
        case 1: return [.qui, .verbe]
        case 2: return [.qui, .verbe, .quoi]
        default: return [.qui, .verbe, .ou]
        }
    }

    public static func verbs(level: Int) -> [PhraseVerb] {
        switch level {
        case 1: return PhraseLexicon.verbs.filter { !$0.transitive || $0.absolute }
        case 2: return PhraseLexicon.verbs.filter { $0.transitive }
        default: return PhraseLexicon.verbs.filter { !$0.transitive && !placeCards(verb: $0.id).isEmpty }
        }
    }

    /// Les cartes « où ? » d'un verbe, lieu après lieu (tous différents d'abord).
    public static func placeCards(verb verbID: String) -> [PhraseCard] {
        guard let v = PhraseLexicon.verb(verbID) else { return [] }
        let places = PhraseLexicon.nouns(.ou).filter { v.places.isEmpty || v.places.contains($0.id) }
        let byPlace = places.map { n in
            v.prepositions.filter { n.prepositions.contains($0) }.map { PhraseCard(.ou, n.id, preposition: $0) }
        }
        var out: [PhraseCard] = []
        var k = 0
        while byPlace.contains(where: { k < $0.count }) && k <= 8 {
            for group in byPlace where k < group.count { out.append(group[k]) }
            k += 1
        }
        return out
    }

    static func rotated(_ cards: [PhraseCard], by shift: Int, size: Int) -> [PhraseCard] {
        guard !cards.isEmpty else { return [] }
        let d = ((shift % cards.count) + cards.count) % cards.count
        return Array((Array(cards[d...]) + Array(cards[..<d])).prefix(size))
    }

    /// Les pictos proposés pour un wagon, au tour `round` (une phrase après l'autre : le
    /// plateau tourne dans un ordre fixe, rien n'est tiré au hasard — docs/EVEIL.md § 4.6).
    public static func tray(_ role: PhraseRole, level: Int, round: Int = 0, verb: String = "",
                            size: Int = PhraseLevels.traySize) -> [PhraseCard] {
        switch role {
        case .qui:
            return rotated(PhraseLexicon.nouns(.qui).map { PhraseCard(.qui, $0.id) }, by: 3 * round, size: size)
        case .verbe:
            return rotated(verbs(level: level).map { PhraseCard(.verbe, $0.id) }, by: 2 * round, size: size)
        case .quoi:
            let objects = PhraseLexicon.verb(verb)?.objects ?? []
            return rotated(objects.map { PhraseCard(.quoi, $0) }, by: round, size: size)
        case .ou:
            return rotated(placeCards(verb: verb), by: 2 * round, size: size)
        }
    }
}

// MARK: - Les questions du train (la voix demande ce qui manque)

public enum PhrasePrompts {
    /// La question pour le wagon à remplir, construite avec ce qui est déjà choisi :
    /// « Qui ? », « Que fait le chat ? », « Le chat mange quoi ? », « Le chat dort où ? ».
    public static func question(for role: PhraseRole, cards: [PhraseCard], locale: String) -> String {
        let fr = locale.hasPrefix("fr")
        let subject = cards.first { $0.role == .qui }.flatMap { PhraseLexicon.noun($0.key) }
        let soFar = cards.map { PhraseGrammar.chunk($0, locale: locale) }.joined(separator: " ")
        let start = soFar.isEmpty ? "" : soFar.prefix(1).uppercased() + soFar.dropFirst()
        switch role {
        case .qui:
            return fr ? "Qui ?" : "Who?"
        case .verbe:
            guard let subject else { return fr ? "Fait quoi ?" : "Does what?" }
            let np = PhraseGrammar.nounPhrase(subject, locale: locale)
            return fr ? "Que fait \(np) ?" : "What does \(np) do?"
        case .quoi:
            return start.isEmpty ? (fr ? "Quoi ?" : "What?") : (fr ? "\(start) quoi ?" : "\(start) what?")
        case .ou:
            return start.isEmpty ? (fr ? "Où ?" : "Where?") : (fr ? "\(start) où ?" : "\(start) where?")
        }
    }

    /// Toutes les questions que la voix du train des phrases peut poser dans cette langue, niveau par
    /// niveau, avec tout ce qui peut déjà être accroché devant (« Qui ? », « Que fait le chat ? », « Le chat
    /// mange quoi ? », « Le chat dort où ? »). Voix préparée (17/11/2026) : `eveil/outils/voix/generer.py`
    /// lit l'inventaire écrit par les tests de l'app, sans recopier ces règles.
    public static func voiceLines(locale: String) -> [String] {
        var out: [String] = []
        for level in PhraseLevels.levels {
            let roles = PhraseLevels.roles(level: level)
            var prefixes: [[PhraseCard]] = [[]]
            for (k, role) in roles.enumerated() {
                out += prefixes.map { question(for: role, cards: $0, locale: locale) }
                guard k + 1 < roles.count else { break }
                prefixes = prefixes.flatMap { p in
                    PhraseGrammar.allCards(role, level: level, after: p).map { p + [$0] }
                }
            }
        }
        var seen = Set<String>()
        return out.filter { seen.insert($0).inserted }
    }

    /// L'étiquette d'un wagon vide.
    public static func label(for role: PhraseRole, locale: String) -> String {
        let fr = locale.hasPrefix("fr")
        switch role {
        case .qui: return fr ? "Qui ?" : "Who?"
        case .verbe: return fr ? "Fait quoi ?" : "Does what?"
        case .quoi: return fr ? "Quoi ?" : "What?"
        case .ou: return fr ? "Où ?" : "Where?"
        }
    }
}
