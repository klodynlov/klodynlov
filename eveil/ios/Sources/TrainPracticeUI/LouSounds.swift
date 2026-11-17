// LouSounds.swift — quels gestes Lou fait pour un mot, syllabe par syllabe (wagon par wagon).
//
// Miroir de `eveil/outils/gestes/sons_mots.py` (mêmes cas dans les tests). Les gestes de la méthode
// Borel-Maisonny, validés par une orthophoniste le 06/10/2026, sont montrés par Lou dans le petit
// train et dans les livres des sons (décision de l'utilisateur). Chaque son donne l'étiquette de son
// geste (`gestes.py`, champ `son`) ; /w/ + /a/ = « oi », /w/ + /ɛ̃/ = « oin » (un seul geste) ; /w/
// ailleurs est sauté ; /j/ = « ill » ; /ɥ/ = « ui » (pas de geste : la bouche seule). Français
// seulement : la méthode est celle du français.

import Foundation
import WordEndCore

public enum LouSounds {
    static let byIPA: [String: String] = [
        "a": "a", "o": "o", "ɔ": "o", "u": "ou", "i": "i", "y": "u", "e": "é", "ɛ": "è",
        "ø": "eu", "œ": "eu ouvert", "ə": "e", "ɑ̃": "an", "ɔ̃": "on", "ɛ̃": "in",
        "ʃ": "ch", "s": "s", "z": "z", "ʒ": "j", "f": "f", "v": "v", "p": "p", "b": "b", "t": "t",
        "d": "d", "k": "k", "ɡ": "g", "m": "m", "n": "n", "ɲ": "gn", "l": "l", "ʁ": "r",
        "j": "ill", "ɥ": "ui",
    ]
    static let afterW: [String: String] = ["a": "oi", "ɛ̃": "oin"]

    /// « vwa » → ["v", "oi"] ; « ʒi » → ["j", "i"] ; « nɥaʒ » → ["n", "ui", "a", "j"].
    public static func keys(syllable: String) -> [String] {
        // Un Character Swift garde la voyelle nasale entière (« ɛ̃ » = ɛ + tilde combinant).
        let phonemes = syllable.filter { $0 != "ˈ" && $0 != "ˌ" && $0 != "." }.map(String.init)
        var out: [String] = []
        var i = 0
        while i < phonemes.count {
            let p = phonemes[i]
            if p == "w" {
                if i + 1 < phonemes.count, let both = afterW[phonemes[i + 1]] {
                    out.append(both)
                    i += 2
                } else {
                    i += 1
                }
                continue
            }
            if let key = byIPA[p] { out.append(key) }
            i += 1
        }
        return out
    }

    /// Une liste de gestes par syllabe (« ʒi.ʁaf » → [["j", "i"], ["r", "a", "f"]]).
    public static func keys(ipa: String) -> [[String]] {
        ipaSyllables(ipa).map { keys(syllable: $0) }
    }

    /// Le son d'un geste, en API (pour que la voix le dise) : « ch » → « ʃ ».
    public static func ipa(ofGesture key: String) -> String? {
        let pairs = byIPA.filter { $0.value == key }.map(\.key).sorted()
        if key == "oi" { return "wa" }
        if key == "oin" { return "wɛ̃" }
        return pairs.first
    }

    /// Les gestes de chaque wagon d'un mot (vide hors du français ou sans API, ex. mots de la famille).
    public static func keys(for word: TargetWord, locale: String) -> [[String]] {
        guard locale.hasPrefix("fr"), let ipa = word.ipa, !ipa.isEmpty else { return [] }
        let perSyllable = keys(ipa: ipa)
        return perSyllable.count == word.wagons.count ? perSyllable : []
    }
}
