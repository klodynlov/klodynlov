// Recipes+Animals.swift — les cris des animaux des livres des sons.
//
// Demande de l'utilisateur (17/11/2026) : « dans le livre des sons, quand on est sur
// un animal, si on appuie sur l'image, fais entendre le son : ex. rugissement pour le
// lion ». Mêmes règles que les autres bruitages des mots (`Recipes+WordsFR.swift`) :
// on garde LE trait qui fait reconnaître l'animal à un enfant de 3 ans, et on arrondit
// le reste — un rugissement de dessin animé, pas un fauve qui fait peur.
//
//   - lion « rrroaaar » : voix grave qui s'ouvre o → a → o, sous-harmonique et RÂPE
//     de gorge (gain qui tremble irrégulièrement vers 35 Hz) ;
//   - dinosaure : un pas lourd « boum », puis un rugissement plus grave et plus long ;
//   - dragon : un rugissement, puis le SOUFFLE de feu (bruit qui s'ouvre et crépite) ;
//   - loup « aouuuu » : voix presque pure qui monte, tient, redescend ;
//   - poule « cot cot cot codêêt », coq « co-co-ri-cooo » (4 syllabes qui montent, la
//     dernière longue qui retombe), canard « coin-coin » (2 coups nasaux et grésillants) ;
//   - cheval (et zèbre) : hennissement aigu qui descend en TRILLE, et l'ébrouement ;
//   - grenouille « coâ-coâ » : deux coassements roulés (pulsations ≈ 32/s) ;
//   - mouton « bêêê » : voyelle « è » chevrotante (≈ 7 Hz) ;
//   - phoque « ar-ar-ar » : trois aboiements nasaux, rapprochés ;
//   - dauphin : rafale de clics qui accélère, puis sifflets « ii-ii-iii » ;
//   - crocodile : la mâchoire grince en s'ouvrant, puis « clac ! », deux fois ;
//   - lapin : il grignote (trois bouchées de petits craquements) ; il ne crie pas ;
//   - araignée : petits pas pizzicato qui MONTENT (elle grimpe à son fil) ; elle ne
//     crie pas non plus. La girafe, muette, mâche ses feuilles (`rustle`, réutilisé).
//
// Les graves gardent un corps audible sur un iPad (formants à 400–1500 Hz).

import Foundation

extension Vowels {
    /// « è » ouvert (bêêê, codêêt).
    static let e: Vowel = [Formant(580, 90, 1), Formant(1800, 130, 0.5), Formant(2550, 170, 0.3)]
}

extension Recipes {
    // MARK: - Briques

    /// Râpe de gorge : un gain qui tremble IRRÉGULIÈREMENT autour de `rate` Hz (bruit filtré),
    /// entre 1 − `depth` et 1. Garder `depth` ≤ 0,6 : le creux reste au-dessus du seuil du
    /// comptage des coups (un rugissement reste UN coup).
    static func rasp(_ seconds: Double, rate: Double, depth: Double, _ rng: inout Rng) -> [Double] {
        let wobble = filter(whiteNoise(seconds, &rng), .bandPass, rate, q: 2)
        let energy = wobble.reduce(0) { $0 + $1 * $1 } / Double(Swift.max(wobble.count, 1))
        let rms = Swift.max(energy.squareRoot(), 1e-12)
        return wobble.map { 1 - depth * (0.5 + 0.5 * tanh(1.5 * $0 / rms)) }
    }

    /// Ramené à une même force : la plus forte tranche de 10 ms vaut `rms`. Les syllabes d'un même
    /// cri n'ont pas toutes la même force après les formants (un « i » sur une voix aiguë sort bien
    /// plus faible qu'un « o ») ; on les égalise avant de poser leurs gains.
    static func leveled(_ x: [Double], rms: Double = 0.3) -> [Double] {
        let n = Swift.max(frames(0.01), 1)
        var loudest = 0.0
        for start in stride(from: 0, to: x.count, by: n) {
            let end = Swift.min(start + n, x.count)
            var sum = 0.0
            for i in start..<end { sum += x[i] * x[i] }
            loudest = Swift.max(loudest, sum / Double(n))
        }
        return loudest > 0 ? x.scaled(rms / loudest.squareRoot()) : x
    }

