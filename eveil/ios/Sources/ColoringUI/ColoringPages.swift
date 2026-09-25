// ColoringPages.swift — les pages à colorier : des dessins au trait pour les 3-5 ans.
//
// Chaque page est un croquis (cf. Sketch) : des formes empilées du fond vers
// l'avant, dont on ne garde que les traits visibles. Règles de dessin :
// - traits épais (≈ 1,2 % de la page), grandes zones, peu de petites ;
// - un trait n'existe que là où une zone s'arrête (sauf quelques détails ouverts
//   — moustaches, sourires, rayons — qui ne ferment rien) ;
// - toute aire visible se remplit ; les petites zones (< 0,3 % de la page) sont
//   des détails VOULUS (yeux, boutons) et déclarés comme tels ;
// - chaque zone dessinée porte un point-témoin : les tests vérifient qu'aucune ne
//   fuit dans sa voisine ni dans le fond.
// Tracés provisoires, en attendant les dessins d'un illustrateur.

#if canImport(CoreGraphics)
import CoreGraphics
import Foundation

public struct ColoringPage: Identifiable, Sendable {
    public let id: String
    public let titleFR: String
    public let titleEN: String
    /// Épaisseur du trait affiché, en unité de page.
    let lineWidth: CGFloat
    let draw: @Sendable (inout Sketch) -> Void

    init(_ id: String, fr: String, en: String, lineWidth: CGFloat = 0.012,
         draw: @escaping @Sendable (inout Sketch) -> Void) {
        self.id = id
        self.titleFR = fr
        self.titleEN = en
        self.lineWidth = lineWidth
        self.draw = draw
    }

    public func title(locale: String) -> String { locale.hasPrefix("fr") ? titleFR : titleEN }

    /// Le croquis (formes, témoins) — recalculé à chaque appel : réservé aux tests et au cache.
    var sketch: Sketch {
        var s = Sketch()
        draw(&s)
        return s
    }

    /// Les traits visibles (calculés une fois, puis gardés).
    public var lineArt: LineArt { LineArtCache.shared.art(for: self) }
}

public enum ColoringPages {
    public static let all: [ColoringPage] = [
        train, cat, house, fly, cow, hive, fish, butterfly, flowers, iceCream, boat, rocket, snail, dogHouse, bell,
    ]
}

// MARK: Éléments de décor partagés

extension Sketch {
    /// Soleil : un disque et des rayons (traits ouverts : ils ne ferment rien).
    mutating func sun(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, rays: Int = 8) {
        shape(G.circle(cx, cy, r), at: (cx, cy))
        for k in 0..<rays {
            let a = (CGFloat(k) / CGFloat(rays) * 360 + 22.5) * .pi / 180
            line(G.line([(cx + (r + 0.022) * cos(a), cy + (r + 0.022) * sin(a)),
                         (cx + (r + 0.055) * cos(a), cy + (r + 0.055) * sin(a))]))
        }
    }

    /// Nuage d'un seul contour (ses bosses sont réunies).
    mutating func cloud(_ cx: CGFloat, _ cy: CGFloat, _ w: CGFloat) {
        shape(G.cloud(cx, cy, w), at: (cx, cy + w * 0.06))
    }

    /// Ligne d'horizon d'un bord à l'autre : l'herbe dessous est une zone.
    mutating func ground(_ y: CGFloat, wave: CGFloat = 0.012) {
        line(G.spline([(-0.05, y), (0.18, y - wave), (0.42, y + wave * 0.6), (0.66, y - wave * 0.8),
                       (0.86, y + wave * 0.4), (1.05, y)]))
    }

    /// Touffes d'herbe (petits « v » ouverts, sous l'horizon).
    mutating func grass(_ spots: [(CGFloat, CGFloat)]) {
        for (x, y) in spots {
            line(G.line([(x - 0.022, y - 0.028), (x - 0.006, y), (x, y - 0.034), (x + 0.006, y), (x + 0.022, y - 0.028)]))
        }
    }

    /// Une abeille, tête vers la gauche (`flip` : vers la droite) ; `k` = échelle.
    /// Corps long à deux rayures (trois anneaux de même largeur), deux grandes ailes.
    mutating func bee(_ cx: CGFloat, _ cy: CGFloat, _ k: CGFloat = 1, flip: Bool = false) {
        let d: CGFloat = flip ? -1 : 1
        let wingBack = G.ellipse(cx + d * 0.035 * k, cy - 0.072 * k, 0.036 * k, 0.056 * k, deg: 22 * d)
        let wingFront = G.ellipse(cx - d * 0.015 * k, cy - 0.078 * k, 0.036 * k, 0.056 * k, deg: -16 * d)
        shape(wingBack, at: (cx + d * 0.052 * k, cy - 0.098 * k))
        shape(wingFront, at: (cx - d * 0.022 * k, cy - 0.105 * k))
        let body = G.ellipse(cx, cy, 0.09 * k, 0.052 * k)
        shape(body)
        for sx in [CGFloat(-0.005), 0.042] {
            let x = cx + d * sx * k
            line(G.spline([(x + d * 0.006 * k, cy - 0.07 * k), (x - d * 0.006 * k, cy), (x + d * 0.006 * k, cy + 0.07 * k)]),
                 in: body)
        }
        expect(cx - d * 0.03 * k, cy + 0.012 * k)
        expect(cx + d * 0.018 * k, cy)
        expect(cx + d * 0.065 * k, cy)
        let hx = cx - d * 0.09 * k
        line(G.spline([(hx, cy - 0.03 * k), (hx - d * 0.02 * k, cy - 0.075 * k), (hx - d * 0.045 * k, cy - 0.085 * k)]))
        ink(G.circle(hx - d * 0.045 * k, cy - 0.085 * k, 0.011 * k))
        shape(G.circle(hx, cy, 0.04 * k), at: (hx + d * 0.012 * k, cy - 0.02 * k))
        ink(G.circle(hx - d * 0.012 * k, cy - 0.01 * k, 0.009 * k))
        line(G.arc(hx - d * 0.006 * k, cy + 0.006 * k, 0.017 * k, from: 30, to: 150))
    }

