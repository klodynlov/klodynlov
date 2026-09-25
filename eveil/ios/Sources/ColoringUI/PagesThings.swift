// PagesThings.swift — les choses et les scènes : les fleurs, la glace, le bateau,
// la fusée, la niche (et son chien), la cloche.
//
// Les motifs qui découpent une forme (gaufre du cornet, bandes de la cloche,
// pétales, rayures de la planète) sont des traits coupés à l'intérieur de la
// forme : chaque morceau devient sa propre zone, assez grande pour un doigt de
// 3 ans. La gaufre part d'un rebord droit, SOUS la boule : ses losanges sont
// entiers (une boule qui mordrait dessus laisserait des éclats minuscules).

#if canImport(CoreGraphics)
import CoreGraphics

extension ColoringPages {
    static let flowers = ColoringPage("fleurs", fr: "Les fleurs", en: "The flowers") { s in
        // La table.
        s.line(G.line([(-0.05, 0.925), (1.05, 0.925)]))
        s.expect(0.12, 0.965)
        // Feuilles et tiges, derrière le pot.
        s.shape(G.leaf((0.50, 0.60), (0.35, 0.50), width: 0.045), at: (0.425, 0.55))
        s.shape(G.leaf((0.50, 0.53), (0.66, 0.445), width: 0.05), at: (0.58, 0.485))
        let stems = [G.spline([(0.43, 0.72), (0.37, 0.56), (0.25, 0.42)]),
                     G.spline([(0.50, 0.72), (0.50, 0.50), (0.50, 0.28)]),
                     G.spline([(0.57, 0.72), (0.63, 0.57), (0.75, 0.44)])]
        let stemProbes: [(CGFloat, CGFloat)] = [(0.345, 0.525), (0.50, 0.60), (0.66, 0.54)]
        for (stem, probe) in zip(stems, stemProbes) { s.shape(G.band(stem, width: 0.03), at: probe) }
        // La tulipe : trois pétales.
        let tulip = G.blob([(0.175, 0.285), (0.215, 0.335), (0.25, 0.265), (0.285, 0.335), (0.325, 0.285),
                            (0.32, 0.40), (0.25, 0.455), (0.18, 0.40)])
        s.shape(tulip)
        s.line(G.spline([(0.215, 0.335), (0.228, 0.40), (0.25, 0.46)]), in: tulip)
        s.line(G.spline([(0.285, 0.335), (0.272, 0.40), (0.25, 0.46)]), in: tulip)
        s.expect(0.20, 0.37)
        s.expect(0.25, 0.35)
        s.expect(0.30, 0.37)
        // La marguerite : huit pétales autour d'un cœur.
        for k in 0..<8 {
            let a = CGFloat(k) * 45
            let c = G.rotated((0.50, 0.105), a, around: (0.50, 0.205))
            s.shape(G.ellipse(c.0, c.1, 0.03, 0.062, deg: a), at: G.rotated((0.50, 0.095), a, around: (0.50, 0.205)))
        }
        s.shape(G.circle(0.50, 0.205, 0.052), at: (0.50, 0.205))
        // La fleur ronde : cinq pétales festonnés, séparés par un trait.
        var bumps: [CGPath] = []
        for k in 0..<5 {
            let a = (CGFloat(k) * 72 - 90) * .pi / 180
            bumps.append(G.circle(0.75 + 0.058 * cos(a), 0.385 + 0.058 * sin(a), 0.052))
        }
        let petals = G.union(bumps)
        s.shape(petals)
        for k in 0..<5 {
            let a = (CGFloat(k) * 72 - 54) * .pi / 180
            s.line(G.line([(0.75, 0.385), (0.75 + 0.2 * cos(a), 0.385 + 0.2 * sin(a))]), in: petals)
            let b = (CGFloat(k) * 72 - 90) * .pi / 180
            s.expect(0.75 + 0.075 * cos(b), 0.385 + 0.075 * sin(b))
        }
        s.shape(G.circle(0.75, 0.385, 0.038), at: (0.75, 0.385))
        // Le pot, son rebord, un cœur.
        s.shape(G.poly([(0.30, 0.70), (0.70, 0.70), (0.645, 0.95), (0.355, 0.95)], r: 0.02), at: (0.40, 0.87))
        s.shape(G.rect(0.27, 0.66, 0.46, 0.075, r: 0.025), at: (0.36, 0.6975))
        s.shape(G.heart(0.5, 0.835, 0.055), at: (0.5, 0.835))
    }

