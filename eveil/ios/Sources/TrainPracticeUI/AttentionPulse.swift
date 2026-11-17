// AttentionPulse.swift — la bulle palpite quand c'est à l'enfant de toucher « À toi ! ».
//
// Demande de l'utilisateur (17/11/2026) : « quand c'est à l'enfant d'appuyer sur À toi, fais clignoter la
// bulle pour son attention ». Une lueur jaune qui respire et la bulle qui grossit à peine (~1 battement
// par seconde), pas un clignotement brutal (enfant de 3 ans). Piloté par l'horloge (`TimelineView`),
// jamais par `repeatForever` (piège déjà vu : l'animation « capture » celles des parents). « Réduire
// les animations » : un cadre jaune fixe, sans mouvement.

#if canImport(SwiftUI)
import SwiftUI

struct AttentionPulse: ViewModifier {
    let active: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// La pulsation entre 0 et 1 à l'instant `t` (secondes) : 0,9 s par battement.
    static func level(at t: TimeInterval) -> Double {
        0.5 - 0.5 * cos(t * 2 * .pi / 0.9)
    }

    func body(content: Content) -> some View {
        if !active {
            content
        } else if reduceMotion {
            content.overlay(RoundedRectangle(cornerRadius: 26).stroke(Color.yellow, lineWidth: 5))
        } else {
            TimelineView(.animation) { timeline in
                let p = Self.level(at: timeline.date.timeIntervalSinceReferenceDate)
                content
                    .scaleEffect(1 + 0.06 * p)
                    .shadow(color: Color.yellow.opacity(0.95 * p), radius: 6 + 22 * p)
                    .shadow(color: Color.orange.opacity(0.5 * p), radius: 4 + 8 * p)
            }
        }
    }
}
#endif
