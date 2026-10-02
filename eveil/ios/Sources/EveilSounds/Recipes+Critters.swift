// Recipes+Critters.swift — les bestioles qu'on attrape, chacune avec SON bruit.
//
// Exemple fondateur (utilisateur, 25/09/2026) : pour « mouche », des mouches
// volent derrière le mot ; l'enfant en attrape une et entend « bzzz ». Plusieurs
// bestioles du même genre volent ensemble : la variante change un peu leur
// hauteur (et leur hasard), pour qu'elles ne sonnent pas toutes pareil. La
// note de musique (`ding`) suit une gamme pentatonique : jamais de fausse note,
// quel que soit l'ordre des captures.

import Foundation

extension Recipes {
    /// Mouche : dent de scie ≈ 180–240 Hz (205 Hz pour la variante 0) qui tourne (lente
    /// ondulation + vibrato), qui passe devant l'oreille (Doppler, volume en cloche), filtrée en
    /// bande pour le « zzz ».
    static func buzz(_ c: inout Ctx) -> [Double] {
        let length = 1.2
        let f0 = c.pick([205.0, 186, 228, 196, 216, 178, 240, 210])     // ≈ un ton d'écart entre voisines
        let wobble = c.rng.range(0, 2 * .pi)
        let pass = c.rng.range(0.45, 0.7)                     // instant où elle passe au plus près
        var x = osc(.saw, length) { t in
            let doppler = 1 + 0.035 * tanh((pass - t) * 5)
            let turn = 1 + 0.04 * sin(2 * .pi * 1.1 * t + wobble)
            let vibrato = 1 + 0.012 * sin(2 * .pi * 7 * t)
            return f0 * doppler * turn * vibrato
        }
        x = filter(x, .bandPass, 800, q: 0.7).mixed(filter(x, .bandPass, 1900, q: 2), gain: 0.35)
        x = lowPass4(x, 4000)
        return x.shaped { t in
            let near = exp(-pow((t - pass) / 0.33, 2))           // de loin → tout près → loin
            let flicker = 0.85 + 0.15 * sin(2 * .pi * 13 * t + wobble)
            return gate(t, length: length, rise: 0.06, fall: 0.12) * (0.25 + 0.75 * near) * flicker
        }
    }

    /// Abeille : plus aiguë (≈ 235–295 Hz) et plus RONDE — harmoniques aigus coupés, corps
    /// vers 520 Hz, vibrato lent ; vol sur place qui enfle et désenfle.
    static func beeBuzz(_ c: inout Ctx) -> [Double] {
        let length = 1.1
        let f0 = c.pick([262.0, 247, 280, 294, 236, 270])
        let phase = c.rng.range(0, 2 * .pi)
        var x = osc(.saw, length) { t in
            f0 * (1 + 0.02 * sin(2 * .pi * 4.5 * t + phase)) * (1 + 0.01 * sin(2 * .pi * 0.8 * t))
        }
        x = lowPass4(x, 1500)
        x = body(x, [(freq: 520, q: 2, gain: 0.8)])
        return x.shaped { t in
            gate(t, length: length, rise: 0.15, fall: 0.25) * (0.85 + 0.15 * sin(2 * .pi * 3.2 * t + phase))
        }
    }

    /// Oiseau « cui-cui » : 2 à 4 gazouillis sinusoïdaux rapides dans les 2–4 kHz, qui montent
    /// (« cui »), modulés en fréquence ; le dernier trille un peu.
    static func tweet(_ c: inout Ctx) -> [Double] {
        let chirps = c.pick([2, 3, 4, 2, 3])
        let base = c.pick([2800.0, 3100, 2600, 3300, 2950])
        let length = 0.085, period = 0.15
        var out = silence(Double(chirps) * period + 0.1)
        for k in 0..<chirps {
            let f = base * (1 + 0.04 * c.rng.bipolar())
            let last = k == chirps - 1
            let depth = last ? 0.06 : 0.025, rate = last ? 38.0 : 70.0
            let chirp = osc(.sine, length) { t in
                let u = t / length
                return f * (0.78 + 0.55 * u - 0.12 * u * u) * (1 + depth * sin(2 * .pi * rate * t))
            }
            out.add(chirp.shaped { t in bump(t / length, 0.7) }, at: Double(k) * period)
        }
        return out
    }

    /// Papillon : froufrou d'ailes — bruit rose doux (≈ 1 kHz) haché par des battements rapides
    /// (≈ 13 par seconde : coup d'aile vif, retombée douce). Volontairement DOUX.
    static func flutter(_ c: inout Ctx) -> [Double] {
        let length = 0.9
        let rate = 13 * c.pitch
        let jitter = c.rng.range(0, 6)
        let x = lowPass4(filter(pinkNoise(length, &c.rng), .bandPass, 1100, q: 0.8), 3500)
        return x.shaped { t in
            let beat = t * rate + 0.08 * sin(2 * .pi * 1.7 * t + jitter)
            let p = beat - beat.rounded(.down)
            let flap = p < 0.3 ? sin(.pi * p / 0.6) : exp(-(p - 0.3) * 7)
            return arch(t, length) * (0.25 + 0.75 * flap)
        }
    }

