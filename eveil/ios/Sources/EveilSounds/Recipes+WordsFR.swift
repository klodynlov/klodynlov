// Recipes+WordsFR.swift — le bruit des objets des mots français.
//
// L'image du mot « fait son bruit » quand l'enfant la touche : la vache meugle,
// la saucisse grésille, le carrosse trotte. Bruitages de DESSIN ANIMÉ : on
// garde le trait qui fait reconnaître l'objet (la hauteur qui monte et descend
// du « miaou », les deux tons du « pin-pon », les chocs creux des sabots) et on
// arrondit tout le reste — jamais de grognement, de cri ou de fracas.
//
// Les graves sont doublés d'un « corps » à 200–600 Hz : les haut-parleurs d'un
// iPad ne descendent guère sous 150 Hz, et c'est ce corps qu'on entendra.

import Foundation

extension Recipes {
    /// Douche : jet continu (bruit rose ≈ 0,8–5 kHz, un peu irrégulier) et texture de gouttes
    /// (petits sinus qui montent, par dizaines) — de l'eau, pas un chuintement.
    static func shower(_ c: inout Ctx) -> [Double] {
        let length = 1.4
        let wobble = c.rng.range(0, 6)
        let spray = lowPass4(highPass4(pinkNoise(length, &c.rng), 800), 5000)
        var out = spray.shaped { t in 0.45 * (0.85 + 0.15 * sin(2 * .pi * 5.3 * t + wobble)) }
        for t in poisson(&c.rng, from: 0, to: length - 0.05, rate: { _ in 90 }) {
            let f = c.rng.logRange(900, 3200)
            let drop = osc(.sine, 0.03) { u in f * (1 + 0.35 * u / 0.03) }
            out.add(drop.shaped { u in strike(u, attack: 0.0008, decay: 0.007) }, at: t, gain: c.rng.range(0.08, 0.3))
        }
        return out.shaped { t in gate(t, length: length, rise: 0.12, fall: 0.25) }
    }

    /// Un aboiement : voix brève (dent de scie + souffle) qui passe de « ou » à « a » dans des
    /// formants de chien (F1 ≈ 750 Hz, F2 ≈ 1,3 kHz × `size`), attaque sèche, chute rapide.
    static func bark(_ f0: Double, length: Double, size: Double, _ rng: inout Rng) -> [Double] {
        let voice = osc(.saw, length) { t in f0 * (0.88 + 0.3 * sin(.pi * pow(min(t / length, 1), 0.7))) }
        let source = voice.mixed(filter(whiteNoise(length, &rng), .lowPass, 3000), gain: 0.35)
        let closed = Vowels.scaled(Vowels.u, size), open = Vowels.scaled(Vowels.a, size)
        return formants(source) { t in blend(closed, open, smooth(t, 0, 0.04)) }.shaped { t in
            let body = t < 0.008 ? t / 0.008 : exp(-(t - 0.008) / (length * 0.4))
            return body * gate(t, length: length, rise: 0, fall: 0.025)     // se tait avant la fin du tampon
        }
    }

    /// Niche : « ouaf ouaf » — deux aboiements de chien moyen (≈ 300 Hz), le second un peu plus
    /// grave. Pas de grognement.
    static func woof(_ c: inout Ctx) -> [Double] {
        let f = 300 * c.pitch
        var out = silence(0.7)
        out.add(bark(f, length: 0.17, size: 1, &c.rng))
        out.add(bark(f * 0.93, length: 0.19, size: 1, &c.rng), at: 0.3, gain: 0.95)
        return out
    }

    /// Caniche : petit « waf » aigu — deux jappements serrés (≈ 620 Hz, formants de petit chien).
    static func yap(_ c: inout Ctx) -> [Double] {
        let f = 620 * c.pitch
        var out = silence(0.4)
        out.add(bark(f, length: 0.09, size: 1.4, &c.rng))
        out.add(bark(f * 1.06, length: 0.08, size: 1.4, &c.rng), at: 0.16, gain: 0.85)
        return out
    }

