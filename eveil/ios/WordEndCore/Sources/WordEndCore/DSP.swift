// DSP.swift — primitives de traitement du signal, portage ligne à ligne de
// `eveil/reference/wordend/dsp.py` (la référence Python, testée).
//
// Règle de portabilité : mêmes constantes, mêmes ordres d'opérations, même
// PRNG. La parité est vérifiée par `GoldenVectorsTests` contre
// `golden_vectors.json`, produit par la référence Python.
//
// Swift pur (Foundation) : compile sur iOS, macOS et Linux.

import Foundation

/// Constantes d'analyse partagées (identiques à la référence Python).
public enum WordEnd {
    /// Fréquence d'analyse canonique : assez pour les sibilantes d'enfant
    /// (énergie jusque vers 10 kHz), deux fois moins coûteuse que 48 kHz.
    public static let analysisRate = 24_000
    /// Taille de trame = taille FFT (21,3 ms à 24 kHz).
    public static let frameSize = 512
    /// Pas d'analyse (10 ms à 24 kHz).
    public static let hopSize = 240
    /// Largeur d'un bin FFT : 46,875 Hz, exactement représentable.
    public static let binHz = Double(analysisRate) / Double(frameSize)
    /// Plancher numérique avant log10.
    public static let eps = 1e-12

    /// Pas d'analyse en millisecondes (10 ms).
    public static var frameMs: Double { 1000.0 * Double(hopSize) / Double(analysisRate) }

    /// Durée → nombre de trames. `round()` de Python arrondit au pair : on fait de même.
    public static func msToFrames(_ ms: Double) -> Int {
        Int((ms / frameMs).rounded(.toNearestOrEven))
    }
}

// MARK: - PRNG déterministe

/// SplitMix64 — identique bit à bit à la version Python (`&+`, `&*` = modulo 2⁶⁴).
public struct SplitMix64: Sendable {
    public private(set) var state: UInt64

    public init(seed: UInt64) { state = seed }

    public mutating func nextU64() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// Uniforme dans [0, 1) sur 53 bits.
    public mutating func nextUnit() -> Double {
        Double(nextU64() >> 11) * (1.0 / 9_007_199_254_740_992.0)
    }

    /// Uniforme dans [-1, 1) — bruit blanc sans fonction transcendante.
    public mutating func nextSigned() -> Double { 2.0 * nextUnit() - 1.0 }
}

// MARK: - FFT portable

/// FFT radix-2 itérative (Cooley-Tukey) d'un signal réel, en Double.
///
/// À 512 points × 100 trames/s, le coût est négligeable sur n'importe quel iPad :
/// Accelerate n'est pas nécessaire au budget CPU. Le backend vDSP reste
/// disponible (`AccelerateSpectrum`) et vérifié par un test de parité.
public struct RadixTwoFFT: Sendable {
    public let size: Int
    private let cosTable: [Double]
    private let sinTable: [Double]

    public init(size: Int) {
        precondition(size > 0 && size & (size - 1) == 0, "taille FFT non puissance de 2 : \(size)")
        self.size = size
        var c: [Double] = []
        var s: [Double] = []
        c.reserveCapacity(size / 2)
        s.reserveCapacity(size / 2)
        for k in 0..<(size / 2) {
            let ang = -2.0 * Double.pi * Double(k) / Double(size)
            c.append(cos(ang))
            s.append(sin(ang))
        }
        cosTable = c
        sinTable = s
    }

    /// DFT de `input` (réel, `size` échantillons) → parties réelle et imaginaire.
    public func transform(_ input: [Double]) -> (re: [Double], im: [Double]) {
        let n = size
        precondition(input.count == n, "entrée de \(input.count) échantillons pour une FFT de \(n)")
        var re = input
        var im = [Double](repeating: 0.0, count: n)
        var j = 0
        for i in 1..<max(n, 1) {                    // permutation bit-reverse
            var bit = n >> 1
            while j & bit != 0 {
                j ^= bit
                bit >>= 1
            }
            j ^= bit
            if i < j {
                re.swapAt(i, j)
                im.swapAt(i, j)
            }
        }
        var len = 2
        while len <= n {
            let half = len / 2
            let step = n / len
            var start = 0
            while start < n {
                for k in 0..<half {
                    let wr = cosTable[k * step]
                    let wi = sinTable[k * step]
                    let xr = re[start + k + half]
                    let xi = im[start + k + half]
                    let vr = xr * wr - xi * wi
                    let vi = xr * wi + xi * wr
                    let ur = re[start + k]
                    let ui = im[start + k]
                    re[start + k] = ur + vr
                    im[start + k] = ui + vi
                    re[start + k + half] = ur - vr
                    im[start + k + half] = ui - vi
                }
                start += len
            }
            len *= 2
        }
        return (re, im)
    }

    /// Spectre de puissance |X[k]|² pour k = 0 … size/2.
    public func powerSpectrum(_ input: [Double]) -> [Double] {
        let (re, im) = transform(input)
        return (0...(size / 2)).map { re[$0] * re[$0] + im[$0] * im[$0] }
    }
}

