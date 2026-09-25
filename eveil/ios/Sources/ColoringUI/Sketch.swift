// Sketch.swift — comment on dessine une page : un empilement de formes, puis les traits VISIBLES.
//
// Une page à colorier est un DESSIN AU TRAIT, comme sur papier : ce sont les
// traits qui délimitent les zones (cf. ZoneMap), et rien d'autre. Retour de
// l'iPad (25/09/2026) : « ne pas fusionner les formes pour laisser les traits
// apparents » — l'ancienne version traçait le contour de TOUTES ses formes
// superposées, et l'enfant voyait des traits qui ne correspondaient pas à ce qui
// se remplissait (le nuage en trois ellipses, le haut des roues…).
//
// Choix : on décrit la page comme un empilement de formes pleines, du fond vers
// l'avant (facile à dessiner), et on en tire les traits par ÉLIMINATION DES
// PARTIES CACHÉES : le contour d'une forme n'est tracé que là où aucune forme
// posée devant ne le recouvre (opérations booléennes de CoreGraphics, iOS 16+).
// Un nuage = l'union de ses bosses : un seul contour, une seule zone. On ne voit
// donc un trait QUE là où une zone s'arrête, et chaque aire fermée devient sa
// propre zone, comme le pot de peinture sur un coloriage papier.
//
// Le croquis porte aussi ce qu'on ATTEND de lui : un point au cœur de chaque zone
// dessinée (`probe`) et les petites zones voulues (yeux, boutons : `detail`).
// Les tests vérifient que chaque point tombe dans sa propre zone (aucune fuite,
// aucune fusion) et qu'aucune zone minuscule n'existe sans avoir été voulue.
//
// Deux pièges de CoreGraphics, vérifiés (25/09/2026) et contournés :
// - ses opérations sur les tracés (contour d'un trait épais, booléens) ont des
//   tolérances ABSOLUES : dans le carré unité, un bout rond disparaît. On calcule
//   donc tout à l'échelle × 1000 (`G.work`), et l'on revient au carré unité à la fin ;
// - `lineSubtracting` traite un tracé OUVERT comme fermé (corde parasite, ou
//   segment droit qui s'évanouit). Les traits sont donc découpés ici, à la main
//   (`LineClipper`) : on échantillonne chaque courbe, on teste si le point est
//   caché (formes de devant) ou hors de sa forme-support, on affine chaque
//   passage par dichotomie, et l'on garde les sous-courbes de Bézier exactes.
//
// Coordonnées « unité » : le carré 0…1, y vers le bas (comme SwiftUI).

#if canImport(CoreGraphics)
import CoreGraphics
import Foundation

/// Les traits d'une page, prêts à tracer à l'écran et à rastériser pour les zones.
/// `CGPath` est immuable et sûr entre fils : d'où le `@unchecked Sendable`.
public struct LineArt: @unchecked Sendable {
    /// Tous les traits visibles (bouts et jointures arrondis).
    public let strokes: CGPath
    /// Les aplats d'encre (pupilles, truffes, moyeux) : remplis, et bordés par `strokes`.
    public let ink: CGPath
    /// Épaisseur du trait, en unité de page.
    public let lineWidth: CGFloat
}

/// Un croquis : l'empilement des formes (du fond vers l'avant) et ce qu'on en attend.
public struct Sketch {
    enum Layer {
        /// Forme pleine : cache ce qui est derrière ; son contour est tracé là où il se voit.
        case shape(CGPath)
        /// Trait simple (ouvert ou fermé), éventuellement coupé à l'intérieur de `clip` : ne cache rien.
        case line(CGPath, clip: CGPath?)
        /// Aplat d'encre : rempli de la couleur du trait, cache ce qui est derrière.
        case ink(CGPath)
    }

    private(set) var layers: [Layer] = []
    /// Un point au cœur de chaque zone dessinée : chacun doit tomber dans SA zone.
    private(set) var probes: [CGPoint] = []
    /// Les petites zones voulues (yeux, boutons…) : seules zones permises sous 0,3 % de la page.
    private(set) var details: [CGPoint] = []

    public init() {}

    /// Ajoute une forme pleine ; `at` = un point où l'enfant la touchera (zone attendue).
    public mutating func shape(_ path: CGPath, at probe: (CGFloat, CGFloat)? = nil) {
        layers.append(.shape(path))
        if let probe { probes.append(CGPoint(x: probe.0, y: probe.1)) }
    }

