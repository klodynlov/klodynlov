// Worlds.swift — les mondes que traverse le petit train.
//
// Chaque mot bien dit fait partir le train vers un AUTRE MONDE (demande de
// l'utilisateur, 25/09/2026). Ordre fixe, jamais tiré au hasard : un voyage, pas
// une loterie (docs/EVEIL.md § 4.6 : pas de récompenses aléatoires).
//
// Contrat de mise en page de chaque décor (l'écran de jeu pose par-dessus le
// train, la carte du mot, le chat et sa bulle) :
//   - bande de SOL plate de 0,76 h jusqu'en bas (le train roule vers 0,73–0,76 h) ;
//   - haut de l'écran (12 %) calme : boutons en haut à gauche et à droite ;
//   - décor sur les côtés et au fond ; bande du milieu (≈ 25–55 % h, 70 % central
//     de la largeur) claire et dégagée : carte, chat et bulle y vivent ;
//   - portrait ET paysage (tout est calculé depuis w × h), `ignoresSafeArea` ;
//   - mouvement d'ambiance doux et bon marché, figé si « Réduire les animations ».
//
// Un fichier par monde (`World…Scene.swift`) ; outils communs : `WorldKit.swift`.

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

    /// Pictogramme de la « ligne de train » (les gares du voyage) : un symbole
    /// système distinct par monde (vérifié par les tests de rendu).
    public var symbol: String {
        switch self {
        case .countryside: return "camera.macro"        // une fleur des champs
        case .forest: return "tree.fill"
        case .mountains: return "mountain.2.fill"
        case .icefloe: return "snowflake"
        case .seaside: return "sailboat.fill"
        case .desert: return "sun.max.fill"
        case .city: return "building.2.fill"
        case .space: return "moon.stars.fill"
        }
    }

    /// Vrai si le ciel est sombre : ce qui est écrit ou dessiné en encre foncée
    /// directement sur le décor (et non sur une carte blanche) doit passer en clair.
    public var isDark: Bool { self == .space }
}

/// Le décor plein écran d'un monde (voir le contrat en tête de fichier).
public struct WorldScenery: View {
    public let world: World

    public init(world: World) { self.world = world }

    public var body: some View {
        GeometryReader { geo in
            WorldSceneryCanvas(world: world, frame: SceneryFrame(geo.size))
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// Aiguillage vers le décor du monde ; ses champs sont de simples valeurs, donc
/// SwiftUI ne le recalcule pas quand l'écran de jeu change d'état.
struct WorldSceneryCanvas: View {
    let world: World
    let frame: SceneryFrame

    var body: some View {
        Group {
            switch world {
            case .countryside: CountrysideScene(f: frame)
            case .forest: ForestScene(f: frame)
            case .mountains: MountainsScene(f: frame)
            case .icefloe: IcefloeScene(f: frame)
            case .seaside: SeasideScene(f: frame)
            case .desert: DesertScene(f: frame)
            case .city: CityScene(f: frame)
            case .space: SpaceScene(f: frame)
            }
        }
        .frame(width: frame.w, height: frame.h)
        .clipped()
    }
}

#Preview("Le voyage") {
    ScrollView(.horizontal) {
        HStack(spacing: 12) {
            ForEach(World.allCases) { world in
                WorldScenery(world: world).frame(width: 417, height: 597)
            }
        }
    }
}
#endif