// MARK: - Descripteurs par trame

/// Bande de fréquences [lo, hi) en Hz.
public struct Band: Equatable, Sendable {
    public var lo: Double
    public var hi: Double
    public init(_ lo: Double, _ hi: Double) {
        self.lo = lo
        self.hi = hi
    }
}

/// Bandes d'analyse. Valeurs par défaut justifiées dans docs/EVEIL.md §5.
public struct Bands: Equatable, Sendable {
    public var low = Band(300.0, 2500.0)        // voyelles (F1/F2)
    public var high = Band(3000.0, 11000.0)     // bruit de friction sibilant
    public var centroid = Band(1000.0, 11000.0)
    public init() {}
}

/// Indices de bins [k0, k1) couvrant la bande.
public func bandBins(_ band: Band) -> (Int, Int) {
    let k0 = max(1, Int(ceil(band.lo / WordEnd.binHz)))
    let k1 = min(WordEnd.frameSize / 2 + 1, Int(ceil(band.hi / WordEnd.binHz)))
    return (k0, max(k0, k1))
}

@inline(__always) func toDb(_ power: Double) -> Double { 10.0 * log10(power + WordEnd.eps) }

public struct FrameFeatures: Equatable, Sendable {
    public let index: Int
    public let rmsDb: Double       // énergie totale (dB, référence arbitraire)
    public let lowDb: Double       // énergie bande « voyelle »
    public let highDb: Double      // énergie bande « friction »
    public let highRatio: Double   // E_high / (E_low + E_high) ∈ [0, 1]
    public let centroidHz: Double  // centroïde spectral sur la bande `centroid`
    public let zcrHz: Double       // passages par zéro par seconde
    public let peak: Double        // max |x| (écrêtage)
}

/// Fenêtre de Hann périodique (dénominateur N), comme la référence.
public let hannWindow: [Double] = (0..<WordEnd.frameSize).map {
    0.5 - 0.5 * cos(2.0 * Double.pi * Double($0) / Double(WordEnd.frameSize))
}

/// Nombre de trames entièrement contenues dans le signal.
public func frameCount(_ sampleCount: Int) -> Int {
    sampleCount < WordEnd.frameSize ? 0 : 1 + (sampleCount - WordEnd.frameSize) / WordEnd.hopSize
}

/// Calcule les descripteurs de trames. Réutilisable (FFT pré-calculée).
public struct FeatureExtractor: Sendable {
    public let bands: Bands
    private let fft = RadixTwoFFT(size: WordEnd.frameSize)
    private let low: (Int, Int)
    private let high: (Int, Int)
    private let centroid: (Int, Int)

    public init(bands: Bands = Bands()) {
        self.bands = bands
        low = bandBins(bands.low)
        high = bandBins(bands.high)
        centroid = bandBins(bands.centroid)
    }

    public func frame(_ samples: [Double], index: Int) -> FrameFeatures {
        let n = WordEnd.frameSize
        let start = index * WordEnd.hopSize
        var seg = [Double](repeating: 0.0, count: n)
        let end = min(samples.count, start + n)
        if start < end {
            for i in start..<end { seg[i - start] = samples[i] }
        }
        var total = 0.0
        for v in seg { total += v }
        let mean = total / Double(n)
        let x = seg.map { $0 - mean }
        var energy = 0.0
        for v in x { energy += v * v }
        energy /= Double(n)

        var crossings = 0
        var prevNeg = x[0] < 0.0
        for i in 1..<n {
            let neg = x[i] < 0.0
            if neg != prevNeg { crossings += 1 }
            prevNeg = neg
        }
        let zcr = Double(crossings) * Double(WordEnd.analysisRate) / Double(n)
        var peak = 0.0
        for v in seg { peak = max(peak, abs(v)) }

        var windowed = [Double](repeating: 0.0, count: n)
        for i in 0..<n { windowed[i] = x[i] * hannWindow[i] }
        let power = fft.powerSpectrum(windowed)

        var eLow = 0.0
        for k in low.0..<low.1 { eLow += power[k] }
        var eHigh = 0.0
        for k in high.0..<high.1 { eHigh += power[k] }
        var eC = 0.0
        var eCF = 0.0
        for k in centroid.0..<centroid.1 {
            eC += power[k]
            eCF += power[k] * Double(k) * WordEnd.binHz
        }
        let centroidHz = eC > WordEnd.eps ? eCF / eC : 0.0
        let ratio = (eLow + eHigh) > WordEnd.eps ? eHigh / (eLow + eHigh) : 0.0
        return FrameFeatures(index: index, rmsDb: toDb(energy), lowDb: toDb(eLow), highDb: toDb(eHigh),
                             highRatio: ratio, centroidHz: centroidHz, zcrHz: zcr, peak: peak)
    }