    /// Ajoute une petite forme VOULUE (œil, bouton, moyeu…), `at` en son cœur.
    public mutating func detail(_ path: CGPath, at point: (CGFloat, CGFloat)) {
        layers.append(.shape(path))
        details.append(CGPoint(x: point.0, y: point.1))
    }

    /// Ajoute un trait ; `in` le coupe à l'intérieur d'une forme (rayures, taches, veines).
    public mutating func line(_ path: CGPath, in clip: CGPath? = nil) {
        layers.append(.line(path, clip: clip))
    }

    /// Ajoute un aplat d'encre (pupille, truffe, note de musique…).
    public mutating func ink(_ path: CGPath) {
        layers.append(.ink(path))
    }

    /// Déclare une zone attendue que dessinent des traits (bande entre deux rayures…).
    public mutating func expect(_ x: CGFloat, _ y: CGFloat) { probes.append(CGPoint(x: x, y: y)) }

    /// Déclare une petite zone voulue que dessinent des traits.
    public mutating func expectDetail(_ x: CGFloat, _ y: CGFloat) { details.append(CGPoint(x: x, y: y)) }

    /// Les traits visibles : on parcourt l'empilement de l'avant vers le fond, en
    /// accumulant les formes qui sont devant ; chaque contour, chaque trait est
    /// amputé de ce qu'elles recouvrent (calcul à l'échelle × 1000).
    func lineArt(lineWidth: CGFloat) -> LineArt {
        let strokes = CGMutablePath()
        let ink = CGMutablePath()
        var clipper = LineClipper()
        for layer in layers.reversed() {
            switch layer {
            case let .shape(path):
                let big = G.big(path)
                clipper.addVisible(big, clip: nil, to: strokes)
                clipper.occlude(big)
            case let .line(path, clip):
                clipper.addVisible(G.big(path), clip: clip.map(G.big), to: strokes)
            case let .ink(path):
                let big = G.big(path)
                clipper.addVisible(big, clip: nil, to: strokes)
                ink.addPath(clipper.visibleRegion(of: big))
                clipper.occlude(big)
            }
        }
        return LineArt(strokes: G.small(strokes), ink: G.small(ink), lineWidth: lineWidth)
    }
}

/// Découpe des traits contre les formes posées devant eux (repère × 1000).
struct LineClipper {
    private struct Occluder {
        let path: CGPath
        let box: CGRect
    }

    /// Pas d'échantillonnage le long d'une courbe (4 ‰ de la page).
    private let step: CGFloat = 4
    private var occluders: [Occluder] = []

    /// Une forme pleine passe devant tout ce qui viendra ensuite (plus au fond).
    mutating func occlude(_ path: CGPath) {
        occluders.append(Occluder(path: path, box: path.boundingBoxOfPath))
    }

    func isHidden(_ p: CGPoint) -> Bool {
        for o in occluders where o.box.contains(p) && o.path.contains(p) { return true }
        return false
    }

    /// La surface visible d'un aplat (moins les formes de devant qui le touchent).
    func visibleRegion(of path: CGPath) -> CGPath {
        let box = path.boundingBoxOfPath
        var visible = path
        for o in occluders where o.box.intersects(box) { visible = visible.subtracting(o.path) }
        return visible
    }

