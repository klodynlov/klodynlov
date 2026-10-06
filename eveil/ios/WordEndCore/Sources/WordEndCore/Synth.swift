// Synth.swift — « pseudo-parole » déterministe, portage de
// `eveil/reference/wordend/synth.py`.
//
// ⚠️ Ce n'est PAS de la parole d'enfant : des signaux dont la structure
// acoustique reproduit ce que le détecteur mesure. Sert aux tests de parité
// (`golden_vectors.json`), aux aperçus SwiftUI et au « micro simulé » des
// démonstrations — jamais à juger un enfant.

import Foundation

public enum Synth {
    public static let refRms = 0.1   // niveau RMS d'une voyelle à 0 dB (≈ −20 dBFS)

    static let vowels: [String: (Double, Double, Double)] = [
        "i": (370.0, 3200.0, 3730.0),
        "u": (430.0, 1170.0, 3260.0),
        "a": (1030.0, 1370.0, 3170.0),
        "o": (560.0, 1000.0, 3300.0),
        "e": (530.0, 2500.0, 3500.0),
        "@": (560.0, 1700.0, 3300.0),
    ]
    static let nasals: [String: (Double, Double, Double)] = [
        "m": (280.0, 1300.0, 2600.0),
        "n": (280.0, 1700.0, 2700.0),
    ]
    static let sibilants: [String: (Double, Double)] = ["S": (4200.0, 1500.0), "s": (7500.0, 2000.0)]
    static let voicedPlosives: Set<String> = ["d", "b", "g"]
    static let voicelessPlosives: Set<String> = ["t", "p", "k"]

    /// Bibliothèque d'énoncés de test (mêmes specs que la référence Python).
    public static let library: [String: String] = [
        "douche": "d50 u230 S180",
        "dou": "d50 u260",
        "douche_schwa": "d50 u200 S150 @110/-9",
        "dou_souffle": "d50 u240 h:u120",
        "dou_clic": "d50 u260 _600 click15",
        "minouche": "m70 i140 n70 u190 S180",
        "minou": "m70 i150 n70 u240",
        "mi": "m70 i260",
        "minousse": "m70 i140 n70 u190 s180",
        "fish": "f90 i180 S170",
        "fi": "f90 i230",
        "goose": "g50 u220 s170",
        "goo": "g50 u260",
        "chut": "S300",
    ]
}

public struct Seg: Equatable, Sendable {
    public var phone: String
    public var ms: Double
    public var levelDb: Double?
}

public struct Utterance: Equatable, Sendable {
    public var segments: [Seg]
    public var f0Start = 300.0
    public var f0End = 250.0
    public var preMs = 300.0
    public var postMs = 1200.0
    public var snrDb = 35.0
    public var noise = "pink"          // "pink" | "white" | "none"
    public var gainDb = 0.0
    public var seed = 1
    public var rate = WordEnd.analysisRate

    public init(segments: [Seg]) { self.segments = segments }

    /// Spec compacte : `"d50 u230 S180"` ; niveau explicite : `"@110/-9"`.
    public init(spec: String) {
        var segs: [Seg] = []
        for raw in spec.split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "\n" }) {
            var token = String(raw)
            var level: Double?
            if let slash = token.firstIndex(of: "/") {
                level = Double(token[token.index(after: slash)...])
                token = String(token[..<slash])
            }
            var i = token.endIndex
            while i > token.startIndex {
                let prev = token.index(before: i)
                if token[prev].isNumber || token[prev] == "." { i = prev } else { break }
            }
            segs.append(Seg(phone: String(token[..<i]), ms: Double(token[i...]) ?? 0.0, levelDb: level))
        }
        segments = segs
    }
}

extension Synth {
    static func pyRound(_ x: Double) -> Int { Int(x.rounded(.toNearestOrEven)) }

    /// Résonateur numérique de Klatt (gain unitaire en continu).
    static func resonator(_ x: [Double], _ fHz: Double, _ bwHz: Double, _ rate: Int) -> [Double] {
        let t = 1.0 / Double(rate)
        let c = -exp(-2.0 * Double.pi * bwHz * t)
        let b = 2.0 * exp(-Double.pi * bwHz * t) * cos(2.0 * Double.pi * fHz * t)
        let a = 1.0 - b - c
        var y1 = 0.0
        var y2 = 0.0
        var out: [Double] = []
        out.reserveCapacity(x.count)
        for v in x {
            let y = a * v + b * y1 + c * y2
            out.append(y)
            y2 = y1
            y1 = y
        }
        return out
    }

