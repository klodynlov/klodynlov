// TrainView.swift — le petit train : une locomotive, un wagon par syllabe
// ORALE, et le fourgon de queue pour la consonne finale.
//
// Métaphore choisie : quand l'enfant produit la fin du mot, le fourgon
// « s'accroche » au train. S'il manque, il est « resté en gare » : une image
// concrète, non culpabilisante, et le son du fourgon (« chhh », la vapeur ;
// « sss », le serpent) est un symbole sonore classique en orthophonie.
//
// États du fourgon (cf. `CabooseState`) : accroché, montré (seulement sur un
// verdict SÛR), en attente (neutre), absent (mot sans consonne finale).

#if canImport(SwiftUI)
import SwiftUI
import WordEndCore

public struct TrainView: View {
    public let wagons: [String]
    public let lit: [Bool]
    public let cabooseLabel: String?
    public let caboose: CabooseState
    public var showsLetters = true            // lettres pour l'adulte ; l'enfant voit les couleurs

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    public init(wagons: [String], lit: [Bool], cabooseLabel: String?, caboose: CabooseState,
                showsLetters: Bool = true) {
        self.wagons = wagons
        self.lit = lit
        self.cabooseLabel = cabooseLabel
        self.caboose = caboose
        self.showsLetters = showsLetters
    }

    public var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            Image(systemName: "train.side.front.car")
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(.red)
                .accessibilityHidden(true)
            ForEach(Array(wagons.enumerated()), id: \.offset) { index, label in
                WagonView(label: label, lit: lit.indices.contains(index) && lit[index],
                          showsLetters: showsLetters)
            }
            if let cabooseLabel, caboose != .none {
                CabooseView(label: cabooseLabel, state: caboose, showsLetters: showsLetters)
                    .padding(.leading, caboose == .hooked ? 0 : 36)      // décroché = écart visible
                    .scaleEffect(caboose == .pointed && pulse && !reduceMotion ? 1.08 : 1.0)
            }
        }
        .animation(reduceMotion ? nil : .spring(duration: 0.45), value: lit)
        .animation(reduceMotion ? nil : .spring(duration: 0.45), value: caboose)
        .onChange(of: caboose) { _, newValue in
            pulse = false
            if newValue == .pointed && !reduceMotion {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { pulse = true }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        let cars = wagons.enumerated().map { i, w in
            "wagon \(w) " + (lit.indices.contains(i) && lit[i] ? "allumé" : "éteint")
        }
        var parts = ["Le petit train"] + cars
        if let cabooseLabel {
            switch caboose {
            case .hooked: parts.append("fourgon \(cabooseLabel) accroché")
            case .pointed: parts.append("fourgon \(cabooseLabel) resté en gare")
            case .waiting: parts.append("fourgon \(cabooseLabel) en attente")
            case .none: break
            }
        }
        return parts.joined(separator: ", ")
    }
}

struct WagonView: View {
    let label: String
    let lit: Bool
    let showsLetters: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(showsLetters ? label : " ")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(lit ? Color.primary : Color.secondary)
                .frame(minWidth: 88, minHeight: 64)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(lit ? Color.yellow : Color.gray.opacity(0.25))
                        .shadow(color: lit ? .yellow.opacity(0.7) : .clear, radius: lit ? 12 : 0)
                )
            HStack(spacing: 22) {
                Circle().frame(width: 18, height: 18)
                Circle().frame(width: 18, height: 18)
            }
            .foregroundStyle(.secondary)
        }
    }
}

struct CabooseView: View {
    let label: String
    let state: CabooseState
    let showsLetters: Bool

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .top) {
                Text(showsLetters ? label : " ")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .frame(minWidth: 72, minHeight: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(state == .hooked ? Color.orange : Color.orange.opacity(0.25))
                    )
                if state == .hooked {
                    Image(systemName: "cloud.fill")              // la « vapeur » du son final
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.9))
                        .offset(y: -30)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            HStack(spacing: 18) {
                Circle().frame(width: 16, height: 16)
                Circle().frame(width: 16, height: 16)
            }
            .foregroundStyle(.secondary)
        }
    }
}

#Preview("Fin manquante") {
    TrainView(wagons: ["mi", "nou"], lit: [true, true], cabooseLabel: "ch", caboose: .pointed)
        .padding()
}

#Preview("Complet") {
    TrainView(wagons: ["dou"], lit: [true], cabooseLabel: "ch", caboose: .hooked)
        .padding()
}
#endif
