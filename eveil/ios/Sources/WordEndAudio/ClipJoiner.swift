// ClipJoiner.swift — enchaîner des fichiers de voix préparée en une seule phrase (Swift pur, testé).
//
// Demande de l'utilisateur (17/11/2026) : la voix du petit train pour toutes les activités. Le train des
// phrases libre compte ≈ 10 400 phrases par langue : on ne les rend pas toutes. Chaque WAGON a son fichier
// (« le chat », « mange », « la pêche ») ; la phrase entière se compose de ces fichiers : on coupe le
// silence de début et de fin de chacun (même seuil que `eveil/outils/voix/generer.py`, `_rogner`), on garde
// une petite marge pour ne pas manger une attaque ou une consonne finale, et on pose une courte pause.
// `eveil/outils/voix/composer.py` fait exactement la même chose pour les mesures et la page d'écoute.

import Foundation

public enum ClipJoiner {
    /// Trames de 10 ms ; une trame « parle » si son énergie dépasse 1,2 % de la plus forte (comme `_rogner`).
    public static let frame = 0.010
    public static let threshold = 0.012
    /// Marges gardées autour de la voix : l'attaque, puis la fin (une consonne finale est faible).
    public static let lead = 0.020
    public static let tail = 0.040
    /// Silence ajouté entre deux morceaux. Avec les marges : ≈ 100 ms de silence d'un mot à l'autre.
    public static let gap = 0.040
    /// Fondu aux coupures (pas de clic).
    public static let fade = 0.004

    /// La partie parlée d'un morceau (avec ses marges), en indices d'échantillons.
    public static func voicedRange(_ samples: [Float], rate: Double) -> Range<Int> {
        let step = max(1, Int(rate * frame))
        let frames = samples.count / step
        guard frames >= 3 else { return 0..<samples.count }
        var energy = [Float](repeating: 0, count: frames)
        for f in 0..<frames {
            var sum: Float = 0
            for x in samples[(f * step)..<((f + 1) * step)] { sum += x * x }
            energy[f] = (sum / Float(step)).squareRoot()
        }
        let floor = max((energy.max() ?? 0) * Float(threshold), 1e-4)
        guard let first = energy.firstIndex(where: { $0 > floor }),
              let last = energy.lastIndex(where: { $0 > floor }) else { return 0..<samples.count }
        let start = max(0, first * step - Int(rate * lead))
        let end = min(samples.count, (last + 1) * step + Int(rate * tail))
        return start..<end
    }

    /// Les morceaux à la suite : chacun réduit à sa partie parlée, un fondu aux coupures, `gap` entre deux.
    public static func join(_ clips: [[Float]], rate: Double, gap: Double = ClipJoiner.gap) -> [Float] {
        let pause = [Float](repeating: 0, count: Int(rate * gap))
        let ramp = max(1, Int(rate * fade))
        var out: [Float] = []
        for (k, clip) in clips.enumerated() {
            var part = Array(clip[voicedRange(clip, rate: rate)])
            let n = min(ramp, part.count / 2)
            for i in 0..<n {
                let g = Float(i) / Float(n)
                part[i] *= g
                part[part.count - 1 - i] *= g
            }
            if k > 0 { out += pause }
            out += part
        }
        return out
    }

    /// Un fichier WAV en mémoire (PCM 16 bits, mono) pour `AVAudioPlayer(data:)`.
    public static func wav(_ samples: [Float], rate: Int) -> Data {
        var d = Data()
        func u32(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { d.append(contentsOf: $0) } }
        func u16(_ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { d.append(contentsOf: $0) } }
        let bytes = UInt32(samples.count * 2)
        d.append(contentsOf: Array("RIFF".utf8)); u32(36 + bytes)
        d.append(contentsOf: Array("WAVE".utf8))
        d.append(contentsOf: Array("fmt ".utf8)); u32(16); u16(1); u16(1); u32(UInt32(rate)); u32(UInt32(rate * 2))
        u16(2); u16(16)
        d.append(contentsOf: Array("data".utf8)); u32(bytes)
        d.reserveCapacity(d.count + samples.count * 2)
        for x in samples {
            let v = Int16(max(-1, min(1, x)) * 32767)
            u16(UInt16(bitPattern: v))
        }
        return d
    }
}
