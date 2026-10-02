// WorldKit.swift — la boîte à outils des décors (et des bestioles) : horloge
// douce, hasard reproductible, courbes et petits motifs partagés.
//
// Principe de performance (iPad Pro 11" M1) : tout ce qui ne bouge pas est peint
// UNE fois dans un `Canvas` (repeint seulement si la taille change) ; ce qui
// bouge est fait de petites vues déplacées par transformations (`offset`,
// `rotationEffect`, `opacity`), à 30 images/s au plus pour les décors. Aucun
// flou : les halos sont des dégradés radiaux vers le transparent.
//
// Noms préfixés (`Scenery…`, `SketchPen`) : le module est partagé avec d'autres
// dessins, on évite les collisions d'extensions génériques.

#if canImport(SwiftUI)
import SwiftUI

// MARK: - Horloge

/// Temps figé (secondes) pour les rendus de test et les aperçus ; `nil` = le vrai temps.
struct SceneryFrozenTimeKey: EnvironmentKey {
    static let defaultValue: Double? = nil
}

extension EnvironmentValues {
    /// Fige les décors et les bestioles à l'instant donné (rendus PNG, aperçus).
    var sceneryFrozenTime: Double? {
        get { self[SceneryFrozenTimeKey.self] }
        set { self[SceneryFrozenTimeKey.self] = newValue }
    }
}

/// Couche animée d'un décor : `content(t)` reçoit le temps en secondes.
/// « Réduire les animations » → image fixe (t = 0), aucune horloge.
struct SceneryAmbient<Content: View>: View {
    var fps: Double = 30
    @ViewBuilder var content: (Double) -> Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.sceneryFrozenTime) private var frozenTime

    var body: some View {
        if let t = frozenTime ?? (reduceMotion ? 0 : nil) {
            content(t)
        } else {
            TimelineView(.animation(minimumInterval: 1 / fps)) { timeline in
                content(timeline.date.timeIntervalSinceReferenceDate)
            }
        }
    }
}

/// Mouvements élémentaires, tous périodiques (rien d'aléatoire à l'écran).
enum SceneryMotion {
    /// Oscillation douce dans [-1, 1] ; `phase` en tours.
    static func swing(_ t: Double, period: Double, phase: Double = 0) -> CGFloat {
        CGFloat(sin(2 * Double.pi * (t / period + phase)))
    }

    /// Progression qui boucle dans [0, 1) (défilement, chute, dérive).
    static func loop(_ t: Double, period: Double, phase: Double = 0) -> CGFloat {
        let v = (t / period + phase).truncatingRemainder(dividingBy: 1)
        return CGFloat(v < 0 ? v + 1 : v)
    }

    /// Scintillement doux dans [0, 1] (étoiles, fenêtres, lueurs).
    static func twinkle(_ t: Double, period: Double, phase: Double = 0) -> CGFloat {
        0.5 + 0.5 * swing(t, period: period, phase: phase)
    }
}

// MARK: - Hasard reproductible

/// SplitMix64 : le même semis (fleurs, étoiles, galets) à chaque affichage.
struct SceneryRandom {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// Uniforme dans [0, 1).
    mutating func unit() -> CGFloat { CGFloat(next() >> 11) / 9_007_199_254_740_992 }

    mutating func range(_ a: CGFloat, _ b: CGFloat) -> CGFloat { a + (b - a) * unit() }

    mutating func pick<T>(_ items: [T]) -> T { items[Int(next() % UInt64(items.count))] }
}

// MARK: - Géométrie

/// Repère d'un décor : largeur, hauteur, et la « petite dimension » `s` qui
/// dimensionne les objets (mêmes proportions en portrait et en paysage).
struct SceneryFrame: Equatable {
    let w: CGFloat
    let h: CGFloat

    init(_ size: CGSize) {
        w = max(size.width, 1)
        h = max(size.height, 1)
    }

    var s: CGFloat { min(w, h) }
    /// Haut de la bande de sol (contrat : le train roule vers 0,73–0,76 h).
    var ground: CGFloat { h * 0.76 }

    /// Le gros bouton « À toi ! » vit au centre du sol : on n'y sème rien (fractions de w et h).
    static func isButtonZone(_ x: CGFloat, _ y: CGFloat) -> Bool {
        x > 0.28 && x < 0.72 && y < 0.88
    }

