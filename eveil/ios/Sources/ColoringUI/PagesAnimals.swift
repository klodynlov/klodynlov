// PagesAnimals.swift — les bêtes : la mouche, la vache, la ruche et ses abeilles,
// le poisson, le papillon, l'escargot.
//
// Plusieurs rejoignent les mots du petit train (mouche, vache, ruche, poisson) :
// l'enfant colorie ce qu'il vient de dire. Grandes zones, yeux en points d'encre
// (pas de minuscules reflets à remplir), rayures et taches qui découpent de vraies
// zones bien larges. Pattes, antennes, tiges : des traits qui ne touchent pas
// d'autres contours, pour ne pas fermer de miettes.

#if canImport(CoreGraphics)
import CoreGraphics

extension ColoringPages {
    static let fly = ColoringPage("mouche", fr: "La mouche", en: "The fly") { s in
        // Les ailes (et leur nervure, qui ne ferme rien), derrière le corps.
        let wing = G.ellipse(0.285, 0.41, 0.12, 0.2, deg: -38)
        s.shape(wing, at: (0.21, 0.44))
        s.shape(G.mirror(wing), at: (0.79, 0.44))
        let vein = G.spline([(0.37, 0.52), (0.31, 0.44), (0.235, 0.345)])
        s.line(vein, in: wing)
        s.line(G.mirror(vein), in: G.mirror(wing))
        // Six pattes, trois de chaque côté, bien sous les ailes.
        for leg in [[(0.40, 0.655), (0.275, 0.645), (0.225, 0.715)],
                    [(0.40, 0.735), (0.285, 0.765), (0.255, 0.84)],
                    [(0.43, 0.80), (0.355, 0.865), (0.345, 0.94)]] as [[(CGFloat, CGFloat)]] {
            s.line(G.line(leg))
            s.line(G.mirror(G.line(leg)))
            if let foot = leg.last {
                s.ink(G.circle(foot.0, foot.1, 0.013))
                s.ink(G.circle(1 - foot.0, foot.1, 0.013))
            }
        }
        // Le corps rayé.
        let body = G.ellipse(0.5, 0.675, 0.155, 0.2)
        s.shape(body)
        s.line(G.spline([(0.33, 0.655), (0.5, 0.69), (0.67, 0.655)]), in: body)
        s.line(G.spline([(0.33, 0.765), (0.5, 0.80), (0.67, 0.765)]), in: body)
        s.expect(0.5, 0.605)
        s.expect(0.5, 0.735)
        s.expect(0.5, 0.835)
        // Les antennes, puis la tête : de grands yeux, un sourire.
        let antenna = G.spline([(0.465, 0.24), (0.43, 0.16), (0.385, 0.12)])
        s.line(antenna)
        s.line(G.mirror(antenna))
        s.ink(G.circle(0.385, 0.12, 0.018))
        s.ink(G.circle(0.615, 0.12, 0.018))
        s.shape(G.circle(0.5, 0.385, 0.165), at: (0.36, 0.43))
        let eye = G.ellipse(0.43, 0.35, 0.058, 0.075)
        s.shape(eye, at: (0.415, 0.305))
        s.shape(G.mirror(eye), at: (0.585, 0.305))
        s.ink(G.circle(0.445, 0.37, 0.028))
        s.ink(G.circle(0.555, 0.37, 0.028))
        s.line(G.arc(0.5, 0.445, 0.058, from: 25, to: 155))
    }