    /// Dérivée discrète (+6 dB/octave).
    static func difference(_ x: [Double]) -> [Double] {
        var out: [Double] = []
        out.reserveCapacity(x.count)
        var prev = 0.0
        for v in x {
            out.append(v - prev)
            prev = v
        }
        return out
    }

    static func rms(_ x: ArraySlice<Double>) -> Double {
        guard !x.isEmpty else { return 0.0 }
        var s = 0.0
        for v in x { s += v * v }
        return (s / Double(x.count)).squareRoot()
    }

    static func scaleTo(_ x: [Double], steady: (Int, Int), _ targetRms: Double) -> [Double] {
        let (lo, hi) = steady
        let r = hi > lo ? rms(x[lo..<hi]) : rms(x[...])
        guard r > 0.0 else { return x }
        let g = targetRms / r
        return x.map { $0 * g }
    }

    static func voiceSource(_ n: Int, wordStart: Int, wordEnd: Int, f0Start: Double, f0End: Double,
                            rate: Int) -> [Double] {
        var src = [Double](repeating: 0.0, count: n)
        var phase = 0.0
        let span = max(1, wordEnd - wordStart)
        let lo = max(0, wordStart - rate / 50)
        let hi = min(n, wordEnd + rate / 50)
        guard lo < hi else { return src }
        for i in lo..<hi {
            let pos = min(1.0, max(0.0, Double(i - wordStart) / Double(span)))
            let f0 = f0Start + (f0End - f0Start) * pos
            phase += f0 / Double(rate)
            if phase >= 1.0 {
                phase -= 1.0
                src[i] = 1.0
            }
        }
        return src
    }

    static func noise(_ rng: inout SplitMix64, _ count: Int) -> [Double] {
        (0..<count).map { _ in rng.nextSigned() }
    }

    static func envelope(_ length: Int, rampIn: Int, rampOut: Int) -> [Double] {
        var env = [Double](repeating: 1.0, count: length)
        for i in 0..<min(rampIn, length) {
            env[i] = 0.5 - 0.5 * cos(Double.pi * (Double(i) + 0.5) / Double(rampIn))
        }
        for i in 0..<min(rampOut, length) {
            let j = length - 1 - i
            env[j] = min(env[j], 0.5 - 0.5 * cos(Double.pi * (Double(i) + 0.5) / Double(rampOut)))
        }
        return env
    }

    static func levelFor(_ phone: String) -> Double {
        if phone == "@" { return -8.0 }
        if vowels[phone] != nil { return 0.0 }
        if nasals[phone] != nil { return -12.0 }
        if sibilants[phone] != nil { return -10.0 }
        if phone == "f" { return -22.0 }
        if phone.hasPrefix("h:") { return -20.0 }
        if phone == "click" { return -3.0 }
        return -10.0
    }

    static func renderSegment(_ seg: Seg, length: Int, voice: [Double], rng: inout SplitMix64,
                              rate: Int) -> [Double] {
        let p = seg.phone
        if let formants = vowels[p] ?? nasals[p] {
            let bws = vowels[p] != nil ? (80.0, 120.0, 180.0) : (100.0, 200.0, 300.0)
            var x = resonator(voice, 0.0, 200.0, rate)
            x = resonator(x, formants.0, bws.0, rate)
            x = resonator(x, formants.1, bws.1, rate)
            x = resonator(x, formants.2, bws.2, rate)
            return difference(x)
        }
        if let sibilant = sibilants[p] {
            let (centre, bw) = sibilant
            let x = difference(difference(noise(&rng, length)))
            return resonator(resonator(x, centre, bw, rate), centre, bw, rate)
        }
        if p == "f" { return difference(noise(&rng, length)) }
        if p.hasPrefix("h:"), let formants = vowels[String(p.dropFirst(2))] {
            var x = noise(&rng, length)
            x = resonator(x, formants.0, 120.0, rate)
            x = resonator(x, formants.1, 180.0, rate)
            x = resonator(x, formants.2, 250.0, rate)
            return difference(x)
        }
        if p == "click" { return noise(&rng, length) }
        return [Double](repeating: 0.0, count: length)   // occlusives (traitées à part), silence
    }