    /// Vache « meuh » : dent de scie ≈ 100 → 85 Hz dans des formants ; attaque nasale (« m » :
    /// un formant grave, le reste étouffé) qui s'ouvre sur une voyelle ronde, puis « ou ».
    static func moo(_ c: inout Ctx) -> [Double] {
        let length = 1.25
        let p = c.pitch
        let contour = Curve([(0, 94), (0.2, 102), (0.7, 95), (1.25, 84)])
        let voice = osc(.saw, length) { t in contour(t) * p * (1 + 0.006 * sin(2 * .pi * 4.5 * t)) }
        let source = voice.mixed(filter(pinkNoise(length, &c.rng), .lowPass, 1500), gain: 0.08)
        let open = Vowels.o
        let call = formants(source) { t in
            if t < 0.15 { return Vowels.m }
            if t < 0.5 { return blend(Vowels.m, open, smooth(t, 0.15, 0.4)) }
            return blend(open, Vowels.u, smooth(t, 0.7, 1.2))
        }
        let amp = Curve([(0, 0), (0.12, 0.55), (0.35, 1), (0.95, 0.9), (1.25, 0)])
        return call.shaped { t in amp(t) }
    }

    /// Biche : petits bonds sur les feuilles — deux paires d'appuis légers, chacun un « toc »
    /// sourd (≈ 190/430 Hz) et un froissement de feuilles.
    static func hooves(_ c: inout Ctx) -> [Double] {
        let p = c.pitch
        var out = silence(1.0)
        for (t, amp) in [(0.0, 1.0), (0.085, 0.75), (0.43, 0.95), (0.515, 0.7)] {
            var hop = modes([Partial(190 * p, 0.03, 0.35), Partial(430 * p, 0.02, 0.5), Partial(960 * p, 0.01, 0.3)], 0.2)
            var leaves = silence(0.09)
            for u in poisson(&c.rng, from: 0, to: 0.07, rate: { _ in 260 }) {
                leaves.add(grain(&c.rng, decay: c.rng.range(0.0008, 0.003)), at: u, gain: c.rng.range(0.2, 1))
            }
            hop.add(lowPass4(filter(leaves, .bandPass, c.rng.range(2500, 3800), q: 0.9), 6500), gain: 0.7)
            out.add(hop, at: t + c.rng.range(0, 0.01), gain: amp)
        }
        return out
    }

    /// Tasse : porcelaine « tink » — partiels inharmoniques ≈ 2,35 / 3,45 / 4,9 kHz qui
    /// s'éteignent vite, deux jumeaux proches qui battent ; la cuillère rebondit une fois.
    static func clink(_ c: inout Ctx) -> [Double] {
        let f = 2350 * c.pitch
        func tink(_ rng: inout Rng) -> [Double] {
            var x = modes([Partial(f, 0.2, 1), Partial(f * 1.004, 0.18, 0.5), Partial(f * 1.47, 0.1, 0.45),
                           Partial(f * 2.09, 0.06, 0.3)], 0.7, attack: 0.0008)
            x.add(highPass4(grain(&rng, decay: 0.0006), 3000), gain: 0.25)
            return x
        }
        var out = tink(&c.rng)
        out.add(tink(&c.rng), at: 0.1, gain: 0.22)
        return out
    }

    /// Minouche « miaou » : hauteur 510 → 750 → 450 Hz, formants de petit chat qui glissent
    /// i → a → ou.
    static func meow(_ c: inout Ctx) -> [Double] {
        let length = 0.85
        let p = c.pitch
        let contour = Curve([(0, 510), (0.28, 750), (0.5, 700), (0.85, 450)])
        let voice = osc(.saw, length) { t in contour(t) * p * (1 + 0.012 * sin(2 * .pi * 6 * t)) }
        let source = voice.mixed(filter(whiteNoise(length, &c.rng), .bandPass, 2500, q: 0.7), gain: 0.04)
        let cat = 1.15
        let i = Vowels.scaled(Vowels.i, cat), a = Vowels.scaled(Vowels.a, cat), u = Vowels.scaled(Vowels.u, cat)
        let sung = formants(source) { t in t < 0.4 ? blend(i, a, smooth(t, 0.08, 0.3)) : blend(a, u, smooth(t, 0.5, 0.8)) }
        let amp = Curve([(0, 0), (0.06, 0.6), (0.3, 1), (0.6, 0.85), (0.85, 0)])
        return sung.shaped { t in amp(t) }
    }

