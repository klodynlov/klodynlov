// MascotView.swift — la mascotte (placeholder, à confier à un illustrateur).
//
// Elle ne dit jamais « faux ». Elle célèbre, montre GENTIMENT le fourgon resté
// en gare (verdict sûr uniquement), remodèle le mot, ou tend l'oreille quand
// l'écoute n'est pas concluante.

#if canImport(SwiftUI)
import SwiftUI
import WordEndCore

public struct MascotView: View {
    public let action: MascotAction?
    public let isListening: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(action: MascotAction?, isListening: Bool) {
        self.action = action
        self.isListening = isListening
    }

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 72))
                .foregroundStyle(.teal)
                .symbolEffect(.bounce, value: action == .celebrate && !reduceMotion)
            if action == .pointCaboose {
                Image(systemName: "hand.point.right.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)
                    .accessibilityLabel("La mascotte montre le fourgon")
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var symbol: String {
        if isListening { return "ear.fill" }
        switch action {
        case .celebrate?: return "star.circle.fill"
        case .modelWord?: return "speaker.wave.2.fill"
        case .listenAgain?: return "ear"
        case .invite?: return "hand.wave.fill"
        case .pointCaboose?: return "figure.wave"
        case nil: return "figure.wave"
        }
    }
}
#endif