    /// Produit échantillon par échantillon (source × gain).
    static func times(_ x: [Double], _ gain: [Double]) -> [Double] { zip(x, gain).map { $0 * $1 } }

    /// Un rugissement : dent de scie + sous-harmonique (f0 / 2) + souffle, râpés, dans des
    /// formants qui s'ouvrent « o → a » puis se referment ; `size` < 1 = une plus grande bête.
    static func roarCall(_ contour: Curve, length: Double, size: Double, raspRate: Double,
                         _ rng: inout Rng) -> [Double] {
        let f0: (Double) -> Double = { t in contour(t) * (1 + 0.015 * sin(2 * .pi * 4 * t)) }
        var source = osc(.saw, length, f0).mixed(osc(.saw, length, phase: 0.3) { t in 0.5 * f0(t) }, gain: 0.45)
        source = source.mixed(filter(pinkNoise(length, &rng), .lowPass, 2200), gain: 0.6)
        source = times(source, rasp(length, rate: raspRate, depth: 0.55, &rng))
        let o = Vowels.scaled(Vowels.o, size), a = Vowels.scaled(Vowels.a, size)
        let call = formants(source) { t in
            t < 0.55 * length ? blend(o, a, smooth(t, 0.05 * length, 0.35 * length))
                              : blend(a, o, smooth(t, 0.55 * length, length))
        }
        let amp = Curve([(0, 0), (0.08 * length, 0.6), (0.3 * length, 1), (0.65 * length, 0.85), (length, 0)])
        return lowPass4(call, 3500).shaped { t in amp(t) }
    }

    /// Un pas lourd « boum » : sinus qui tombe 150 → 55 Hz (le sol) et son « toum » de corps
    /// (≈ 170 / 400 Hz, celui qu'un iPad fait entendre).
    static func thump(_ p: Double, _ rng: inout Rng) -> [Double] {
        let drop: (Double) -> Double = { u in (55 + 95 * exp(-u / 0.05)) * p }
        var step = osc(.sine, 0.5, drop).shaped { u in strike(u, attack: 0.004, decay: 0.13) }.scaled(0.7)
        step.add(osc(.sine, 0.4) { u in 2.6 * drop(u) }.shaped { u in strike(u, attack: 0.004, decay: 0.09) }, gain: 0.7)
        step.add(modes([Partial(170 * p, 0.07, 0.55), Partial(400 * p, 0.045, 0.5)], 0.35))
        step.add(lowPass4(grain(&rng, decay: 0.008), 1200), gain: 0.8)
        return step
    }

    // MARK: - Les grands cris

    /// Lion « rrroaaar » : voix ≈ 95 → 150 → 85 Hz, râpée (≈ 36 Hz), formants de grande bête.
    static func roar(_ c: inout Ctx) -> [Double] {
        let p = c.pitch
        let contour = Curve([(0, 95 * p), (0.35, 150 * p), (0.9, 135 * p), (1.45, 85 * p)])
        return roarCall(contour, length: 1.45, size: 0.9, raspRate: 36, &c.rng)
    }

    /// Dinosaure : « boum » d'un pas lourd, puis un rugissement plus grave (≈ 70 → 110 → 60 Hz),
    /// plus long, formants d'une bête encore plus grande, râpe plus lente.
    static func dinoRoar(_ c: inout Ctx) -> [Double] {
        let p = c.pitch
        var out = leveled(thump(p, &c.rng), rms: 0.2)
        let contour = Curve([(0, 72 * p), (0.45, 110 * p), (1.1, 98 * p), (1.65, 60 * p)])
        out.add(leveled(roarCall(contour, length: 1.65, size: 0.72, raspRate: 26, &c.rng)), at: 0.32)
        return out
    }