    /// Bulle qui éclate : minuscule clic, puis sinus qui monte très vite (« pop »).
    static func pop(_ c: inout Ctx) -> [Double] {
        let f0 = c.pick([520.0, 600, 470, 680, 560, 640])
        var out = osc(.sine, 0.2) { t in f0 * (1 + 1.6 * (1 - exp(-t / 0.02))) }
            .shaped { t in strike(t, attack: 0.001, decay: 0.035) }
        out.add(highPass4(grain(&c.rng, decay: 0.0008), 2000), gain: 0.3)
        return out
    }

    /// Goutte « plic » : petit sinus qui DESCEND vite (≈ 1,9 → 0,8 kHz), puis une gouttelette
    /// plus petite et plus aiguë qui rebondit.
    static func drip(_ c: inout Ctx) -> [Double] {
        func blip(_ high: Double, _ low: Double, _ decay: Double) -> [Double] {
            osc(.sine, decay * 7) { t in low + (high - low) * exp(-t / 0.018) }
                .shaped { t in strike(t, attack: 0.0015, decay: decay) }
        }
        var out = silence(0.35)
        out.add(blip(1900 * c.pitch, 800 * c.pitch, 0.045))
        out.add(blip(2600 * c.pitch, 1500 * c.pitch, 0.02), at: 0.11, gain: 0.3)
        return out
    }

    /// Note de musique : lame de métal douce (fondamental + un peu d'octave et de partiels de
    /// barre), hauteur selon la variante — voir `dingFrequency`.
    static func ding(_ c: inout Ctx) -> [Double] {
        let f = dingFrequency(c.variant)
        var out = modes([Partial(f, 0.55, 1), Partial(f * 2, 0.22, 0.12), Partial(f * 2.76, 0.12, 0.1),
                         Partial(f * 5.4, 0.05, 0.04)], 1.0, attack: 0.002)
        out.add(lowPass4(grain(&c.rng, decay: 0.001), 3000), gain: 0.1)      // le petit maillet
        return out
    }

    /// Gamme PENTATONIQUE (do ré mi sol la) sur trois octaves : variante 0 = do5, 1 = ré5 …
    /// 4 = la5, 5 = do6 … 9 = la6, 10 = do4 … 14 = la4, puis ça recommence (−1 = la4).
    static func dingFrequency(_ variant: Int) -> Double {
        let semitones = [0.0, 2, 4, 7, 9]
        let index = ((variant + 5) % 15 + 15) % 15            // 0…14 : do4 … la6
        let octave = Double(index / 5 - 1)
        return 523.2511 * pow(2, octave + semitones[index % 5] / 12)
    }

    /// Feu qui crépite : souffle doux des flammes (bruit brun sous 700 Hz, qui vacille) et
    /// crépitements épars (grains passés-haut, certains avec un petit « ping » aigu).
    static func crackle(_ c: inout Ctx) -> [Double] {
        let length = 1.0
        let flicker = c.rng.range(0, 6)
        var out = lowPass4(brownNoise(length, &c.rng), 700).shaped { t in
            0.35 * (0.7 + 0.3 * sin(2 * .pi * 2.3 * t + flicker) * sin(2 * .pi * 3.7 * t))
        }
        for t in poisson(&c.rng, from: 0.02, to: length - 0.05, rate: { _ in 22 }) {
            let amp = pow(c.rng.range(0.3, 1), 2)
            var snap = lowPass4(highPass4(grain(&c.rng, decay: c.rng.range(0.0006, 0.0015)), 1800), 6000)
            if c.rng.unit() < 0.4 { snap = snap.mixed(modes([Partial(c.rng.range(1500, 3500), 0.005, 0.4)], 0.03)) }
            out.add(snap, at: t, gain: amp)
        }
        return out.shaped { t in gate(t, length: length, rise: 0.06, fall: 0.15) }
    }

    /// Feuille morte froissée : trois gestes, chacun une nuée de micro-craquements (grains de
    /// 1–4 ms) dans une bande qui saute (≈ 2–3,5 kHz) — le « crounch » du papier sec.
    static func rustle(_ c: inout Ctx) -> [Double] {
        var out = silence(0.8)
        for (start, length, gain) in [(0.0, 0.2, 1.0), (0.26, 0.17, 0.75), (0.48, 0.24, 0.9)] {
            var cluster = silence(length)
            for t in poisson(&c.rng, from: 0, to: length, rate: { _ in 170 }) {
                cluster.add(grain(&c.rng, decay: c.rng.range(0.001, 0.004)), at: t, gain: c.rng.range(0.2, 1))
            }
            let centre = c.rng.range(2000, 3500), colour = c.rng.range(0, 6)
            cluster = sweep(cluster, .bandPass, q: 1.3) { t in centre * (1 + 0.4 * sin(2 * .pi * 17 * t + colour)) }
            out.add(cluster.shaped { t in gate(t, length: length, rise: 0.02, fall: 0.08) }, at: start, gain: gain)
        }
        return lowPass4(highPass4(out, 700), 7000)
    }