    static let iceCream = ColoringPage("glace", fr: "La glace", en: "The ice cream") { s in
        // Le cornet : un rebord sous la boule, puis la gaufre en losanges (parallèles aux bords).
        let cone = G.poly([(0.30, 0.53), (0.70, 0.53), (0.50, 0.97)], r: 0.025)
        s.shape(cone)
        let rim: CGFloat = 0.655
        s.line(G.line([(0.2, rim), (0.8, rim)]), in: cone)
        s.expect(0.40, 0.625)
        let slope: CGFloat = 0.20 / 0.44
        for x in [CGFloat(0.4523), 0.5477] {
            s.line(G.line([(x, rim), (x + 0.4 * slope, rim + 0.4)]), in: cone)
            s.line(G.line([(x, rim), (x - 0.4 * slope, rim + 0.4)]), in: cone)
        }
        for (x, y) in [(0.405, 0.69), (0.50, 0.69), (0.595, 0.69), (0.4523, 0.76), (0.5477, 0.76), (0.50, 0.865)]
            as [(CGFloat, CGFloat)] {
            s.expect(x, y)
        }
        // Deux boules qui coulent, la cerise (sa queue passe derrière).
        s.shape(G.union([G.ellipse(0.5, 0.47, 0.215, 0.12), G.circle(0.36, 0.555, 0.04), G.circle(0.46, 0.575, 0.04),
                         G.circle(0.575, 0.565, 0.04), G.circle(0.66, 0.535, 0.03)]),
                at: (0.42, 0.49))
        s.line(G.spline([(0.535, 0.12), (0.55, 0.07), (0.60, 0.04)]))
        s.shape(G.circle(0.535, 0.165, 0.05), at: (0.555, 0.185))
        s.line(G.arc(0.535, 0.165, 0.028, from: 200, to: 255))
        s.shape(G.union([G.ellipse(0.5, 0.305, 0.18, 0.115), G.circle(0.40, 0.385, 0.035), G.circle(0.50, 0.40, 0.04),
                         G.circle(0.60, 0.385, 0.035)]),
                at: (0.44, 0.31))
        // Des vermicelles sur les boules, des étincelles autour.
        for (x0, y0, x1, y1) in [(0.36, 0.44, 0.385, 0.43), (0.56, 0.45, 0.585, 0.465), (0.47, 0.51, 0.495, 0.50),
                                 (0.63, 0.49, 0.645, 0.47), (0.40, 0.27, 0.42, 0.285), (0.55, 0.26, 0.575, 0.25),
                                 (0.60, 0.33, 0.615, 0.35)] as [(CGFloat, CGFloat, CGFloat, CGFloat)] {
            s.line(G.line([(x0, y0), (x1, y1)]))
        }
        for (x, y, r) in [(0.17, 0.26, 0.04), (0.84, 0.21, 0.035), (0.17, 0.72, 0.035), (0.83, 0.70, 0.045)]
            as [(CGFloat, CGFloat, CGFloat)] {
            s.line(G.line([(x - r, y), (x + r, y)]))
            s.line(G.line([(x, y - r), (x, y + r)]))
        }
    }