    func x(_ f: CGFloat) -> CGFloat { w * f }
    func y(_ f: CGFloat) -> CGFloat { h * f }
    func p(_ fx: CGFloat, _ fy: CGFloat) -> CGPoint { CGPoint(x: w * fx, y: h * fy) }
}

enum SceneryPath {
    /// Courbe douce (Catmull-Rom) passant par `points`, fermée jusqu'à `bottom`.
    static func ridge(_ points: [CGPoint], bottom: CGFloat) -> Path {
        var p = Path()
        guard let first = points.first, let last = points.last else { return p }
        p.move(to: CGPoint(x: first.x, y: bottom))
        p.addLine(to: first)
        addSmooth(&p, through: points)
        p.addLine(to: CGPoint(x: last.x, y: bottom))
        p.closeSubpath()
        return p
    }

    /// Ajoute une courbe douce passant par tous les points (le premier est le point courant).
    static func addSmooth(_ p: inout Path, through pts: [CGPoint]) {
        guard pts.count > 1 else { return }
        for i in 0..<(pts.count - 1) {
            let p0 = pts[max(i - 1, 0)], p1 = pts[i], p2 = pts[i + 1], p3 = pts[min(i + 2, pts.count - 1)]
            let c1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
            let c2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
            p.addCurve(to: p2, control1: c1, control2: c2)
        }
    }

    /// Chaîne de montagnes aux sommets arrondis : `peaks` alterne creux et sommets.
    static func range(_ pts: [CGPoint], bottom: CGFloat, roundness: CGFloat = 0.16) -> Path {
        var p = Path()
        guard pts.count > 2, let first = pts.first, let last = pts.last else { return p }
        p.move(to: CGPoint(x: first.x, y: bottom))
        p.addLine(to: first)
        for i in 1..<(pts.count - 1) {
            let prev = pts[i - 1], cur = pts[i], next = pts[i + 1]
            let a = CGPoint(x: cur.x + (prev.x - cur.x) * roundness, y: cur.y + (prev.y - cur.y) * roundness)
            let b = CGPoint(x: cur.x + (next.x - cur.x) * roundness, y: cur.y + (next.y - cur.y) * roundness)
            p.addLine(to: a)
            p.addQuadCurve(to: b, control: cur)
        }
        p.addLine(to: last)
        p.addLine(to: CGPoint(x: last.x, y: bottom))
        p.closeSubpath()
        return p
    }

    static func circle(_ c: CGPoint, _ r: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
    }

    static func ellipse(_ c: CGPoint, _ rx: CGFloat, _ ry: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: c.x - rx, y: c.y - ry, width: 2 * rx, height: 2 * ry))
    }

    /// Polygone aux coins adoucis (étoiles, feuilles, pics).
    static func polygon(_ pts: [CGPoint]) -> Path {
        var p = Path()
        p.addLines(pts)
        p.closeSubpath()
        return p
    }

    /// Étoile à `branches` branches, pointe vers le haut.
    static func star(_ c: CGPoint, outer: CGFloat, inner: CGFloat, branches: Int = 5, rotation: CGFloat = 0) -> Path {
        var pts: [CGPoint] = []
        for i in 0..<(branches * 2) {
            let r = i.isMultiple(of: 2) ? outer : inner
            let a = -CGFloat.pi / 2 + rotation + CGFloat(i) * .pi / CGFloat(branches)
            pts.append(CGPoint(x: c.x + r * cos(a), y: c.y + r * sin(a)))
        }
        return polygon(pts)
    }
}

// MARK: - Crayon

/// Enveloppe de `GraphicsContext` : formes pleines, dégradés, halos sans flou.
struct SketchPen {
    var ctx: GraphicsContext

    func fill(_ path: Path, _ color: Color) { ctx.fill(path, with: .color(color)) }

    /// Dégradé vertical de `y0` à `y1`.
    func fill(_ path: Path, top y0: CGFloat, bottom y1: CGFloat, _ colors: [Color]) {
        ctx.fill(path, with: .linearGradient(Gradient(colors: colors),
                                             startPoint: CGPoint(x: 0, y: y0), endPoint: CGPoint(x: 0, y: y1)))
    }

    /// Dégradé entre deux points quelconques.
    func fill(_ path: Path, from a: CGPoint, to b: CGPoint, _ colors: [Color]) {
        ctx.fill(path, with: .linearGradient(Gradient(colors: colors), startPoint: a, endPoint: b))
    }

