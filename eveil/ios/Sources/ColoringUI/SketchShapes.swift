// SketchShapes.swift — les formes de base pour dessiner les pages (carré unité, y vers le bas).
//
// De quoi dessiner vite et proprement des pages pour les 3-5 ans : cercles,
// polygones aux coins arrondis, formes « molles » passant par des points (spline
// de Catmull-Rom fermée : nuages, taches, flammes, feuilles), bandes (un trait
// épais devenu forme : tiges, queues, algues), étoiles, symétrie gauche-droite.
// Tout est `CGPath`. Les opérations de CoreGraphics sur les tracés (union,
// différence, contour d'un trait, pointillés) se font à l'échelle × 1000 : leurs
// tolérances sont absolues, trop grossières pour le carré unité (bouts ronds perdus).

#if canImport(CoreGraphics)
import CoreGraphics
import Foundation

enum G {
    typealias XY = (CGFloat, CGFloat)

    /// Échelle de travail des opérations sur les tracés.
    static let work: CGFloat = 1000

    static func big(_ p: CGPath) -> CGPath {
        var t = CGAffineTransform(scaleX: work, y: work)
        return p.copy(using: &t) ?? p
    }

    static func small(_ p: CGPath) -> CGPath {
        var t = CGAffineTransform(scaleX: 1 / work, y: 1 / work)
        return p.copy(using: &t) ?? p
    }

    static func point(_ p: XY) -> CGPoint { CGPoint(x: p.0, y: p.1) }

    // MARK: Formes fermées