    static let boat = ColoringPage("bateau", fr: "Le bateau", en: "The sailboat") { s in
        s.sun(0.14, 0.14, 0.07)
        s.cloud(0.78, 0.14, 0.24)
        s.line(G.path { p in
            p.move(to: CGPoint(x: 0.30, y: 0.27))
            p.addQuadCurve(to: CGPoint(x: 0.34, y: 0.26), control: CGPoint(x: 0.32, y: 0.235))
            p.addQuadCurve(to: CGPoint(x: 0.38, y: 0.27), control: CGPoint(x: 0.36, y: 0.235))
        })
        // La mer : deux vagues d'un bord à l'autre.
        func wave(_ y: CGFloat) -> CGPath {
            var pts: [(CGFloat, CGFloat)] = []
            for k in 0...12 { pts.append((-0.05 + CGFloat(k) * 0.0917, y + (k.isMultiple(of: 2) ? -0.013 : 0.013))) }
            return G.spline(pts)
        }
        s.line(wave(0.745))
        s.line(wave(0.87))
        s.expect(0.08, 0.81)
        s.expect(0.5, 0.94)
        // Le mât, le fanion, les voiles (bord commun avec le mât).
        s.line(G.line([(0.50, 0.10), (0.50, 0.67)]))
        s.shape(G.poly([(0.50, 0.085), (0.635, 0.125), (0.50, 0.165)], r: 0.008), at: (0.54, 0.125))
        s.shape(G.path { p in
            p.move(to: CGPoint(x: 0.50, y: 0.175))
            p.addQuadCurve(to: CGPoint(x: 0.80, y: 0.665), control: CGPoint(x: 0.74, y: 0.31))
            p.addLine(to: CGPoint(x: 0.50, y: 0.665))
            p.closeSubpath()
        }, at: (0.60, 0.50))
        s.shape(G.path { p in
            p.move(to: CGPoint(x: 0.50, y: 0.21))
            p.addLine(to: CGPoint(x: 0.50, y: 0.665))
            p.addLine(to: CGPoint(x: 0.24, y: 0.665))
            p.addQuadCurve(to: CGPoint(x: 0.50, y: 0.21), control: CGPoint(x: 0.30, y: 0.38))
        }, at: (0.42, 0.52))
        // La coque, sa bande, ses hublots.
        let hull = G.poly([(0.16, 0.64), (0.84, 0.64), (0.73, 0.81), (0.27, 0.81)], r: 0.03)
        s.shape(hull)
        s.line(G.line([(0.1, 0.695), (0.9, 0.695)]), in: hull)
        s.expect(0.30, 0.667)
        s.expect(0.31, 0.77)
        for x in [CGFloat(0.40), 0.50, 0.60] { s.detail(G.circle(x, 0.752, 0.028), at: (x, 0.752)) }
    }

    static let rocket = ColoringPage("fusee", fr: "La fusée", en: "The rocket") { s in
        // Étoiles, lune, planète à rayures.
        for (x, y, r) in [(0.15, 0.17, 0.065), (0.11, 0.53, 0.06), (0.89, 0.55, 0.06)] as [(CGFloat, CGFloat, CGFloat)] {
            s.shape(G.star(x, y, r, inner: r * 0.5), at: (x, y + 0.004))
        }
        s.shape(G.minus(G.circle(0.83, 0.18, 0.09), G.circle(0.875, 0.145, 0.075)), at: (0.775, 0.20))
        let planet = G.circle(0.18, 0.85, 0.09)
        s.shape(planet)
        s.line(G.spline([(0.07, 0.83), (0.18, 0.81), (0.29, 0.83)]), in: planet)
        s.line(G.spline([(0.07, 0.895), (0.18, 0.875), (0.29, 0.895)]), in: planet)
        s.expect(0.18, 0.785)
        s.expect(0.18, 0.845)
        s.expect(0.18, 0.912)
        // La flamme (et son cœur), les ailerons, derrière le corps.
        s.shape(G.blob([(0.43, 0.745), (0.395, 0.83), (0.45, 0.89), (0.50, 0.965), (0.55, 0.89), (0.605, 0.83),
                        (0.57, 0.745)]),
                at: (0.42, 0.81))
        s.shape(G.blob([(0.465, 0.77), (0.45, 0.83), (0.50, 0.905), (0.55, 0.83), (0.535, 0.77)]), at: (0.50, 0.84))
        let fin = G.poly([(0.40, 0.52), (0.265, 0.66), (0.265, 0.795), (0.40, 0.72)], r: 0.02)
        s.shape(fin, at: (0.31, 0.70))
        s.shape(G.mirror(fin), at: (0.69, 0.70))
        // Le corps en ogive : pointe, milieu, bas.
        let body = G.path { p in
            p.move(to: CGPoint(x: 0.39, y: 0.765))
            p.addLine(to: CGPoint(x: 0.39, y: 0.40))
            p.addCurve(to: CGPoint(x: 0.50, y: 0.095), control1: CGPoint(x: 0.39, y: 0.24),
                       control2: CGPoint(x: 0.45, y: 0.135))
            p.addCurve(to: CGPoint(x: 0.61, y: 0.40), control1: CGPoint(x: 0.55, y: 0.135),
                       control2: CGPoint(x: 0.61, y: 0.24))
            p.addLine(to: CGPoint(x: 0.61, y: 0.765))
            p.addQuadCurve(to: CGPoint(x: 0.39, y: 0.765), control: CGPoint(x: 0.50, y: 0.795))
            p.closeSubpath()
        }
        s.shape(body)
        s.line(G.spline([(0.36, 0.285), (0.50, 0.315), (0.64, 0.285)]), in: body)
        s.line(G.spline([(0.36, 0.635), (0.50, 0.665), (0.64, 0.635)]), in: body)
        s.expect(0.50, 0.21)
        s.expect(0.43, 0.56)
        s.expect(0.43, 0.715)
        // Le hublot (cadre et vitre, avec un reflet), l'aileron du milieu.
        s.shape(G.circle(0.50, 0.45, 0.078), at: (0.50, 0.385))
        s.shape(G.circle(0.50, 0.45, 0.052), at: (0.515, 0.465))
        s.line(G.arc(0.50, 0.45, 0.032, from: 195, to: 255))
        s.shape(G.rect(0.482, 0.60, 0.036, 0.19, r: 0.018), at: (0.50, 0.72))
    }