    /// Fleur ronde sur sa tige : un contour festonné (pétales) et un cœur (petit détail).
    mutating func flower(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, stemTo groundY: CGFloat) {
        line(G.line([(cx, cy), (cx, groundY + 0.02)]))
        var bumps: [CGPath] = []
        for k in 0..<6 {
            let a = CGFloat(k) * .pi / 3
            bumps.append(G.circle(cx + r * 0.62 * cos(a), cy + r * 0.62 * sin(a), r * 0.48))
        }
        shape(G.union(bumps), at: (cx + r * 0.8, cy))
        detail(G.circle(cx, cy, r * 0.42), at: (cx, cy))
    }
}

extension G {
    /// Un cœur centré en (cx, cy), de largeur ≈ 2 × `r`.
    static func heart(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> CGPath {
        path { p in
            p.move(to: CGPoint(x: cx, y: cy + r * 0.95))
            p.addCurve(to: CGPoint(x: cx - r, y: cy - r * 0.15), control1: CGPoint(x: cx - r * 0.55, y: cy + r * 0.55),
                       control2: CGPoint(x: cx - r, y: cy + r * 0.25))
            p.addCurve(to: CGPoint(x: cx, y: cy - r * 0.45), control1: CGPoint(x: cx - r, y: cy - r * 0.75),
                       control2: CGPoint(x: cx - r * 0.2, y: cy - r * 0.8))
            p.addCurve(to: CGPoint(x: cx + r, y: cy - r * 0.15), control1: CGPoint(x: cx + r * 0.2, y: cy - r * 0.8),
                       control2: CGPoint(x: cx + r, y: cy - r * 0.75))
            p.addCurve(to: CGPoint(x: cx, y: cy + r * 0.95), control1: CGPoint(x: cx + r, y: cy + r * 0.25),
                       control2: CGPoint(x: cx + r * 0.55, y: cy + r * 0.55))
            p.closeSubpath()
        }
    }

    /// Une feuille en amande, de `a` à `b`, de largeur `w`.
    static func leaf(_ a: (CGFloat, CGFloat), _ b: (CGFloat, CGFloat), width w: CGFloat) -> CGPath {
        let mx = (a.0 + b.0) / 2, my = (a.1 + b.1) / 2
        let dx = b.0 - a.0, dy = b.1 - a.1
        let len = max(hypot(dx, dy), 0.0001)
        let nx = -dy / len * w, ny = dx / len * w
        return path { p in
            p.move(to: CGPoint(x: a.0, y: a.1))
            p.addQuadCurve(to: CGPoint(x: b.0, y: b.1), control: CGPoint(x: mx + nx, y: my + ny))
            p.addQuadCurve(to: CGPoint(x: a.0, y: a.1), control: CGPoint(x: mx - nx, y: my - ny))
            p.closeSubpath()
        }
    }

    /// Rectangle aux coins arrondis un par un (haut-gauche, haut-droit, bas-droit, bas-gauche).
    static func roundRect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat,
                          tl: CGFloat, tr: CGFloat, br: CGFloat, bl: CGFloat) -> CGPath {
        path { p in
            p.move(to: CGPoint(x: x + tl, y: y))
            p.addLine(to: CGPoint(x: x + w - tr, y: y))
            if tr > 0 { p.addArc(tangent1End: CGPoint(x: x + w, y: y), tangent2End: CGPoint(x: x + w, y: y + h), radius: tr) }
            p.addLine(to: CGPoint(x: x + w, y: y + h - br))
            if br > 0 { p.addArc(tangent1End: CGPoint(x: x + w, y: y + h), tangent2End: CGPoint(x: x, y: y + h), radius: br) }
            p.addLine(to: CGPoint(x: x + bl, y: y + h))
            if bl > 0 { p.addArc(tangent1End: CGPoint(x: x, y: y + h), tangent2End: CGPoint(x: x, y: y), radius: bl) }
            p.addLine(to: CGPoint(x: x, y: y + tl))
            if tl > 0 { p.addArc(tangent1End: CGPoint(x: x, y: y), tangent2End: CGPoint(x: x + w, y: y), radius: tl) }
            p.closeSubpath()
        }
    }

    /// Porte en arche : bas en `bottom`, largeur `w`, haut du montant en `springY`.
    static func archDoor(_ x: CGFloat, _ springY: CGFloat, _ w: CGFloat, bottom: CGFloat) -> CGPath {
        path { p in
            p.move(to: CGPoint(x: x, y: bottom))
            p.addLine(to: CGPoint(x: x, y: springY))
            p.addArc(center: CGPoint(x: x + w / 2, y: springY), radius: w / 2, startAngle: .pi, endAngle: 2 * .pi,
                     clockwise: false)
            p.addLine(to: CGPoint(x: x + w, y: bottom))
            p.closeSubpath()
        }
    }
}
#endif