    static let cow = ColoringPage("vache", fr: "La vache", en: "The cow") { s in
        s.sun(0.88, 0.12, 0.06)
        s.ground(0.865)
        s.expect(0.55, 0.95)
        // La queue et son toupet, la mamelle (derrière le corps).
        s.line(G.spline([(0.855, 0.42), (0.905, 0.47), (0.92, 0.56), (0.915, 0.625)]))
        s.shape(G.blob([(0.915, 0.615), (0.945, 0.66), (0.935, 0.715), (0.895, 0.715), (0.885, 0.66)]), at: (0.915, 0.675))
        s.shape(G.ellipse(0.585, 0.64, 0.062, 0.055), at: (0.585, 0.67))
        // Les pattes par paires (celle du fond, puis celle de devant) et leurs sabots.
        for (x, visible) in [(CGFloat(0.29), CGFloat(0.03)), (0.35, 0.04), (0.71, 0.03), (0.77, 0.04)] {
            let leg = G.rect(x, 0.56, 0.08, 0.335, r: 0.03)
            s.shape(leg, at: (x + visible, 0.73))
            s.line(G.line([(x - 0.01, 0.82), (x + 0.09, 0.82)]), in: leg)
            s.expect(x + visible, 0.858)
        }
        // Le corps et ses taches (celle de la croupe déborde : coupée au bord).
        let body = G.rect(0.27, 0.33, 0.61, 0.31, r: 0.13)
        s.shape(body, at: (0.66, 0.58))
        s.shape(G.blob([(0.47, 0.375), (0.555, 0.365), (0.60, 0.42), (0.555, 0.49), (0.475, 0.475), (0.445, 0.42)]),
                at: (0.52, 0.425))
        s.line(G.blob([(0.72, 0.30), (0.82, 0.29), (0.87, 0.36), (0.83, 0.445), (0.745, 0.435), (0.70, 0.37)]), in: body)
        s.expect(0.79, 0.385)
        s.shape(G.blob([(0.35, 0.52), (0.415, 0.50), (0.45, 0.555), (0.405, 0.60), (0.35, 0.585)]), at: (0.40, 0.55))
        // La tête : oreilles, cornes (petits détails), tête, museau.
        s.shape(G.ellipse(0.08, 0.30, 0.06, 0.032, deg: 18), at: (0.07, 0.297))
        s.shape(G.ellipse(0.345, 0.30, 0.06, 0.032, deg: -18), at: (0.355, 0.297))
        s.detail(G.blob([(0.135, 0.265), (0.115, 0.20), (0.13, 0.15), (0.16, 0.19), (0.18, 0.255)]), at: (0.145, 0.215))
        s.detail(G.blob([(0.24, 0.255), (0.26, 0.19), (0.29, 0.15), (0.305, 0.20), (0.285, 0.265)]), at: (0.275, 0.215))
        s.shape(G.ellipse(0.21, 0.36, 0.115, 0.13), at: (0.21, 0.275))
        s.shape(G.ellipse(0.20, 0.47, 0.118, 0.075), at: (0.13, 0.49))
        s.ink(G.ellipse(0.155, 0.458, 0.018, 0.012))
        s.ink(G.ellipse(0.245, 0.458, 0.018, 0.012))
        s.line(G.arc(0.20, 0.47, 0.045, from: 40, to: 140))
        s.ink(G.circle(0.165, 0.33, 0.02))
        s.ink(G.circle(0.255, 0.33, 0.02))
        s.grass([(0.08, 0.95), (0.60, 0.975), (0.93, 0.95)])
    }

    static let hive = ColoringPage("ruche", fr: "La ruche", en: "The beehive") { s in
        s.ground(0.925)
        s.expect(0.5, 0.965)
        s.flower(0.09, 0.76, 0.062, stemTo: 0.925)
        s.flower(0.91, 0.78, 0.058, stemTo: 0.925)
        // Le support : deux pieds derrière la planche.
        let c: CGFloat = 0.46
        s.shape(G.rect(c - 0.215, 0.80, 0.055, 0.145, r: 0.01), at: (c - 0.1875, 0.87))
        s.shape(G.rect(c + 0.16, 0.80, 0.055, 0.145, r: 0.01), at: (c + 0.1875, 0.87))
        // La ruche en paille : des boudins empilés, chacun devant celui du dessus.
        s.shape(G.rect(c - 0.055, 0.225, 0.11, 0.09, r: 0.035), at: (c, 0.26))
        let bands: [(CGFloat, CGFloat, CGFloat)] = [(0.29, 0.38, 0.19), (0.36, 0.47, 0.30), (0.45, 0.57, 0.38),
                                                     (0.55, 0.67, 0.44), (0.65, 0.785, 0.46)]
        for (k, (top, bottom, width)) in bands.enumerated() {
            let next = k + 1 < bands.count ? bands[k + 1].0 : bottom
            s.shape(G.rect(c - width / 2, top, width, bottom - top, r: (bottom - top) / 2),
                    at: (k == bands.count - 1 ? c - 0.155 : c, (top + next) / 2))
        }
        s.shape(G.ellipse(c, 0.735, 0.068, 0.043), at: (c, 0.735))
        s.shape(G.rect(c - 0.28, 0.77, 0.56, 0.05, r: 0.02), at: (c - 0.23, 0.795))
        // Les abeilles (et le pointillé de leur vol).
        s.line(G.dashed(G.spline([(0.335, 0.235), (0.37, 0.185), (0.44, 0.16)]), on: 0.02, off: 0.018))
        s.bee(0.20, 0.25, 1.3)
        s.bee(0.78, 0.21, 1.3)
        s.bee(0.855, 0.50, 1.2)
    }

