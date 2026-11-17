// ConfettiLayer.swift — « J'ai fini ! » : une pluie de confettis aux couleurs de la palette.
//
// Mode interactif de l'atelier (demande de l'utilisateur, 28/09/2026) : quand l'enfant
// dit qu'il a fini, le dessin prend vie (il danse, voir `ColoringView.dance`) et des
// confettis tombent sur tout l'écran. Rien d'aléatoire : chaque confetti a sa place, sa
// vitesse et sa couleur calculées d'après son numéro (même fête à chaque fois). Le
// mouvement vient de l'horloge (`TimelineView`) ; « Réduire les animations » : rien.

#if canImport(SwiftUI)
import SwiftUI

struct ConfettiLayer: View {
    let start: Date
    let colors: [Color]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Durée de la fête (secondes).
    static let duration = 2.8
    static let count = 90

    var body: some View {
        if !reduceMotion && !colors.isEmpty {
            TimelineView(.animation(minimumInterval: 1.0 / 60)) { timeline in
                let t = timeline.date.timeIntervalSince(start)
                Canvas { context, size in
                    for k in 0..<Self.count {
                        guard let piece = Self.piece(k, at: t, in: size) else { continue }
                        var c = context
                        c.translateBy(x: piece.x, y: piece.y)
                        c.rotate(by: .degrees(piece.angle))
                        c.scaleBy(x: piece.flip, y: 1)
                        let rect = CGRect(x: -7, y: -4, width: 14, height: 8)
                        let shape = k % 3 == 0 ? Path(ellipseIn: CGRect(x: -5, y: -5, width: 10, height: 10))
                                               : Path(roundedRect: rect, cornerRadius: 2)
                        c.opacity = piece.opacity
                        c.fill(shape, with: .color(colors[k % colors.count]))
                    }
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    /// Un confetti à l'instant `t` : position, angle, retournement (effet papier), opacité.
    static func piece(_ k: Int, at t: Double, in size: CGSize) -> (x: CGFloat, y: CGFloat, angle: Double,
                                                                   flip: CGFloat, opacity: Double)? {
        // Nombres « au hasard » mais fixes, tirés du numéro (suite de Weyl).
        func u(_ salt: Double) -> Double {
            let v = (Double(k) * 0.618_033_988_75 + salt * 0.754_877_666_2).truncatingRemainder(dividingBy: 1)
            return v < 0 ? v + 1 : v
        }
        let delay = 0.6 * u(0.1)
        let local = t - delay
        guard local > 0, local < duration - delay else { return nil }
        let fall = 0.55 + 0.45 * u(0.3)                          // fraction de la hauteur par seconde
        let x0 = Double(size.width) * u(0.2)
        let sway = 26 * sin(2 * .pi * (0.6 + 0.7 * u(0.4)) * local + 6 * u(0.5))
        let y = -20 + Double(size.height) * fall * local
        guard y < Double(size.height) + 20 else { return nil }
        let fade = min(1, (duration - delay - local) / 0.4)
        return (CGFloat(x0 + sway), CGFloat(y), 360 * u(0.6) + 240 * local * (u(0.7) > 0.5 ? 1 : -1),
                CGFloat(cos(2 * .pi * (1 + 1.5 * u(0.8)) * local)), fade)
    }
}
#endif