    /// Dragon : un rugissement (≈ 110 → 175 → 105 Hz), puis le souffle de feu « fffhhhooo » :
    /// bruit rose dans une bande qui s'ouvre (≈ 0,5 → 2,7 kHz) et retombe, avec des crépitements.
    static func dragonRoar(_ c: inout Ctx) -> [Double] {
        let p = c.pitch
        let contour = Curve([(0, 110 * p), (0.3, 175 * p), (0.7, 160 * p), (1.0, 105 * p)])
        var out = leveled(roarCall(contour, length: 1.0, size: 0.85, raspRate: 40, &c.rng))
        let length = 1.25
        var flame = sweep(pinkNoise(length, &c.rng), .bandPass, q: 0.9) { t in (500 + 2200 * bump(t / length, 0.7)) * p }
        flame = flame.shaped { t in gate(t, length: length, rise: 0.15, fall: 0.7) }
        for t in poisson(&c.rng, from: 0.1, to: length - 0.2, rate: { _ in 45 }) {
            flame.add(highPass4(grain(&c.rng, decay: c.rng.range(0.0008, 0.002)), 1500), at: t, gain: c.rng.range(0.1, 0.3))
        }
        out.add(leveled(lowPass4(flame, 6000), rms: 0.22), at: 0.62)
        return out
    }

    /// Loup « aouuuu » : voix presque pure (triangle + un peu de dent de scie) qui monte
    /// ≈ 330 → 560 Hz, tient avec un vibrato lent, redescend à ≈ 400 Hz ; « a » qui se ferme en « ou ».
    static func howl(_ c: inout Ctx) -> [Double] {
        let length = 1.8, p = c.pitch
        let contour = Curve([(0, 330), (0.35, 560), (1.1, 530), (1.8, 400)])
        let f0: (Double) -> Double = { t in contour(t) * p * (1 + 0.012 * sin(2 * .pi * 5 * t) * smooth(t, 0.3, 0.6)) }
        let voice = osc(.triangle, length, f0).mixed(osc(.saw, length, f0), gain: 0.35)
        let source = voice.mixed(filter(pinkNoise(length, &c.rng), .bandPass, 1200, q: 0.8), gain: 0.05)
        // Formants LARGES : la voix monte à travers F1 — une résonance étroite ferait un « coup ».
        let wide: (Vowel) -> Vowel = { v in Vowels.scaled(v, 1.1).map { Formant($0.freq, $0.width * 4, $0.gain) } }
        let a = wide(Vowels.a), u = wide(Vowels.u)
        let call = formants(source) { t in blend(a, u, smooth(t, 0.1, 0.5)) }.mixed(voice, gain: 0.25)
        let amp = Curve([(0, 0), (0.25, 0.85), (0.5, 1), (1.3, 0.85), (1.8, 0)])
        return call.shaped { t in amp(t) }
    }

    // MARK: - La basse-cour

    /// Une syllabe d'oiseau de basse-cour : dent de scie (+ râpe éventuelle) dans des formants,
    /// la hauteur suit `pitch(t)`, et le petit « k » de la consonne au début.
    static func beakSyllable(_ length: Double, pitch: (Double) -> Double, vowel: (Double) -> Vowel,
                             rough: Double = 0, _ rng: inout Rng) -> [Double] {
        var source = osc(.saw, length, pitch).mixed(filter(whiteNoise(length, &rng), .bandPass, 2500, q: 1), gain: 0.12)
        if rough > 0 { source = times(source, rasp(length, rate: 55, depth: rough, &rng)) }
        var x = formants(source, vowel).shaped { t in
            gate(t, length: length, rise: 0.008, fall: Swift.min(0.05, length * 0.35))
        }
        x.add(highPass4(grain(&rng, decay: 0.0012), 1500), gain: 0.3)
        return x
    }

