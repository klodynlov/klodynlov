// DSPKit.swift — la petite boîte à outils de synthèse des bruitages.
//
// Swift pur, sans AVFoundation : testable sur Mac, rendu identique partout.
// Tout se calcule en Double (les filtres graves restent stables), en mono, à
// `SoundSynth.sampleRate` ; `SoundSynth` ne convertit en Float qu'à la fin.
//
// Choix, du plus fondamental au plus « recette » :
// - hasard DÉTERMINISTE : SplitMix64, graine tirée du nom de l'effet (FNV-1a,
//   car `String.hashValue` change à chaque lancement). Même effet, même son ;
// - oscillateurs à phase accumulée : la fréquence peut glisser à chaque
//   échantillon (miaou, meuh, sirène) sans clic ; dent de scie corrigée
//   PolyBLEP (pas d'harmoniques repliées en aigus parasites), carré « doux »
//   par saturation d'un sinus (sirène, klaxon) ;
// - bruits blanc, rose (filtre de Kellet) et brun ;
// - filtres « SVF » trapézoïdaux (Zavalishin, formulation d'A. Simper) :
//   passe-bas, bande et haut d'un même filtre, STABLES même quand
//   la coupure bouge vite (balayages, formants, « wah ») ;
// - biquads RBJ pour les plateaux (pondération de sonie de `SoundSynth`) ;
// - synthèse MODALE : un choc = une somme de sinusoïdes amorties ; les rapports
//   de fréquences et les durées de vie font la matière (bois, porcelaine,
//   bronze, verre) ;
// - banc de FORMANTS parallèle : une source (dent de scie + souffle) passe dans
//   des résonances de voyelle qui glissent (meuh, miaou, ouaf, honk) ;
// - enveloppes (attaque douce, décroissance exponentielle, courbes par
//   points), écho court et résonance de caisse.

import Foundation

/// Fréquence d'échantillonnage de toute la synthèse (Hz).
let fs = SoundSynth.sampleRate

// MARK: - Hasard déterministe

/// SplitMix64 (Steele, Lea & Flood, 2014) : minuscule, rapide, bien mélangé — et
/// identique sur toutes les machines, contrairement au générateur du système.
struct Rng {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// Uniforme dans [0, 1).
    mutating func unit() -> Double { Double(next() >> 11) * 0x1p-53 }

    /// Uniforme dans [lo, hi).
    mutating func range(_ lo: Double, _ hi: Double) -> Double { lo + (hi - lo) * unit() }

    /// Uniforme dans [-1, 1).
    mutating func bipolar() -> Double { 2 * unit() - 1 }

    /// Log-uniforme dans [lo, hi) : autant de graves que d'aigus, à l'oreille.
    mutating func logRange(_ lo: Double, _ hi: Double) -> Double { lo * pow(hi / lo, unit()) }
}

/// Graine stable : FNV-1a du nom de l'effet, mêlée à la variante.
func stableSeed(_ name: String, variant: Int) -> UInt64 {
    var hash: UInt64 = 0xCBF2_9CE4_8422_2325
    for byte in name.utf8 { hash = (hash ^ UInt64(byte)) &* 0x0000_0100_0000_01B3 }
    return hash ^ (UInt64(bitPattern: Int64(variant)) &* 0x9E37_79B9_7F4A_7C15)
}

// MARK: - Temps et pistes

/// Nombre d'échantillons dans `seconds`.
@inline(__always) func frames(_ seconds: Double) -> Int { max(0, Int((seconds * fs).rounded())) }

/// `seconds` de silence.
func silence(_ seconds: Double) -> [Double] { [Double](repeating: 0, count: frames(seconds)) }

/// Échantillonne `f(t)` (t en secondes) pendant `seconds`.
func signal(_ seconds: Double, _ f: (Double) -> Double) -> [Double] {
    let n = frames(seconds)
    var out = [Double](repeating: 0, count: n)
    for i in 0..<n { out[i] = f(Double(i) / fs) }
    return out
}