    /// Saucisse dans la poêle : grésillement (bruit 3,2–8,5 kHz), crépitements serrés dont la
    /// densité ondule (la graisse qui saute) et bulles de graisse plus graves.
    static func sizzle(_ c: inout Ctx) -> [Double] {
        let length = 1.4
        let phase = c.rng.range(0, 6)
        var out = lowPass4(highPass4(whiteNoise(length, &c.rng), 3200), 8500).scaled(0.35)
        for t in poisson(&c.rng, from: 0, to: length - 0.02, rate: { t in 110 + 70 * sin(2 * .pi * 1.3 * t + phase) }) {
            out.add(highPass4(grain(&c.rng, decay: c.rng.range(0.0004, 0.0012)), 2500), at: t,
                    gain: pow(c.rng.range(0.2, 1), 2))
        }
        let fat = filter(whiteNoise(length, &c.rng), .bandPass, 1500, q: 1.2)
        out.add(fat.shaped { t in 0.12 * max(0, sin(2 * .pi * 23 * t) * sin(2 * .pi * 7.7 * t + phase)) })
        return lowPass4(out, 8500).shaped { t in gate(t, length: length, rise: 0.1, fall: 0.3) }
    }

    /// Trousse : fermeture éclair — cliquetis de dents qui ACCÉLÈRE (≈ 35 → 155 clics/s), un
    /// frottement dessous, et le petit « clac » du curseur qui arrive au bout.
    static func zipper(_ c: inout Ctx) -> [Double] {
        let run = 0.5
        let p = c.pitch
        var out = silence(0.65)
        var t = 0.0
        while t < run {
            let tooth = filter(grain(&c.rng, decay: 0.0007), .bandPass, 3200 * p, q: 1.5)
                .mixed(modes([Partial(1600 * p, 0.004, 0.25)], 0.02))
            out.add(tooth, at: t, gain: c.rng.range(0.6, 1))
            t += (1 / (35 + 120 * pow(t / run, 1.5))) * (1 + 0.08 * c.rng.bipolar())
        }
        let friction = filter(whiteNoise(run, &c.rng), .bandPass, 2500, q: 0.8)
        out.add(friction.shaped { t in 0.1 * (0.4 + 0.6 * t / run) * gate(t, length: run, rise: 0.03, fall: 0.03) })
        let stop = modes([Partial(900 * p, 0.02, 0.6), Partial(2100 * p, 0.01, 0.3)], 0.1)
        out.add(stop.mixed(filter(grain(&c.rng, decay: 0.001), .bandPass, 2500, q: 1)), at: run + 0.02, gain: 0.8)
        return out
    }

    /// Mousse : cascade de petites bulles — 18 « pops » de hauteurs variées, de plus en plus
    /// serrés, sur un léger chuintement de mousse.
    static func bubbles(_ c: inout Ctx) -> [Double] {
        var out = silence(1.1)
        for k in 0..<18 {
            let t = 0.95 * pow(Double(k) / 18, 0.8) + c.rng.range(0, 0.03)
            let f = c.rng.logRange(500, 1800) * c.pitch
            let decay = c.rng.range(0.012, 0.03)
            let bubble = osc(.sine, decay * 6) { u in f * (1 + 0.9 * (1 - exp(-u / 0.012))) }
            out.add(bubble.shaped { u in strike(u, attack: 0.001, decay: decay) }, at: t, gain: c.rng.range(0.3, 1))
        }
        out.add(filter(pinkNoise(1.0, &c.rng), .bandPass, 2500, q: 0.6).shaped { t in 0.04 * arch(t, 1.0) })
        return out
    }

