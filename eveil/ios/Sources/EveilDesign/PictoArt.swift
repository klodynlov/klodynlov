// PictoArt.swift — les pictos du train des phrases : les dessins des mots, et les autres.
//
// Un picto s'affiche par son identifiant :
//   • un mot du petit train (« fr.vache », « en.fish »…) : son dessin vivant (`WordArt`) ;
//   • un verbe (« verbe.manger »), un lieu (« lieu.niche »), Lou (« perso.lou ») : un dessin
//     fait en Python et relu sur planche (eveil/outils/pictos → `PictoDessins.swift`, généré).
// Même repère que `WordArt` : un carré 200 × 200, fond transparent (la carte blanche est
// dessinée par l'écran). Un LIEU porte des ancres : où poser un personnage « dans »,
// « sur », « sous », « devant », « derrière » — et ce qui passe devant lui (`front`).

#if canImport(SwiftUI)
import SwiftUI

/// Les prépositions de lieu (niveau 3 du train des phrases).
public enum PictoPreposition: String, CaseIterable, Sendable {
    case dans, sur, sous, devant, derriere
}

/// Ordre de dessin d'un personnage posé sur un lieu.
public enum PictoOrder: Sendable {
    case front      // le lieu, puis le personnage
    case inside     // le fond du lieu, le personnage, puis ce qui passe devant (bord de la boîte…)
    case behind     // le personnage, puis le lieu (il dépasse à peine)
}

/// Où poser un personnage : point bas-milieu (repère 200 × 200 du lieu), taille relative.
public struct PictoAnchor: Equatable, Sendable {
    public let x: CGFloat
    public let y: CGFloat
    /// Hauteur du carré du personnage / côté du lieu.
    public let size: CGFloat
    public let order: PictoOrder
}

/// Un picto dessiné : des aplats et des traits, du fond vers l'avant.
public struct PictoDrawing: Sendable {
    struct Op: Sendable {
        let path: Path
        let rgba: UInt32
        /// 0 = aplat ; sinon épaisseur du trait (bouts ronds).
        let width: CGFloat
        /// Calque qui passe DEVANT le personnage (lieux seulement).
        let front: Bool
    }

    public enum Layers: Sendable { case all, back, front }

    private(set) var ops: [Op] = []
    public private(set) var anchors: [PictoPreposition: PictoAnchor] = [:]

    init() {}

    mutating func fill(_ rgba: UInt32, _ data: String, front: Bool = false) {
        ops.append(Op(path: PictoPath.parse(data), rgba: rgba, width: 0, front: front))
    }

    mutating func stroke(_ rgba: UInt32, _ width: CGFloat, _ data: String, front: Bool = false) {
        ops.append(Op(path: PictoPath.parse(data), rgba: rgba, width: width, front: front))
    }

    mutating func anchor(_ preposition: PictoPreposition, x: CGFloat, y: CGFloat, size: CGFloat, order: PictoOrder) {
        anchors[preposition] = PictoAnchor(x: x, y: y, size: size, order: order)
    }

    /// Peint le picto dans `context`, déjà placé dans le repère 200 × 200.
    public func paint(_ context: GraphicsContext, layers: Layers = .all) {
        for op in ops {
            if layers == .back && op.front { continue }
            if layers == .front && !op.front { continue }
            let color = Color(.sRGB,
                              red: Double((op.rgba >> 24) & 0xFF) / 255,
                              green: Double((op.rgba >> 16) & 0xFF) / 255,
                              blue: Double((op.rgba >> 8) & 0xFF) / 255,
                              opacity: Double(op.rgba & 0xFF) / 255)
            if op.width > 0 {
                context.stroke(op.path, with: .color(color),
                               style: StrokeStyle(lineWidth: op.width, lineCap: .round, lineJoin: .round))
            } else {
                context.fill(op.path, with: .color(color))
            }
        }
    }
}

/// La bibliothèque des pictos dessinés (le contenu est généré : `PictoDessins.swift`).
public enum PictoLibrary {
    public static func drawing(_ id: String) -> PictoDrawing? { drawn[id] }

    /// Vrai si l'identifiant a un dessin (mot du petit train ou picto dessiné).
    public static func isDrawn(_ id: String) -> Bool { drawn[id] != nil || WordArt.isIllustrated(id) }

    public static var ids: [String] { drawn.keys.sorted() }
}

/// Un picto à l'écran : le dessin vivant d'un mot, ou un picto dessiné, dans un carré `size`.
public struct PictoView: View {
    public let id: String
    public let size: CGFloat
    public let pulse: Int

    public init(id: String, size: CGFloat = 200, pulse: Int = 0) {
        self.id = id
        self.size = size
        self.pulse = pulse
    }

    public var body: some View {
        if WordArt.isIllustrated(id) {
            WordArt(wordId: id, size: size, pulse: pulse)
        } else if let drawing = PictoLibrary.drawing(id) {
            PictoCanvas(drawing: drawing, layers: .all)
                .frame(width: size, height: size)
                .accessibilityHidden(true)
        } else {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: size * 0.4))
                .foregroundStyle(.secondary)
                .frame(width: size, height: size)
                .accessibilityHidden(true)
        }
    }
}

/// Un picto dessiné, mis à l'échelle de sa place (repère 200 × 200 centré).
public struct PictoCanvas: View {
    public let drawing: PictoDrawing
    public let layers: PictoDrawing.Layers

    public init(drawing: PictoDrawing, layers: PictoDrawing.Layers = .all) {
        self.drawing = drawing
        self.layers = layers
    }

    public var body: some View {
        Canvas { context, area in
            let k = min(area.width, area.height) / 200
            var g = context
            g.translateBy(x: (area.width - 200 * k) / 2, y: (area.height - 200 * k) / 2)
            g.scaleBy(x: k, y: k)
            drawing.paint(g, layers: layers)
        }
    }
}

/// Relit les tracés générés : commandes absolues M, L, C, Z séparées par des espaces.
enum PictoPath {
    static func parse(_ text: String) -> Path {
        var path = Path()
        var command: Character = "M"
        var n: [CGFloat] = []
        n.reserveCapacity(6)
        for token in text.split(separator: " ") {
            if let first = token.first, first.isLetter {
                command = first
                n.removeAll(keepingCapacity: true)
                if first == "Z" { path.closeSubpath() }
                continue
            }
            guard let value = Double(token) else { continue }
            n.append(CGFloat(value))
            switch (command, n.count) {
            case ("M", 2):
                path.move(to: CGPoint(x: n[0], y: n[1]))
                n.removeAll(keepingCapacity: true)
                command = "L"                   // comme en SVG : les paires suivantes sont des lignes
            case ("L", 2):
                path.addLine(to: CGPoint(x: n[0], y: n[1]))
                n.removeAll(keepingCapacity: true)
            case ("C", 6):
                path.addCurve(to: CGPoint(x: n[4], y: n[5]), control1: CGPoint(x: n[0], y: n[1]),
                              control2: CGPoint(x: n[2], y: n[3]))
                n.removeAll(keepingCapacity: true)
            default:
                break
            }
        }
        return path
    }
}
#endif