    /// Étoile magique : pluie de petites notes aiguës PENTATONIQUES (do6 → sol7) qui montent
    /// en s'éteignant — scintillement.
    static func sparkle(_ c: inout Ctx) -> [Double] {
        let scale = [1046.5, 1174.7, 1318.5, 1568.0, 1760.0, 2093.0, 2349.3, 2637.0, 3136.0]
        let count = 12
        var out = silence(1.1)
        for k in 0..<count {
            let t = 0.055 * Double(k) + c.rng.range(0, 0.02)
            let step = min(scale.count - 1, Int(Double(k) * 0.6) + Int(c.rng.range(0, 2.99)))
            let f = scale[step] * c.pitch
            let amp = (0.55 + 0.45 * c.rng.unit()) * (1 - 0.35 * Double(k) / Double(count))
            out.add(modes([Partial(f, 0.12, 1), Partial(f * 2, 0.04, 0.15)], 0.5, attack: 0.001), at: t, gain: amp)
        }
        return out
    }

    /// Plume qui passe : bruit rose dans une bande qui monte puis redescend (≈ 0,45 → 1,8 →
    /// 0,45 kHz), volume en arche. Volontairement DOUX.
    static func whooshSoft(_ c: inout Ctx) -> [Double] {
        let length = 0.9
        let p = c.pitch
        let x = sweep(pinkNoise(length, &c.rng), .bandPass, q: 1.3) { t in (450 + 1350 * bump(t / length, 2)) * p }
        return lowPass4(x, 4000).shaped { t in bump(t / length, 2) }
    }

    /// Goutte de peinture « splotch » : bruit mouillé dont le passe-bas se referme vite, un
    /// « poc » grave dessous, et quelques gouttelettes qui repartent.
    static func splat(_ c: inout Ctx) -> [Double] {
        let p = c.pitch
        var out = sweep(whiteNoise(0.4, &c.rng), .lowPass, q: 1.4) { t in (600 + 2400 * exp(-t / 0.05)) * p }
            .shaped { t in strike(t, attack: 0.002, decay: 0.07) }
        let thud = osc(.sine, 0.3) { t in (90 + 110 * exp(-t / 0.03)) * p }
        out.add(thud.shaped { t in strike(t, attack: 0.002, decay: 0.05) }, gain: 0.45)
        for _ in 0..<4 {
            let f = c.rng.range(700, 1400) * p
            let drop = osc(.sine, 0.12) { t in f * (1 + 0.5 * (1 - exp(-t / 0.01))) }
            out.add(drop.shaped { t in strike(t, attack: 0.001, decay: 0.02) },
                    at: c.rng.range(0.05, 0.25), gain: c.rng.range(0.15, 0.3))
        }
        return out
    }

    /// Cœur : bisou « mmm-smack » — un petit « mm » de lèvres serrées (voix nasale douce), puis
    /// les lèvres se décollent : « blip » qui monte (≈ 0,9 → 1,7 kHz), claquement bref vers
    /// 1,5 kHz et souffle d'air.
    static func kiss(_ c: inout Ctx) -> [Double] {
        let p = c.pitch
        var out = silence(0.32)
        let hum = osc(.saw, 0.09) { t in 240 * p * (1 + 0.1 * t / 0.09) }
        let lips = Vowels.scaled(Vowels.m, 1.3)
        out.add(formants(hum) { _ in lips }.shaped { t in gate(t, length: 0.09, rise: 0.025, fall: 0.015) }, gain: 0.35)
        let smack = 0.085
        let blip = osc(.sine, 0.08) { t in (900 + 800 * (1 - exp(-t / 0.008))) * p }
        out.add(blip.shaped { t in strike(t, attack: 0.001, decay: 0.02) }, at: smack, gain: 0.8)
        out.add(filter(grain(&c.rng, decay: 0.004), .bandPass, 1500 * p, q: 1), at: smack, gain: 0.5)
        let air = lowPass4(filter(pinkNoise(0.2, &c.rng), .bandPass, 2500, q: 0.7), 6000)
        out.add(air.shaped { t in strike(t, attack: 0.003, decay: 0.04) }, at: smack + 0.005, gain: 0.25)
        return out
    }

    /// Flocon : clochette de cristal qu'on agite — deux notes aiguës (si6, mi7) tintées en
    /// alternance rapide, de plus en plus doucement ; chaque note a sa jumelle désaccordée
    /// (battement ≈ 6 Hz) qui scintille.
    static func twinkle(_ c: inout Ctx) -> [Double] {
        let notes = [1975.5, 2637.0].map { $0 * c.pitch }
        var out = silence(1.0)
        for k in 0..<8 {
            let f = notes[k % 2], start = 0.065 * Double(k)
            let tinkle = modes([Partial(f, 0.25, 1), Partial(f + 6, 0.22, 0.6), Partial(f * 2.32, 0.05, 0.1)],
                               1.0 - start, attack: 0.001)
            out.add(tinkle, at: start + c.rng.range(0, 0.01), gain: pow(0.82, Double(k)))
        }
        return out
    }
}