    /// Pêche qui tombe « ploc » : résonance creuse ≈ 560 Hz (le « ploc » qu'on entend) sur un
    /// coup sourd (≈ 190 → 95 Hz), et un petit rebond.
    static func plop(_ c: inout Ctx) -> [Double] {
        let p = c.pitch
        func thud(_ rng: inout Rng) -> [Double] {
            var x = osc(.sine, 0.3) { t in (95 + 95 * exp(-t / 0.025)) * p }
                .shaped { t in strike(t, attack: 0.002, decay: 0.045) }
            x = x.scaled(0.55)
            x.add(modes([Partial(560 * p, 0.04, 1.1), Partial(1150 * p, 0.02, 0.35)], 0.25))
            x.add(lowPass4(grain(&rng, decay: 0.003), 1500), gain: 0.5)
            return x
        }
        var out = thud(&c.rng)
        out.add(thud(&c.rng), at: 0.17, gain: 0.3)
        return out
    }

    /// Os « croc-croc » : deux coups de dents, chacun une nuée serrée de craquements
    /// (≈ 1–3,5 kHz) sur un petit choc de mâchoire.
    static func crunch(_ c: inout Ctx) -> [Double] {
        let p = c.pitch
        var out = silence(0.7)
        for (start, gain) in [(0.0, 1.0), (0.32, 0.9)] {
            var bite = silence(0.14)
            for t in poisson(&c.rng, from: 0, to: 0.12, rate: { t in 320 * exp(-t / 0.08) }) {
                bite.add(grain(&c.rng, decay: c.rng.range(0.0006, 0.002)), at: t, gain: pow(c.rng.range(0.25, 1), 1.5))
            }
            let centre = c.rng.range(1500, 2500) * p
            bite = lowPass4(sweep(bite, .bandPass, q: 1.1) { t in centre * (1 + 0.5 * sin(2 * .pi * 11 * t)) }, 6000)
            bite.add(modes([Partial(150 * p, 0.03, 0.3), Partial(330 * p, 0.02, 0.3)], 0.15))
            out.add(bite, at: start, gain: gain)
        }
        return out
    }

    /// Police « pin-pon » : deux-tons français (≈ 580 / 435 Hz), 0,4 s chacun, deux fois ;
    /// timbre de trompe (sinus saturé, filtré), bascules de hauteur lissées sur 8 ms.
    static func siren(_ c: inout Ctx) -> [Double] {
        let high = 580 * c.pitch, low = 435 * c.pitch, note = 0.4
        let length = 4 * note
        var x = osc(.soft(drive: 2.5), length) { t in
            let k = Int(t / note)
            let target = k % 2 == 0 ? high : low
            guard k > 0 else { return target }
            let previous = k % 2 == 0 ? low : high
            return previous + (target - previous) * min((t - Double(k) * note) / 0.008, 1)
        }
        x = body(lowPass4(x, 1800), [(freq: 1100, q: 1.5, gain: 0.4)])
        return x.shaped { t in gate(t, length: length, rise: 0.02, fall: 0.06) }
    }

    /// Limace : glissade gluante — son grave qui tangue (dent de scie ≈ 150 Hz) et bruit
    /// mouillé, passés dans une résonance « wah » qui gargouille (≈ 0,35–1,2 kHz) ; trois
    /// « gloups ».
    static func slime(_ c: inout Ctx) -> [Double] {
        let length = 1.1
        let p = c.pitch
        let wobble = c.rng.range(0, 6)
        let tone = osc(.saw, length) { t in 150 * p * (1 + 0.25 * sin(2 * .pi * 3 * t)) }
        let source = tone.mixed(highPass4(pinkNoise(length, &c.rng), 250), gain: 0.8)
        let wah = sweep(source, .bandPass, q: 4) { t in
            (750 + 420 * sin(2 * .pi * 5.5 * t + 0.8 * sin(2 * .pi * 1.3 * t + wobble))) * p
        }
        let gloops = Curve([(0, 0), (0.12, 1), (0.3, 0.45), (0.45, 1), (0.62, 0.4), (0.78, 0.9), (1.1, 0)])
        return lowPass4(wah, 3000).shaped { t in gloops(t) }
    }

