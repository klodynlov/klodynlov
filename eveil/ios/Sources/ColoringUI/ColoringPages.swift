// ColoringPages.swift — les pages à colorier : des formes fermées dans un carré unité.
//
// Chaque page est une liste de régions (`Path` en coordonnées 0…1), de la plus
// basse à la plus haute : la région 0 est le fond. Toucher une région la remplit ;
// un trait de pinceau reste dans la région où il a commencé (pochoir). Tracés
// provisoires, en attendant les dessins d'un illustrateur.

#if canImport(SwiftUI)
import SwiftUI

public struct ColoringPage: Identifiable, Sendable {
    public let id: String
    public let titleFR: String
    public let titleEN: String
    let regions: [Path]

    public func title(locale: String) -> String { locale.hasPrefix("fr") ? titleFR : titleEN }

    /// Région la plus haute sous le point (coordonnées unité), ou `nil`.
    func region(at p: CGPoint) -> Int? {
        regions.indices.reversed().first { regions[$0].contains(p) }
    }
}

public enum ColoringPages {
    public static let all: [ColoringPage] = [train, cat, house]

    // MARK: Primitives (carré unité)

    static func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, r: CGFloat = 0) -> Path {
        Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: r, style: .continuous)
    }

    /// Rectangle arrondi à gauche seulement (une chaudière qui s'appuie sur la cabine).
    static func roundedLeft(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, r: CGFloat) -> Path {
        UnevenRoundedRectangle(topLeadingRadius: r, bottomLeadingRadius: r,
                               bottomTrailingRadius: 0, topTrailingRadius: 0, style: .continuous)
            .path(in: CGRect(x: x, y: y, width: w, height: h))
    }

    static func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r))
    }

    static func ellipse(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: 2 * rx, height: 2 * ry))
    }

    static func polygon(_ pts: [(CGFloat, CGFloat)]) -> Path {
        var p = Path()
        p.addLines(pts.map { CGPoint(x: $0.0, y: $0.1) })
        p.closeSubpath()
        return p
    }

    static func cloud(_ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat) -> Path {
        var p = Path()
        p.addEllipse(in: CGRect(x: cx - 1.0 * s, y: cy - 0.3 * s, width: 1.0 * s, height: 0.7 * s))
        p.addEllipse(in: CGRect(x: cx - 0.55 * s, y: cy - 0.62 * s, width: 1.05 * s, height: 1.0 * s))
        p.addEllipse(in: CGRect(x: cx + 0.05 * s, y: cy - 0.32 * s, width: 0.95 * s, height: 0.7 * s))
        return p
    }

    // MARK: Pages

    static let train = ColoringPage(id: "train", titleFR: "Le petit train", titleEN: "The little train", regions: [
        rect(0, 0, 1, 1),                                   // fond (ciel)
        circle(0.84, 0.15, 0.085),                           // soleil
        cloud(0.5, 0.17, 0.12),                              // nuage
        rect(0, 0.78, 1, 0.22),                              // herbe
        polygon([(0.15, 0.25), (0.27, 0.25), (0.25, 0.44), (0.17, 0.44)]),   // cheminée
        roundedLeft(0.10, 0.44, 0.295, 0.22, r: 0.07),       // chaudière (bord droit contre la cabine)
        rect(0.39, 0.30, 0.17, 0.36, r: 0.025),              // cabine
        rect(0.42, 0.35, 0.11, 0.10, r: 0.02),               // fenêtre
        rect(0.60, 0.42, 0.32, 0.24, r: 0.035),              // wagon
        circle(0.19, 0.70, 0.058),                           // roues
        circle(0.33, 0.70, 0.058),
        circle(0.49, 0.69, 0.068),
        circle(0.68, 0.71, 0.052),
        circle(0.85, 0.71, 0.052),
    ])

    static let cat = ColoringPage(id: "chat", titleFR: "Le chat chef de gare", titleEN: "The station master cat", regions: [
        rect(0, 0, 1, 1),                                   // fond
        rect(0.28, 0.80, 0.44, 0.22, r: 0.08),               // veste
        polygon([(0.20, 0.42), (0.26, 0.10), (0.44, 0.30)]),  // oreille gauche
        polygon([(0.80, 0.42), (0.74, 0.10), (0.56, 0.30)]),  // oreille droite
        ellipse(0.5, 0.56, 0.33, 0.28),                      // tête
        polygon([(0.30, 0.12), (0.70, 0.12), (0.67, 0.32), (0.33, 0.32)]),   // casquette
        rect(0.31, 0.32, 0.44, 0.06, r: 0.03),               // visière
        circle(0.5, 0.21, 0.035),                            // insigne
        ellipse(0.39, 0.54, 0.045, 0.06),                    // yeux
        ellipse(0.61, 0.54, 0.045, 0.06),
        polygon([(0.46, 0.63), (0.54, 0.63), (0.50, 0.68)]), // nez
        circle(0.31, 0.66, 0.045),                           // joues
        circle(0.69, 0.66, 0.045),
    ])

    static let house = ColoringPage(id: "maison", titleFR: "La maison", titleEN: "The house", regions: [
        rect(0, 0, 1, 1),                                   // ciel
        circle(0.14, 0.14, 0.08),                            // soleil
        cloud(0.62, 0.14, 0.10),                             // nuage
        rect(0, 0.82, 1, 0.18),                              // herbe
        rect(0.60, 0.22, 0.07, 0.16),                        // cheminée
        polygon([(0.14, 0.44), (0.47, 0.18), (0.80, 0.44)]),  // toit
        rect(0.19, 0.44, 0.56, 0.40),                        // mur
        rect(0.41, 0.62, 0.13, 0.22, r: 0.02),               // porte
        rect(0.24, 0.52, 0.12, 0.11, r: 0.015),              // fenêtres
        rect(0.59, 0.52, 0.12, 0.11, r: 0.015),
        rect(0.84, 0.60, 0.04, 0.24),                        // tronc
        circle(0.86, 0.52, 0.10),                            // feuillage
        circle(0.10, 0.86, 0.035),                           // fleurs
        circle(0.20, 0.90, 0.03),
    ])
}
#endif
