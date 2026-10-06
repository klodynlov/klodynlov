// Policy.swift — la pédagogie, séparée de l'acoustique. Portage de
// `eveil/reference/wordend/policy.py` et du garde-fou lexical.
//
// Règles encodées (et testées côté Python comme côté Swift) :
// 1. On ne montre du doigt le fourgon (consonne finale) que sur un verdict
//    `.missingFinalConsonant` — jamais sur `.unsure`.
// 2. Incertain / aucune parole ⇒ messages neutres, jamais « ce n'est pas ça ».
// 3. Syllabe(s) en moins ⇒ aucun wagon désigné : on ne sait pas LAQUELLE
//    manque ; on remodèle le mot entier.
// 4. Pas de boucle d'échec : après `maxAttempts`, on félicite l'effort et on passe.
// 5. Séances courtes, fin ritualisée, budget quotidien réglable par le parent.
// 6. Répétitions (28/09/2026) : l'adulte choisit combien de fois le mot est redit
//    (1 à 5, 3 par défaut) ; seul un verdict COMPLET fait avancer le décompte, et
//    la règle 4 vaut pour chaque répétition.
// 7. Étoiles (28/09/2026) : des étoiles de JEU, pas un score de langage — plus c'est
//    bien dit, plus il y en a ; on n'en perd jamais ; le doute ne coûte pas plus
//    qu'une fin manquée (asymétrie).

import Foundation

public enum CabooseState: String, Sendable {
    case hooked      // accroché : la consonne finale a été entendue
    case pointed     // resté en gare, la mascotte le montre (verdict sûr seulement)
    case waiting     // neutre : en attente
    case none        // mot sans consonne finale
}

public enum MascotAction: String, Sendable {
    case celebrate
    case pointCaboose = "point_caboose"
    case modelWord = "model_word"
    case listenAgain = "listen_again"
    case invite
}

public enum MessageKey: String, CaseIterable, Sendable {
    case bravo
    case hookCaboose = "hook_caboose"
    case modelSlowly = "model_slowly"
    case listenAgain = "listen_again"
    case invite
    case effortNext = "effort_next"
    case again          // un mot bien dit, mais le décompte n'est pas fini

    /// Clés autorisées quand le détecteur n'est PAS sûr : aucune ne désigne d'erreur.
    public static let neutral: Set<MessageKey> = [.listenAgain, .invite, .effortNext, .modelSlowly]

    /// Textes par défaut (l'app utilise un String Catalog ; ceci sert aux tests et aux aperçus).
    public func defaultText(locale: String) -> String {
        let fr: [MessageKey: String] = [
            .bravo: "Bravo ! Tout le train est parti !",
            .hookCaboose: "Oh, le petit fourgon est resté en gare ! On l'accroche avec « chhh » ?",
            .modelSlowly: "Écoute bien le train : on le dit doucement, ensemble.",
            .listenAgain: "Je n'ai pas bien entendu. On le redit ensemble ?",
            .invite: "À toi ! Dis le mot au petit train.",
            .effortNext: "Merci d'avoir bien essayé ! On va voir le mot suivant.",
            .again: "Bravo ! Encore une fois !",
        ]
        let en: [MessageKey: String] = [
            .bravo: "Hooray! The whole train is leaving!",
            .hookCaboose: "Oh, the little caboose stayed at the station! Let's hook it with \"shhh\"?",
            .modelSlowly: "Listen to the train: let's say it slowly, together.",
            .listenAgain: "I didn't hear it well. Shall we say it again together?",
            .invite: "Your turn! Tell the word to the little train.",
            .effortNext: "Thanks for trying so hard! Let's see the next word.",
            .again: "Great! One more time!",
        ]
        return (locale.hasPrefix("fr") ? fr : en)[self]!
    }
}

public struct Feedback: Equatable, Sendable {
    public let litWagons: [Bool]
    public let caboose: CabooseState
    public let mascot: MascotAction
    public let message: MessageKey
    public let advance: Bool
    public let countsAsAttempt: Bool
}

public enum FeedbackPolicy {
    public static let maxAttempts = 3