    /// Poule « cot cot cot codêêt » : trois « cot » brefs (≈ 430 Hz, « o » de petit oiseau),
    /// puis « co » et un « dêêt » plus haut (≈ 640 Hz) et long, qui retombe.
    static func cluck(_ c: inout Ctx) -> [Double] {
        let p = c.pitch
        let o = Vowels.scaled(Vowels.o, 1.5), e = Vowels.scaled(Vowels.e, 1.3)
        var out = silence(1.05)
        for (t, f) in [(0.0, 430.0), (0.17, 415), (0.34, 440)] {
            out.add(leveled(beakSyllable(0.075, pitch: { u in f * p * (1 - 1.6 * u) }, vowel: { _ in o }, &c.rng)),
                    at: t, gain: 0.8)
        }
        out.add(leveled(beakSyllable(0.07, pitch: { u in 470 * p * (1 + 0.7 * u) }, vowel: { _ in o }, &c.rng)),
                at: 0.55, gain: 0.75)
        let det = Curve([(0, 620), (0.08, 680), (0.36, 540)])
        out.add(leveled(beakSyllable(0.36, pitch: { u in det(u) * p * (1 + 0.015 * sin(2 * .pi * 9 * u)) },
                                     vowel: { _ in e }, &c.rng)), at: 0.66)
        return out
    }

    /// Coq « co-co-ri-cooo » : quatre syllabes qui MONTENT (≈ 520, 610, 750 Hz), la dernière
    /// longue, la plus haute (≈ 880 Hz) puis qui retombe (≈ 600 Hz) en se fermant « o → ou » ;
    /// un peu de râpe : un coq a la voix éraillée.
    static func crow(_ c: inout Ctx) -> [Double] {
        let p = c.pitch
        let o = Vowels.scaled(Vowels.o, 1.35), i = Vowels.scaled(Vowels.i, 1.35), u = Vowels.scaled(Vowels.u, 1.35)
        let syllables: [(at: Double, length: Double, pitch: Curve, vowel: (Double) -> Vowel)] = [
            (0.0, 0.11, Curve([(0, 500), (0.11, 540)]), { _ in o }),
            (0.15, 0.11, Curve([(0, 590), (0.11, 630)]), { _ in o }),
            (0.3, 0.13, Curve([(0, 720), (0.13, 780)]), { _ in i }),
            (0.48, 0.8, Curve([(0, 820), (0.15, 880), (0.45, 800), (0.8, 600)]), { t in blend(o, u, smooth(t, 0.3, 0.75)) }),
        ]
        var out = silence(1.3)
        for (k, s) in syllables.enumerated() {
            let call = beakSyllable(s.length, pitch: { t in s.pitch(t) * p * (1 + 0.01 * sin(2 * .pi * 6 * t)) },
                                    vowel: s.vowel, rough: 0.3, &c.rng)
            out.add(leveled(call), at: s.at, gain: [0.75, 0.8, 0.85, 1][k])
        }
        return out
    }

    /// Canard « coin-coin » : deux coups brefs, voix ≈ 250 Hz qui fléchit, GRÉSILLANTE (râpe
    /// ≈ 70 Hz), dans des formants nasaux hauts (≈ 1 / 1,65 kHz) — plus nasillard que l'oie.
    static func quack(_ c: inout Ctx) -> [Double] {
        let nasal: Vowel = [Formant(1000, 140, 1), Formant(1650, 170, 0.75), Formant(2600, 220, 0.35)]
        let length = 0.2
        var out = silence(0.6)
        for (t, f, amp) in [(0.0, 250.0, 1.0), (0.3, 235, 0.92)] {
            let pf = f * c.pitch
            let voice = osc(.saw, length) { u in pf * (1.05 - 0.15 * u / length) }
            let call = formants(times(voice, rasp(length, rate: 70, depth: 0.5, &c.rng))) { _ in nasal }
            out.add(call.shaped { u in
                let body = u < 0.012 ? u / 0.012 : exp(-(u - 0.012) / 0.09)
                return body * gate(u, length: length, rise: 0, fall: 0.03)
            }, at: t, gain: amp)
        }
        return out
    }

