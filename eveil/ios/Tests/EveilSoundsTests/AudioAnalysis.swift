// AudioAnalysis.swift — les « oreilles » des tests : on ne peut pas écouter, on MESURE.
//
// Outils volontairement indépendants de `DSPKit` (le code testé) : FFT radix-2,
// spectre moyen de Welch, part d'énergie par bande, centroïde, hauteur par YIN
// (de Cheveigné & Kawahara, 2002), niveau « actif » (RMS des fenêtres de 100 ms à
// moins de 20 dB de la plus forte), comptage des coups (aboiements, sabots…), et
// l'écriture d'un WAV 16 bits À LA MAIN (en-tête RIFF avec `Data`) : jamais
// `AVAudioFile(forWriting:)`, interdit par le garde-fou de confidentialité.

import EveilSounds
import Foundation

/// Les sons déjà calculés pendant la séance de tests : un rendu coûte ~50 ms en debug, et la
/// plupart des tests relisent les mêmes. (Le test de déterminisme, lui, recalcule exprès.)
enum Renders {
    private final class Store: @unchecked Sendable {
        let lock = NSLock()
        var sounds: [String: [Float]] = [:]
    }

    private static let store = Store()

    static func sound(_ effect: SoundEffect, _ variant: Int = 0) -> [Float] {
        let key = "\(effect.rawValue)#\(variant)"
        store.lock.lock()
        let known = store.sounds[key]
        store.lock.unlock()
        if let known { return known }
        let x = SoundSynth.render(effect, variant: variant)
        store.lock.lock()
        store.sounds[key] = x
        store.lock.unlock()
        return x
    }
}

enum AudioAnalysis {
    static let rate = SoundSynth.sampleRate

    // MARK: - Spectre

    /// FFT complexe radix-2 en place (taille = puissance de 2).
    static func fft(_ re: inout [Double], _ im: inout [Double]) {
        let n = re.count
        var j = 0
        for i in 1..<n {
            var bit = n >> 1
            while j & bit != 0 {
                j ^= bit
                bit >>= 1
            }
            j |= bit
            if i < j {
                re.swapAt(i, j)
                im.swapAt(i, j)
            }
        }
        var size = 2
        while size <= n {
            let half = size / 2
            let angle = -2 * Double.pi / Double(size)
            let (wr, wi) = (cos(angle), sin(angle))
            var start = 0
            while start < n {
                var cr = 1.0, ci = 0.0
                for k in 0..<half {
                    let a = start + k, b = a + half
                    let vr = re[b] * cr - im[b] * ci
                    let vi = re[b] * ci + im[b] * cr
                    re[b] = re[a] - vr
                    im[b] = im[a] - vi
                    re[a] += vr
                    im[a] += vi
                    let next = cr * wr - ci * wi
                    ci = cr * wi + ci * wr
                    cr = next
                }
                start += size
            }
            size <<= 1
        }
    }

    /// Spectre de puissance moyen (Welch : fenêtres de Hann de `size` points, recouvrement
    /// de moitié ; un son plus court est complété de zéros). Indices 0…size/2.
    static func powerSpectrum(_ x: [Float], size: Int = 4096) -> [Double] {
        var total = [Double](repeating: 0, count: size / 2 + 1)
        let hann = (0..<size).map { 0.5 - 0.5 * cos(2 * Double.pi * Double($0) / Double(size)) }
        var start = 0
        repeat {
            var re = [Double](repeating: 0, count: size), im = [Double](repeating: 0, count: size)
            for i in 0..<size where start + i < x.count { re[i] = Double(x[start + i]) * hann[i] }
            fft(&re, &im)
            for k in 0...size / 2 { total[k] += re[k] * re[k] + im[k] * im[k] }
            start += size / 2
        } while start + size / 2 < x.count
        return total
    }

    static func frequency(ofBin k: Int, size: Int = 4096) -> Double { Double(k) * rate / Double(size) }

    /// Part de l'énergie comprise entre `low` et `high` Hz.
    static func bandFraction(_ x: [Float], _ low: Double, _ high: Double) -> Double {
        let p = powerSpectrum(x)
        let all = p.reduce(0, +)
        guard all > 0 else { return 0 }
        var inside = 0.0
        for (k, e) in p.enumerated() where frequency(ofBin: k) >= low && frequency(ofBin: k) < high { inside += e }
        return inside / all
    }

    /// Centroïde spectral (Hz) : le « centre de gravité » du timbre.
    static func centroid(_ x: [Float]) -> Double {
        let p = powerSpectrum(x)
        let all = p.reduce(0, +)
        guard all > 0 else { return 0 }
        return p.enumerated().reduce(0) { $0 + frequency(ofBin: $1.offset) * $1.element } / all
    }

    /// Fréquence du pic le plus fort entre `low` et `high` Hz (interpolation parabolique).
    static func dominantFrequency(_ x: [Float], from low: Double, to high: Double) -> Double {
        let size = 16_384
        let p = powerSpectrum(x, size: size)
        var best = 1
        for k in 1..<(p.count - 1) {
            let f = frequency(ofBin: k, size: size)
            if f >= low, f <= high, p[k] > p[best] || frequency(ofBin: best, size: size) < low { best = k }
        }
        let (a, b, c) = (log(p[best - 1] + 1e-30), log(p[best] + 1e-30), log(p[best + 1] + 1e-30))
        let shift = (a - 2 * b + c) != 0 ? 0.5 * (a - c) / (a - 2 * b + c) : 0
        return frequency(ofBin: best, size: size) + shift * rate / Double(size)
    }