    static let dogHouse = ColoringPage("niche", fr: "La niche", en: "The dog house") { s in
        s.sun(0.12, 0.12, 0.06)
        s.cloud(0.76, 0.13, 0.24)
        s.ground(0.85)
        s.expect(0.60, 0.95)
        // La niche : le mur, la porte en arche, le toit en chevron, l'écriteau.
        s.shape(G.poly([(0.075, 0.87), (0.075, 0.54), (0.27, 0.37), (0.465, 0.54), (0.465, 0.87)]), at: (0.12, 0.72))
        s.shape(G.archDoor(0.175, 0.675, 0.19, bottom: 0.872), at: (0.27, 0.77))
        s.shape(G.band(G.line([(0.05, 0.55), (0.27, 0.35), (0.49, 0.55)]), width: 0.06), at: (0.15, 0.459))
        s.shape(G.rect(0.20, 0.475, 0.14, 0.06, r: 0.016), at: (0.27, 0.505))
        // Le chien assis : queue, corps, cuisse, pattes avant (côte à côte).
        s.shape(G.band(G.spline([(0.88, 0.76), (0.93, 0.70), (0.935, 0.60)]), width: 0.042), at: (0.93, 0.70))
        s.shape(G.ellipse(0.785, 0.735, 0.13, 0.145), at: (0.855, 0.66))
        s.shape(G.ellipse(0.87, 0.815, 0.065, 0.068), at: (0.875, 0.815))
        s.shape(G.rect(0.695, 0.70, 0.058, 0.185, r: 0.028), at: (0.72, 0.80))
        s.shape(G.rect(0.751, 0.70, 0.058, 0.185, r: 0.028), at: (0.782, 0.80))
        // Le collier et sa médaille.
        s.shape(G.band(G.spline([(0.68, 0.57), (0.745, 0.60), (0.815, 0.575)]), width: 0.032), at: (0.705, 0.583))
        s.detail(G.circle(0.77, 0.625, 0.024), at: (0.77, 0.628))
        // La tête : tache sur l'œil, oreilles tombantes, museau, truffe, sourire.
        s.shape(G.circle(0.745, 0.45, 0.115), at: (0.745, 0.37))
        s.shape(G.ellipse(0.795, 0.41, 0.05, 0.046), at: (0.80, 0.385))
        s.shape(G.ellipse(0.625, 0.465, 0.04, 0.088, deg: 14), at: (0.622, 0.47))
        s.shape(G.ellipse(0.865, 0.465, 0.04, 0.088, deg: -14), at: (0.868, 0.47))
        s.ink(G.circle(0.705, 0.42, 0.016))
        s.ink(G.circle(0.795, 0.42, 0.016))
        s.shape(G.ellipse(0.745, 0.525, 0.058, 0.048), at: (0.705, 0.505))
        s.ink(G.ellipse(0.745, 0.50, 0.022, 0.016))
        s.line(G.line([(0.745, 0.51), (0.745, 0.535)]))
        s.line(G.arc(0.731, 0.535, 0.014, from: 20, to: 160))
        s.line(G.arc(0.759, 0.535, 0.014, from: 20, to: 160))
        // L'os.
        s.shape(G.union([G.rect(0.41, 0.902, 0.15, 0.034, r: 0.01), G.circle(0.41, 0.902, 0.021),
                         G.circle(0.41, 0.936, 0.021), G.circle(0.56, 0.902, 0.021), G.circle(0.56, 0.936, 0.021)]),
                at: (0.485, 0.919))
    }

