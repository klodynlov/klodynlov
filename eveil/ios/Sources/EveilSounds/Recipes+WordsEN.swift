// Recipes+WordsEN.swift — le bruit des objets des mots anglais.
//
// Mêmes règles que pour le français (voir `Recipes+WordsFR.swift`) : un trait
// reconnaissable, tout le reste arrondi, des graves doublés d'un « corps »
// audible sur un iPad.

import Foundation

extension Recipes {
    /// Fish : bulles « blub » — grosses bulles graves dont la hauteur monte (≈ 220 → 480 Hz),
    /// sous l'eau (grondement sourd).
    static func blub(_ c: inout Ctx) -> [Double] {
        var out = silence(0.62)
        for (t, f, amp) in [(0.0, 220.0, 1.0), (0.19, 275.0, 0.85), (0.34, 245.0, 0.6)] {
            let pf = f * c.pitch
            let rise: (Double) -> Double = { u in 1 + 1.2 * (1 - exp(-u / 0.035)) }
            let fundamental = osc(.sine, 0.25) { u in pf * rise(u) }.shaped { u in strike(u, attack: 0.004, decay: 0.05) }
            let second = osc(.sine, 0.25) { u in 2 * pf * rise(u) }.shaped { u in strike(u, attack: 0.004, decay: 0.03) }
            out.add(fundamental.mixed(second, gain: 0.2), at: t, gain: amp)
        }
        out.add(lowPass4(pinkNoise(0.6, &c.rng), 500).shaped { t in 0.08 * arch(t, 0.6) })
        return out
    }

    /// Push : caisse poussée sur le sol — frottement (bruit ≈ 0,3–2 kHz) haché par le
    /// « colle-glisse » (24–36 à-coups/s irréguliers), caisse en bois qui résonne.
    static func scrape(_ c: inout Ctx) -> [Double] {
        let length = 1.05
        let p = c.pitch
        let noise = pinkNoise(length, &c.rng).mixed(whiteNoise(length, &c.rng), gain: 0.3)
        var x = filter(noise, .bandPass, 900 * p, q: 0.8)
        var jolts = [Double](repeating: 0, count: x.count)
        let jolt = signal(0.04) { u in strike(u, attack: 0.002, decay: 0.012) }
        var t = 0.0
        while t < length {
            jolts.add(jolt, at: t, gain: c.rng.range(0.5, 1))
            t += 1 / c.rng.range(24, 36)
        }
        for i in x.indices { x[i] *= 0.35 + jolts[i] }
        x = body(x, [(freq: 240 * p, q: 6, gain: 0.8), (freq: 610 * p, q: 5, gain: 0.5)])
        return lowPass4(x, 3500).shaped { t in gate(t, length: length, rise: 0.1, fall: 0.15) }
    }

    /// Wash : eau qui clapote — vagues lentes (≈ 2 par seconde) de bruit grave, éclaboussures
    /// aux crêtes, glouglous (petits sinus qui montent).
    static func water(_ c: inout Ctx) -> [Double] {
        let length = 1.4
        let phase = c.rng.range(0, 1)
        let wave: (Double) -> Double = { t in pow(sin(.pi * (2.2 * t + phase)), 2) }
        let deep = brownNoise(length, &c.rng).mixed(pinkNoise(length, &c.rng), gain: 0.5)
        var out = filter(deep, .lowPass, 900, q: 0.8).shaped { t in 0.5 * (0.35 + 0.65 * wave(t)) }
        let spray = lowPass4(filter(pinkNoise(length, &c.rng), .bandPass, 2200, q: 0.8), 5000)
        out.add(spray.shaped { t in 0.35 * pow(wave(t), 3) })
        for t in poisson(&c.rng, from: 0, to: length - 0.05, rate: { _ in 22 }) {
            let f = c.rng.logRange(250, 900)
            let glug = osc(.sine, 0.08) { u in f * (1 + 0.8 * (1 - exp(-u / 0.015))) }
            out.add(glug.shaped { u in strike(u, attack: 0.002, decay: 0.02) }, at: t, gain: c.rng.range(0.2, 0.55))
        }
        return out.shaped { t in gate(t, length: length, rise: 0.15, fall: 0.3) }
    }

