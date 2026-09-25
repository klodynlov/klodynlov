// DemoScenarios.swift — « micro simulé » : montrer le petit train sans enfant ni micro.
//
// Pour présenter l'app (panel, famille, captures d'écran) : chaque scénario
// synthétise une pseudo-parole avec `Synth` — la même que les tests de parité —
// et la fait passer par le VRAI détecteur, en temps réel. Le train réagit donc
// exactement comme avec un enfant. Ce n'est jamais une mesure d'enfant.

import WordEndCore

public enum DemoScenario: String, CaseIterable, Identifiable, Sendable {
    case complete         // le mot entier (« douche »)
    case missingEnd       // sans la consonne finale (« dou »)
    case fewerSyllables   // une syllabe en moins (« mi » pour « minouche »)

    public var id: String { rawValue }

    public func label(locale: String) -> String {
        let fr = locale.hasPrefix("fr")
        switch self {
        case .complete: return fr ? "Mot entier" : "Whole word"
        case .missingEnd: return fr ? "Sans la fin" : "No ending"
        case .fewerSyllables: return fr ? "Une syllabe en moins" : "One syllable short"
        }
    }

    public var symbol: String {
        switch self {
        case .complete: return "checkmark.circle.fill"
        case .missingEnd: return "scissors"
        case .fewerSyllables: return "minus.circle.fill"
        }
    }

    public func isAvailable(for word: TargetWord) -> Bool {
        switch self {
        case .complete: return true
        case .missingEnd: return word.coda != nil
        case .fewerSyllables: return word.nuclei >= 2
        }
    }

    /// Spécification `Synth` : une syllabe « consonne + voyelle » par noyau, puis la
    /// consonne finale (« ch » → `S`, « s » → `s`). Mêmes motifs que les tests du détecteur.
    public func spec(for word: TargetWord) -> String? {
        guard isAvailable(for: word) else { return nil }
        let onsets = ["d50", "m70", "n70", "b50"]
        let vowels = ["u", "i", "a", "o"]
        let syllables = self == .fewerSyllables ? 1 : max(1, word.nuclei)
        var parts: [String] = []
        for k in 0..<syllables {
            let last = k == syllables - 1
            let ms = !last ? 140 : (self == .complete && word.coda != nil ? 190 : 250)
            parts.append(onsets[k % onsets.count])
            parts.append("\(vowels[k % vowels.count])\(ms)")
        }
        if self == .complete, let coda = word.coda {
            parts.append(coda == "s" ? "s180" : "S180")
        }
        return parts.joined(separator: " ")
    }

    /// Le signal à pousser dans le détecteur (24 kHz), ou `nil` si le scénario ne s'applique pas.
    public func samples(for word: TargetWord, seed: Int = 1) -> [Double]? {
        guard let spec = spec(for: word) else { return nil }
        var utterance = Utterance(spec: spec)
        utterance.seed = seed
        return Synth.synthesize(utterance)
    }
}