    static let bell = ColoringPage("cloche", fr: "La cloche", en: "The bell") { s in
        // « Ding ! » : des arcs de chaque côté, deux notes.
        for r in [CGFloat(0.36), 0.415] {
            s.line(G.arc(0.5, 0.50, r, from: 162, to: 198))
            s.line(G.arc(0.5, 0.50, r, from: -18, to: 18))
        }
        for (x, y) in [(0.14, 0.24), (0.84, 0.20)] as [(CGFloat, CGFloat)] {
            s.ink(G.ellipse(x, y, 0.028, 0.02, deg: -20))
            s.line(G.line([(x + 0.024, y - 0.005), (x + 0.024, y - 0.11)]))
            s.line(G.spline([(x + 0.024, y - 0.11), (x + 0.05, y - 0.085), (x + 0.058, y - 0.05)]))
        }
        // La cloche : le corps, ses deux bandes, une étoile ; le battant ; le bord.
        let bell = G.path { p in
            p.move(to: CGPoint(x: 0.50, y: 0.205))
            p.addCurve(to: CGPoint(x: 0.66, y: 0.34), control1: CGPoint(x: 0.60, y: 0.205), control2: CGPoint(x: 0.66, y: 0.27))
            p.addCurve(to: CGPoint(x: 0.70, y: 0.62), control1: CGPoint(x: 0.66, y: 0.46), control2: CGPoint(x: 0.67, y: 0.56))
            p.addCurve(to: CGPoint(x: 0.82, y: 0.765), control1: CGPoint(x: 0.73, y: 0.69), control2: CGPoint(x: 0.80, y: 0.72))
            p.addLine(to: CGPoint(x: 0.18, y: 0.765))
            p.addCurve(to: CGPoint(x: 0.30, y: 0.62), control1: CGPoint(x: 0.20, y: 0.72), control2: CGPoint(x: 0.27, y: 0.69))
            p.addCurve(to: CGPoint(x: 0.34, y: 0.34), control1: CGPoint(x: 0.33, y: 0.56), control2: CGPoint(x: 0.34, y: 0.46))
            p.addCurve(to: CGPoint(x: 0.50, y: 0.205), control1: CGPoint(x: 0.34, y: 0.27), control2: CGPoint(x: 0.40, y: 0.205))
            p.closeSubpath()
        }
        s.shape(bell)
        s.line(G.spline([(0.30, 0.445), (0.50, 0.475), (0.70, 0.445)]), in: bell)
        s.line(G.spline([(0.30, 0.525), (0.50, 0.555), (0.70, 0.525)]), in: bell)
        s.expect(0.50, 0.34)
        s.expect(0.50, 0.515)
        s.expect(0.35, 0.67)
        s.shape(G.star(0.50, 0.65, 0.066, inner: 0.033), at: (0.50, 0.655))
        s.shape(G.circle(0.50, 0.835, 0.05), at: (0.50, 0.85))
        s.shape(G.rect(0.15, 0.735, 0.70, 0.07, r: 0.035), at: (0.30, 0.77))
        // Le nœud : deux boucles et le nœud du milieu, posés sur la cloche.
        let loop = G.blob([(0.49, 0.175), (0.42, 0.105), (0.335, 0.095), (0.315, 0.165), (0.35, 0.235), (0.43, 0.225)])
        s.shape(loop, at: (0.37, 0.16))
        s.shape(G.mirror(loop), at: (0.63, 0.16))
        s.shape(G.rect(0.462, 0.13, 0.076, 0.08, r: 0.024), at: (0.50, 0.17))
    }
}
#endif
