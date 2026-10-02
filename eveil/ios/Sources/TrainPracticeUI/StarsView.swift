// StarsView.swift — les étoiles : plus c'est bien dit, plus le train en donne.
//
// Demande de l'utilisateur (28/09/2026) : « ajouter un score selon la prononciation,
// plus c'est bien répété plus le user a des points ». Ce sont des étoiles de JEU
// (`Stars.earned`) et non un score de langage (docs/EVEIL.md § 7.3) : mot entier 3,
// toutes les syllabes sans la fin 2, doute du détecteur 2, syllabe en moins 1 (l'essai
// compte), rien entendu 0 — on n'en perd jamais. Elles s'envolent du train vers le
// compteur ; le trésor (un total, rien d'autre) reste sur l'iPad. L'adulte peut les
// masquer dans l'espace des grands.
//
// Le mouvement est calculé à partir de l'heure (`TimelineView`), comme tout le reste :
// pas de boucle d'animation SwiftUI.

#if canImport(SwiftUI)
import EveilDesign
import SwiftUI

/// Le compteur d'étoiles : une pastille dorée qui rebondit quand il augmente.
public struct StarCounter: View {
    public let count: Int
    public var size: CGFloat = 26
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(count: Int, size: CGFloat = 26) {
        self.count = count
        self.size = size
    }

    public var body: some View {
        HStack(spacing: size * 0.3) {
            Image(systemName: "star.fill")
                .font(.system(size: size, weight: .bold))
                .foregroundStyle(EveilPalette.wagonLit)
                .shadow(color: EveilPalette.wagonLit.opacity(0.7), radius: 6)
            Text("\(count)")
                .font(.system(size: size * 1.05, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText(value: Double(count)))
                .monospacedDigit()
        }
        .padding(.horizontal, size * 0.6)
        .padding(.vertical, size * 0.3)
        .background(Capsule().fill(EveilPalette.ink.opacity(0.35)))
        .animation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.5), value: count)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(count) ★")
    }
}

/// Une volée d'étoiles gagnées par un essai.
struct StarBurst: Equatable, Identifiable {
    let id = UUID()
    let count: Int
    let start: Date
    /// Durée du vol d'une étoile, et décalage entre deux étoiles.
    static let flight = 0.9
    static let stagger = 0.18

    var duration: Double { StarBurst.flight + StarBurst.stagger * Double(max(0, count - 1)) }
}

/// Les étoiles qui s'envolent de `from` vers `to` (le compteur), une à une.
struct StarBurstLayer: View {
    let burst: StarBurst
    let from: CGPoint
    let to: CGPoint

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(burst.start)
            Canvas { context, _ in
                for k in 0..<burst.count {
                    let t = (elapsed - StarBurst.stagger * Double(k)) / StarBurst.flight
                    guard t > 0, t < 1 else { continue }
                    let p = point(at: t, index: k)
                    let scale = 1 + 0.6 * sin(.pi * t)
                    let r = 16 * scale
                    let star = starPath(center: p, radius: r)
                    context.fill(star, with: .color(EveilPalette.wagonLit.opacity(t > 0.85 ? (1 - t) / 0.15 : 1)))
                    context.stroke(star, with: .color(.white.opacity(0.9)), lineWidth: 2.5)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Un arc qui monte d'abord (l'étoile jaillit du train), puis file vers le compteur.
    private func point(at t: Double, index k: Int) -> CGPoint {
        let spread = CGFloat(k - 1) * 60
        let control = CGPoint(x: from.x + spread, y: min(from.y, to.y) - 40 + CGFloat(k % 2) * 30)
        let u = CGFloat(1 - (1 - t) * (1 - t))           // part vite, se pose en douceur
        let a = CGPoint(x: from.x + (control.x - from.x) * u, y: from.y + (control.y - from.y) * u)
        let b = CGPoint(x: control.x + (to.x - control.x) * u, y: control.y + (to.y - control.y) * u)
        return CGPoint(x: a.x + (b.x - a.x) * u, y: a.y + (b.y - a.y) * u)
    }

    private func starPath(center c: CGPoint, radius r: Double) -> Path {
        var path = Path()
        for i in 0..<10 {
            let angle = -Double.pi / 2 + Double(i) * .pi / 5
            let rr = i.isMultiple(of: 2) ? r : r * 0.45
            let p = CGPoint(x: c.x + CGFloat(cos(angle) * rr), y: c.y + CGFloat(sin(angle) * rr))
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }
}
#endif