    // MARK: - Hauteur (YIN)

    /// Hauteur (Hz) autour de l'instant `t`, par YIN ; `nil` si le son n'est pas périodique là.
    static func pitch(_ x: [Float], at t: Double, window: Double = 0.04, minHz: Double = 60,
                      maxHz: Double = 3000) -> Double? {
        let w = Int(window * rate)
        let maxLag = Int(rate / minHz), minLag = max(2, Int(rate / maxHz))
        let start = max(0, min(Int(t * rate) - w / 2, x.count - w - maxLag - 1))
        guard start >= 0, start + w + maxLag < x.count else { return nil }
        var d = [Double](repeating: 0, count: maxLag + 2)
        for tau in 1...(maxLag + 1) {
            var sum = 0.0
            for j in 0..<w {
                let diff = Double(x[start + j]) - Double(x[start + j + tau])
                sum += diff * diff
            }
            d[tau] = sum
        }
        var cmnd = [Double](repeating: 1, count: maxLag + 2)
        var running = 0.0
        for tau in 1...(maxLag + 1) {
            running += d[tau]
            cmnd[tau] = running > 0 ? d[tau] * Double(tau) / running : 1
        }
        var found = -1
        var tau = minLag
        while tau <= maxLag {
            if cmnd[tau] < 0.2 {
                while tau + 1 <= maxLag, cmnd[tau + 1] < cmnd[tau] { tau += 1 }
                found = tau
                break
            }
            tau += 1
        }
        if found < 0 {
            let best = (minLag...maxLag).min { cmnd[$0] < cmnd[$1] } ?? minLag
            guard cmnd[best] < 0.45 else { return nil }
            found = best
        }
        let (a, b, c) = (cmnd[found - 1], cmnd[found], cmnd[found + 1])
        let shift = (a - 2 * b + c) != 0 ? 0.5 * (a - c) / (a - 2 * b + c) : 0
        return rate / (Double(found) + shift)
    }

    // MARK: - Niveaux et enveloppe

    /// RMS de tout le fichier (dB).
    static func rmsDB(_ x: [Float]) -> Double {
        let e = x.reduce(0.0) { $0 + Double($1) * Double($1) } / Double(max(x.count, 1))
        return 10 * log10(max(e, 1e-20))
    }

    /// RMS des passages ACTIFS (dB) : fenêtres de 100 ms (pas de 25 ms), seules comptent celles
    /// à moins de 20 dB de la plus forte. Mesure non pondérée (indépendante de `SoundSynth`).
    static func activeRMSDB(_ x: [Float]) -> Double {
        let window = Int(0.1 * rate), hop = Int(0.025 * rate)
        var energies: [Double] = []
        var start = 0
        repeat {
            var sum = 0.0
            for i in start..<min(start + window, x.count) { sum += Double(x[i]) * Double(x[i]) }
            energies.append(sum / Double(window))
            start += hop
        } while start + window <= x.count
        let loudest = energies.max() ?? 0
        let kept = energies.filter { $0 >= loudest * 0.01 }
        return 10 * log10(max(kept.reduce(0, +) / Double(max(kept.count, 1)), 1e-20))
    }

    /// Enveloppe RMS par tranches de `step` secondes.
    static func envelope(_ x: [Float], step: Double = 0.01) -> [Double] {
        let n = max(Int(step * rate), 1)
        return stride(from: 0, to: x.count, by: n).map { s in
            let slice = x[s..<min(s + n, x.count)]
            return (slice.reduce(0.0) { $0 + Double($1) * Double($1) } / Double(slice.count)).squareRoot()
        }
    }

    /// Nombre de coups distincts : l'enveloppe dépasse 30 % du maximum, après être
    /// redescendue sous 12 % (hystérésis).
    static func bursts(_ x: [Float], high: Double = 0.3, low: Double = 0.12) -> Int {
        let env = envelope(x, step: 0.005)
        let top = env.max() ?? 0
        guard top > 0 else { return 0 }
        var count = 0, armed = true
        for e in env {
            if armed, e >= high * top {
                count += 1
                armed = false
            } else if !armed, e < low * top {
                armed = true
            }
        }
        return count
    }

    // MARK: - WAV

    /// WAV PCM 16 bits mono, en-tête RIFF écrit à la main.
    static func wav(_ x: [Float], sampleRate: Int = Int(SoundSynth.sampleRate)) -> Data {
        var data = Data()
        func text(_ s: String) { data.append(contentsOf: Array(s.utf8)) }
        func u32(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }
        func u16(_ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }
        let bytes = x.count * 2
        text("RIFF")
        u32(UInt32(36 + bytes))
        text("WAVE")
        text("fmt ")
        u32(16)                          // taille du bloc « fmt »
        u16(1)                           // PCM
        u16(1)                           // mono
        u32(UInt32(sampleRate))
        u32(UInt32(sampleRate * 2))      // octets par seconde
        u16(2)                           // octets par échantillon
        u16(16)                          // bits
        text("data")
        u32(UInt32(bytes))
        for s in x {
            let v = Int16(max(-32767, min(32767, (Double(s) * 32767).rounded())))
            u16(UInt16(bitPattern: v))
        }
        return data
    }
}