    /// Dégradé à arrêts explicites (ciels).
    func fill(_ path: Path, top y0: CGFloat, bottom y1: CGFloat, stops: [Gradient.Stop]) {
        ctx.fill(path, with: .linearGradient(Gradient(stops: stops),
                                             startPoint: CGPoint(x: 0, y: y0), endPoint: CGPoint(x: 0, y: y1)))
    }

    func stroke(_ path: Path, _ color: Color, width: CGFloat, dash: [CGFloat] = []) {
        ctx.stroke(path, with: .color(color),
                   style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round, dash: dash))
    }

    func circle(_ c: CGPoint, _ r: CGFloat, _ color: Color) { fill(SceneryPath.circle(c, r), color) }

    func ellipse(_ c: CGPoint, _ rx: CGFloat, _ ry: CGFloat, _ color: Color) {
        fill(SceneryPath.ellipse(c, rx, ry), color)
    }

    func rect(_ r: CGRect, _ color: Color, corner: CGFloat = 0) {
        fill(Path(roundedRect: r, cornerRadius: corner, style: .continuous), color)
    }

    /// Halo : dégradé radial vers le transparent (remplace un flou, coût nul à l'affichage).
    func glow(_ c: CGPoint, _ radius: CGFloat, _ color: Color, strength: Double = 0.55) {
        ctx.fill(SceneryPath.circle(c, radius),
                 with: .radialGradient(Gradient(colors: [color.opacity(strength), color.opacity(strength * 0.35),
                                                         color.opacity(0)]),
                                       center: c, startRadius: 0, endRadius: radius))
    }

    /// Même dessin dans un repère local (origine `at`, rotation, échelle).
    func local(at origin: CGPoint, rotation: Angle = .zero, scale: CGFloat = 1,
               _ draw: (SketchPen) -> Void) {
        var c = ctx
        c.translateBy(x: origin.x, y: origin.y)
        if rotation != .zero { c.rotate(by: rotation) }
        if scale != 1 { c.scaleBy(x: scale, y: scale) }
        draw(SketchPen(ctx: c))
    }

    /// Dessin découpé dans `path` (calottes de neige, reflets).
    func clipped(to path: Path, _ draw: (SketchPen) -> Void) {
        var c = ctx
        c.clip(to: path)
        draw(SketchPen(ctx: c))
    }
}

// MARK: - Motifs partagés entre les mondes

enum SceneryMotif {
    /// Arbre rond : tronc, couronne de boules, reflets clairs.
    static func roundTree(_ pen: SketchPen, base: CGPoint, height hgt: CGFloat,
                          leaf: Color, leafLight: Color, trunk: Color) {
        let r = hgt * 0.30
        pen.rect(CGRect(x: base.x - hgt * 0.055, y: base.y - hgt * 0.52, width: hgt * 0.11, height: hgt * 0.52),
                 trunk, corner: hgt * 0.04)
        let cy = base.y - hgt + r
        pen.circle(CGPoint(x: base.x - r * 0.62, y: cy + r * 0.55), r * 0.78, leaf)
        pen.circle(CGPoint(x: base.x + r * 0.64, y: cy + r * 0.50), r * 0.80, leaf)
        pen.circle(CGPoint(x: base.x, y: cy), r, leaf)
        pen.circle(CGPoint(x: base.x - r * 0.30, y: cy - r * 0.28), r * 0.42, leafLight)
        pen.circle(CGPoint(x: base.x - r * 0.78, y: cy + r * 0.40), r * 0.26, leafLight)
    }