extension Array where Element == Double {
    /// Pose `other` à l'instant `at` (s), multiplié par `gain` ; la piste s'allonge au besoin.
    /// La fin du morceau posé passe par un fondu de 3 ms : un son coupé net, même presque
    /// éteint, ferait un petit clic au milieu du bruitage.
    mutating func add(_ other: [Double], at seconds: Double = 0, gain: Double = 1) {
        let offset = frames(seconds)
        let end = offset + other.count
        if end > count { append(contentsOf: repeatElement(0.0, count: end - count)) }
        let fade = Swift.min(frames(0.003), other.count / 4)
        for i in other.indices {
            let left = other.count - 1 - i
            let g = left < fade ? 0.5 - 0.5 * cos(.pi * Double(left) / Double(fade)) : 1
            self[offset + i] += gain * g * other[i]
        }
    }

    /// Multiplié, échantillon par échantillon, par l'enveloppe `env(t)`.
    func shaped(_ env: (Double) -> Double) -> [Double] {
        var out = self
        for i in out.indices { out[i] *= env(Double(i) / fs) }
        return out
    }

    /// Multiplié par un gain constant.
    func scaled(_ gain: Double) -> [Double] { map { $0 * gain } }

    /// Additionné à `other` (la plus longue des deux donne la durée).
    func mixed(_ other: [Double], gain: Double = 1) -> [Double] {
        var out = self
        out.add(other, gain: gain)
        return out
    }

    /// Plus grande valeur absolue.
    var peak: Double { reduce(0) { Swift.max($0, abs($1)) } }
}

// MARK: - Oscillateurs

enum Wave {
    /// Sinus pur (sifflets, gouttes, notes).
    case sine
    /// Dent de scie PolyBLEP : riche en harmoniques (voix, bourdonnements, cuivres).
    case saw
    /// Triangle : doux, peu d'harmoniques.
    case triangle
    /// Sinus saturé (tanh) : un carré « arrondi », timbre de trompe (sirène, klaxon).
    case soft(drive: Double)
}

/// Correction PolyBLEP d'une discontinuité (Välimäki & Huovilainen) : adoucit le saut
/// sur un échantillon de part et d'autre, ce qui supprime l'essentiel du repliement.
@inline(__always) private func polyBlep(_ t: Double, _ dt: Double) -> Double {
    if t < dt {
        let x = t / dt
        return x + x - x * x - 1
    }
    if t > 1 - dt {
        let x = (t - 1) / dt
        return x * x + x + x + 1
    }
    return 0
}

/// Oscillateur dont la fréquence `freq(t)` (Hz) est lue à chaque échantillon.
func osc(_ wave: Wave, _ seconds: Double, phase: Double = 0, _ freq: (Double) -> Double) -> [Double] {
    let n = frames(seconds)
    var out = [Double](repeating: 0, count: n)
    var ph = phase - phase.rounded(.down)
    for i in 0..<n {
        let dt = Swift.min(Swift.max(freq(Double(i) / fs) / fs, 0), 0.45)
        switch wave {
        case .sine:
            out[i] = sin(2 * .pi * ph)
        case .saw:
            out[i] = 2 * ph - 1 - polyBlep(ph, dt)
        case .triangle:
            out[i] = 1 - 4 * abs(ph - 0.5)
        case let .soft(drive):
            out[i] = tanh(drive * sin(2 * .pi * ph)) / tanh(drive)
        }
        ph += dt
        if ph >= 1 { ph -= 1 }
    }
    return out
}

// MARK: - Bruits

/// Bruit blanc uniforme dans [-1, 1).
func whiteNoise(_ seconds: Double, _ rng: inout Rng) -> [Double] {
    let n = frames(seconds)
    var out = [Double](repeating: 0, count: n)
    for i in 0..<n { out[i] = rng.bipolar() }
    return out
}