    // MARK: - Les animaux de la ferme et de la prairie

    /// Cheval (et zèbre) : hennissement — un « hiii » aigu (≈ 1 kHz) qui descend jusqu'à
    /// ≈ 420 Hz en TRILLE (≈ 11 battements/s, hauteur et force), voyelle i → è → a ; puis
    /// l'ébrouement « brrr » (souffle grave haché ≈ 28/s).
    static func neigh(_ c: inout Ctx) -> [Double] {
        let length = 1.2, p = c.pitch, trill = 11.0
        let base = Curve([(0, 650), (0.15, 1000), (0.35, 900), (1.05, 430), (1.2, 400)])
        let depth = Curve([(0, 0), (0.22, 0), (0.32, 0.07), (1.0, 0.09), (1.2, 0.04)])
        let f0: (Double) -> Double = { t in base(t) * p * (1 + depth(t) * sin(2 * .pi * trill * t)) }
        let source = osc(.saw, length, f0).mixed(filter(whiteNoise(length, &c.rng), .bandPass, 2500, q: 0.8), gain: 0.12)
        // Formants larges (comme le loup) : la voix descend à travers F1 sans « coup » de résonance.
        let wide: (Vowel) -> Vowel = { v in Vowels.scaled(v, 1.2).map { Formant($0.freq, $0.width * 3, $0.gain) } }
        let i = wide(Vowels.i), e = wide(Vowels.e), a = wide(Vowels.a)
        let call = formants(source) { t in t < 0.5 ? blend(i, e, smooth(t, 0.15, 0.5)) : blend(e, a, smooth(t, 0.5, 1.1)) }
        let tremolo = Curve([(0, 0), (0.25, 0), (0.35, 0.55), (1.1, 0.6)])
        let amp = Curve([(0, 0), (0.06, 1), (0.25, 1), (0.9, 0.8), (1.2, 0.55)])
        var out = call.shaped { t in
            amp(t) * gate(t, length: length, rise: 0.03, fall: 0.12)
                * (1 - tremolo(t) * (0.5 + 0.5 * cos(2 * .pi * trill * t)))
        }
        let snortLength = 0.3
        let snort = lowPass4(filter(pinkNoise(snortLength, &c.rng), .bandPass, 500 * p, q: 0.8), 1500)
        out.add(snort.shaped { t in
            gate(t, length: snortLength, rise: 0.03, fall: 0.12) * (0.55 + 0.45 * sin(2 * .pi * 28 * t))
        }, at: 1.15, gain: 0.5)
        return out
    }

    /// Grenouille « coâ-coâ » : deux coassements, voix grave (≈ 150 Hz) ROULÉE (gain qui pulse
    /// ≈ 32 fois par seconde, creux à 40 %), « o → a ».
    static func croak(_ c: inout Ctx) -> [Double] {
        let length = 0.3
        var out = silence(0.75)
        for (t, f, amp) in [(0.0, 150.0, 1.0), (0.42, 140, 0.9)] {
            let pf = f * c.pitch
            let voice = osc(.saw, length) { u in pf * (1 + 0.1 * smooth(u, 0, 0.1) - 0.15 * u / length) }
            let rolled = signal(length) { u in 1 - 0.6 * (0.5 + 0.5 * cos(2 * .pi * 32 * u)) }
            let source = times(voice, rolled).mixed(filter(pinkNoise(length, &c.rng), .lowPass, 1500), gain: 0.05)
            let o = Vowels.scaled(Vowels.o, 1.1), a = Vowels.scaled(Vowels.a, 1.1)
            let call = formants(source) { u in blend(o, a, smooth(u, 0.05, 0.2)) }
            out.add(call.shaped { u in gate(u, length: length, rise: 0.015, fall: 0.06) }, at: t, gain: amp)
        }
        return out
    }