    /// Sapin : tronc et trois étages arrondis.
    static func pine(_ pen: SketchPen, base: CGPoint, height hgt: CGFloat,
                     leaf: Color, leafLight: Color, trunk: Color) {
        let wid = hgt * 0.62
        pen.rect(CGRect(x: base.x - hgt * 0.05, y: base.y - hgt * 0.22, width: hgt * 0.10, height: hgt * 0.22),
                 trunk, corner: hgt * 0.02)
        for tier in 0..<3 {
            let f = CGFloat(tier)
            let bottom = base.y - hgt * (0.14 + f * 0.24)
            let half = wid * (0.5 - f * 0.11)
            let top = bottom - hgt * (0.44 - f * 0.04)
            var p = Path()
            p.move(to: CGPoint(x: base.x - half, y: bottom))
            p.addQuadCurve(to: CGPoint(x: base.x + half, y: bottom),
                           control: CGPoint(x: base.x, y: bottom + hgt * 0.07))
            p.addLine(to: CGPoint(x: base.x + half * 0.12, y: top + hgt * 0.02))
            p.addQuadCurve(to: CGPoint(x: base.x - half * 0.12, y: top + hgt * 0.02),
                           control: CGPoint(x: base.x, y: top - hgt * 0.02))
            p.closeSubpath()
            pen.fill(p, leaf)
            // Reflet sur le flanc gauche de l'étage.
            var r = Path()
            r.move(to: CGPoint(x: base.x - half * 0.72, y: bottom - hgt * 0.02))
            r.addLine(to: CGPoint(x: base.x - half * 0.14, y: top + hgt * 0.06))
            r.addLine(to: CGPoint(x: base.x - half * 0.30, y: bottom - hgt * 0.01))
            r.closeSubpath()
            pen.fill(r, leafLight)
        }
    }

    /// Petite fleur : cinq pétales autour d'un cœur.
    static func flower(_ pen: SketchPen, at c: CGPoint, radius r: CGFloat, petal: Color, heart: Color) {
        for i in 0..<5 {
            let a = CGFloat(i) * 2 * .pi / 5 - .pi / 2
            pen.circle(CGPoint(x: c.x + cos(a) * r * 0.62, y: c.y + sin(a) * r * 0.62), r * 0.46, petal)
        }
        pen.circle(c, r * 0.38, heart)
    }

    /// Touffe d'herbe : trois brins.
    static func tuft(_ pen: SketchPen, at c: CGPoint, size z: CGFloat, _ color: Color) {
        var p = Path()
        for (dx, tip) in [(-0.45, CGPoint(x: -0.75, y: -0.9)), (0.0, CGPoint(x: 0.05, y: -1.25)),
                          (0.45, CGPoint(x: 0.8, y: -0.85))] as [(CGFloat, CGPoint)] {
            p.move(to: CGPoint(x: c.x + dx * z - z * 0.18, y: c.y))
            p.addQuadCurve(to: CGPoint(x: c.x + tip.x * z, y: c.y + tip.y * z),
                           control: CGPoint(x: c.x + dx * z, y: c.y - z * 0.45))
            p.addQuadCurve(to: CGPoint(x: c.x + dx * z + z * 0.18, y: c.y),
                           control: CGPoint(x: c.x + dx * z + z * 0.12, y: c.y - z * 0.4))
            p.closeSubpath()
        }
        pen.fill(p, color)
    }

    /// Galet arrondi avec son reflet.
    static func pebble(_ pen: SketchPen, at c: CGPoint, size z: CGFloat, _ color: Color, light: Color) {
        pen.ellipse(c, z, z * 0.62, color)
        pen.ellipse(CGPoint(x: c.x - z * 0.25, y: c.y - z * 0.2), z * 0.42, z * 0.2, light)
    }
}

/// Un nuage qui dérive lentement de gauche à droite et revient par la gauche.
struct SceneryDriftingCloud: Identifiable {
    let id: Int
    let y: CGFloat          // fraction de h
    let width: CGFloat      // fraction de s
    let period: Double      // secondes pour traverser
    let phase: Double       // position de départ (tours)
    var opacity: Double = 0.92

    /// Position horizontale (points) à l'instant `t`.
    func x(_ t: Double, frame f: SceneryFrame) -> CGFloat {
        let span = f.w + f.s * width * 2
        return SceneryMotion.loop(t, period: period, phase: phase) * span - f.s * width
    }
}

/// Couche de nuages à la dérive (vue animée, un calque par nuage).
struct SceneryCloudLayer: View {
    let frame: SceneryFrame
    let clouds: [SceneryDriftingCloud]
    var color: Color = .white

    var body: some View {
        SceneryAmbient { t in
            ZStack {
                ForEach(clouds) { c in
                    CloudShape().fill(color.opacity(c.opacity))
                        .frame(width: frame.s * c.width, height: frame.s * c.width * 0.4)
                        .position(x: c.x(t, frame: frame), y: frame.y(c.y))
                }
            }
            .frame(width: frame.w, height: frame.h)
        }
    }
}
#endif
