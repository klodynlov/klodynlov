// SoundSynth.swift — synthèse des bruitages (Swift pur, testable sur Mac).
//
// Chaque effet a sa RECETTE (fichiers `Recipes+…`), écrite avec la boîte à
// outils `DSPKit` ; puis tout passe par la même chaîne de « mastering », pour
// que les sons soient homogènes dans le jeu :
//
//   1. passe-haut 40 Hz (continu, infra-grave inutile) et passe-bas 10 kHz
//      d'ordre 4 : rien d'agressif dans l'extrême aigu (oreilles de 3 ans) ;
//   2. queue silencieuse coupée, 2,5 s au plus ;
//   3. SONIE égalisée : chaque effet est amené au même niveau perçu — mesure
//      « active » pondérée K (UIT-R BS.1770, comme les LUFS), fenêtres de
//      100 ms, seules comptent les fenêtres à moins de 20 dB de la plus forte
//      (le silence entre deux « ouaf » ne dilue pas la mesure). Les effets
//      volontairement doux (`whooshSoft`, `flutter`) sont posés plus bas ;
//   4. limiteur à anticipation (crête ≤ 0,89, gain lissé sur ~2 ms : pas de
//      distorsion audible) ;
//   5. fondus d'entrée (4 ms) et de sortie (12 ms) : jamais de clic.
//
// Tout est déterministe : le hasard des recettes vient d'un SplitMix64 dont la
// graine dépend du nom de l'effet et de la variante.

import Foundation

public enum SoundSynth {
    public static let sampleRate = 44_100.0

    /// L'effet en mono, échantillons dans [-1, 1]. `variant` fait varier la hauteur
    /// (notes de musique, bestioles qui ne chantent pas toutes pareil). Déterministe.
    public static func render(_ effect: SoundEffect, variant: Int = 0) -> [Float] {
        var context = Ctx(variant: variant, seed: stableSeed(effect.rawValue, variant: variant))
        return master(recipe(effect, &context), offset: levelOffset(effect))
    }

    /// Sonie visée (dB, mesure `loudness`) : même niveau perçu pour tous les effets.
    static let targetLoudness = -20.0
    /// Plafond de crête après limitation (le contrat demande ≤ 0,9).
    static let ceiling = 0.89
    /// Durée maximale d'un effet.
    static let maxDuration = 2.5

    /// Écart de niveau voulu (dB) : les effets « doux » restent doux.
    static func levelOffset(_ effect: SoundEffect) -> Double {
        switch effect {
        case .whooshSoft, .flutter: return -7
        default: return 0
        }
    }

    static func recipe(_ effect: SoundEffect, _ c: inout Ctx) -> [Double] {
        switch effect {
        case .whistle: return Recipes.whistle(&c)
        case .steam: return Recipes.steam(&c)
        case .hiss: return Recipes.hiss(&c)
        case .chime: return Recipes.chime(&c)
        case .buzz: return Recipes.buzz(&c)
        case .beeBuzz: return Recipes.beeBuzz(&c)
        case .tweet: return Recipes.tweet(&c)
        case .flutter: return Recipes.flutter(&c)
        case .pop: return Recipes.pop(&c)
        case .drip: return Recipes.drip(&c)
        case .ding: return Recipes.ding(&c)
        case .crackle: return Recipes.crackle(&c)
        case .rustle: return Recipes.rustle(&c)
        case .sparkle: return Recipes.sparkle(&c)
        case .whooshSoft: return Recipes.whooshSoft(&c)
        case .splat: return Recipes.splat(&c)
        case .kiss: return Recipes.kiss(&c)
        case .twinkle: return Recipes.twinkle(&c)
        case .shower: return Recipes.shower(&c)
        case .woof: return Recipes.woof(&c)
        case .moo: return Recipes.moo(&c)
        case .hooves: return Recipes.hooves(&c)
        case .clink: return Recipes.clink(&c)
        case .meow: return Recipes.meow(&c)
        case .sizzle: return Recipes.sizzle(&c)
        case .zipper: return Recipes.zipper(&c)
        case .bubbles: return Recipes.bubbles(&c)
        case .plop: return Recipes.plop(&c)
        case .crunch: return Recipes.crunch(&c)
        case .siren: return Recipes.siren(&c)
        case .yap: return Recipes.yap(&c)
        case .slime: return Recipes.slime(&c)
        case .clipClop: return Recipes.clipClop(&c)
        case .maracas: return Recipes.maracas(&c)
        case .bell: return Recipes.bell(&c)
        case .lick: return Recipes.lick(&c)
        case .arrow: return Recipes.arrow(&c)
        case .brushing: return Recipes.brushing(&c)
        case .footsteps: return Recipes.footsteps(&c)
        case .blub: return Recipes.blub(&c)
        case .scrape: return Recipes.scrape(&c)
        case .water: return Recipes.water(&c)
        case .honk: return Recipes.honk(&c)
        case .bellow: return Recipes.bellow(&c)
        case .iceClink: return Recipes.iceClink(&c)
        case .click: return Recipes.click(&c)
        case .horn: return Recipes.horn(&c)
        case .pok: return Recipes.pok(&c)
        case .squeak: return Recipes.squeak(&c)
        case .slurp: return Recipes.slurp(&c)
        case .doorbell: return Recipes.doorbell(&c)
        case .fanfare: return Recipes.fanfare(&c)
        case .splash: return Recipes.splash(&c)
        }
    }

    // MARK: - Mastering