    /// Goose : « honk » ×2 — voix nasale (≈ 390 Hz qui fléchit), formant fort et serré vers
    /// 800 Hz, un rien de rugosité.
    static func honk(_ c: inout Ctx) -> [Double] {
        let length = 0.2
        let nasal: Vowel = [Formant(800, 70, 1), Formant(1250, 110, 0.35), Formant(2600, 180, 0.3)]
        var out = silence(0.65)
        for (t, f, amp) in [(0.0, 390.0, 1.0), (0.29, 370.0, 0.9)] {
            let pf = f * c.pitch
            let voice = osc(.saw, length) { u in pf * (1.03 - 0.08 * u / length) * (1 + 0.01 * sin(2 * .pi * 7 * u)) }
            let honk = formants(voice) { _ in nasal }.shaped { u in
                gate(u, length: length, rise: 0.015, fall: 0.05) * (0.85 + 0.15 * sin(2 * .pi * 45 * u))
            }
            out.add(honk, at: t, gain: amp)
        }
        return out
    }

    /// Moose : long appel grave — voix ≈ 120–140 Hz qui s'ouvre « ou → a » puis se referme en
    /// « o », vibrato lent. Long mais doux : un appel, pas un rugissement.
    static func bellow(_ c: inout Ctx) -> [Double] {
        let length = 1.8
        let p = c.pitch
        let contour = Curve([(0, 118), (0.3, 138), (1.2, 128), (1.8, 102)])
        let voice = osc(.saw, length) { t in contour(t) * p * (1 + 0.01 * sin(2 * .pi * 3.5 * t)) }
        let source = voice.mixed(filter(pinkNoise(length, &c.rng), .lowPass, 1200), gain: 0.06)
        let call = formants(source) { t in
            t < 0.9 ? blend(Vowels.u, Vowels.a, smooth(t, 0.2, 0.8)) : blend(Vowels.a, Vowels.o, smooth(t, 0.9, 1.6))
        }
        let amp = Curve([(0, 0), (0.25, 0.8), (0.7, 1), (1.35, 0.85), (1.8, 0)])
        return lowPass4(call, 3000).shaped { t in amp(t) }
    }

    /// Ice : glaçons qui s'entrechoquent — 5 petits chocs de verre (partiels ≈ 2,6–3,8 kHz,
    /// très brefs), à des instants et des hauteurs au hasard.
    static func iceClink(_ c: inout Ctx) -> [Double] {
        var out = silence(0.8)
        var t = 0.0
        for k in 0..<5 {
            let f = c.rng.range(2600, 3800) * c.pitch
            let d = c.rng.range(0.04, 0.08)
            var clink = modes([Partial(f, d, 1), Partial(f * 1.61, d * 0.6, 0.4), Partial(f * 2.27, d * 0.35, 0.2)], 0.3,
                              attack: 0.0008)
            clink.add(highPass4(grain(&c.rng, decay: 0.0005), 3000), gain: 0.3)
            out.add(clink, at: t, gain: k == 0 ? 1 : c.rng.range(0.35, 0.9))
            t += c.rng.range(0.06, 0.14)
        }
        return out
    }

    /// Piece : pièce de puzzle qui s'emboîte « clic » — claquement bref (≈ 2,1 / 3,3 kHz) sur un
    /// petit corps de bois (≈ 780 Hz), puis la pièce qui se cale.
    static func click(_ c: inout Ctx) -> [Double] {
        let p = c.pitch
        func snap(_ rng: inout Rng) -> [Double] {
            var x = modes([Partial(2100 * p, 0.012, 0.6), Partial(3300 * p, 0.006, 0.25), Partial(780 * p, 0.03, 0.5),
                           Partial(1450 * p, 0.018, 0.25)], 0.2)
            x.add(highPass4(grain(&rng, decay: 0.0006), 1500), gain: 0.6)
            return x
        }
        var out = snap(&c.rng)
        out.add(snap(&c.rng), at: 0.035, gain: 0.35)
        return out
    }

