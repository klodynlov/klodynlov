// Critters.swift — les bestioles (et petites choses) qui volent derrière le mot.
//
// Exemple fondateur (utilisateur, 25/09/2026) : pour « mouche », des mouches
// volent en arrière-plan ; l'enfant en attrape une et entend son « bzzz ».
// Ce fichier ne fait que les DESSINER (tournées vers la droite, ailes qui
// battent) ; le vol et la capture vivent dans l'écran de jeu.
//
// ÉBAUCHE : pictogrammes système en attendant les dessins.

#if canImport(SwiftUI)
import SwiftUI

public enum CritterKind: String, CaseIterable, Sendable {
    case fly, bee, bird, butterfly, bubble, drop, note, spark, leaf, star, feather, paint, heart, snowflake
}

public struct CritterView: View {
    public let kind: CritterKind
    public let size: CGFloat
    public let flapping: Bool
    public let tint: Color?

    /// `flapping` : ailes qui battent (faux quand la bestiole se pose, pendant l'écoute).
    /// `tint` : variante de couleur (papillons, notes, gouttes de peinture).
    public init(kind: CritterKind, size: CGFloat = 64, flapping: Bool = true, tint: Color? = nil) {
        self.kind = kind
        self.size = size
        self.flapping = flapping
        self.tint = tint
    }

    public var body: some View {
        Image(systemName: Self.symbols[kind] ?? "circle.fill")
            .font(.system(size: size * 0.7))
            .foregroundStyle(tint ?? .orange)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    private static let symbols: [CritterKind: String] = [
        .fly: "ant.fill", .bee: "ladybug.fill", .bird: "bird.fill", .butterfly: "leaf.fill",
        .bubble: "circle", .drop: "drop.fill", .note: "music.note", .spark: "sparkle",
        .leaf: "leaf.fill", .star: "star.fill", .feather: "wind", .paint: "drop.fill",
        .heart: "heart.fill", .snowflake: "snowflake",
    ]
}
#endif
