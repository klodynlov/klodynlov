// Recipes+Train.swift — les bruits du Petit Train.
//
// Le train est le fil rouge : sifflet au départ vers un autre monde, carillon à
// l'arrivée, et les deux fourgons « symboles sonores » — « chhh » (la vapeur)
// pour ch, « sss » (le serpent) pour s. Ces deux-là doivent ressembler AUX
// CONSONNES que l'enfant vient de dire : bandes calées sur /ʃ/ (≈ 2–6 kHz) et
// /s/ (≈ 5–9 kHz), la seconde nettement plus aiguë que la première.

import Foundation

extension Recipes {
    /// Sifflet à vapeur « tchou-tchou » : accord majeur de trois tuyaux + souffle, deux coups.
    static func whistle(_ c: inout Ctx) -> [Double] {
        let chord = [466.16, 587.33, 698.46].map { $0 * c.pitch }   // si♭4 – ré5 – fa5
        var out = silence(1.15)
        out.add(steamBlow(chord, length: 0.34, &c.rng))
        out.add(steamBlow(chord, length: 0.62, &c.rng), at: 0.46)
        return out
    }

    /// Un coup de sifflet : chaque tuyau « monte en pression » (un peu bas à l'attaque), avec
    /// un léger vibrato de vapeur et un peu d'octave ; le souffle est plus fort à l'attaque.
    static func steamBlow(_ chord: [Double], length: Double, _ rng: inout Rng) -> [Double] {
        var out = silence(length)
        for (k, f) in chord.enumerated() {
            let pipe = f * (1 + 0.0015 * Double(k - 1))            // tuyaux pas tout à fait justes
            let rate = 5.2 + 0.7 * Double(k)
            let pitch: (Double) -> Double = { t in
                pipe * (1 - 0.03 * exp(-t / 0.045)) * (1 + 0.0025 * sin(2 * .pi * rate * t))
            }
            let tone = osc(.sine, length, phase: 0.23 * Double(k), pitch)
            let octave = osc(.sine, length, phase: 0.11 * Double(k)) { t in 2 * pitch(t) }
            out.add(tone.mixed(octave, gain: 0.12), gain: 0.3)
        }
        let breath = filter(pinkNoise(length, &rng), .bandPass, 2400, q: 0.8)
        out.add(breath.shaped { t in 0.1 + 0.3 * exp(-t / 0.05) }, gain: 0.5)
        return out.shaped { t in gate(t, length: length, rise: 0.03, fall: 0.08) }
    }

    /// « Chhh » : bruit dans la bande de /ʃ/ (≈ 1,9–6,2 kHz, pic vers 3,5 kHz), une bouffée
    /// qui s'éteint doucement.
    static func steam(_ c: inout Ctx) -> [Double] {
        let length = 0.62
        var x = whiteNoise(length, &c.rng)
        x = lowPass4(highPass4(x, 1900 * c.pitch), 6200 * c.pitch)
        x = filter(x, .bandPass, 3500 * c.pitch, q: 0.6).mixed(x, gain: 0.5)
        return x.shaped { t in gate(t, length: length, rise: 0.035, fall: 0.3) * (1 - 0.25 * t / length) }
    }

    /// « Sss » : bruit dans la bande de /s/ (5–9 kHz), plus aigu que la vapeur, léger
    /// balancement de serpent.
    static func hiss(_ c: inout Ctx) -> [Double] {
        let length = 0.75
        let x = lowPass4(highPass4(whiteNoise(length, &c.rng), 5000 * c.pitch), 9000)
        return x.shaped { t in gate(t, length: length, rise: 0.07, fall: 0.18) * (0.88 + 0.12 * sin(2 * .pi * 3 * t)) }
    }

    /// Carillon d'arrivée : trois notes qui montent (do6 – mi6 – sol6), lames de métal.
    static func chime(_ c: inout Ctx) -> [Double] {
        let notes = [1046.5, 1318.5, 1568.0].map { $0 * c.pitch }
        var out = silence(1.1)
        for (k, f) in notes.enumerated() {
            let start = 0.12 * Double(k)
            out.add(metalBar(f, decay: 0.45, length: 1.1 - start), at: start, gain: k == 2 ? 1 : 0.8)
        }
        return out
    }

    /// Lame de métal frappée (glockenspiel) : partiels 1 – 2,76 – 5,40 d'une barre libre, et une
    /// jumelle à peine désaccordée qui fait « scintiller » (battement lent).
    static func metalBar(_ f: Double, decay: Double, length: Double) -> [Double] {
        modes([Partial(f, decay, 1), Partial(f * 1.0025, decay * 0.9, 0.35), Partial(f * 2.76, decay * 0.25, 0.22),
               Partial(f * 5.40, decay * 0.1, 0.08)], length, attack: 0.001)
    }
}