    static func master(_ raw: [Double], offset: Double) -> [Float] {
        var x = filter(raw, .highPass, 40)
        x = lowPass4(x, 10_000)
        x = cappedAndTrimmed(x)
        let level = loudness(x)
        if level.isFinite { x = x.scaled(pow(10, (targetLoudness + offset - level) / 20)) }
        x = limited(x, ceiling: ceiling)
        fadeEdges(&x, fadeIn: 0.004, fadeOut: 0.012)
        return x.map { Float($0) }
    }

    /// Sonie « active » (dB) : pondération K de l'UIT-R BS.1770 (plateau +4 dB au-dessus
    /// de ~1,7 kHz, coupe des infra-graves), puis `activeLevel`.
    static func loudness(_ x: [Double]) -> Double {
        var shelf = Biquad.highShelf(1681.97, gainDB: 4, q: 0.7072)
        var rumble = Biquad.highPass(38.135, q: 0.5003)
        var weighted = x
        for i in x.indices { weighted[i] = rumble.tick(shelf.tick(x[i])) }
        return activeLevel(weighted)
    }

    /// Niveau des passages ACTIFS (dB RMS) : énergie par fenêtres de 100 ms (pas de 25 ms) ;
    /// on ne garde que les fenêtres à moins de 20 dB de la plus forte. Un son plus court
    /// qu'une fenêtre compte pour ce qu'il est (complété de silence) : l'oreille intègre
    /// l'énergie sur ~100 ms, un clic isolé paraît moins fort qu'un son tenu.
    static func activeLevel(_ x: [Double]) -> Double {
        guard !x.isEmpty else { return -.infinity }
        let window = frames(0.1), hop = frames(0.025)
        var energies: [Double] = []
        var start = 0
        repeat {
            let end = Swift.min(start + window, x.count)
            var sum = 0.0
            for i in start..<end { sum += x[i] * x[i] }
            energies.append(sum / Double(window))
            start += hop
        } while start + window <= x.count
        let loudest = energies.max() ?? 0
        guard loudest > 0 else { return -.infinity }
        let kept = energies.filter { $0 >= loudest * 0.01 }
        return 10 * log10(kept.reduce(0, +) / Double(kept.count))
    }

    /// Coupe la queue sous −60 dB de la crête (en gardant 10 ms) et borne à `maxDuration`.
    static func cappedAndTrimmed(_ x: [Double]) -> [Double] {
        var y = x
        let floor = y.peak * 0.001
        if floor > 0, let last = y.lastIndex(where: { abs($0) > floor }) {
            y = Array(y[0..<Swift.min(y.count, Swift.max(last + frames(0.01), frames(0.06)))])
        }
        let limit = frames(maxDuration)
        if y.count > limit {
            y = Array(y[0..<limit])
            let fade = frames(0.08)
            for i in 0..<fade { y[limit - 1 - i] *= Double(i) / Double(fade) }
        }
        return y
    }

    /// Limiteur à anticipation : gain requis par échantillon, minimum glissant sur ±2 ms,
    /// puis moyenne glissante sur ±1 ms. Toute fenêtre de moyenne autour d'une crête ne
    /// contient que des gains ≤ celui qu'exige cette crête : le plafond est GARANTI, et le
    /// gain varie en douceur (pas de distorsion audible).
    static func limited(_ x: [Double], ceiling: Double) -> [Double] {
        let n = x.count
        var need = [Double](repeating: 1, count: n)
        var over = false
        for i in 0..<n where abs(x[i]) > ceiling {
            need[i] = ceiling / abs(x[i])
            over = true
        }
        guard over else { return x }
        let reach = frames(0.002), half = reach / 2
        var hold = need
        for i in 0..<n where need[i] < 1 {
            for j in Swift.max(0, i - reach)...Swift.min(n - 1, i + reach) { hold[j] = Swift.min(hold[j], need[i]) }
        }
        var sums = [Double](repeating: 0, count: n + 1)
        for i in 0..<n { sums[i + 1] = sums[i] + hold[i] }
        var y = x
        for i in 0..<n {
            let lo = Swift.max(0, i - half), hi = Swift.min(n - 1, i + half)
            y[i] *= (sums[hi + 1] - sums[lo]) / Double(hi - lo + 1)
        }
        return y
    }

    /// Fondus en cosinus aux deux bouts : le premier et le dernier échantillon valent 0.
    static func fadeEdges(_ x: inout [Double], fadeIn: Double, fadeOut: Double) {
        let a = Swift.min(frames(fadeIn), x.count / 2), b = Swift.min(frames(fadeOut), x.count / 2)
        for i in 0..<a { x[i] *= 0.5 - 0.5 * cos(.pi * Double(i) / Double(a)) }
        for i in 0..<b { x[x.count - 1 - i] *= 0.5 - 0.5 * cos(.pi * Double(i) / Double(b)) }
    }
}

/// Ce que reçoit chaque recette : la variante et son hasard.
struct Ctx {
    let variant: Int
    var rng: Rng

    init(variant: Int, seed: UInt64) {
        self.variant = variant
        rng = Rng(seed: seed)
    }

    /// Choix cyclique selon la variante : la variante 0 prend le premier.
    func pick<T>(_ options: [T]) -> T {
        let n = options.count
        return options[((variant % n) + n) % n]
    }

    /// Petit décalage de hauteur propre à la variante (1 pour la variante 0, sinon quelques
    /// pour cent : deux bestioles du même genre ne sonnent pas pareil).
    var pitch: Double { pick([1.0, 1.06, 0.95, 1.12, 0.9, 1.03, 0.97]) }
}

/// Les recettes, rangées par famille dans les fichiers `Recipes+…`.
enum Recipes {}