    /// Bus « tut-tut » : klaxon à deux trompes (≈ 400 et 500 Hz, tierce majeure), sinus saturés
    /// et filtrés, deux coups (court, long).
    static func horn(_ c: inout Ctx) -> [Double] {
        let p = c.pitch
        var out = silence(0.72)
        for (t, length) in [(0.0, 0.18), (0.28, 0.34)] {
            let low = osc(.soft(drive: 3), length) { _ in 400 * p }
            let high = osc(.soft(drive: 3), length, phase: 0.3) { _ in 500 * p }
            let blast = body(lowPass4(low.mixed(high), 2200), [(freq: 1200, q: 1.2, gain: 0.5)])
            out.add(blast.shaped { u in gate(u, length: length, rise: 0.012, fall: 0.03) }, at: t, gain: 0.5)
        }
        return out
    }

    /// Tennis : balle « pok » — choc creux (≈ 1 kHz, bref) sur un corps plus grave, petit écho
    /// du court.
    static func pok(_ c: inout Ctx) -> [Double] {
        let p = c.pitch
        var x = modes([Partial(1050 * p, 0.018, 1), Partial(2300 * p, 0.008, 0.3), Partial(380 * p, 0.025, 0.45)], 0.2)
        x.add(filter(grain(&c.rng, decay: 0.0005), .bandPass, 2000, q: 0.8), gain: 0.5)
        return echo(x, delay: 0.045, feedback: 0.25, mix: 0.22)
    }

    /// Mouse « couic » : sinus qui glisse vers le haut puis retombe (1,6 → 2,5 → 1,8 kHz) en
    /// 0,25 s, avec un petit trille.
    static func squeak(_ c: inout Ctx) -> [Double] {
        let length = 0.25
        let p = c.pitch
        let contour = Curve([(0, 1600), (0.07, 2500), (0.25, 1800)])
        let pitch: (Double) -> Double = { t in contour(t) * p * (1 + 0.02 * sin(2 * .pi * 18 * t)) }
        let tone = osc(.sine, length, pitch)
        let octave = osc(.sine, length) { t in 2 * pitch(t) }
        return tone.mixed(octave, gain: 0.08).shaped { t in gate(t, length: length, rise: 0.015, fall: 0.06) }
    }

    /// Juice : aspiration à la paille — souffle dans la résonance de la paille (≈ 1,4 kHz),
    /// haché par les gorgées (15–30 à-coups/s), glouglous, puis crachotement d'air au fond du
    /// verre.
    static func slurp(_ c: inout Ctx) -> [Double] {
        let length = 0.85
        let p = c.pitch
        let air = lowPass4(filter(pinkNoise(length, &c.rng), .bandPass, 1400 * p, q: 3), 4500)
        var x = air.mixed(filter(pinkNoise(length, &c.rng), .bandPass, 700 * p, q: 2), gain: 0.7)
        var gulps = [Double](repeating: 0, count: x.count)
        let gulp = signal(0.05) { u in strike(u, attack: 0.004, decay: 0.015) }
        var t = 0.0
        while t < 0.6 {
            gulps.add(gulp, at: t, gain: c.rng.range(0.4, 1))
            t += 1 / c.rng.range(15, 30)
        }
        for i in x.indices {
            let u = Double(i) / fs
            let sputter = u > 0.6 ? 0.5 * max(0, sin(2 * .pi * 40 * u)) : 0
            x[i] *= 0.25 + gulps[i] + sputter
        }
        for u in poisson(&c.rng, from: 0, to: 0.55, rate: { _ in 12 }) {
            let f = c.rng.logRange(300, 700) * p
            let glug = osc(.sine, 0.06) { v in f * (1 + 0.8 * (1 - exp(-v / 0.012))) }
            x.add(glug.shaped { v in strike(v, attack: 0.002, decay: 0.015) }, at: u, gain: 0.3)
        }
        return x.shaped { u in gate(u, length: length, rise: 0.04, fall: 0.15) }
    }