    /// `attempt` commence à 1 pour la première tentative (de CETTE répétition).
    /// `repetitionsLeft` : répétitions encore demandées APRÈS celle-ci si elle est réussie
    /// (0 = la dernière). Seul le verdict complet en dépend : la fête a lieu, mais le train
    /// attend la répétition suivante au lieu de partir.
    public static func feedback(for verdict: Verdict, wagons: Int, hasCaboose: Bool, attempt: Int,
                                repetitionsLeft: Int = 0,
                                maxAttempts: Int = FeedbackPolicy.maxAttempts) -> Feedback {
        let lastTry = attempt >= maxAttempts
        let allLit = [Bool](repeating: true, count: wagons)
        let noneLit = [Bool](repeating: false, count: wagons)
        let waiting: CabooseState = hasCaboose ? .waiting : .none
        switch verdict.kind {
        case .complete:
            let more = repetitionsLeft > 0
            return Feedback(litWagons: allLit, caboose: hasCaboose ? .hooked : .none, mascot: .celebrate,
                            message: more ? .again : .bravo, advance: !more, countsAsAttempt: true)
        case .missingFinalConsonant where hasCaboose:
            if lastTry {
                return Feedback(litWagons: allLit, caboose: .waiting, mascot: .modelWord,
                                message: .effortNext, advance: true, countsAsAttempt: true)
            }
            return Feedback(litWagons: allLit, caboose: .pointed, mascot: .pointCaboose,
                            message: .hookCaboose, advance: false, countsAsAttempt: true)
        case .fewerSyllables:
            return Feedback(litWagons: noneLit, caboose: waiting, mascot: .modelWord,
                            message: lastTry ? .effortNext : .modelSlowly, advance: lastTry,
                            countsAsAttempt: true)
        case .noSpeech:
            return Feedback(litWagons: noneLit, caboose: waiting, mascot: .invite,
                            message: lastTry ? .effortNext : .invite, advance: lastTry,
                            countsAsAttempt: true)
        default:
            // Incertain (et tout cas imprévu) : neutre, rien de désigné.
            return Feedback(litWagons: noneLit, caboose: waiting, mascot: .listenAgain,
                            message: lastTry ? .effortNext : .listenAgain, advance: lastTry,
                            countsAsAttempt: true)
        }
    }
}

// MARK: - Répétitions (le décompte)

/// Combien de fois l'enfant redit le mot : réglage de l'adulte, affiché en décompte
/// (« encore 2 fois ») pendant le jeu. Miroir de `policy.py`.
public enum Repetitions {
    public static let range = 1...5
    public static let defaultCount = 3
    /// Clé du réglage (espace des grands).
    public static let settingKey = "eveil.repetitions"

    public static func clamp(_ n: Int) -> Int { min(range.upperBound, max(range.lowerBound, n)) }

    /// Après une réussite : « Bravo ! Encore 2 fois ! ».
    public static func againText(remaining: Int, locale: String) -> String {
        let fr = locale.hasPrefix("fr")
        if remaining <= 1 { return MessageKey.again.defaultText(locale: locale) }
        return fr ? "Bravo ! Encore \(remaining) fois !" : "Great! \(remaining) more times!"
    }

    /// L'invitation du début de mot, avec le nombre de répétitions demandées.
    public static func inviteText(count: Int, locale: String) -> String {
        let fr = locale.hasPrefix("fr")
        if count <= 1 { return MessageKey.invite.defaultText(locale: locale) }
        return fr ? "À toi ! Dis-le \(count) fois au petit train." : "Your turn! Say it \(count) times to the little train."
    }
}

// MARK: - Le juge adulte

public extension Verdict {
    /// Le verdict de l'ADULTE (« juge adulte », docs/EVEIL.md § 4.7) : il a entendu l'enfant dire
    /// le mot entier et touche « Il l'a dit ! ». Sert là où le détecteur ne sait pas juger (les
    /// livres des sons : un son au début ou au milieu du mot). Un adulte ne rend jamais d'autre
    /// verdict : s'il ne touche rien, on continue sans rien compter.
    static func adultHeard(wagons: Int, hasCaboose: Bool) -> Verdict {
        Verdict(kind: .complete, heardNuclei: wagons, expectedNuclei: wagons, codaExpected: hasCaboose,
                codaHeard: hasCaboose, codaPlace: nil, codaMs: 0, epenthesis: false, snrDb: 0,
                reasons: ["adult_judge"])
    }
}