    /// Carrosse : sabots du cheval — chocs CREUX (la noix de coco du bruiteur) : résonances
    /// ≈ 1,3 kHz (« clip ») et ≈ 0,9 kHz (« clop ») en alternance, trot court-long, 6 pas.
    static func clipClop(_ c: inout Ctx) -> [Double] {
        var out = silence(1.05)
        for (k, t) in [0.0, 0.13, 0.36, 0.49, 0.72, 0.85].enumerated() {
            let f = (k % 2 == 0 ? 1300.0 : 900.0) * c.pitch * (1 + 0.02 * c.rng.bipolar())
            var knock = modes([Partial(f, 0.02, 1), Partial(f * 2.05, 0.008, 0.25), Partial(f * 0.5, 0.025, 0.35)], 0.15)
            knock.add(highPass4(grain(&c.rng, decay: 0.0008), 1000), gain: 0.25)
            out.add(knock, at: t, gain: (k % 2 == 0 ? 1 : 0.85) * c.rng.range(0.9, 1))
        }
        return out
    }

    /// Cactus : maracas — secousses de graines (nuée dense de micro-impacts, bande ≈ 3–8 kHz),
    /// rythme « tch-tch-tchi-tchaa ».
    static func maracas(_ c: inout Ctx) -> [Double] {
        var out = silence(0.9)
        for (start, length) in [(0.0, 0.11), (0.2, 0.11), (0.4, 0.09), (0.52, 0.25)] {
            var shake = silence(length)
            for t in poisson(&c.rng, from: 0, to: length, rate: { _ in 1400 }) {
                shake.add(grain(&c.rng, decay: 0.0004), at: t, gain: c.rng.range(0.1, 1))
            }
            shake = lowPass4(filter(shake, .bandPass, 5000 * c.pitch, q: 1.1), 8500)
            out.add(shake.shaped { t in strike(t, attack: 0.004, decay: length * 0.45) }, at: start)
        }
        return out
    }

    /// Cloche « ding-dong » : deux cloches de bronze à tierce MAJEURE (plus gaie que la tierce
    /// mineure des églises) ; « ding » (mi5) puis « dong » (si4).
    static func bell(_ c: inout Ctx) -> [Double] {
        var out = silence(2.2)
        out.add(bronze(nominal: 659.3 * c.pitch, length: 2.0, &c.rng))
        out.add(bronze(nominal: 493.9 * c.pitch, length: 1.6, &c.rng), at: 0.6, gain: 0.95)
        return out.shaped { t in t < 1.8 ? 1 : max(0, 1 - (t - 1.8) / 0.4) }
    }

    /// Une cloche : partiels hum / prime / tierce / quinte / nominal / … (rapports d'une cloche
    /// accordée), chacun sa durée de vie ; on entend la note du « nominal ».
    static func bronze(nominal: Double, length: Double, _ rng: inout Rng) -> [Double] {
        let prime = nominal / 2
        var x = modes([
            Partial(prime * 0.5, 1.2, 0.12),    // hum (discret : une cloche gaie, pas un glas)
            Partial(prime, 0.9, 0.45),          // prime
            Partial(prime * 1.25, 0.7, 0.3),    // tierce (majeure)
            Partial(prime * 1.5, 0.5, 0.2),     // quinte
            Partial(prime * 2, 0.8, 0.6),       // nominal
            Partial(prime * 2.5, 0.3, 0.15),
            Partial(prime * 3, 0.25, 0.12),
            Partial(prime * 4.2, 0.15, 0.07),
        ], length, attack: 0.002)
        x.add(filter(grain(&rng, decay: 0.002), .bandPass, 2500, q: 0.8), gain: 0.2)   // le battant
        return x
    }

    /// Glace : coup de langue « slurp » — bruit mouillé dans deux formants qui MONTENT (la
    /// langue remonte), et le petit « tsk » de la langue à la fin.
    static func lick(_ c: inout Ctx) -> [Double] {
        let p = c.pitch
        let length = 0.4
        let noise = pinkNoise(length, &c.rng).mixed(whiteNoise(length, &c.rng), gain: 0.3)
        let rise: (Double) -> Double = { t in pow(min(t / 0.32, 1), 0.8) }
        let f1 = sweep(noise, .bandPass, q: 4) { t in (700 + 1500 * rise(t)) * p }
        let f2 = sweep(noise, .bandPass, q: 4) { t in (1500 + 2200 * rise(t)) * p }
        var out = f1.mixed(f2, gain: -0.5).shaped { t in
            gate(t, length: 0.34, rise: 0.03, fall: 0.12) * (0.75 + 0.25 * sin(2 * .pi * 28 * t))
        }
        out.add(modes([Partial(1800 * p, 0.006, 0.2), Partial(3100 * p, 0.003, 0.08)], 0.05), at: 0.34)
        return out
    }