/// Bruit rose (−3 dB/octave), filtre « raffiné » de Paul Kellet : doux, « naturel ».
func pinkNoise(_ seconds: Double, _ rng: inout Rng) -> [Double] {
    let n = frames(seconds)
    var out = [Double](repeating: 0, count: n)
    var b0 = 0.0, b1 = 0.0, b2 = 0.0, b3 = 0.0, b4 = 0.0, b5 = 0.0, b6 = 0.0
    for i in 0..<n {
        let w = rng.bipolar()
        b0 = 0.99886 * b0 + w * 0.0555179
        b1 = 0.99332 * b1 + w * 0.0750759
        b2 = 0.96900 * b2 + w * 0.1538520
        b3 = 0.86650 * b3 + w * 0.3104856
        b4 = 0.55000 * b4 + w * 0.5329522
        b5 = -0.7616 * b5 - w * 0.0168980
        let low = b0 + b1 + b2
        let high = b3 + b4 + b5 + b6
        out[i] = (low + high + w * 0.5362) * 0.2
        b6 = w * 0.115926
    }
    return out
}

/// Bruit brun (−6 dB/octave) : grondement, flammes, eau profonde. Crête ramenée à 1.
func brownNoise(_ seconds: Double, _ rng: inout Rng) -> [Double] {
    let n = frames(seconds)
    var out = [Double](repeating: 0, count: n)
    var y = 0.0
    for i in 0..<n {
        y = 0.995 * y + 0.1 * rng.bipolar()
        out[i] = y
    }
    let top = out.peak
    return top > 0 ? out.scaled(1 / top) : out
}

/// Grain de bruit : rafale blanche qui s'éteint avec la constante `decay` (s). C'est la
/// brique des textures : crépitements, graines de maracas, dents de fermeture éclair.
func grain(_ rng: inout Rng, decay: Double) -> [Double] {
    let n = Swift.max(frames(decay * 5), 2)
    var out = [Double](repeating: 0, count: n)
    let k = exp(-1 / (decay * fs))
    var a = 1.0
    for i in 0..<n {
        out[i] = a * rng.bipolar()
        a *= k
    }
    return out
}

/// Instants d'un processus de Poisson de densité `rate(t)` (événements par seconde).
func poisson(_ rng: inout Rng, from start: Double, to end: Double, rate: (Double) -> Double) -> [Double] {
    var times: [Double] = []
    var t = start
    while true {
        t += -log(1 - rng.unit()) / Swift.max(rate(t), 0.01)
        if t >= end { break }
        times.append(t)
    }
    return times
}

// MARK: - Filtres

enum Pass { case lowPass, bandPass, highPass }

/// Filtre à variables d'état en topologie trapézoïdale (Zavalishin, « The Art of VA
/// Filter Design » ; formulation d'A. Simper). 12 dB/octave ; la sortie passe-bande est
/// normalisée (gain 1 au centre), `q` règle la résonance.
struct SVF {
    private var ic1 = 0.0, ic2 = 0.0
    private var k = 1.4142, a1 = 0.0, a2 = 0.0, a3 = 0.0

    init(_ freq: Double, q: Double) { tune(freq, q: q) }

    mutating func tune(_ freq: Double, q: Double) {
        let f = Swift.min(Swift.max(freq, 5), fs * 0.45)
        let g = tan(.pi * f / fs)
        k = 1 / Swift.max(q, 0.05)
        a1 = 1 / (1 + g * (g + k))
        a2 = g * a1
        a3 = g * a2
    }

    @inline(__always) mutating func tick(_ x: Double, _ pass: Pass) -> Double {
        let v3 = x - ic2
        let v1 = a1 * ic1 + a2 * v3
        let v2 = ic2 + a2 * ic1 + a3 * v3
        ic1 = 2 * v1 - ic1
        ic2 = 2 * v2 - ic2
        switch pass {
        case .lowPass: return v2
        case .bandPass: return k * v1
        case .highPass: return x - k * v1 - v2
        }
    }
}