    static func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> CGPath {
        CGPath(ellipseIn: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r), transform: nil)
    }

    /// Ellipse de centre (cx, cy), demi-axes rx/ry, tournée de `deg` degrés.
    static func ellipse(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat, deg: CGFloat = 0) -> CGPath {
        let e = CGPath(ellipseIn: CGRect(x: -rx, y: -ry, width: 2 * rx, height: 2 * ry), transform: nil)
        var t = CGAffineTransform(translationX: cx, y: cy).rotated(by: deg * .pi / 180)
        return e.copy(using: &t) ?? e
    }

    /// Rectangle, coins arrondis de rayon `r` (borné à la moitié du petit côté).
    static func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, r: CGFloat = 0) -> CGPath {
        let rr = max(0, min(r, w / 2 - 0.0001, h / 2 - 0.0001))
        return CGPath(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerWidth: rr, cornerHeight: rr,
                      transform: nil)
    }

    /// Polygone fermé ; `r` arrondit chaque coin (arc tangent aux deux côtés).
    static func poly(_ pts: [XY], r: CGFloat = 0) -> CGPath {
        let p = CGMutablePath()
        let v = pts.map(point)
        guard v.count > 2 else { return p }
        if r <= 0 {
            p.addLines(between: v)
            p.closeSubpath()
            return p
        }
        let n = v.count
        p.move(to: mid(v[n - 1], v[0]))
        for i in 0..<n {
            p.addArc(tangent1End: v[i], tangent2End: v[(i + 1) % n], radius: r)
        }
        p.closeSubpath()
        return p
    }

    /// Forme molle fermée passant par les points (Catmull-Rom → Bézier cubiques).
    static func blob(_ pts: [XY], tension: CGFloat = 1) -> CGPath {
        let v = pts.map(point)
        let p = CGMutablePath()
        let n = v.count
        guard n > 2 else { return p }
        p.move(to: v[0])
        for i in 0..<n {
            let p0 = v[(i - 1 + n) % n], p1 = v[i], p2 = v[(i + 1) % n], p3 = v[(i + 2) % n]
            p.addCurve(to: p2, control1: p1 + (p2 - p0) * (tension / 6), control2: p2 - (p3 - p1) * (tension / 6))
        }
        p.closeSubpath()
        return p
    }

    // MARK: Traits ouverts

    /// Ligne brisée ouverte.
    static func line(_ pts: [XY]) -> CGPath {
        let p = CGMutablePath()
        p.addLines(between: pts.map(point))
        return p
    }

    /// Courbe ouverte lisse passant par les points (Catmull-Rom, extrémités doublées).
    static func spline(_ pts: [XY], tension: CGFloat = 1) -> CGPath {
        let v = pts.map(point)
        let p = CGMutablePath()
        guard let first = v.first else { return p }
        p.move(to: first)
        let n = v.count
        guard n > 1 else { return p }
        for i in 0..<(n - 1) {
            let p0 = v[max(i - 1, 0)], p1 = v[i], p2 = v[i + 1], p3 = v[min(i + 2, n - 1)]
            p.addCurve(to: p2, control1: p1 + (p2 - p0) * (tension / 6), control2: p2 - (p3 - p1) * (tension / 6))
        }
        return p
    }

    /// Arc de cercle ouvert, angles en degrés (0° = à droite, sens horaire à l'écran).
    static func arc(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, from a0: CGFloat, to a1: CGFloat) -> CGPath {
        let p = CGMutablePath()
        let s = a0 * .pi / 180, e = a1 * .pi / 180
        p.move(to: CGPoint(x: cx + r * cos(s), y: cy + r * sin(s)))
        p.addArc(center: CGPoint(x: cx, y: cy), radius: r, startAngle: s, endAngle: e, clockwise: e < s)
        return p
    }

    /// Chemin libre (courbes de Bézier à la main).
    static func path(_ build: (CGMutablePath) -> Void) -> CGPath {
        let p = CGMutablePath()
        build(p)
        return p
    }

    // MARK: Formes composées

    /// Un trait épais devenu forme (tige, queue, algue) : son contour, sans recouvrements.
    static func band(_ path: CGPath, width: CGFloat) -> CGPath {
        small(big(path).copy(strokingWithWidth: width * work, lineCap: .round, lineJoin: .round, miterLimit: 4)
            .normalized())
    }

    /// Un trait en pointillés (tirets de `on`, espaces de `off`, en unité de page).
    static func dashed(_ path: CGPath, on: CGFloat, off: CGFloat) -> CGPath {
        small(big(path).copy(dashingWithPhase: 0, lengths: [on * work, off * work]))
    }

    /// Étoile à `n` branches (rayons extérieur/intérieur), coins légèrement arrondis.
    static func star(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, inner: CGFloat, n: Int = 5,
                     deg: CGFloat = -90, round: CGFloat = 0.006) -> CGPath {
        var pts: [XY] = []
        for i in 0..<(2 * n) {
            let a = (deg + CGFloat(i) * 180 / CGFloat(n)) * .pi / 180
            let rr = i.isMultiple(of: 2) ? r : inner
            pts.append((cx + rr * cos(a), cy + rr * sin(a)))
        }
        return poly(pts, r: round)
    }

    /// Un nuage : des bosses sur une base aplatie, réunies en UNE forme (un seul contour).
    static func cloud(_ cx: CGFloat, _ cy: CGFloat, _ w: CGFloat) -> CGPath {
        let h = w * 0.42
        return union([
            rect(cx - w / 2, cy - h * 0.05, w, h * 0.55, r: h * 0.27),
            circle(cx - w * 0.22, cy, w * 0.17),
            circle(cx + w * 0.02, cy - h * 0.18, w * 0.23),
            circle(cx + w * 0.26, cy + h * 0.02, w * 0.15),
        ])
    }

    static func union(_ paths: [CGPath]) -> CGPath {
        guard let first = paths.first else { return CGMutablePath() }
        var acc = big(first)
        for p in paths.dropFirst() { acc = acc.union(big(p)) }
        return small(acc)
    }

    static func minus(_ a: CGPath, _ b: CGPath) -> CGPath { small(big(a).subtracting(big(b))) }

    static func intersect(_ a: CGPath, _ b: CGPath) -> CGPath { small(big(a).intersection(big(b))) }

    // MARK: Transformations

    /// Symétrique par rapport à l'axe vertical x = `axis` (0,5 = milieu de la page).
    static func mirror(_ p: CGPath, axis: CGFloat = 0.5) -> CGPath {
        var t = CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: 2 * axis, ty: 0)
        return p.copy(using: &t) ?? p
    }

    static func rotate(_ p: CGPath, _ deg: CGFloat, around c: XY) -> CGPath {
        var t = CGAffineTransform(translationX: c.0, y: c.1).rotated(by: deg * .pi / 180)
            .translatedBy(x: -c.0, y: -c.1)
        return p.copy(using: &t) ?? p
    }

    static func move(_ p: CGPath, _ dx: CGFloat, _ dy: CGFloat) -> CGPath {
        var t = CGAffineTransform(translationX: dx, y: dy)
        return p.copy(using: &t) ?? p
    }

    static func scale(_ p: CGPath, _ s: CGFloat, around c: XY) -> CGPath {
        var t = CGAffineTransform(translationX: c.0, y: c.1).scaledBy(x: s, y: s).translatedBy(x: -c.0, y: -c.1)
        return p.copy(using: &t) ?? p
    }

    /// Point tourné de `deg` autour de `c` (pour placer sondes et détails sur une forme tournée).
    static func rotated(_ p: XY, _ deg: CGFloat, around c: XY) -> XY {
        let a = deg * .pi / 180
        let dx = p.0 - c.0, dy = p.1 - c.1
        return (c.0 + dx * cos(a) - dy * sin(a), c.1 + dx * sin(a) + dy * cos(a))
    }

    private static func mid(_ a: CGPoint, _ b: CGPoint) -> CGPoint { CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2) }
}

// Petite arithmétique de points, pour les splines.
private func + (a: CGPoint, b: CGPoint) -> CGPoint { CGPoint(x: a.x + b.x, y: a.y + b.y) }
private func - (a: CGPoint, b: CGPoint) -> CGPoint { CGPoint(x: a.x - b.x, y: a.y - b.y) }
private func * (a: CGPoint, k: CGFloat) -> CGPoint { CGPoint(x: a.x * k, y: a.y * k) }
#endif