    /// Flèche « fffuit… toc ! » : souffle qui monte en sifflant (bande ≈ 0,5 → 2,8 kHz), choc de
    /// bois dans la cible, et la flèche qui vibre un instant (« boïng » doux).
    static func arrow(_ c: inout Ctx) -> [Double] {
        let fly = 0.32
        let p = c.pitch
        var out = sweep(pinkNoise(fly, &c.rng), .bandPass, q: 2.2) { t in (500 + 2300 * pow(t / fly, 1.5)) * p }
            .shaped { t in 3 * pow(min(t / fly, 1), 1.5) * gate(t, length: fly, rise: 0.02, fall: 0.01) }
        var toc = modes([Partial(720 * p, 0.03, 1), Partial(1500 * p, 0.015, 0.4), Partial(310 * p, 0.04, 0.5)], 0.25)
        toc.add(lowPass4(grain(&c.rng, decay: 0.001), 3000), gain: 0.5)
        out.add(toc, at: fly)
        let twang = osc(.triangle, 0.5) { t in 190 * p * (1 + 0.04 * sin(2 * .pi * 22 * t)) }
            .shaped { t in strike(t, attack: 0.005, decay: 0.15) * (0.6 + 0.4 * sin(2 * .pi * 22 * t)) }
        out.add(lowPass4(twang, 1200), at: fly + 0.01, gain: 0.3)
        return out
    }

    /// Brosse : frotte-frotte — quatre passages de poils (nuée de grains, bande ≈ 2,6–3,6 kHz),
    /// l'aller plus brillant que le retour.
    static func brushing(_ c: inout Ctx) -> [Double] {
        let length = 0.2
        var out = silence(0.95)
        for k in 0..<4 {
            let forth = k % 2 == 0
            var stroke = silence(length)
            for t in poisson(&c.rng, from: 0, to: length, rate: { _ in 900 }) {
                stroke.add(grain(&c.rng, decay: 0.0006), at: t, gain: c.rng.range(0.2, 1))
            }
            stroke = lowPass4(filter(stroke, .bandPass, (forth ? 3600 : 2600) * c.pitch, q: 0.9), 7000)
            out.add(stroke.shaped { t in bump(t / length, 1.5) }, at: 0.23 * Double(k), gain: forth ? 1 : 0.8)
        }
        return out
    }

    /// Autruche : grandes enjambées « boum boum » — coups sourds 150 → 60 Hz (le sol), doublés
    /// d'un « toum » de corps (≈ 180–420 Hz, c'est lui qu'un iPad fait entendre), d'un bruit
    /// d'appui et d'un peu de poussière.
    static func footsteps(_ c: inout Ctx) -> [Double] {
        var out = silence(1.05)
        for (k, t) in [0.0, 0.46].enumerated() {
            let p = c.pitch * (k == 0 ? 1 : 0.94)
            let drop: (Double) -> Double = { u in (60 + 90 * exp(-u / 0.05)) * p }
            var step = osc(.sine, 0.5, drop).shaped { u in strike(u, attack: 0.004, decay: 0.12) }.scaled(0.7)
            let upper = osc(.sine, 0.4) { u in 2.6 * drop(u) }
            step.add(upper.shaped { u in strike(u, attack: 0.004, decay: 0.09) }, gain: 0.7)
            step.add(modes([Partial(180 * p, 0.06, 0.55), Partial(420 * p, 0.04, 0.5)], 0.3))
            step.add(lowPass4(grain(&c.rng, decay: 0.008), 1200), gain: 0.8)
            let dust = lowPass4(filter(whiteNoise(0.15, &c.rng), .bandPass, 1800, q: 0.7), 5000)
            step.add(dust.shaped { u in strike(u, attack: 0.01, decay: 0.04) }, gain: 0.08)
            out.add(step, at: t, gain: k == 0 ? 1 : 0.92)
        }
        return out
    }
}
