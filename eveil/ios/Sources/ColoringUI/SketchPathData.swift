// SketchPathData.swift — relire les pages DESSINÉES EN PYTHON (PagesDessins.swift, généré).
//
// Les pages générées par eveil/outils/coloriages arrivent déjà « au trait » : l'outil
// empile les formes, en tire les traits visibles avec le même algorithme que
// `LineClipper`, et place les points-témoins d'après une carte des zones simulée
// comme `ZoneMap` (mêmes règles de rastérisation et d'étiquetage). Il n'y a donc
// rien à cacher ici : chaque page n'est qu'un trait, des aplats d'encre et ses témoins.
//
// Format des tracés, volontairement minimal : commandes absolues M (déplacer),
// L (ligne), C (courbe de Bézier), Z (fermer), séparées par des espaces, dans le
// repère 1000 × 1000 (l'échelle de travail de `G`), ramené ici au carré unité.
// Les points (témoins, détails) : « x y x y … » en coordonnées unité.

#if canImport(CoreGraphics)
import CoreGraphics
import Foundation

extension G {
    /// Un tracé écrit en commandes absolues M, L, C, Z dans le repère 1000 × 1000.
    static func data(_ text: String) -> CGPath {
        let p = CGMutablePath()
        var command: Character = "M"
        var n: [CGFloat] = []
        n.reserveCapacity(6)
        for token in text.split(separator: " ") {
            if let first = token.first, first.isLetter {
                command = first
                n.removeAll(keepingCapacity: true)
                if first == "Z" { p.closeSubpath() }
                continue
            }
            guard let value = Double(token) else { continue }
            n.append(CGFloat(value) / work)
            switch (command, n.count) {
            case ("M", 2):
                p.move(to: CGPoint(x: n[0], y: n[1]))
                n.removeAll(keepingCapacity: true)
                command = "L"                   // comme en SVG : les paires suivantes sont des lignes
            case ("L", 2):
                p.addLine(to: CGPoint(x: n[0], y: n[1]))
                n.removeAll(keepingCapacity: true)
            case ("C", 6):
                p.addCurve(to: CGPoint(x: n[4], y: n[5]), control1: CGPoint(x: n[0], y: n[1]),
                           control2: CGPoint(x: n[2], y: n[3]))
                n.removeAll(keepingCapacity: true)
            default:
                break
            }
        }
        return p
    }

    /// Des points « x y x y … » (coordonnées unité).
    static func points(_ text: String) -> [CGPoint] {
        let v = text.split(separator: " ").compactMap { Double($0) }
        return stride(from: 0, to: v.count - 1, by: 2).map { CGPoint(x: v[$0], y: v[$0 + 1]) }
    }
}

extension Sketch {
    /// Déclare les zones attendues d'une page générée (un point « x y » par zone).
    mutating func expectAll(_ text: String) {
        for p in G.points(text) { expect(p.x, p.y) }
    }

    /// Déclare les petites zones voulues d'une page générée.
    mutating func expectDetails(_ text: String) {
        for p in G.points(text) { expectDetail(p.x, p.y) }
    }
}
#endif
