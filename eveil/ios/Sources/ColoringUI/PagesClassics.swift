// PagesClassics.swift — les trois premières pages, redessinées au trait : le petit
// train, le chat chef de gare, la maison.
//
// Retour de l'iPad : chaque trait visible doit border une zone qui se remplit.
// Le nuage est d'un seul contour ; la chaudière passe derrière la cabine ; les
// roues, devant, mordent franchement sur la caisse ET sur le rail (jamais un
// contact tangent, qui ferait des miettes) ; les moyeux sont des points d'encre.

#if canImport(CoreGraphics)
import CoreGraphics

extension ColoringPages {
    static let train = ColoringPage("train", fr: "Le petit train", en: "The little train") { s in
        s.sun(0.87, 0.13, 0.065)
        s.cloud(0.64, 0.15, 0.22)
        // La fumée : trois bouffées qui montent.
        s.shape(G.circle(0.26, 0.215, 0.042), at: (0.26, 0.215))
        s.shape(G.circle(0.335, 0.135, 0.05), at: (0.335, 0.135))
        s.shape(G.circle(0.435, 0.07, 0.04), at: (0.435, 0.07))
        s.ground(0.845, wave: 0)
        s.expect(0.5, 0.93)
        // Locomotive : cheminée (et son bord), dôme, chaudière, cabine, toit, fenêtre.
        s.shape(G.poly([(0.13, 0.33), (0.27, 0.33), (0.245, 0.50), (0.155, 0.50)], r: 0.012), at: (0.20, 0.42))
        s.shape(G.rect(0.11, 0.285, 0.18, 0.055, r: 0.022), at: (0.20, 0.3125))
        s.shape(G.ellipse(0.35, 0.475, 0.065, 0.06), at: (0.35, 0.45))
        let boiler = G.roundRect(0.07, 0.48, 0.39, 0.26, tl: 0.1, tr: 0, br: 0, bl: 0.1)
        s.shape(boiler, at: (0.19, 0.60))
        s.line(G.line([(0.30, 0.45), (0.30, 0.77)]), in: boiler)
        s.expect(0.375, 0.60)
        s.shape(G.rect(0.42, 0.33, 0.19, 0.41, r: 0.02), at: (0.47, 0.60))
        s.shape(G.rect(0.39, 0.27, 0.25, 0.065, r: 0.028), at: (0.515, 0.3025))
        s.shape(G.rect(0.455, 0.38, 0.12, 0.11, r: 0.022), at: (0.515, 0.435))
        // Wagon chargé de ballons (derrière ses parois), et l'attelage.
        s.shape(G.circle(0.715, 0.505, 0.052), at: (0.705, 0.48))
        s.shape(G.circle(0.895, 0.505, 0.052), at: (0.905, 0.48))
        s.shape(G.circle(0.805, 0.485, 0.062), at: (0.805, 0.46))
        s.shape(G.rect(0.645, 0.52, 0.315, 0.24, r: 0.03), at: (0.80, 0.63))
        s.line(G.line([(0.60, 0.69), (0.66, 0.69)]))
        // Les roues, devant tout, avec un moyeu d'encre.
        for (x, y, r) in [(0.155, 0.795, 0.07), (0.335, 0.795, 0.07), (0.535, 0.775, 0.09),
                          (0.72, 0.805, 0.06), (0.885, 0.805, 0.06)] as [(CGFloat, CGFloat, CGFloat)] {
            s.shape(G.circle(x, y, r), at: (x, y - r * 0.55))
            s.ink(G.circle(x, y, 0.017))
        }
    }