    /// Mouton « bêêê » : « b » (murmure fermé) qui s'ouvre sur un « è » CHEVROTANT — hauteur
    /// (≈ 330 Hz, ± 3,5 %) et force qui tremblent ensemble ≈ 7 fois par seconde.
    static func baa(_ c: inout Ctx) -> [Double] {
        let length = 1.0, p = c.pitch, quaver = 7.0
        let contour = Curve([(0, 290), (0.12, 340), (0.7, 325), (1.0, 285)])
        let f0: (Double) -> Double = { t in
            contour(t) * p * (1 + 0.035 * sin(2 * .pi * quaver * t) * smooth(t, 0.08, 0.2))
        }
        let source = osc(.saw, length, f0).mixed(filter(whiteNoise(length, &c.rng), .bandPass, 2000, q: 0.7), gain: 0.06)
        let e = Vowels.scaled(Vowels.e, 1.15)
        let call = formants(source) { t in blend(Vowels.m, e, smooth(t, 0.02, 0.09)) }
        let amp = Curve([(0, 0), (0.06, 0.7), (0.2, 1), (0.75, 0.85), (1.0, 0)])
        return call.shaped { t in
            amp(t) * (1 - 0.45 * smooth(t, 0.1, 0.2) * (0.5 + 0.5 * sin(2 * .pi * quaver * t)))
        }
    }

    // MARK: - Les animaux de l'eau

    /// Phoque « ar-ar-ar » : trois aboiements courts et rapprochés, voix ≈ 330 Hz râpée, qui
    /// passent de « o » à une voyelle nasale (≈ 700 / 1150 Hz) — plus « klaxon » qu'un chien.
    static func sealBark(_ c: inout Ctx) -> [Double] {
        let nasal: Vowel = [Formant(700, 90, 1), Formant(1150, 120, 0.5), Formant(2500, 200, 0.25)]
        let length = 0.15
        var out = silence(0.7)
        for (k, (t, f)) in [(0.0, 330.0), (0.24, 345), (0.48, 315)].enumerated() {
            let pf = f * c.pitch
            let voice = osc(.saw, length) { u in pf * (0.85 + 0.3 * bump(u / length, 0.8)) }
            let source = times(voice, rasp(length, rate: 45, depth: 0.45, &c.rng))
            let call = formants(source) { u in blend(Vowels.o, nasal, smooth(u, 0, 0.05)) }
            out.add(call.shaped { u in
                let body = u < 0.01 ? u / 0.01 : exp(-(u - 0.01) / 0.07)
                return body * gate(u, length: length, rise: 0, fall: 0.03)
            }, at: t, gain: k == 1 ? 0.92 : 1)
        }
        return out
    }

    /// Dauphin : une rafale de clics qui ACCÉLÈRE (≈ 25 → 60 par seconde, chocs ≈ 2,6 / 4,3 kHz),
    /// puis trois sifflets « ii-ii-iii » qui montent (≈ 1,7 → 3,3 kHz), le dernier redescend,
    /// avec un trémolo de bavardage.
    static func dolphin(_ c: inout Ctx) -> [Double] {
        let p = c.pitch
        var out = silence(1.5)
        var t = 0.0, gap = 0.04
        while t < 0.36 {
            var click = modes([Partial(2600 * p, 0.0025, 1), Partial(4300 * p, 0.0015, 0.5)], 0.02, attack: 0.0002)
            click.add(filter(grain(&c.rng, decay: 0.0005), .bandPass, 3500, q: 1.5), gain: 0.6)
            out.add(click, at: t, gain: 0.9)
            t += gap
            gap = Swift.max(0.016, gap * 0.85)
        }
        let whistles: [(at: Double, length: Double, pitch: Curve)] = [
            (0.45, 0.22, Curve([(0, 1700), (0.22, 2900)])),
            (0.72, 0.22, Curve([(0, 1900), (0.22, 3100)])),
            (0.99, 0.48, Curve([(0, 2000), (0.2, 3300), (0.48, 2300)])),
        ]
        for w in whistles {
            let f: (Double) -> Double = { u in w.pitch(u) * p * (1 + 0.03 * sin(2 * .pi * 22 * u)) }
            let tone = osc(.sine, w.length, f).mixed(osc(.sine, w.length) { u in 2 * f(u) }, gain: 0.12)
            out.add(tone.shaped { u in gate(u, length: w.length, rise: 0.02, fall: 0.06) }, at: w.at, gain: 0.8)
        }
        return out
    }