/// Filtre SVF à coupure fixe.
func filter(_ x: [Double], _ pass: Pass, _ freq: Double, q: Double = 0.7071) -> [Double] {
    var f = SVF(freq, q: q)
    var out = x
    for i in x.indices { out[i] = f.tick(x[i], pass) }
    return out
}

/// Filtre SVF dont la coupure suit `freq(t)` (recalculée tous les 16 échantillons).
func sweep(_ x: [Double], _ pass: Pass, q: Double = 0.7071, _ freq: (Double) -> Double) -> [Double] {
    var f = SVF(freq(0), q: q)
    var out = x
    for i in x.indices {
        if i & 15 == 0 { f.tune(freq(Double(i) / fs), q: q) }
        out[i] = f.tick(x[i], pass)
    }
    return out
}

/// Passe-bas de Butterworth d'ordre 4 (24 dB/octave) : deux SVF, Q = 0,541 et 1,307.
func lowPass4(_ x: [Double], _ freq: Double) -> [Double] {
    filter(filter(x, .lowPass, freq, q: 0.5412), .lowPass, freq, q: 1.3066)
}

/// Passe-haut de Butterworth d'ordre 4.
func highPass4(_ x: [Double], _ freq: Double) -> [Double] {
    filter(filter(x, .highPass, freq, q: 0.5412), .highPass, freq, q: 1.3066)
}

/// Biquad (formules du « cookbook » de R. Bristow-Johnson), forme directe II transposée.
struct Biquad {
    private var b0 = 1.0, b1 = 0.0, b2 = 0.0, a1 = 0.0, a2 = 0.0
    private var z1 = 0.0, z2 = 0.0

    private init(_ b: (Double, Double, Double), _ a: (Double, Double, Double)) {
        b0 = b.0 / a.0
        b1 = b.1 / a.0
        b2 = b.2 / a.0
        a1 = a.1 / a.0
        a2 = a.2 / a.0
    }

    /// Plateau aigu de `gainDB` au-dessus de `freq`.
    static func highShelf(_ freq: Double, gainDB: Double, q: Double) -> Biquad {
        let amp = pow(10, gainDB / 40)
        let w = 2 * .pi * freq / fs
        let cw = cos(w)
        let alpha = sin(w) / (2 * q)
        let root = 2 * amp.squareRoot() * alpha
        let b = (amp * ((amp + 1) + (amp - 1) * cw + root),
                 -2 * amp * ((amp - 1) + (amp + 1) * cw),
                 amp * ((amp + 1) + (amp - 1) * cw - root))
        let a = ((amp + 1) - (amp - 1) * cw + root,
                 2 * ((amp - 1) - (amp + 1) * cw),
                 (amp + 1) - (amp - 1) * cw - root)
        return Biquad(b, a)
    }

    /// Passe-haut du second ordre.
    static func highPass(_ freq: Double, q: Double) -> Biquad {
        let w = 2 * .pi * freq / fs
        let cw = cos(w)
        let alpha = sin(w) / (2 * q)
        return Biquad(((1 + cw) / 2, -(1 + cw), (1 + cw) / 2), (1 + alpha, -2 * cw, 1 - alpha))
    }

    @inline(__always) mutating func tick(_ x: Double) -> Double {
        let y = b0 * x + z1
        z1 = b1 * x - a1 * y + z2
        z2 = b2 * x - a2 * y
        return y
    }
}

// MARK: - Formants (voix d'animaux)

/// Une résonance du conduit vocal : fréquence (Hz), largeur de bande (Hz), gain.
struct Formant {
    var freq: Double
    var width: Double
    var gain: Double

    init(_ freq: Double, _ width: Double, _ gain: Double) {
        self.freq = freq
        self.width = width
        self.gain = gain
    }
}

typealias Vowel = [Formant]

