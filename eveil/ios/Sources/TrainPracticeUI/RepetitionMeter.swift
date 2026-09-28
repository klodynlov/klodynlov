// RepetitionMeter.swift — le décompte : combien de fois encore l'enfant redit le mot.
//
// Demande de l'utilisateur (28/09/2026) : « afficher un décompte pour le nombre de
// fois que l'enfant doit répéter ». Un gros chiffre (ce qui reste, pour l'adulte et
// pour l'enfant qui connaît ses chiffres) et une lanterne par répétition, allumée
// quand le mot a été bien dit (l'enfant non-lecteur compte les lanternes). Seul un
// mot bien dit allume une lanterne (`FeedbackPolicy`) ; un essai incomplet n'en
// éteint jamais, et après trop d'essais le train part quand même (pas de boucle
// d'échec) : le décompte encourage, il ne retient pas.

#if canImport(SwiftUI)
import EveilDesign
import SwiftUI
import WordEndCore

struct RepetitionMeter: View {
    let plan: RepetitionPlan
    let locale: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(plan.isComplete ? EveilPalette.go : Color.white)
                if plan.isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 26, weight: .black))
                        .foregroundStyle(.white)
                } else {
                    Text("\(plan.remaining)")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(EveilPalette.ink)
                        .contentTransition(.numericText(countsDown: true))
                }
            }
            .frame(width: 58, height: 58)
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            HStack(spacing: 8) {
                ForEach(0..<plan.target, id: \.self) { k in
                    RepetitionLantern(lit: k < plan.done)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Capsule().fill(EveilPalette.ink.opacity(0.22)))
        .animation(reduceMotion ? nil : .spring(duration: 0.45, bounce: 0.4), value: plan.done)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        if locale.hasPrefix("fr") {
            return plan.isComplete ? "Toutes les répétitions sont faites"
                                   : "Encore \(plan.remaining) fois sur \(plan.target)"
        }
        return plan.isComplete ? "All repeats done" : "\(plan.remaining) more of \(plan.target)"
    }
}

/// Une lanterne du décompte : éteinte (à dire), allumée d'une étoile (bien dit).
struct RepetitionLantern: View {
    let lit: Bool

    var body: some View {
        ZStack {
            Circle().fill(lit ? EveilPalette.wagonLit : Color.white.opacity(0.35))
            if lit {
                Image(systemName: "star.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 34, height: 34)
        .overlay(Circle().stroke(Color.white.opacity(0.9), lineWidth: 3))
        .shadow(color: lit ? EveilPalette.wagonLit.opacity(0.8) : .clear, radius: lit ? 8 : 0)
        .scaleEffect(lit ? 1.08 : 1)
    }
}
#endif
