// MascotView.swift — la mascotte à l'écran : le chat chef de gare (choix provisoire).
//
// Elle ne dit jamais « faux ». Elle célèbre, montre GENTIMENT le fourgon resté
// en gare (verdict sûr uniquement), remodèle le mot, ou tend l'oreille quand
// l'écoute n'est pas concluante. Le dessin vit dans `CatStationMaster`.

#if canImport(SwiftUI)
import EveilDesign
import SwiftUI
import WordEndCore

public struct MascotView: View {
    public let action: MascotAction?
    public let isListening: Bool
    public let size: CGFloat

    public init(action: MascotAction?, isListening: Bool, size: CGFloat = 240) {
        self.action = action
        self.isListening = isListening
        self.size = size
    }

    public var body: some View {
        CatStationMaster(mood: mood, size: size)
    }

    /// Humeur du chat selon l'état de l'écoute et le retour de `FeedbackPolicy`.
    var mood: CatMood {
        if isListening { return .listening }
        switch action {
        case .celebrate?: return .cheering
        case .pointCaboose?: return .pointing
        case .modelWord?: return .speaking
        case .listenAgain?: return .puzzled
        case .invite?, nil: return .hello
        }
    }
}
#endif