/// Voyelles « de dessin animé » : formants F1–F3 d'une voix adulte (Hz), à transposer
/// (`scaled`) pour les petites bêtes.
enum Vowels {
    static let a: Vowel = [Formant(750, 90, 1), Formant(1300, 110, 0.6), Formant(2550, 160, 0.3)]
    static let i: Vowel = [Formant(300, 60, 1), Formant(2250, 120, 0.45), Formant(3000, 180, 0.3)]
    static let o: Vowel = [Formant(500, 80, 1), Formant(900, 100, 0.55), Formant(2450, 160, 0.18)]
    static let u: Vowel = [Formant(320, 70, 1), Formant(780, 100, 0.45), Formant(2300, 160, 0.15)]
    /// « m » : murmure nasal — un seul formant grave, le reste très étouffé.
    static let m: Vowel = [Formant(260, 70, 1), Formant(1000, 150, 0.05), Formant(2200, 200, 0.02)]

    static func scaled(_ vowel: Vowel, _ factor: Double) -> Vowel {
        vowel.map { Formant($0.freq * factor, $0.width * factor, $0.gain) }
    }
}

/// Voyelle intermédiaire (u de 0 à 1), formant par formant.
func blend(_ a: Vowel, _ b: Vowel, _ u: Double) -> Vowel {
    zip(a, b).map { x, y in
        Formant(x.freq + (y.freq - x.freq) * u, x.width + (y.width - x.width) * u, x.gain + (y.gain - x.gain) * u)
    }
}

/// Banc de formants PARALLÈLE : un passe-bande résonant par formant (Q = fréquence /
/// largeur), signes alternés (comme chez Klatt) pour ne pas creuser de trou entre deux
/// formants voisins. `vowel(t)` peut glisser d'une voyelle à l'autre (même nombre de
/// formants) ; les filtres sont réaccordés tous les 32 échantillons.
func formants(_ x: [Double], _ vowel: (Double) -> Vowel) -> [Double] {
    var shape = vowel(0)
    var bank = shape.map { SVF($0.freq, q: $0.freq / $0.width) }
    var out = [Double](repeating: 0, count: x.count)
    for i in x.indices {
        if i & 31 == 0 {
            shape = vowel(Double(i) / fs)
            for j in bank.indices where j < shape.count {
                bank[j].tune(shape[j].freq, q: shape[j].freq / shape[j].width)
            }
        }
        var y = 0.0
        for j in bank.indices where j < shape.count {
            let sign = j % 2 == 0 ? 1.0 : -1.0
            y += sign * shape[j].gain * bank[j].tick(x[i], .bandPass)
        }
        out[i] = y
    }
    return out
}

// MARK: - Synthèse modale (chocs, cloches, verre)

/// Un partiel : fréquence (Hz), constante de décroissance (s), amplitude.
struct Partial {
    var freq: Double
    var decay: Double
    var amp: Double

    init(_ freq: Double, _ decay: Double, _ amp: Double) {
        self.freq = freq
        self.decay = decay
        self.amp = amp
    }
}

/// Choc sur un objet qui résonne : somme de sinusoïdes amorties (phaseur tournant, exact
/// et rapide). Les partiels au-delà de 9 kHz sont ignorés : rien d'agressif tout en haut.
/// Un fondu de 15 ms ferme la fin du tampon : un partiel coupé net ferait un clic.
func modes(_ partials: [Partial], _ seconds: Double, attack: Double = 0.0005) -> [Double] {
    let n = frames(seconds)
    var out = [Double](repeating: 0, count: n)
    for p in partials where p.freq > 0 && p.freq < 9_000 && p.decay > 0 {
        let w = 2 * .pi * p.freq / fs
        let (cw, sw) = (cos(w), sin(w))
        let fade = exp(-1 / (p.decay * fs))
        var re = 1.0, im = 0.0, a = p.amp
        let stop = Swift.min(n, frames(p.decay * 9))
        for i in 0..<stop {
            out[i] += a * im
            let r = re * cw - im * sw
            im = re * sw + im * cw
            re = r
            a *= fade
        }
    }
    let rise = Swift.min(frames(attack), n)
    for i in 0..<rise { out[i] *= 0.5 - 0.5 * cos(.pi * Double(i) / Double(rise)) }
    let fall = Swift.min(frames(0.015), n / 4)
    for i in 0..<fall { out[n - 1 - i] *= 0.5 - 0.5 * cos(.pi * Double(i) / Double(fall)) }
    return out
}

