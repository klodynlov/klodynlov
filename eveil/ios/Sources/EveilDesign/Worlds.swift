// Worlds.swift — les mondes que traverse le petit train.
//
// Chaque mot bien dit fait partir le train vers un AUTRE MONDE (demande de
// l'utilisateur, 25/09/2026). Ordre fixe, jamais tiré au hasard : un voyage, pas
// une loterie (docs/EVEIL.md § 4.6 : pas de récompenses aléatoires).
//
// ÉBAUCHE : décor unique en attendant les huit mondes dessinés.

#if canImport(SwiftUI)
import SwiftUI

public enum World: Int, CaseIterable, Identifiable, Sendable {
    case countryside, forest, mountains, icefloe, seaside, desert, city, space

    public var id: Int { rawValue }

    /// Le monde suivant du voyage (on boucle après l'espace).
    public var next: World { World(rawValue: (rawValue + 1) % World.allCases.count) ?? .countryside }

    public func name(locale: String) -> String {
        let fr = locale.hasPrefix("fr")
        switch self {
        case .countryside: return fr ? "La campagne" : "The countryside"
        case .forest: return fr ? "La forêt" : "The forest"
        case .mountains: return fr ? "La montagne" : "The mountains"
        case .icefloe: return fr ? "La banquise" : "The ice floe"
        case .seaside: return fr ? "La mer" : "The seaside"
        case .desert: return fr ? "Le désert" : "The desert"
        case .city: return fr ? "La ville" : "The city"
        case .space: return fr ? "L'espace" : "Outer space"
        }
    }

    /// Pictogramme de la « ligne de train » (les gares du voyage).
    public var symbol: String {
        switch self {
        case .countryside: return "leaf.fill"
        case .forest: return "tree.fill"
        case .mountains: return "mountain.2.fill"
        case .icefloe: return "snowflake"
        case .seaside: return "water.waves"
        case .desert: return "sun.max.fill"
        case .city: return "building.2.fill"
        case .space: return "moon.stars.fill"
        }
    }
}

/// Le décor plein écran d'un monde. Contrat de mise en page (le train est posé
/// par l'écran de jeu, pas par le décor) : sol plat de ~0,76 h jusqu'en bas ;
/// haut de l'écran calme (boutons) ; `ignoresSafeArea` ; « Réduire les
/// animations » respecté.
public struct WorldScenery: View {
    public let world: World

    public init(world: World) { self.world = world }

    public var body: some View {
        SceneryView(night: world == .space)
    }
}
#endif
