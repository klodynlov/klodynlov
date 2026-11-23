// ListeningDiagnosis.swift — expliquer à l'ADULTE ce que le train a entendu.
//
// Sert au « Test du micro » de l'espace des grands : un adulte dit un mot, et
// l'app explique en clair ce que le détecteur a entendu et POURQUOI il a pu
// rester prudent (voix d'adulte, pièce bruyante, son saturé, deux paroles…).
// C'est un test du micro et du réglage, pas une évaluation : rien n'est gardé,
// et l'écran de l'enfant n'affiche jamais ces détails.

import WordEndCore

public struct ListeningDiagnosis: Equatable, Sendable {
    public enum Tone: Sendable { case good, neutral, caution }

    public let tone: Tone
    public let headline: String
    public let details: [String]
    public let advice: [String]

    public init(verdict: Verdict, word: TargetWord, locale: String) {
        let fr = locale.hasPrefix("fr")
        let end = word.caboose ?? ""
        switch verdict.kind {
        case .complete:
            tone = .good
            headline = word.coda == nil
                ? (fr ? "Tous les wagons sont allumés : le train a entendu le mot." : "All the wagons lit up: the train heard the word.")
                : (fr ? "Fourgon accroché : le train a entendu le mot entier." : "Caboose hooked: the train heard the whole word.")
        case .missingFinalConsonant:
            tone = .neutral
            headline = fr ? "Fourgon resté en gare : la fin « \(end) » n'a pas été entendue."
                          : "Caboose left behind: the final \"\(end)\" was not heard."
        case .fewerSyllables:
            tone = .neutral
            headline = fr ? "Un wagon est resté éteint : moins de syllabes que prévu."
                          : "A wagon stayed dark: fewer syllables than expected."
        case .noSpeech:
            tone = .caution
            headline = fr ? "Rien entendu." : "Nothing heard."
        case .unsure:
            tone = .caution
            headline = fr ? "Le train n'a pas pu trancher : il reste prudent." : "The train could not tell: it stays cautious."
        }

        var details: [String] = []
        if verdict.kind != .noSpeech {
            details.append(fr ? "Syllabes entendues : \(verdict.heardNuclei) sur \(verdict.expectedNuclei)"
                              : "Syllables heard: \(verdict.heardNuclei) of \(verdict.expectedNuclei)")
            if verdict.codaExpected {
                details.append(verdict.codaHeard
                    ? (fr ? "Fin « \(end) » : entendue (\(Int(verdict.codaMs.rounded())) ms)"
                          : "Final \"\(end)\": heard (\(Int(verdict.codaMs.rounded())) ms)")
                    : (fr ? "Fin « \(end) » : pas entendue" : "Final \"\(end)\": not heard"))
            }
            details.append(fr ? "Marge sur le bruit de la pièce : \(Int(verdict.snrDb.rounded())) dB (confortable dès 20 dB)"
                              : "Margin over room noise: \(Int(verdict.snrDb.rounded())) dB (comfortable from 20 dB)")
        }
        self.details = details

        var advice: [String] = []
        let reasons = verdict.kind == .noSpeech ? ["no_speech"] : verdict.reasons
        for reason in reasons {
            if let text = Self.explain(reason, fr: fr, end: end) { advice.append(text) }
        }
        self.advice = advice
    }

    /// Une raison du détecteur, dite simplement, avec ce qu'on peut y faire.
    static func explain(_ reason: String, fr: Bool, end: String) -> String? {
        switch reason {
        case "adult_voice_suspected":
            return fr
                ? "Voix grave d'adulte reconnue : le jeu l'écarte exprès, pour ne pas prendre le mot dit par un parent pour celui de l'enfant. Pour essayer vous-même, activez « Essai par un adulte »."
                : "Deep adult voice detected: the game ignores it on purpose, so a parent's model is never taken for the child's answer. To try it yourself, turn on \"Adult trial\"."
        case "clipping":
            return fr ? "Son saturé : parlez à 30-50 cm de l'iPad, sans crier."
                      : "Clipped sound: speak 30-50 cm from the iPad, without shouting."
        case "multiple_utterances":
            return fr ? "Deux paroles entendues : un seul mot à la fois, et personne d'autre ne parle pendant l'écoute."
                      : "Two utterances heard: one word at a time, and nobody else talks while the train listens."
        case "low_snr":
            return fr ? "Pièce bruyante (télé, musique, machine…) : le jeu reste prudent."
                      : "Noisy room (TV, music, appliances…): the game stays cautious."
        case "extra_nuclei":
            return fr ? "Plus de syllabes que prévu : un autre mot, ou une petite phrase ?"
                      : "More syllables than expected: another word, or a short sentence?"
        case "no_vowel_nucleus":
            return fr ? "Pas de voyelle nette : parlez un peu plus fort." : "No clear vowel: speak a little louder."
        case "truncated":
            return fr ? "Écoute coupée trop tôt : laissez un petit silence après le mot."
                      : "Listening cut too early: leave a short silence after the word."
        case "coda_ambiguous":
            return fr ? "Fin du mot pas nette : le jeu ne tranche pas (il ne dit jamais « faux » au hasard)."
                      : "Unclear word ending: the game does not decide (it never says \"wrong\" by chance)."
        case "epenthetic_schwa":
            return fr ? "Petit « e » ajouté à la fin (« dou-che-e ») : accepté." : "Small extra vowel at the end: accepted."
        case "place_differs":
            return fr ? "Le « \(end) » ressemblait à un autre son (« s » / « ch ») : noté, jamais compté comme une erreur."
                      : "The \"\(end)\" sounded like another sibilant (s / sh): noted, never counted as an error."
        case "other_word_suspected":
            return fr ? "La reconnaissance vocale de l'iPad a cru entendre un autre mot."
                      : "The iPad's speech recognition thought it heard another word."
        case "no_speech":
            return fr ? "Parlez juste après le mot du train, à 30-50 cm de l'iPad. Vérifiez aussi l'accès au micro."
                      : "Speak right after the train says the word, 30-50 cm from the iPad. Also check microphone access."
        default:
            return nil
        }
    }
}