// MARK: - Enveloppes

/// Attaque en demi-cosinus sur `attack`, puis décroissance exponentielle de constante `decay`.
func strike(_ t: Double, attack: Double, decay: Double) -> Double {
    if t < 0 { return 0 }
    if t < attack { return 0.5 - 0.5 * cos(.pi * t / attack) }
    return exp(-(t - attack) / decay)
}

/// Porte adoucie : monte en `rise`, tient, redescend en `fall` pour finir à `length`.
func gate(_ t: Double, length: Double, rise: Double, fall: Double) -> Double {
    guard t > 0, t < length else { return 0 }
    var g = 1.0
    if t < rise { g = 0.5 - 0.5 * cos(.pi * t / rise) }
    let left = length - t
    if left < fall { g = Swift.min(g, 0.5 - 0.5 * cos(.pi * left / fall)) }
    return g
}

/// Arche de Hann sur [0, length] (0 ailleurs) : ce qui passe et s'en va.
func arch(_ t: Double, _ length: Double) -> Double {
    guard t > 0, t < length else { return 0 }
    return 0.5 - 0.5 * cos(2 * .pi * t / length)
}

/// Rampe douce de 0 à 1 (« smoothstep ») entre `a` et `b`.
func smooth(_ t: Double, _ a: Double, _ b: Double) -> Double {
    let u = Swift.min(Swift.max((t - a) / (b - a), 0), 1)
    return u * u * (3 - 2 * u)
}

/// Sinus redressé et élevé à une puissance : bosse lisse sur [0, 1] (0 hors bornes).
func bump(_ u: Double, _ power: Double = 1) -> Double {
    guard u > 0, u < 1 else { return 0 }
    return pow(sin(.pi * u), power)
}

/// Courbe par points (t, valeur), interpolée linéairement, constante au-delà.
struct Curve {
    private let times: [Double]
    private let values: [Double]

    init(_ points: [(Double, Double)]) {
        times = points.map(\.0)
        values = points.map(\.1)
    }

    func callAsFunction(_ t: Double) -> Double {
        guard let first = times.first, let last = times.last else { return 0 }
        if t <= first { return values[0] }
        if t >= last { return values[values.count - 1] }
        var i = 1
        while times[i] < t { i += 1 }
        let u = (t - times[i - 1]) / Swift.max(times[i] - times[i - 1], 1e-9)
        return values[i - 1] + (values[i] - values[i - 1]) * u
    }
}

// MARK: - Espace et caisse

/// Écho court (petite pièce, court de tennis) : retard + réinjection, mêlé au son sec.
func echo(_ x: [Double], delay: Double, feedback: Double, mix: Double) -> [Double] {
    let d = Swift.max(frames(delay), 1)
    let repeats = Int((log(0.001) / log(Swift.min(Swift.max(feedback, 0.01), 0.9))).rounded(.up))
    var out = x + [Double](repeating: 0, count: d * Swift.min(repeats, 12))
    var wet = [Double](repeating: 0, count: out.count)
    for i in out.indices where i >= d {
        let dry = i - d < x.count ? x[i - d] : 0
        wet[i] = dry + feedback * wet[i - d]
        out[i] += mix * wet[i]
    }
    return out
}

/// Résonances de caisse (passe-bandes parallèles) ajoutées au son sec.
func body(_ x: [Double], _ resonances: [(freq: Double, q: Double, gain: Double)]) -> [Double] {
    var out = x
    for r in resonances {
        var f = SVF(r.freq, q: r.q)
        for i in x.indices { out[i] += r.gain * f.tick(x[i], .bandPass) }
    }
    return out
}