    /// Ajoute à `out` les morceaux visibles de `path` : hors des formes de devant et,
    /// s'il y en a une, à l'intérieur de `clip`.
    func addVisible(_ path: CGPath, clip: CGPath?, to out: CGMutablePath) {
        let clipBox = clip?.boundingBoxOfPath
        func visible(_ p: CGPoint) -> Bool {
            if let clip, let clipBox, !(clipBox.contains(p) && clip.contains(p)) { return false }
            return !isHidden(p)
        }
        var current = CGPoint.zero, start = CGPoint.zero
        var penDown = false
        func emit(_ c: Cubic, _ a: CGFloat, _ b: CGFloat) {
            guard b > a else { return }
            let piece = c.piece(a, b)
            if !(a == 0 && penDown) { out.move(to: piece.p0) }
            if c.isLine {
                out.addLine(to: piece.p3)
            } else {
                out.addCurve(to: piece.p3, control1: piece.p1, control2: piece.p2)
            }
            penDown = b == 1
        }
        func process(_ c: Cubic) {
            let n = max(4, Int((c.roughLength / step).rounded(.up)))
            var t0: CGFloat = 0
            var v0 = visible(c.point(0))
            var from: CGFloat? = v0 ? 0 : nil
            if !v0 { penDown = false }
            for k in 1...n {
                let t1 = CGFloat(k) / CGFloat(n)
                let v1 = visible(c.point(t1))
                if v1 != v0 {
                    var lo = t0, hi = t1
                    for _ in 0..<14 {
                        let mid = (lo + hi) / 2
                        if visible(c.point(mid)) == v0 { lo = mid } else { hi = mid }
                    }
                    let cut = (lo + hi) / 2
                    if let a = from {
                        emit(c, a, cut)
                        from = nil
                    } else {
                        from = cut
                    }
                }
                t0 = t1
                v0 = v1
            }
            if let a = from { emit(c, a, 1) }
        }
        path.applyWithBlock { element in
            let e = element.pointee
            switch e.type {
            case .moveToPoint:
                current = e.points[0]
                start = current
                penDown = false
            case .addLineToPoint:
                process(Cubic(line: current, e.points[0]))
                current = e.points[0]
            case .addQuadCurveToPoint:
                process(Cubic(quad: current, e.points[0], e.points[1]))
                current = e.points[1]
            case .addCurveToPoint:
                process(Cubic(p0: current, p1: e.points[0], p2: e.points[1], p3: e.points[2]))
                current = e.points[2]
            case .closeSubpath:
                if hypot(current.x - start.x, current.y - start.y) > 0.001 { process(Cubic(line: current, start)) }
                current = start
            @unknown default:
                break
            }
        }
    }
}

/// Une courbe de Bézier cubique (un segment droit en est une, aux points de contrôle alignés).
struct Cubic {
    var p0, p1, p2, p3: CGPoint
    var isLine = false

    init(p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint) {
        (self.p0, self.p1, self.p2, self.p3) = (p0, p1, p2, p3)
    }

    init(line a: CGPoint, _ b: CGPoint) {
        self.init(p0: a, p1: Cubic.lerp(a, b, 1.0 / 3), p2: Cubic.lerp(a, b, 2.0 / 3), p3: b)
        isLine = true
    }

    init(quad a: CGPoint, _ c: CGPoint, _ b: CGPoint) {
        self.init(p0: a, p1: Cubic.lerp(a, c, 2.0 / 3), p2: Cubic.lerp(b, c, 2.0 / 3), p3: b)
    }

    var roughLength: CGFloat { Cubic.dist(p0, p1) + Cubic.dist(p1, p2) + Cubic.dist(p2, p3) }

    func point(_ t: CGFloat) -> CGPoint {
        let u = 1 - t
        let a = u * u * u, b = 3 * u * u * t, c = 3 * u * t * t, d = t * t * t
        return CGPoint(x: a * p0.x + b * p1.x + c * p2.x + d * p3.x, y: a * p0.y + b * p1.y + c * p2.y + d * p3.y)
    }

    /// La portion de la courbe entre les paramètres `a` et `b` (de Casteljau).
    func piece(_ a: CGFloat, _ b: CGFloat) -> Cubic {
        var left = split(at: b).left
        if a > 0 { left = left.split(at: a / b).right }
        left.isLine = isLine
        return left
    }

    private func split(at t: CGFloat) -> (left: Cubic, right: Cubic) {
        let p01 = Cubic.lerp(p0, p1, t), p12 = Cubic.lerp(p1, p2, t), p23 = Cubic.lerp(p2, p3, t)
        let p012 = Cubic.lerp(p01, p12, t), p123 = Cubic.lerp(p12, p23, t)
        let m = Cubic.lerp(p012, p123, t)
        return (Cubic(p0: p0, p1: p01, p2: p012, p3: m), Cubic(p0: m, p1: p123, p2: p23, p3: p3))
    }

    private static func lerp(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
        CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }

    private static func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(b.x - a.x, b.y - a.y) }
}

/// Les traits de chaque page, calculés une fois (thread-safe : cartes et vignettes
/// les demandent depuis plusieurs fils).
final class LineArtCache: @unchecked Sendable {
    static let shared = LineArtCache()
    private let lock = NSLock()
    private var arts: [String: LineArt] = [:]

    func art(for page: ColoringPage) -> LineArt {
        if let art = lock.withLock({ arts[page.id] }) { return art }
        let art = page.sketch.lineArt(lineWidth: page.lineWidth)
        lock.withLock { arts[page.id] = art }
        return art
    }
}
#endif
