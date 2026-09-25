// SoundSynth.swift — synthèse des bruitages (Swift pur, testable sur Mac).
//
// ÉBAUCHE : un bip par effet, en attendant la vraie synthèse.

import Foundation

public enum SoundSynth {
    public static let sampleRate = 44_100.0

    /// L'effet en mono, échantillons dans [-1, 1]. `variant` fait varier la hauteur
    /// (notes de musique, bestioles qui ne chantent pas toutes pareil). Déterministe.
    public static func render(_ effect: SoundEffect, variant: Int = 0) -> [Float] {
        let n = Int(sampleRate * 0.2)
        let index = SoundEffect.allCases.firstIndex(of: effect) ?? 0
        let f = 330.0 * pow(2, Double((index + variant) % 12) / 12)
        return (0..<n).map { i in
            Float(0.3 * sin(2 * .pi * f * Double(i) / sampleRate) * (1 - Double(i) / Double(n)))
        }
    }
}