    /// Crocodile : la mâchoire s'ouvre en grinçant (crans qui ralentissent, ≈ 700 Hz, discrets),
    /// puis « CLAC ! » — choc de bois creux (≈ 240 / 690 / 1580 / 2900 Hz) et dents ; deux fois.
    static func jawSnap(_ c: inout Ctx) -> [Double] {
        let p = c.pitch
        var out = silence(1.0)
        for (k, t) in [0.0, 0.45].enumerated() {
            var creak = silence(0.2)
            var u = 0.0, step = 0.012
            while u < 0.17 {
                creak.add(lowPass4(grain(&c.rng, decay: 0.0012), 1500), at: u, gain: c.rng.range(0.5, 1))
                u += step
                step *= 1.12
            }
            out.add(filter(creak, .bandPass, 700 * p, q: 2), at: t, gain: 1)
            var clac = modes([Partial(240 * p, 0.05, 0.7), Partial(690 * p, 0.035, 1), Partial(1580 * p, 0.018, 0.6),
                              Partial(2900 * p, 0.009, 0.35)], 0.3, attack: 0.0003)
            clac.add(highPass4(grain(&c.rng, decay: 0.0015), 2000), gain: 0.5)
            out.add(clac, at: t + 0.22, gain: k == 0 ? 1 : 0.95)
        }
        return out
    }

    // MARK: - Les petites bêtes qui ne crient pas

    /// Lapin : il grignote sa carotte — trois bouchées de trois petits craquements (nuées de
    /// grains ≈ 2,4–3,4 kHz sur un « toc » ≈ 900 Hz).
    static func nibble(_ c: inout Ctx) -> [Double] {
        let p = c.pitch
        var out = silence(0.95)
        for group in [0.0, 0.34, 0.68] {
            for (k, d) in [0.0, 0.075, 0.15].enumerated() {
                var bite = silence(0.04)
                for u in poisson(&c.rng, from: 0, to: 0.018, rate: { _ in 450 }) {
                    bite.add(grain(&c.rng, decay: c.rng.range(0.0005, 0.0015)), at: u, gain: c.rng.range(0.3, 1))
                }
                var x = lowPass4(filter(bite, .bandPass, c.rng.range(2400, 3400) * p, q: 1.1), 7000)
                x.add(modes([Partial(900 * p, 0.012, 0.5), Partial(1900 * p, 0.006, 0.3)], 0.06), gain: 0.6)
                out.add(x, at: group + d + c.rng.range(0, 0.008), gain: [1.0, 0.8, 0.9][k])
            }
        }
        return out
    }

    /// Araignée : huit petits pas pizzicato qui MONTENT la gamme pentatonique (do5 → mi6) —
    /// elle grimpe à son fil.
    static func tiptoe(_ c: inout Ctx) -> [Double] {
        let p = c.pitch
        let notes = [523.25, 587.33, 659.26, 783.99, 880.0, 1046.5, 1174.66, 1318.51]
        var out = silence(1.0)
        for (k, f) in notes.enumerated() {
            let pf = f * p
            var pluck = modes([Partial(pf, 0.035, 1), Partial(2 * pf, 0.016, 0.3), Partial(3 * pf, 0.008, 0.12)], 0.2,
                              attack: 0.001)
            pluck.add(highPass4(grain(&c.rng, decay: 0.0006), 2500), gain: 0.15)
            out.add(pluck, at: Double(k) * 0.11, gain: k % 2 == 0 ? 1 : 0.85)
        }
        return out
    }
}