    static let cat = ColoringPage("chat", fr: "Le chat chef de gare", en: "The station master cat") { s in
        // La queue, derrière le corps, au bout d'une autre couleur.
        let tail = G.band(G.spline([(0.64, 0.93), (0.79, 0.92), (0.88, 0.83), (0.875, 0.68)]), width: 0.07)
        s.shape(tail, at: (0.80, 0.915))
        s.line(G.line([(0.82, 0.735), (0.94, 0.755)]), in: tail)
        s.expect(0.875, 0.695)
        // Le manteau, le col, les boutons, les pattes.
        s.shape(G.rect(0.30, 0.64, 0.40, 0.33, r: 0.1), at: (0.40, 0.90))
        s.shape(G.poly([(0.41, 0.62), (0.59, 0.62), (0.50, 0.775)], r: 0.012), at: (0.50, 0.705))
        for y in [CGFloat(0.815), 0.88, 0.945] { s.ink(G.circle(0.5, y, 0.014)) }
        s.shape(G.ellipse(0.33, 0.83, 0.05, 0.055), at: (0.33, 0.83))
        s.shape(G.ellipse(0.67, 0.83, 0.05, 0.055), at: (0.67, 0.83))
        // Les oreilles (et leur creux rose, petit détail voulu), derrière la tête.
        let ear = G.poly([(0.21, 0.45), (0.245, 0.15), (0.43, 0.30)], r: 0.025)
        let inner = G.poly([(0.26, 0.38), (0.272, 0.225), (0.37, 0.305)], r: 0.015)
        s.shape(ear, at: (0.244, 0.325))
        s.shape(G.mirror(ear), at: (0.756, 0.325))
        s.detail(inner, at: (0.285, 0.28))
        s.detail(G.mirror(inner), at: (0.715, 0.28))
        // La tête.
        s.shape(G.ellipse(0.5, 0.45, 0.29, 0.215), at: (0.29, 0.45))
        // La casquette : calotte, bandeau, visière, insigne.
        s.shape(G.poly([(0.33, 0.12), (0.67, 0.12), (0.645, 0.28), (0.355, 0.28)], r: 0.025), at: (0.42, 0.17))
        s.shape(G.rect(0.345, 0.245, 0.31, 0.05, r: 0.012), at: (0.42, 0.265))
        s.shape(G.rect(0.335, 0.285, 0.33, 0.047, r: 0.0235), at: (0.60, 0.3085))
        s.detail(G.circle(0.5, 0.18, 0.034), at: (0.5, 0.18))
        // Les yeux, le nez rose, la bouche, les moustaches.
        s.ink(G.ellipse(0.40, 0.44, 0.028, 0.042))
        s.ink(G.ellipse(0.60, 0.44, 0.028, 0.042))
        s.detail(G.poly([(0.46, 0.52), (0.54, 0.52), (0.50, 0.565)], r: 0.014), at: (0.5, 0.535))
        s.line(G.path { p in
            p.move(to: CGPoint(x: 0.5, y: 0.565))
            p.addQuadCurve(to: CGPoint(x: 0.445, y: 0.60), control: CGPoint(x: 0.48, y: 0.61))
            p.move(to: CGPoint(x: 0.5, y: 0.565))
            p.addQuadCurve(to: CGPoint(x: 0.555, y: 0.60), control: CGPoint(x: 0.52, y: 0.61))
        })
        for (y0, y1) in [(CGFloat(0.515), CGFloat(0.485)), (0.54, 0.54), (0.565, 0.595)] {
            s.line(G.line([(0.40, y0), (0.25, y1)]))
            s.line(G.line([(0.60, y0), (0.75, y1)]))
        }
    }

    static let house = ColoringPage("maison", fr: "La maison", en: "The house") { s in
        s.sun(0.13, 0.13, 0.07)
        s.cloud(0.40, 0.11, 0.2)
        s.ground(0.83)
        s.expect(0.08, 0.93)
        // La cheminée (derrière le toit), le mur, le toit.
        s.shape(G.rect(0.585, 0.20, 0.07, 0.17), at: (0.62, 0.27))
        s.shape(G.rect(0.57, 0.17, 0.10, 0.05, r: 0.012), at: (0.62, 0.195))
        s.shape(G.rect(0.19, 0.44, 0.52, 0.42), at: (0.30, 0.78))
        s.shape(G.poly([(0.13, 0.465), (0.45, 0.19), (0.77, 0.465)], r: 0.02), at: (0.45, 0.37))
        // Fenêtres à croisillons : quatre carreaux chacune.
        for x in [CGFloat(0.245), 0.525] {
            let w = G.rect(x, 0.53, 0.14, 0.14, r: 0.012)
            s.shape(w)
            s.line(G.line([(x + 0.07, 0.52), (x + 0.07, 0.68)]), in: w)
            s.line(G.line([(x - 0.01, 0.60), (x + 0.15, 0.60)]), in: w)
            for (dx, dy) in [(0.035, 0.565), (0.105, 0.565), (0.035, 0.635), (0.105, 0.635)] as [(CGFloat, CGFloat)] {
                s.expect(x + dx, dy)
            }
        }
        // La porte en arche et sa poignée, l'allée.
        s.shape(G.archDoor(0.39, 0.70, 0.12, bottom: 0.862), at: (0.45, 0.76))
        s.ink(G.circle(0.485, 0.785, 0.012))
        s.shape(G.poly([(0.39, 0.855), (0.51, 0.855), (0.60, 1.03), (0.30, 1.03)]), at: (0.45, 0.95))
        // L'arbre et ses pommes, un buisson.
        s.shape(G.rect(0.805, 0.58, 0.06, 0.27, r: 0.012), at: (0.835, 0.76))
        s.shape(G.union([G.circle(0.78, 0.50, 0.078), G.circle(0.885, 0.49, 0.075), G.circle(0.835, 0.41, 0.088)]),
                at: (0.835, 0.455))
        for (x, y) in [(0.77, 0.52), (0.89, 0.47), (0.815, 0.37)] as [(CGFloat, CGFloat)] {
            s.detail(G.circle(x, y, 0.024), at: (x, y))
        }
        s.shape(G.union([G.circle(0.075, 0.845, 0.05), G.circle(0.14, 0.83, 0.055), G.circle(0.20, 0.85, 0.045)]),
                at: (0.14, 0.845))
        s.grass([(0.66, 0.93), (0.90, 0.95), (0.25, 0.96)])
    }
}
#endif