    public func frames(_ samples: [Double]) -> [FrameFeatures] {
        (0..<frameCount(samples.count)).map { frame(samples, index: $0) }
    }
}

// MARK: - Outils statistiques et signaux

/// Percentile « rang inférieur » déterministe (p ∈ [0, 1]).
public func percentile(_ values: [Double], _ p: Double) -> Double {
    precondition(!values.isEmpty, "percentile d'une liste vide")
    let ordered = values.sorted()
    let idx = Int(p * Double(ordered.count - 1))
    return ordered[max(0, min(ordered.count - 1, idx))]
}

/// Moyenne glissante centrée ; aux bords, moyenne des valeurs disponibles.
public func movingAverage(_ values: [Double], width: Int) -> [Double] {
    let half = width / 2
    let n = values.count
    var out: [Double] = []
    out.reserveCapacity(n)
    for t in 0..<n {
        let lo = max(0, t - half)
        let hi = min(n, t + half + 1)
        var s = 0.0
        for i in lo..<hi { s += values[i] }
        out.append(s / Double(hi - lo))
    }
    return out
}

/// F0 par autocorrélation normalisée sur une trame ; nil si non voisé.
/// Retient le plus petit retard dont la corrélation atteint 90 % du maximum.
public func estimateF0(_ samples: [Double], frameIndex: Int, f0Min: Double = 90.0,
                       f0Max: Double = 800.0, minCorr: Double = 0.5) -> Double? {
    let n = WordEnd.frameSize
    let start = frameIndex * WordEnd.hopSize
    guard start >= 0, start + n <= samples.count else { return nil }
    var total = 0.0
    for i in start..<(start + n) { total += samples[i] }
    let mean = total / Double(n)
    let x = (start..<(start + n)).map { samples[$0] - mean }
    let lagMin = Int(Double(WordEnd.analysisRate) / f0Max)
    let lagMax = min(n - 2, Int(Double(WordEnd.analysisRate) / f0Min))
    guard lagMin <= lagMax else { return nil }
    var corr: [(Int, Double)] = []
    for lag in lagMin...lagMax {
        var num = 0.0
        var e0 = 0.0
        var e1 = 0.0
        for i in 0..<(n - lag) {
            let a = x[i]
            let b = x[i + lag]
            num += a * b
            e0 += a * a
            e1 += b * b
        }
        let den = (e0 * e1).squareRoot()
        corr.append((lag, den > WordEnd.eps ? num / den : 0.0))
    }
    let best = corr.map { $0.1 }.max() ?? 0.0
    guard best >= minCorr else { return nil }
    for (lag, c) in corr where c >= 0.9 * best {
        return Double(WordEnd.analysisRate) / Double(lag)
    }
    return nil
}

/// Filtre RIF passe-bas (sinus cardinal fenêtré Blackman), gain unitaire.
public func lowpassFIR(cutoffHz: Double, rate: Double, taps: Int = 63) -> [Double] {
    let fc = cutoffHz / rate
    let mid = Double(taps - 1) / 2.0
    var h: [Double] = []
    for i in 0..<taps {
        let m = Double(i) - mid
        let sinc = m == 0 ? 2.0 * fc : sin(2.0 * Double.pi * fc * m) / (Double.pi * m)
        let w = 0.42 - 0.5 * cos(2.0 * Double.pi * Double(i) / Double(taps - 1))
            + 0.08 * cos(4.0 * Double.pi * Double(i) / Double(taps - 1))
        h.append(sinc * w)
    }
    var total = 0.0
    for v in h { total += v }
    return h.map { $0 / total }
}

/// Rééchantillonnage : passe-bas anti-repliement (si décimation) + interpolation
/// linéaire. Sur iOS, `AVAudioConverter` livre déjà du 24 kHz mono : cette
/// fonction sert aux tests, au banc et aux plateformes sans AVFoundation.
public func resample(_ samples: [Double], from rateIn: Int, to rateOut: Int = WordEnd.analysisRate) -> [Double] {
    if rateIn == rateOut { return samples }
    var src = samples
    if rateOut < rateIn {
        let h = lowpassFIR(cutoffHz: 0.45 * Double(rateOut), rate: Double(rateIn))
        let half = h.count / 2
        let n = src.count
        var filtered = [Double](repeating: 0.0, count: n)
        for i in 0..<n {
            var acc = 0.0
            for (k, hk) in h.enumerated() {
                let j = i + half - k
                if j >= 0 && j < n { acc += hk * src[j] }
            }
            filtered[i] = acc
        }
        src = filtered
    }
    let ratio = Double(rateIn) / Double(rateOut)
    let nOut = Int(Double(src.count) / ratio)
    var out: [Double] = []
    out.reserveCapacity(nOut)
    for i in 0..<nOut {
        let pos = Double(i) * ratio
        let j = Int(pos)
        let frac = pos - Double(j)
        let a = src[j]
        let b = j + 1 < src.count ? src[j + 1] : a
        out.append(a + (b - a) * frac)
    }
    return out
}