    /// House : sonnette « ding-dong » douce — deux lames (mi5 puis do5), marteau feutré.
    static func doorbell(_ c: inout Ctx) -> [Double] {
        var out = silence(1.7)
        for (t, f, amp) in [(0.0, 659.26, 1.0), (0.5, 523.25, 0.95)] {
            let pf = f * c.pitch
            let bar = modes([Partial(pf, 0.75, 1), Partial(pf * 1.002, 0.7, 0.3), Partial(pf * 2, 0.25, 0.08),
                             Partial(pf * 2.76, 0.12, 0.1)], 1.7 - t, attack: 0.003)
            out.add(bar, at: t, gain: amp)
        }
        return out
    }

    /// Circus : petite fanfare « ta-ta-ta-taaa » (sol4 do5 mi5 sol5) — cuivre : dent de scie dont
    /// la brillance suit le souffle (passe-bas qui s'ouvre avec le volume), vibrato sur la
    /// dernière note.
    static func fanfare(_ c: inout Ctx) -> [Double] {
        let notes: [(Double, Double, Double)] = [(0, 392.0, 0.12), (0.14, 523.25, 0.12), (0.28, 659.26, 0.12),
                                                 (0.42, 783.99, 0.55)]
        var out = silence(1.1)
        for (k, (t, f, held)) in notes.enumerated() {
            let pf = f * c.pitch
            let last = k == notes.count - 1
            let length = held + 0.05
            let voice = osc(.saw, length) { u in
                let scoop = 1 - 0.015 * exp(-u / 0.02)            // attaque un peu basse, comme un cuivre
                let vibrato = last ? 1 + 0.008 * sin(2 * .pi * 5.5 * u) * smooth(u, 0.15, 0.3) : 1
                return pf * scoop * vibrato
            }
            let env: (Double) -> Double = { u in gate(u, length: length, rise: 0.02, fall: 0.06) }
            let brass = sweep(voice, .lowPass, q: 0.9) { u in pf * (1.5 + 5 * env(u)) }
            out.add(brass.shaped(env), at: t, gain: last ? 0.6 : 0.55)
        }
        return lowPass4(out, 5000)
    }

    /// Splash « plouf » : grosse éclaboussure (bruit dont le passe-bas se referme, 6 → 0,5 kHz),
    /// « bloup » grave de l'objet qui plonge, et les gouttes qui retombent.
    static func splash(_ c: inout Ctx) -> [Double] {
        let p = c.pitch
        var out = sweep(whiteNoise(0.8, &c.rng), .lowPass, q: 0.9) { t in 500 + 5500 * exp(-t / 0.12) }
            .shaped { t in strike(t, attack: 0.004, decay: 0.16) }
        let plunge = osc(.sine, 0.35) { t in (110 + 170 * (1 - exp(-t / 0.05))) * p }
        out.add(plunge.shaped { t in strike(t, attack: 0.005, decay: 0.09) }, gain: 0.7)
        for _ in 0..<14 {
            let f = c.rng.logRange(900, 3000) * p
            let t = c.rng.range(0.15, 0.8)
            let drop = osc(.sine, 0.05) { u in f * (1 + 0.4 * (1 - exp(-u / 0.006))) }
            out.add(drop.shaped { u in strike(u, attack: 0.001, decay: 0.012) }, at: t,
                    gain: c.rng.range(0.1, 0.35) * (1 - 0.6 * (t - 0.15) / 0.65))
        }
        return out
    }
}