    static let fish = ColoringPage("poisson", fr: "Le poisson", en: "The fish") { s in
        // Le sable, les algues, l'étoile de mer.
        s.line(G.spline([(-0.05, 0.86), (0.25, 0.83), (0.55, 0.87), (0.8, 0.845), (1.05, 0.86)]))
        s.expect(0.45, 0.95)
        s.shape(G.band(G.spline([(0.075, 0.90), (0.055, 0.80), (0.09, 0.71), (0.065, 0.635)]), width: 0.048),
                at: (0.055, 0.80))
        s.shape(G.band(G.spline([(0.915, 0.90), (0.94, 0.78), (0.895, 0.67), (0.93, 0.575)]), width: 0.048),
                at: (0.94, 0.78))
        s.shape(G.star(0.70, 0.915, 0.065, inner: 0.032, deg: -80, round: 0.012), at: (0.70, 0.915))
        // Le poisson : queue et nageoires derrière le corps.
        s.shape(G.blob([(0.32, 0.46), (0.20, 0.35), (0.13, 0.30), (0.16, 0.46), (0.13, 0.62), (0.20, 0.57)]),
                at: (0.19, 0.46))
        s.shape(G.blob([(0.39, 0.34), (0.46, 0.225), (0.58, 0.21), (0.67, 0.32)]), at: (0.53, 0.255))
        s.shape(G.blob([(0.47, 0.59), (0.51, 0.69), (0.59, 0.685), (0.61, 0.59)]), at: (0.54, 0.655))
        let body = G.ellipse(0.53, 0.46, 0.27, 0.175)
        s.shape(body)
        // Deux bandes, comme un poisson-clown.
        for x in [CGFloat(0.40), 0.46, 0.575, 0.635] {
            s.line(G.spline([(x, 0.25), (x + 0.03, 0.46), (x, 0.67)]), in: body)
        }
        s.expect(0.34, 0.46)
        s.expect(0.46, 0.46)
        s.expect(0.5475, 0.46)
        s.expect(0.635, 0.46)
        s.expect(0.72, 0.53)
        // L'œil, la bouche.
        s.detail(G.circle(0.725, 0.41, 0.04), at: (0.703, 0.392))
        s.ink(G.circle(0.732, 0.415, 0.019))
        s.line(G.arc(0.755, 0.49, 0.025, from: 40, to: 130))
        // Les bulles (et leur reflet, ouvert).
        for (x, y, r) in [(0.88, 0.33, 0.032), (0.905, 0.215, 0.042), (0.865, 0.09, 0.052)] as [(CGFloat, CGFloat, CGFloat)] {
            if r < 0.035 { s.detail(G.circle(x, y, r), at: (x, y)) } else { s.shape(G.circle(x, y, r), at: (x, y)) }
            s.line(G.arc(x, y, r * 0.58, from: 195, to: 255))
        }
    }

