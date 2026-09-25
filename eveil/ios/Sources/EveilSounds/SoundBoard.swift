// SoundBoard.swift — jouer les bruitages, jamais pendant l'écoute.
//
// ÉBAUCHE : interface définitive, lecture à venir.

#if canImport(AVFoundation)
import AVFoundation

@MainActor
public final class SoundBoard {
    public static let shared = SoundBoard()

    /// Vrai pendant l'écoute de l'enfant (et pendant le mot modèle) : tout se tait,
    /// et `play` ne fait rien. Tour de parole strict.
    public var isSuspended = false {
        didSet { if isSuspended { stopAll() } }
    }

    public init() {}

    /// Prépare les effets à l'avance (le premier « bzzz » part sans délai).
    public func preload(_ effects: [SoundEffect]) {}

    /// Joue un effet ; plusieurs peuvent se superposer. Sans effet si `isSuspended`.
    public func play(_ effect: SoundEffect, variant: Int = 0, volume: Float = 1) {
        guard !isSuspended else { return }
    }

    /// Coupe tout ce qui joue.
    public func stopAll() {}
}
#endif
