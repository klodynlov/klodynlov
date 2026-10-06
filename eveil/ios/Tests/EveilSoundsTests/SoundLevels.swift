// SoundLevels.swift — accès des tests aux réglages internes de la synthèse.
//
// La sonie pondérée K est celle que la chaîne de mastering égalise : les tests la
// relisent sur le son FINI (après limiteur et fondus) pour vérifier que l'égalisation
// tient. Le RMS non pondéré, lui, est recalculé indépendamment (`AudioAnalysis`).

@testable import EveilSounds

enum SoundLevels {
    static var target: Double { SoundSynth.targetLoudness }

    static func loudness(_ x: [Float]) -> Double { SoundSynth.loudness(x.map(Double.init)) }

    static func offset(_ effect: SoundEffect) -> Double { SoundSynth.levelOffset(effect) }

    static func dingFrequency(_ variant: Int) -> Double { Recipes.dingFrequency(variant) }
}