    static let butterfly = ColoringPage("papillon", fr: "Le papillon", en: "The butterfly") { s in
        let upper = G.blob([(0.47, 0.40), (0.38, 0.24), (0.24, 0.135), (0.10, 0.165), (0.07, 0.32), (0.16, 0.45),
                            (0.33, 0.505), (0.47, 0.53)])
        let lower = G.blob([(0.47, 0.52), (0.33, 0.515), (0.19, 0.58), (0.14, 0.72), (0.21, 0.835), (0.33, 0.82),
                            (0.43, 0.72), (0.47, 0.60)])
        // Les ailes du bas, puis du haut, et leurs taches.
        s.shape(lower, at: (0.38, 0.59))
        s.shape(G.mirror(lower), at: (0.62, 0.59))
        s.shape(G.circle(0.27, 0.70, 0.055), at: (0.27, 0.70))
        s.shape(G.circle(0.73, 0.70, 0.055), at: (0.73, 0.70))
        s.shape(upper, at: (0.40, 0.44))
        s.shape(G.mirror(upper), at: (0.60, 0.44))
        for (x, y, r) in [(0.20, 0.29, 0.075), (0.335, 0.36, 0.04)] as [(CGFloat, CGFloat, CGFloat)] {
            s.shape(G.circle(x, y, r), at: (x, y))
            s.shape(G.circle(1 - x, y, r), at: (1 - x, y))
        }
        // Les antennes, le corps en trois anneaux, la tête souriante.
        let antenna = G.spline([(0.485, 0.25), (0.45, 0.16), (0.40, 0.11), (0.365, 0.12)])
        s.line(antenna)
        s.line(G.mirror(antenna))
        s.ink(G.circle(0.365, 0.12, 0.018))
        s.ink(G.circle(0.635, 0.12, 0.018))
        let body = G.rect(0.465, 0.30, 0.07, 0.50, r: 0.035)
        s.shape(body)
        s.line(G.line([(0.45, 0.50), (0.55, 0.50)]), in: body)
        s.line(G.line([(0.45, 0.63), (0.55, 0.63)]), in: body)
        s.expect(0.5, 0.43)
        s.expect(0.5, 0.565)
        s.expect(0.5, 0.71)
        s.shape(G.circle(0.5, 0.285, 0.068), at: (0.5, 0.245))
        s.ink(G.circle(0.475, 0.28, 0.012))
        s.ink(G.circle(0.525, 0.28, 0.012))
        s.line(G.arc(0.5, 0.295, 0.024, from: 30, to: 150))
    }

    static let snail = ColoringPage("escargot", fr: "L'escargot", en: "The snail") { s in
        s.sun(0.86, 0.13, 0.065)
        s.cloud(0.34, 0.13, 0.24)
        s.ground(0.85)
        s.expect(0.5, 0.95)
        // Le champignon tacheté.
        s.shape(G.rect(0.085, 0.68, 0.06, 0.20, r: 0.02), at: (0.115, 0.80))
        let cap = G.intersect(G.ellipse(0.115, 0.715, 0.105, 0.09), G.rect(-0.1, 0.5, 0.5, 0.215))
        s.shape(cap, at: (0.115, 0.69))
        s.detail(G.circle(0.075, 0.675, 0.021), at: (0.075, 0.675))
        s.detail(G.circle(0.155, 0.66, 0.021), at: (0.155, 0.66))
        // Les yeux au bout des cornes, derrière la tête.
        s.line(G.spline([(0.80, 0.53), (0.785, 0.44), (0.765, 0.375)]))
        s.line(G.spline([(0.86, 0.54), (0.88, 0.45), (0.895, 0.395)]))
        s.detail(G.circle(0.765, 0.365, 0.034), at: (0.748, 0.35))
        s.detail(G.circle(0.895, 0.385, 0.034), at: (0.878, 0.37))
        s.ink(G.circle(0.772, 0.37, 0.014))
        s.ink(G.circle(0.902, 0.39, 0.014))
        // Le corps, d'un seul tenant, de la queue à la tête.
        s.shape(G.blob([(0.25, 0.835), (0.40, 0.80), (0.60, 0.80), (0.70, 0.76), (0.74, 0.66), (0.76, 0.56),
                        (0.82, 0.50), (0.88, 0.53), (0.905, 0.62), (0.885, 0.74), (0.865, 0.85), (0.60, 0.87),
                        (0.35, 0.87)]),
                at: (0.83, 0.70))
        s.line(G.arc(0.855, 0.61, 0.032, from: 20, to: 130))
        // La coquille : une spirale de deux tours, qui finit par un trait droit jusqu'au bord.
        let shell = G.circle(0.52, 0.60, 0.21)
        s.shape(shell)
        var spiral: [(CGFloat, CGFloat)] = []
        let turn: CGFloat = 1.25 * .pi
        for k in 0...64 {
            let t = CGFloat(k) / 64 * 4 * .pi
            let r = 0.014 + 0.16 * t / (4 * .pi)
            spiral.append((0.52 + r * cos(t + turn), 0.60 + r * sin(t + turn)))
        }
        s.line(G.spline(spiral), in: shell)
        if let end = spiral.last {
            s.line(G.line([end, (0.52 + 0.26 * cos(turn), 0.60 + 0.26 * sin(turn))]), in: shell)
        }
        s.expect(0.6416, 0.7216)
        s.grass([(0.30, 0.95), (0.70, 0.96), (0.93, 0.93)])
    }
}
#endif
