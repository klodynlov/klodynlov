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
        ]
        let en: [MessageKey: String] = [
            .bravo: "Hooray! The whole train is leaving!",
            .hookCaboose: "Oh, the little caboose stayed at the station! Let's hook it with \"shhh\"?",
            .modelSlowly: "Listen to the train: let's say it slowly, together.",
            .listenAgain: "I didn't hear it well. Shall we say it again together?",
            .invite: "Your turn! Tell the word to the little train.",
            .effortNext: "Thanks for trying so hard! Let's see the next word.",
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

    /// `attempt` commence à 1 pour la première tentative sur ce mot.
    public static func feedback(for verdict: Verdict, wagons: Int, hasCaboose: Bool, attempt: Int,
                                maxAttempts: Int = FeedbackPolicy.maxAttempts) -> Feedback {
        let lastTry = attempt >= maxAttempts
        let allLit = [Bool](repeating: true, count: wagons)
        let noneLit = [Bool](repeating: false, count: wagons)
        let waiting: CabooseState = hasCaboose ? .waiting : .none
        switch verdict.kind {
        case .complete:
            return Feedback(litWagons: allLit, caboose: hasCaboose ? .hooked : .none, mascot: .celebrate,
                            message: .bravo, advance: true, countsAsAttempt: true)
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
