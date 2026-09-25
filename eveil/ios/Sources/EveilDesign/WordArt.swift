// WordArt.swift — le dessin de chaque mot du petit train.
//
// Contrat : l'objet est dessiné dans un carré `size` × `size`, fond transparent
// (la carte blanche est dessinée par l'écran de jeu). `pulse` augmente à chaque
// fois que l'enfant touche l'image : l'objet « fait son bruit » (la cloche se
// balance, la vache ouvre la bouche…) pendant que le son joue.
//
// ÉBAUCHE : pictogrammes système en attendant les dessins.

#if canImport(SwiftUI)
import SwiftUI

public struct WordArt: View {
    public let wordId: String
    public let size: CGFloat
    public let pulse: Int

    public init(wordId: String, size: CGFloat = 250, pulse: Int = 0) {
        self.wordId = wordId
        self.size = size
        self.pulse = pulse
    }

    /// Vrai si ce mot a un vrai dessin (sinon : pictogramme de repli).
    public static func isIllustrated(_ wordId: String) -> Bool { false }

    public var body: some View {
        Image(systemName: Self.symbols[wordId] ?? "photo")
            .font(.system(size: size * 0.48))
            .foregroundStyle(Self.tints[wordId.unicodeScalars.reduce(0) { $0 + Int($1.value) } % Self.tints.count])
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    private static let symbols: [String: String] = [
        "fr.douche": "shower.fill", "fr.bouche": "mouth.fill", "fr.niche": "house.fill",
        "fr.ruche": "hexagon.fill", "fr.mouche": "ladybug.fill", "fr.vache": "pawprint.fill",
        "fr.biche": "leaf.fill", "fr.tasse": "cup.and.saucer.fill", "fr.minouche": "cat.fill",
        "fr.perruche": "bird.fill", "fr.saucisse": "fork.knife", "fr.trousse": "pencil.and.ruler.fill",
        "en.fish": "fish.fill", "en.dish": "fork.knife", "en.push": "hand.point.right.fill",
        "en.wash": "drop.fill", "en.goose": "bird.fill", "en.moose": "pawprint.fill",
        "en.ice": "snowflake", "en.piece": "puzzlepiece.fill", "en.bus": "bus.fill",
        "en.radish": "carrot.fill", "en.tennis": "tennisball.fill", "en.brush": "paintbrush.fill",
    ]
    private static let tints: [Color] = [.blue, .orange, .pink, .purple, .teal, .indigo, .green, .red]
}
#endif