    /// Rend l'énoncé en échantillons (mono, `u.rate` Hz), écrêtés à ±1.
    public static func synthesize(_ u: Utterance) -> [Double] {
        let rate = u.rate
        let pre = pyRound(u.preMs * Double(rate) / 1000.0)
        var bounds: [(Int, Int)] = []
        var cursor = pre
        for seg in u.segments {
            let length = pyRound(seg.ms * Double(rate) / 1000.0)
            bounds.append((cursor, cursor + length))
            cursor += length
        }
        let wordEnd = cursor
        let n = wordEnd + pyRound(u.postMs * Double(rate) / 1000.0)
        var out = [Double](repeating: 0.0, count: n)
        let voiceFull = voiceSource(n, wordStart: pre, wordEnd: wordEnd, f0Start: u.f0Start,
                                    f0End: u.f0End, rate: rate)
        var rng = SplitMix64(seed: UInt64(truncatingIfNeeded: u.seed))
        let gain = pow(10.0, u.gainDb / 20.0)

        for (seg, (start, end)) in zip(u.segments, bounds) {
            let p = seg.phone
            let level = seg.levelDb ?? levelFor(p)
            let targetRms = refRms * gain * pow(10.0, level / 20.0)
            if p == "_" { continue }
            if voicedPlosives.contains(p) || voicelessPlosives.contains(p) {
                let burstLen = pyRound((voicelessPlosives.contains(p) ? 0.008 : 0.006) * Double(rate))
                let closureLen = max(0, (end - start) - burstLen)
                if voicedPlosives.contains(p) && closureLen > 0 {      // barre de voisement
                    var bar = resonator(Array(voiceFull[start..<(start + closureLen)]), 150.0, 100.0, rate)
                    bar = scaleTo(bar, steady: (0, closureLen), refRms * gain * pow(10.0, -28.0 / 20.0))
                    let env = envelope(closureLen, rampIn: Int(0.005 * Double(rate)),
                                       rampOut: Int(0.005 * Double(rate)))
                    for i in 0..<closureLen { out[start + i] += bar[i] * env[i] }
                }
                var burst = resonator(difference(noise(&rng, burstLen)), 3500.0, 3000.0, rate)
                burst = scaleTo(burst, steady: (0, burstLen), refRms * gain * pow(10.0, -10.0 / 20.0))
                let env = envelope(burstLen, rampIn: max(1, Int(0.001 * Double(rate))),
                                   rampOut: max(1, Int(0.002 * Double(rate))))
                let b0 = start + closureLen
                for i in 0..<burstLen where b0 + i < n { out[b0 + i] += burst[i] * env[i] }
                continue
            }
            let short = p == "click"
            let ramp = max(1, Int((short ? 0.001 : 0.015) * Double(rate)))
            let lo = max(0, start - ramp)
            let hi = min(n, end + ramp)
            let length = hi - lo
            let voice = Array(voiceFull[lo..<hi])
            var x = renderSegment(seg, length: length, voice: voice, rng: &rng, rate: rate)
            x = scaleTo(x, steady: (start - lo, end - lo), targetRms)
            let env = envelope(length, rampIn: 2 * ramp, rampOut: 2 * ramp)
            for i in 0..<length { out[lo + i] += x[i] * env[i] }
        }

        if u.noise != "none" {
            var nrng = SplitMix64(seed: UInt64(truncatingIfNeeded: u.seed) ^ 0x5_DEEC_E66D)
            let white = noise(&nrng, n)
            var bg: [Double]
            if u.noise == "pink" {
                var y = 0.0
                bg = white.map { v in
                    y = 0.95 * y + v
                    return y
                }
            } else {
                bg = white
            }
            bg = scaleTo(bg, steady: (0, n), refRms * gain * pow(10.0, -u.snrDb / 20.0))
            for i in 0..<n { out[i] += bg[i] }
        }
        return out.map { max(-1.0, min(1.0, $0)) }
    }
}