// MARK: - Étoiles (points de jeu)

/// Demande de l'utilisateur (28/09/2026) : « plus c'est bien répété, plus le user a des
/// points ». Des étoiles de JEU, pas un score de langage (docs/EVEIL.md § 7.3) : elles
/// récompensent l'essai et, davantage, le mot entier ; on n'en perd jamais ; elles ne
/// mesurent pas le langage de l'enfant et ne quittent pas l'iPad. Miroir de `stars_for`.
public enum Stars {
    public static let max = 3
    /// Réglage de l'espace des grands : afficher les étoiles (oui par défaut).
    public static let settingKey = "eveil.stars"
    /// Le trésor d'étoiles, gardé sur l'iPad (un total, aucun détail par mot ni par son).
    public static let totalKey = "eveil.starsTotal"

    /// Mot entier : 3 ; toutes les syllabes sans la fin : 2 ; détecteur pas sûr : 2 (le doute
    /// ne coûte pas plus qu'une fin manquée) ; syllabe en moins : 1 ; rien entendu : 0.
    public static func earned(for verdict: Verdict, hasCaboose: Bool = true) -> Int {
        switch verdict.kind {
        case .complete: return 3
        case .missingFinalConsonant: return 2      // sans fourgon : compté comme un doute, 2 aussi
        case .unsure: return 2
        case .fewerSyllables: return 1
        case .noSpeech: return 0
        }
    }
}

/// Le décompte d'un mot : combien de fois encore l'enfant le redit.
public struct RepetitionPlan: Equatable, Sendable {
    public let target: Int
    public private(set) var done: Int

    public init(target: Int = Repetitions.defaultCount, done: Int = 0) {
        let t = Repetitions.clamp(target)
        self.target = t
        self.done = min(t, max(0, done))
    }

    public var remaining: Int { target - done }
    public var isComplete: Bool { done >= target }
    /// Ce qu'il resterait si l'essai en cours réussit (paramètre `repetitionsLeft`).
    public var leftAfterSuccess: Int { max(0, remaining - 1) }

    public mutating func recordSuccess() { done = min(target, done + 1) }
}

public enum SessionStep: String, Sendable {
    case `continue`
    case endSession = "end_session"   // rituel de fin (le train rentre au dépôt)
    case restToday = "rest_today"     // à demain
}

/// Durées par défaut prudentes (cf. recommandations écrans, docs/EVEIL.md §7).
public struct SessionPolicy: Equatable, Sendable {
    public var wordsPerSession = 6
    public var maxSessionSeconds = 8.0 * 60
    public var dailyBudgetSeconds = 15.0 * 60     // réglable dans l'espace parent
    public init() {}

    public func nextStep(wordsDone: Int, sessionSeconds: Double, todaySeconds: Double) -> SessionStep {
        if todaySeconds >= dailyBudgetSeconds { return .restToday }
        if wordsDone >= wordsPerSession || sessionSeconds >= maxSessionSeconds { return .endSession }
        return .continue
    }
}

// MARK: - Garde-fou lexical (reconnaissance vocale on-device, OPTIONNELLE)

public enum LexicalEvidence: String, CaseIterable, Sendable {
    case notChecked = "not_checked"      // pas d'ASR, ou transcription vide
    case consistent                      // le mot (ou sa forme tronquée) a été reconnu
    case inconsistent                    // un autre mot semble avoir été dit
}

/// L'ASR ne peut que rendre le verdict PLUS prudent, jamais l'inverse : elle
/// « corrige » vers des mots réels et se trompe beaucoup sur les voix de 3-5 ans.
public func applyLexical(_ v: Verdict, _ evidence: LexicalEvidence) -> Verdict {
    let decisive: Set<VerdictKind> = [.complete, .missingFinalConsonant, .fewerSyllables]
    guard evidence == .inconsistent, decisive.contains(v.kind) else { return v }
    var out = v
    out.kind = .unsure
    out.reasons.append("other_word_suspected")
    return out
}
