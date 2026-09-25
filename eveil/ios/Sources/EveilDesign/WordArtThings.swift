// WordArtThings.swift — les objets du petit train : douche, bouche, cloche…
//
// Repère 200 × 200, sujet dans 16…184 (cf. WordArtKit.swift). Chaque fonction
// dessine le REPOS quand p.t = 0 et joue son action pour 0 < t < 1.

#if canImport(SwiftUI)
import SwiftUI

extension WordArtPaint {

    // MARK: fr.cloche — une cloche dorée à nœud rouge ; action : elle se balance, le battant suit.

    static func cloche(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let swing = 12 * wobble(t, 2)
        let clapper = 26 * wobble(seg(t, 0.07, 1), 2)
        let gold = hex(0xF7C331), goldLight = hex(0xFFE08A), goldDark = hex(0xDE9B17), bronze = hex(0x9C6512)
        let ribbon = hex(0xE8414B), ribbonDark = hex(0xB72E3B)

        let ring = hold(t, rise: 0.1, fall: 0.7)
        b.soundArcs(44, 62, angle: 205, amount: ring, gap: 8)
        b.soundArcs(156, 62, angle: -25, amount: ring, gap: 8)

        let bell = b.rotated(swing, 100, 26)
        // Le battant (derrière la lèvre), qui pend avec du retard.
        let tongue = bell.rotated(clapper - swing, 100, 138)
        tongue.stroke(curve([pt(100, 138), pt(100, 160)]), bronze, 5)
        tongue.fill(disk(100, 165, 11), bronze)
        tongue.fill(disk(96, 161, 3.5), goldLight.opacity(0.8))

        // Le corps de la cloche.
        var body = Path()
        body.move(to: pt(38, 148))
        body.addCurve(to: pt(66, 74), control1: pt(58, 140), control2: pt(58, 96))
        body.addCurve(to: pt(100, 40), control1: pt(70, 52), control2: pt(84, 40))
        body.addCurve(to: pt(134, 74), control1: pt(116, 40), control2: pt(130, 52))
        body.addCurve(to: pt(162, 148), control1: pt(142, 96), control2: pt(142, 140))
        body.addQuadCurve(to: pt(38, 148), control: pt(100, 162))
        body.closeSubpath()
        bell.fill(body, gold)
        let inside = bell.clipped(body)
        inside.fill(blob([pt(124, 50), pt(150, 100), pt(166, 150), pt(128, 160), pt(122, 110)]), goldDark.opacity(0.55))
        inside.stroke(curve([pt(44, 124), pt(100, 134), pt(156, 124)]), goldDark, 5)
        inside.stroke(curve([pt(52, 112), pt(100, 121), pt(148, 112)]), goldDark.opacity(0.6), 2.5)
        bell.stroke(curve([pt(78, 62), pt(68, 96), pt(62, 132)]), goldLight.opacity(0.9), 8)
        // La lèvre, et l'ombre de l'intérieur.
        bell.fill(oval(100, 149, 63, 11), goldDark)
        bell.fill(oval(100, 151, 52, 6.5), bronze)

        // Le nœud (au-dessus, il tient la cloche).
        bell.fill(blob([pt(80, 44), pt(88, 36), pt(84, 58), pt(74, 62)]), ribbonDark)
        bell.fill(blob([pt(120, 44), pt(112, 36), pt(116, 58), pt(126, 62)]), ribbonDark)
        bell.rotated(-22, 84, 26).fill(oval(80, 26, 19, 11), ribbon)
        bell.rotated(22, 116, 26).fill(oval(120, 26, 19, 11), ribbon)
        bell.rotated(-22, 84, 26).fill(oval(80, 26, 9, 4.5), ribbonDark)
        bell.rotated(22, 116, 26).fill(oval(120, 26, 9, 4.5), ribbonDark)
        bell.fill(box(91, 17, 18, 19, 7), ribbon)
        bell.fill(oval(96, 22, 3.5, 2.5), .white.opacity(0.5))
    }

    // MARK: fr.douche — pommeau chromé et pluie de gouttes ; action : l'eau coule plus fort.

    static func douche(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let strong = hold(t, rise: 0.12, fall: 0.8)
        let chrome = hex(0xC3CDD8), chromeDark = hex(0x8D9AAA), chromeLight = hex(0xEEF2F6)
        let water = hex(0x3E9CF0), waterLight = hex(0x8FD0FF)

        // Flaque et éclaboussures au sol.
        b.fill(oval(104, 176, 58 + 10 * strong, 7 + 1.5 * strong), waterLight.opacity(0.55))
        for (i, x) in [CGFloat(64), 88, 122, 146].enumerated() {
            let lift = CGFloat(2 + 4 * strong) * (i % 2 == 0 ? 1 : 1.5)
            b.fill(disk(x, 170 - lift, 2.6 + 1.2 * strong), water.opacity(0.7))
        }

        // Les filets d'eau : des gouttes allongées qui tombent le long de rayons en éventail.
        // Pendant l'action elles filent 3 intervalles plus loin (entier : pas de saut à la fin).
        let phase = p.cycle(0.55) + 3 * t
        let streams = [-3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0]
        let extra = [-2.5, -1.5, -0.5, 0.5, 1.5, 2.5]
        let spacing: CGFloat = 19
        func stream(_ k: Double, _ alpha: Double) {
            guard alpha > 0.01 else { return }
            let top = pt(104 + CGFloat(k) * 9, 84)
            let bottom = pt(104 + CGFloat(k) * 21, 168)
            let dx = bottom.x - top.x, dy = bottom.y - top.y
            let length = (dx * dx + dy * dy).squareRoot()
            let ux = dx / length, uy = dy / length
            let drop = 9 + 8 * CGFloat(strong)
            let shift = CGFloat(phase - phase.rounded(.down)) * spacing
            var s = shift - spacing
            while s < length {
                let s0 = max(s, 0), s1 = min(s + drop, length)
                if s1 > s0 + 1 {
                    let fade = Double(1 - max(0, (s0 - length * 0.8) / (length * 0.2)))
                    let color = Int(k * 2).isMultiple(of: 2) ? water : hex(0x5DB2F7)
                    b.faded(alpha * fade).fill(capsule(pt(top.x + ux * s0, top.y + uy * s0),
                                                        pt(top.x + ux * s1, top.y + uy * s1), 4.6 + 1.6 * CGFloat(strong)), color)
                }
                s += spacing
            }
        }
        for k in streams { stream(k, 0.95) }
        for k in extra { stream(k, strong) }

        // Le tuyau qui sort du mur, et le pommeau.
        let head = b.moved(CGFloat(1.2 * shake(t, 9) * strong), 0)
        var pipe = Path()
        pipe.move(to: pt(184, 30))
        pipe.addLine(to: pt(128, 30))
        pipe.addQuadCurve(to: pt(104, 54), control: pt(104, 30))
        head.stroke(pipe, chrome, 13)
        var shine = Path()
        shine.move(to: pt(182, 26))
        shine.addLine(to: pt(128, 26))
        shine.addQuadCurve(to: pt(108, 44), control: pt(109, 27))
        head.stroke(shine, chromeLight, 3)
        head.fill(box(176, 18, 12, 24, 4), chromeDark)
        var cone = Path()
        cone.move(to: pt(92, 50))
        cone.addLine(to: pt(116, 50))
        cone.addQuadCurve(to: pt(144, 78), control: pt(140, 58))
        cone.addLine(to: pt(64, 78))
        cone.addQuadCurve(to: pt(92, 50), control: pt(68, 58))
        cone.closeSubpath()
        head.fill(cone, chrome)
        head.fill(blob([pt(98, 54), pt(84, 62), pt(76, 74), pt(86, 72), pt(96, 62)]), chromeLight.opacity(0.9))
        head.fill(oval(104, 79, 41, 9), chromeDark)
        for (x, y) in [(82.0, 79.0), (93.0, 81.0), (104.0, 82.0), (115.0, 81.0), (126.0, 79.0), (98.0, 77.0), (110.0, 77.0)] {
            head.fill(disk(CGFloat(x), CGFloat(y), 2), hex(0x5E6B7B))
        }
    }

    // MARK: fr.bouche — un grand sourire (lèvres, dents, langue) ; action : « miam-miam », elle s'ouvre deux fois.

    static func bouche(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let open = CGFloat(max(pulse(seg(t, 0, 0.5)), pulse(seg(t, 0.5, 1))))
        let lipTop = hex(0xE0435A), lipBottom = hex(0xEF5B70), inside = hex(0x7A1E30)
        let tongueColor = hex(0xF4788C)

        let lowerInner = 130 + 24 * open, lowerOuter = 150 + 28 * open
        var opening = Path()
        opening.move(to: pt(30, 96))
        opening.addCurve(to: pt(170, 96), control1: pt(60, 86), control2: pt(140, 86))
        opening.addCurve(to: pt(30, 96), control1: pt(140, lowerInner), control2: pt(60, lowerInner))
        opening.closeSubpath()

        b.fill(opening, inside)
        let mouth = b.clipped(opening)
        mouth.fill(oval(100, 128 + 20 * open, 44, 18), tongueColor)
        mouth.stroke(curve([pt(100, 118 + 18 * open), pt(100, 132 + 20 * open)]), hex(0xD9546B), 3)
        mouth.fill(oval(100, 86, 64, 14), .white)
        for x in [CGFloat(80), 100, 120] {
            mouth.stroke(curve([pt(x, 88), pt(x, 97)]), hex(0xE1E4EE), 2)
        }

        // Lèvre du haut (arc de Cupidon) et lèvre du bas, charnue.
        var upper = Path()
        upper.move(to: pt(26, 97))
        upper.addCurve(to: pt(86, 60), control1: pt(42, 80), control2: pt(66, 58))
        upper.addQuadCurve(to: pt(100, 69), control: pt(95, 60))
        upper.addQuadCurve(to: pt(114, 60), control: pt(105, 60))
        upper.addCurve(to: pt(174, 97), control1: pt(134, 58), control2: pt(158, 80))
        upper.addCurve(to: pt(26, 97), control1: pt(140, 84), control2: pt(60, 84))
        upper.closeSubpath()
        b.fill(upper, lipTop)
        b.fill(oval(84, 70, 12, 4), .white.opacity(0.35))

        var lower = Path()
        lower.move(to: pt(26, 97))
        lower.addCurve(to: pt(174, 97), control1: pt(60, lowerInner + 1), control2: pt(140, lowerInner + 1))
        lower.addCurve(to: pt(26, 97), control1: pt(140, lowerOuter + 10), control2: pt(60, lowerOuter + 10))
        lower.closeSubpath()
        b.fill(lower, lipBottom)
        b.fill(oval(118, 132 + 24 * open, 15, 4.5), .white.opacity(0.45))
    }

    // MARK: fr.trousse — trousse violette d'où dépassent des crayons ; action : la fermeture éclair glisse, les crayons sautillent.

    static func trousse(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let zip = CGFloat(pulse(t))
        let purple = hex(0x8E5BD9), purpleLight = hex(0xA97BEA), purpleDark = hex(0x6F43B8)
        let teeth = hex(0xD5D9E3), pull = hex(0xFFC53D), wood = hex(0xF6D7A7)

        b.groundShadow(100, 168, 76, 7)
        let pencils: [(x: CGFloat, angle: Double, color: UInt32, len: CGFloat)] = [
            (62, -20, 0xE8414B, 64), (84, -7, 0xFFC53D, 76), (106, 6, 0x3FA9DC, 70), (127, 18, 0x5DBB4F, 60),
        ]
        for (i, pc) in pencils.enumerated() {
            let lift = CGFloat(10 * hop(seg(t, 0.1 + Double(i) * 0.1, 0.5 + Double(i) * 0.1)))
            let pb = b.moved(0, -lift).rotated(pc.angle, pc.x, 100)
            let top = 100 - pc.len
            pb.fill(box(pc.x - 6.5, top + 14, 13, pc.len - 14, 2), hex(pc.color))
            pb.fill(box(pc.x - 2, top + 14, 4, pc.len - 14), .white.opacity(0.25))
            pb.fill(poly([pt(pc.x - 6.5, top + 15), pt(pc.x + 6.5, top + 15), pt(pc.x, top)]), wood)
            pb.fill(poly([pt(pc.x - 2.6, top + 6), pt(pc.x + 2.6, top + 6), pt(pc.x, top)]), hex(pc.color))
        }
        let pouch = box(28, 92, 144, 70, 26)
        b.fill(pouch, purple)
        let cloth = b.clipped(pouch)
        cloth.fill(box(28, 92, 144, 18), purpleLight)
        cloth.fill(box(28, 148, 144, 20), purpleDark.opacity(0.45))
        b.fill(oval(86, 98, 56, 6), purpleDark)
        let zipX = 148 - 46 * zip
        b.dashed(curve([pt(zipX, 98), pt(162, 98)]), teeth, 5, dash: [3, 3])
        b.fill(box(zipX - 7, 93, 14, 10, 3), hex(0xB8BECC))
        b.fill(box(zipX - 4.5, 101, 9, 17, 3.5), pull)
        b.fill(disk(zipX, 113, 2), purpleDark)
        b.fillRounded(star5(124, 134, 13), pull, 1.5)
    }

    // MARK: fr.mousse — un tas de mousse de bain et ses bulles ; action : les bulles montent et éclatent.

    static func mousse(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let foam = hex(0xF9FCFF), foamShade = hex(0xC4DDF5), edge = hex(0x9FC6EC), water = hex(0x9DD3FA)
        let tints = [hex(0xF4A3CC), hex(0xAE9CF2), hex(0x7FC4FA), hex(0x86DDB8)]

        b.fill(oval(100, 168, 82, 14), water)
        b.stroke(curve([pt(30, 170), pt(48, 166), pt(66, 170)]), .white.opacity(0.9), 3)
        b.stroke(curve([pt(132, 172), pt(150, 168), pt(168, 172)]), .white.opacity(0.9), 3)
        // Le tas de mousse : UNE masse moelleuse (bosses sur le pourtour), un seul liseré bleu
        // autour (la mousse blanche reste lisible sur la carte blanche), des petites bulles dedans.
        let heap: [(CGFloat, CGFloat, CGFloat)] = [
            (100, 84, 16), (82, 94, 14), (120, 92, 15),
            (64, 110, 17), (92, 106, 19), (122, 110, 18), (144, 118, 14),
            (48, 130, 17), (76, 128, 19), (106, 128, 20), (136, 132, 18), (158, 140, 13),
            (40, 150, 15), (66, 152, 18), (96, 152, 20), (126, 152, 19), (154, 154, 16),
        ]
        let breathe = CGFloat(1.4 * shake(t, 3))
        var mass = Path()
        for (i, c) in heap.enumerated() {
            mass.addPath(disk(c.0, c.1, c.2 + breathe * (i.isMultiple(of: 2) ? 1 : -1)))
        }
        for (i, c) in heap.enumerated() {
            b.stroke(disk(c.0, c.1, c.2 + breathe * (i.isMultiple(of: 2) ? 1 : -1)), edge, 4)
        }
        b.fill(mass, foam)
        let inside = b.clipped(mass)
        inside.fill(oval(100, 178, 96, 34), foamShade)
        let rings: [(CGFloat, CGFloat, CGFloat)] = [
            (70, 114, 5), (98, 94, 4), (118, 118, 6), (84, 138, 4.5), (140, 142, 5), (56, 142, 3.5),
            (110, 146, 3.5), (128, 98, 3.5), (92, 122, 3), (62, 128, 2.5), (148, 126, 3), (104, 108, 2.5),
        ]
        for (i, r) in rings.enumerated() {
            inside.stroke(disk(r.0, r.1, r.2), i % 3 == 0 ? tints[i % 4] : edge, 1.8)
            inside.fill(disk(r.0 - r.2 * 0.35, r.1 - r.2 * 0.4, max(0.8, r.2 * 0.25)), .white)
        }
        // Les bulles qui flottent (montent en boucle au repos, filent au toucher).
        let floaters: [(CGFloat, CGFloat, CGFloat, Double)] = [
            (44, 74, 11, 0), (158, 66, 13, 0.25), (128, 42, 8, 0.5), (68, 40, 7, 0.75), (168, 104, 7, 0.4),
        ]
        for (i, f) in floaters.enumerated() {
            let loop = p.cycle(4, offset: f.3, rest: 0.5) + 2 * t
            let c = loop - loop.rounded(.down)
            let rise = CGFloat(c - 0.5) * 30
            b.bubble(f.0 + CGFloat(sin(c * 6.3 + Double(i))) * 3, f.1 - rise, f.2, tint: tints[i % 4], amount: bump(c))
        }
        // Au toucher : trois bulles sortent de la mousse et éclatent.
        for k in 0..<3 {
            let u = seg(t, 0.05 + 0.2 * Double(k), 0.55 + 0.2 * Double(k))
            guard u > 0 && u < 1 else { continue }
            let x = [CGFloat(86), 118, 102][k]
            let y = 80 - CGFloat(u) * 46
            if u < 0.78 {
                b.bubble(x, y, 6 + CGFloat(u) * 5, tint: tints[k], amount: 1)
            } else {
                let v = (u - 0.78) / 0.22
                b.faded(1 - v).stroke(disk(x, y, 10 + CGFloat(v) * 8), tints[k], 2)
                b.sparkle(x, y, 6 * CGFloat(1 - v), tints[k], amount: 1 - v)
            }
        }
    }

    // MARK: fr.buche — une bûche (écorce, cernes, un rameau feuillu) ; action : elle saute et retombe « toc ».

    static func buche(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let lift = CGFloat(14 * hop(seg(t, 0, 0.45)))
        let land = CGFloat(pulse(seg(t, 0.42, 0.78)))
        let tilt = 5 * bump(seg(t, 0, 0.45))
        let bark = hex(0x8B5A36), barkDark = hex(0x6E4428), barkLight = hex(0xA8703F), wood = hex(0xF2CD8C), ring = hex(0xD9A55E)

        b.groundShadow(96, 163, 72 - lift, 8)
        for (x, dir) in [(CGFloat(30), CGFloat(-1)), (166, 1)] {
            for k in 0..<3 {
                b.faded(Double(land)).fill(disk(x + dir * CGFloat(4 + k * 7) * land, 160 - CGFloat(k) * 5 * land, 4 + CGFloat(k)),
                                           hex(0xD9CFC2))
            }
        }
        let l = b.moved(0, -lift).rotated(-tilt, 96, 152).scaled(1 + 0.05 * land, 1 - 0.06 * land, 96, 156)
        let twig = l.rotated(10 * wobble(t, 2), 88, 100)
        twig.fill(capsule(pt(88, 100), pt(98, 72), 8), bark)
        var leaf = Path()
        leaf.move(to: pt(97, 74))
        leaf.addQuadCurve(to: pt(128, 58), control: pt(106, 52))
        leaf.addQuadCurve(to: pt(97, 74), control: pt(122, 78))
        leaf.closeSubpath()
        twig.fill(leaf, hex(0x5DBB4F))
        twig.stroke(curve([pt(100, 72), pt(124, 60)]), hex(0x3E9A3A), 2)
        let trunk = box(22, 96, 138, 58, 26)
        l.fill(trunk, bark)
        let skin = l.clipped(trunk)
        skin.fill(box(22, 96, 138, 11), barkLight.opacity(0.7))
        for x in [CGFloat(48), 72, 96, 120] {
            skin.stroke(curve([pt(x, 98), pt(x + 4, 112), pt(x - 3, 128), pt(x + 3, 152)]), barkDark, 3)
        }
        skin.fill(oval(60, 132, 7, 5), barkDark)
        l.fill(oval(158, 125, 24, 31), barkDark)
        l.fill(oval(158, 125, 20, 27), wood)
        for s in [CGFloat(0.72), 0.46, 0.22] {
            l.stroke(oval(158, 125, 20 * s, 27 * s), ring, 2.2)
        }
        l.fill(disk(158, 125, 2.5), ring)
    }

    // MARK: fr.tache — une grosse tache de peinture colorée ; action : « splotch », elle s'écrase et projette ses gouttes.

    static func tache(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let splat = CGFloat(0.12 * pulse(seg(t, 0, 0.3)) - 0.05 * pulse(seg(t, 0.3, 0.7)))
        let spread = CGFloat(1 + 0.16 * pulse(seg(t, 0, 0.75)))
        let blue = hex(0x3E8EF0), yellow = hex(0xFFC53D), pink = hex(0xF2557A)

        func drops(_ cx: CGFloat, _ cy: CGFloat, _ color: Color, _ list: [(Double, CGFloat, CGFloat)]) {
            for (a, d, r) in list {
                b.fill(disk(cx + CGFloat(cos(a)) * d * spread, cy + CGFloat(sin(a)) * d * spread, r), color)
            }
        }
        // Petites taches jaune et rose, derrière la grande.
        let sy = b.scaled(1 + splat, 1 + splat, 146, 58)
        sy.fill(polarBlob(146, 58, count: 14) { a in 20 * (1 + 0.16 * sin(4 * a + 1)) }, yellow)
        drops(146, 58, yellow, [(-0.4, 30, 4.5), (0.9, 28, 3.5), (-1.9, 27, 3)])
        let sp = b.scaled(1 + splat, 1 + splat, 50, 150)
        sp.fill(polarBlob(50, 150, count: 14) { a in 17 * (1 + 0.17 * sin(5 * a + 2)) }, pink)
        drops(50, 150, pink, [(2.4, 25, 4), (1.2, 26, 3), (3.6, 24, 3)])

        let s = b.scaled(1 + splat, 1 + splat, 96, 106)
        let main = polarBlob(96, 106, count: 24) { a in 52 * (1 + 0.15 * sin(5 * a + 0.4) + 0.08 * sin(9 * a + 1.3)) }
        s.fill(main, blue)
        for (a, len) in [(-0.5, CGFloat(24)), (0.95, 26), (2.2, 20), (3.5, 24), (4.8, 18)] {
            let dir = pt(CGFloat(cos(a)), CGFloat(sin(a)))
            let from = pt(96 + dir.x * 44, 106 + dir.y * 44)
            let to = pt(96 + dir.x * (44 + len * spread), 106 + dir.y * (44 + len * spread))
            s.fill(capsule(from, to, 8), blue)
            s.fill(disk(to.x, to.y, 7), blue)
        }
        drops(96, 106, blue, [(-1.2, 66, 5), (0.3, 70, 4.5), (1.6, 62, 4), (2.9, 70, 5.5), (4.2, 66, 4)])
        s.rotated(-25, 78, 86).fill(oval(78, 86, 15, 9), .white.opacity(0.5))
        s.fill(disk(102, 80, 4), .white.opacity(0.45))
    }

    // MARK: fr.cactus — cactus à bras dans son pot, une fleur rose ; action : il se secoue comme des maracas.

    static func cactus(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let sway = 8 * shake(t, 5)
        let green = hex(0x4CB860), greenLight = hex(0x86DA92), greenDark = hex(0x359A4B), spine = hex(0xFFF6D6)
        let pot = hex(0xE07A45), potRim = hex(0xF08C57), flower = hex(0xFF6FA0)

        b.groundShadow(100, 182, 46, 6)
        let shaking = hold(t, rise: 0.1, fall: 0.85)
        b.soundArcs(42, 74, angle: 200, amount: shaking, gap: 7)
        b.soundArcs(158, 74, angle: -20, amount: shaking, gap: 7)
        let c = b.rotated(sway, 100, 140)
        c.fill(capsule(pt(86, 112), pt(60, 112), 20), green)
        c.fill(capsule(pt(60, 114), pt(60, 78), 20), green)
        c.fill(capsule(pt(114, 98), pt(142, 98), 20), green)
        c.fill(capsule(pt(142, 100), pt(142, 64), 20), green)
        let stem = box(78, 44, 44, 110, 22)
        c.fill(stem, green)
        let skin = c.clipped(stem)
        skin.fill(box(108, 40, 20, 120), greenDark.opacity(0.35))
        for x in [CGFloat(90), 100, 110] {
            skin.stroke(curve([pt(x, 52), pt(x, 150)]), greenLight.opacity(0.75), 2.5)
        }
        c.stroke(curve([pt(60, 108), pt(60, 82)]), greenLight.opacity(0.75), 2.5)
        c.stroke(curve([pt(142, 94), pt(142, 68)]), greenLight.opacity(0.75), 2.5)
        for s in [pt(85, 66), pt(115, 78), pt(86, 96), pt(114, 116), pt(88, 130), pt(53, 88), pt(67, 102), pt(149, 74), pt(135, 88)] {
            c.stroke(curve([pt(s.x - 4, s.y - 4), s, pt(s.x + 4, s.y - 4)]), spine, 2)
        }
        let fl = c.rotated(10 * wobble(t, 3), 100, 42)
        for k in 0..<5 {
            fl.rotated(Double(k) * 72, 100, 40).fill(oval(100, 30, 6.5, 10), flower)
        }
        fl.fill(disk(100, 40, 5.5), hex(0xFFD23F))
        b.fillRounded(poly([pt(62, 138), pt(138, 138), pt(130, 178), pt(70, 178)]), pot, 4)
        b.fill(box(52, 128, 96, 17, 6), potRim)
        b.fill(box(52, 140, 96, 5), hex(0xC4602F, 0.5))
    }

    // MARK: fr.fleche — une flèche (pointe, empennage) et sa cible ; action : « fffuit… toc ! », elle file dans la cible et vibre.

    static func fleche(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let red = hex(0xE8414B), redDark = hex(0xC22F3B), gold = hex(0xFFC53D)
        let target = pt(150, 58), tail0 = pt(30, 172)
        let dx = target.x - tail0.x, dy = target.y - tail0.y
        let dist = (dx * dx + dy * dy).squareRoot()
        let ux = dx / dist, uy = dy / dist
        let angle = atan2(Double(uy), Double(ux)) * 180 / .pi
        let length: CGFloat = 112
        let restTip = pt(tail0.x + ux * length, tail0.y + uy * length)
        let impact = pulse(seg(t, 0.2, 0.45))

        // La cible (elle encaisse le choc).
        let tb = b.scaled(1 + 0.08 * CGFloat(impact), 1 + 0.08 * CGFloat(impact), target.x, target.y)
        tb.fill(disk(target.x + 3, target.y + 4, 34), redDark)
        for (r, color) in [(CGFloat(34), red), (26, Color.white), (18, red), (10, gold)] {
            tb.fill(disk(target.x, target.y, r), color)
        }

        // Une flèche dans son repère : pointe en (0, 0), empennage vers les x négatifs.
        func arrow(tip: CGPoint, wiggle: Double, alpha: Double, head: Bool, trail: Double) {
            guard alpha > 0.01 else { return }
            b.layer(opacity: alpha) { layer in
                let a = layer.moved(tip.x, tip.y).rotated(angle + wiggle, 0, 0)
                if trail > 0.01 {
                    for y in [CGFloat(-9), 0, 9] {
                        a.faded(trail).stroke(curve([pt(-length - 8, y), pt(-length - 8 - 26 * CGFloat(trail), y)]),
                                              soundColor, 3.5)
                    }
                }
                a.fillRounded(poly([pt(-length + 4, -2), pt(-length + 28, -2), pt(-length + 17, -15), pt(-length - 2, -15)]),
                              hex(0x3FA9DC), 2)
                a.fillRounded(poly([pt(-length + 4, 2), pt(-length + 28, 2), pt(-length + 17, 15), pt(-length - 2, 15)]),
                              hex(0x3FA9DC), 2)
                a.stroke(curve([pt(-length + 6, -7), pt(-length + 20, -7)]), hex(0x8FD0FF), 2)
                a.stroke(curve([pt(-length + 6, 7), pt(-length + 20, 7)]), hex(0x8FD0FF), 2)
                a.fill(capsule(pt(-length + 2, 0), pt(-10, 0), 6), hex(0xB07A45))
                a.fill(box(-length - 2, -3.5, 7, 7, 2), hex(0x8C5E33))
                if head {
                    a.fillRounded(poly([pt(0, 0), pt(-19, -10), pt(-14, 0), pt(-19, 10)]), hex(0x9AA5B3), 1)
                    a.fill(poly([pt(0, 0), pt(-19, -10), pt(-14, 0)]), hex(0xD3D9E1))
                }
            }
        }
        if t == 0 {
            arrow(tip: restTip, wiggle: 0, alpha: 1, head: true, trail: 0)
        } else {
            let travel = dist - length
            if t < 0.22 {
                let f = CGFloat(easeIn(seg(t, 0.02, 0.22)))
                let tip = pt(restTip.x + ux * travel * f, restTip.y + uy * travel * f)
                arrow(tip: tip, wiggle: 0, alpha: 1, head: travel * (1 - f) > 16, trail: Double(0.3 + 0.7 * f))
            } else {
                arrow(tip: target, wiggle: 6 * wobble(seg(t, 0.22, 0.8), 3), alpha: 1 - seg(t, 0.8, 0.95), head: false, trail: 0)
            }
            // Une nouvelle flèche reprend sa place pour le prochain tir.
            arrow(tip: restTip, wiggle: 0, alpha: seg(t, 0.86, 1), head: true, trail: 0)
        }
    }

    // MARK: fr.brosse — brosse à DENTS avec son dentifrice ; action : frotte-frotte, un peu de mousse.

    static func brosse(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let scrub = CGFloat(9 * shake(t, 3))
        let foam = hold(t, rise: 0.15, fall: 0.8)
        let handle = hex(0x2BB5A8), handleDark = hex(0x1E9488), grip = hex(0xB5F0DA), tuft = hex(0x9CD1F7)

        b.groundShadow(100, 168, 70, 6)
        let br = b.rotated(-26, 100, 112).moved(scrub, 0)
        br.fill(box(20, 112, 110, 18, 9), handle)
        br.fill(box(40, 115, 42, 7, 3.5), grip)
        br.fill(box(22, 124, 106, 5, 2.5), handleDark.opacity(0.45))
        br.fill(box(124, 115, 30, 11, 5), handle)
        br.fill(box(146, 110, 38, 20, 8), handle)
        br.fill(box(148, 88, 34, 24, 4), hex(0xE4EEF8))
        br.fill(box(149, 88, 32, 22, 4), .white)
        for k in 0..<4 {
            br.fill(box(151 + CGFloat(k) * 8, 90, 4.5, 20, 2), tuft)
        }
        let wave = [pt(146, 84), pt(155, 76), pt(165, 84), pt(175, 76), pt(184, 82)]
        br.stroke(curve(wave), hex(0xC9D9EA), 15)
        br.stroke(curve(wave), .white, 12)
        br.stroke(curve(wave.map { pt($0.x, $0.y - 3) }), hex(0xF2557A), 2.4)
        br.stroke(curve(wave.map { pt($0.x, $0.y + 3) }), hex(0x4FCB9F), 2.4)
        for (i, spot) in [pt(150, 62), pt(174, 82), pt(132, 54), pt(166, 50)].enumerated() {
            let a = foam * (0.6 + 0.4 * p.sway(0.5, offset: Double(i) * 0.25))
            b.bubble(spot.x, spot.y, CGFloat(5 + i % 3 * 2), amount: a)
        }
    }

    // MARK: fr.princesse — une princesse souriante couronnée ; action : clin d'œil, étincelles magiques.

    static func princesse(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let tilt = 6 * wobble(t, 1.5)
        let wink = t > 0.25 && t < 0.62
        let skin = hex(0xC98B63), skinShade = hex(0xB47450), hair = hex(0x3B2620), hairLight = hex(0x5E3E31)
        let dress = hex(0xF48FB8), dressLight = hex(0xFFB6D4), gold = hex(0xFFC53D), goldDark = hex(0xE8A317)

        b.fill(blob([pt(40, 184), pt(44, 162), pt(70, 150), pt(100, 156), pt(130, 150), pt(156, 162), pt(160, 184)]), dress)
        b.fill(disk(50, 162, 17), dressLight)
        b.fill(disk(150, 162, 17), dressLight)
        b.fill(oval(100, 150, 17, 10), skin)
        for k in 0..<7 {
            let x = 88 + CGFloat(k) * 4
            b.fill(disk(x, 156 + CGFloat(abs(k - 3)) * -0.9 + 2, 2), gold)
        }
        let h = b.rotated(tilt, 100, 150)
        h.fill(blob([pt(100, 34), pt(146, 50), pt(158, 96), pt(156, 140), pt(132, 150), pt(100, 132),
                     pt(68, 150), pt(44, 140), pt(42, 96), pt(54, 50)]), hair)
        h.fill(box(90, 124, 20, 30, 8), skinShade)
        h.fill(disk(63, 102, 8), skin)
        h.fill(disk(137, 102, 8), skin)
        h.fill(oval(100, 97, 37, 41), skin)
        h.fill(blob([pt(62, 86), pt(64, 60), pt(100, 48), pt(136, 60), pt(138, 86), pt(122, 70), pt(100, 76), pt(80, 70)]), hair)
        h.stroke(curve([pt(72, 64), pt(90, 56)]), hairLight, 4)
        // (Pas de cils en trait : à cette taille ils se lisent comme des sourcils fâchés.)
        h.eye(86, 99, 7, blink: p.blink)
        h.eye(114, 99, 7, blink: p.blink, happy: wink)
        h.cheek(76, 114, 7)
        h.cheek(124, 114, 7)
        h.stroke(curve([pt(100, 105), pt(97, 111), pt(101, 113)]), skinShade, 2.5)
        h.stroke(curve([pt(89, 121), pt(100, 128), pt(111, 121)]), hex(0xB8405A), 3.5)
        let crown = poly([pt(70, 56), pt(68, 32), pt(84, 45), pt(100, 24), pt(116, 45), pt(132, 32), pt(130, 56)])
        h.fillRounded(crown, gold, 3)
        h.fill(box(68, 50, 64, 9, 4), goldDark)
        for (x, y) in [(CGFloat(68), CGFloat(32)), (100, 24), (132, 32)] { h.fill(disk(x, y, 4.5), gold) }
        h.fill(disk(100, 41, 5.5), hex(0xF2557A))
        h.fill(disk(81, 49, 3.5), hex(0x3FA9DC))
        h.fill(disk(119, 49, 3.5), hex(0x3FA9DC))
        for s in [(CGFloat(44), CGFloat(40), CGFloat(10), 0.05), (158, 32, 12, 0.2), (38, 84, 7, 0.35), (164, 80, 8, 0.5)] {
            b.sparkle(s.0, s.1, s.2, gold, amount: pulse(seg(t, s.3, s.3 + 0.45)))
        }
    }

    // MARK: en.push — une main qui pousse une caisse à jouets ; action : la caisse glisse sous la poussée.

    static func push(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let shove = CGFloat(12 * easeInOut(seg(t, 0, 0.5)) * (1 - easeInOut(seg(t, 0.55, 1))))
        let effort = pulse(seg(t, 0, 0.6))
        let crate = hex(0xE8414B), crateDark = hex(0xC22F3B), crateLight = hex(0xF26B5B), star = hex(0xFFC53D)
        let sleeve = hex(0x5DBB4F), sleeveDark = hex(0x46A03B), skin = hex(0xE9A97F), skinShade = hex(0xD48E64)

        b.groundShadow(137 + shove, 176, 46, 6)
        b.speedLines(38, 100, length: 24, amount: max(effort, 0.35))
        for k in 0..<3 {
            b.faded(effort).fill(disk(92 + shove - CGFloat(k) * 9, 172 - CGFloat(k) * 3, 4 + CGFloat(k)), hex(0xD9CFC2))
        }
        let s = b.moved(shove, 0)
        s.fill(disk(118, 90, 15), hex(0x3FA9DC))
        s.stroke(curve([pt(104, 86), pt(118, 82), pt(132, 86)]), .white.opacity(0.7), 3)
        s.fillRounded(box(140, 74, 20, 20, 3), hex(0xFFC53D), 1)
        s.fill(box(96, 96, 82, 78, 10), crate)
        s.fill(box(96, 158, 82, 16, 8), crateDark.opacity(0.45))
        s.fill(box(92, 92, 90, 16, 6), crateLight)
        s.fillRounded(star5(137, 136, 16), star, 2)
        // Le bras et la main : paume à plat contre la caisse, doigts vers le haut. La manche
        // entre par le bord de la carte (voulu : c'est le bras de quelqu'un, hors champ).
        s.fill(capsule(pt(-40, 140), pt(52, 130), 26), sleeve)
        s.fill(capsule(pt(48, 130), pt(56, 129.5), 27), sleeveDark)
        s.fill(capsule(pt(58, 129), pt(72, 127), 20), skinShade)
        // La main penche vers la caisse : on sent l'appui.
        let hand = s.rotated(7, 70, 132)
        for (i, x) in [CGFloat(68.5), 76, 83.5, 91].enumerated() {
            hand.fill(capsule(pt(x, 110), pt(x, 82 + CGFloat(abs(Double(i) - 1.5)) * 5), 7.5), skin)
        }
        hand.fill(box(64, 102, 32, 40, 12), skin)
        hand.fill(capsule(pt(66, 126), pt(52, 110), 9.5), skin)
        hand.stroke(curve([pt(70, 112), pt(90, 112)]), skinShade.opacity(0.6), 2)
    }

    // MARK: en.wash — se laver les mains : robinet, eau, savon ; action : les mains frottent, les bulles montent.

    static func wash(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let rub = CGFloat(7 * shake(t, 3))
        let foam = hold(t, rise: 0.1, fall: 0.85)
        let chrome = hex(0xC3CDD8), chromeDark = hex(0x8D9AAA), chromeLight = hex(0xEEF2F6)
        let water = hex(0x5DB2F7), waterLight = hex(0xA8D8FF), skin = hex(0xF3C09A), skinShade = hex(0xDFA27B)

        // Le robinet et son filet d'eau.
        b.fill(box(16, 28, 16, 34, 5), chromeDark)
        var spout = Path()
        spout.move(to: pt(28, 44))
        spout.addLine(to: pt(76, 44))
        spout.addQuadCurve(to: pt(92, 62), control: pt(92, 44))
        b.stroke(spout, chrome, 16)
        b.stroke(curve([pt(30, 40), pt(74, 40)]), chromeLight, 3)
        b.fill(box(84, 60, 16, 6, 2), chromeDark)
        b.fill(capsule(pt(50, 36), pt(50, 26), 8), chromeDark)
        b.fill(oval(50, 24, 12, 5), hex(0x3FA9DC))
        let flow = CGFloat(p.cycle(0.5, rest: 0.3) + 3 * t)
        let wave = CGFloat(2 * p.sway(0.7)) + CGFloat(3 * shake(t, 4))
        let stream = curve([pt(92, 66), pt(93 + wave, 86), pt(94 - wave, 104)])
        b.stroke(stream, waterLight, 11)
        b.dashed(stream, water, 3.5, dash: [7, 9], phase: -flow * 16)

        // Les mains qui se frottent (paumes l'une contre l'autre).
        func hand(_ h: WordArtBrush, _ color: Color, thumbRight: Bool) {
            for (i, x) in [CGFloat(80), 89, 98, 107].enumerated() {
                h.fill(capsule(pt(x, 118), pt(x, 90 + CGFloat(abs(Double(i) - 1.4)) * 5), 9), color)
            }
            h.fill(box(75, 110, 38, 46, 16), color)
            let thumb = thumbRight ? (pt(110, 142), pt(122, 124)) : (pt(78, 142), pt(66, 124))
            h.fill(capsule(thumb.0, thumb.1, 10), color)
        }
        hand(b.moved(rub * 0.5, -rub).rotated(20, 94, 156), skinShade, thumbRight: true)
        hand(b.moved(-rub * 0.5, rub).rotated(-20, 94, 156), skin, thumbRight: false)
        // La mousse du savon.
        let suds = hex(0xC7DDF3)
        for (x, y, r) in [(CGFloat(90), CGFloat(120), CGFloat(9)), (104, 132, 8), (84, 142, 7), (110, 112, 6)] {
            b.fill(puff(x, y, r, bumps: 6, bumpRadius: r * 0.45).offsetBy(dx: 0, dy: 1.5), suds)
            b.fill(puff(x, y, r, bumps: 6, bumpRadius: r * 0.45), .white)
        }
        let bubbles: [(CGFloat, CGFloat, CGFloat, Double)] = [
            (58, 104, 9, 0), (140, 98, 11, 0.3), (146, 146, 8, 0.55), (52, 150, 7, 0.8), (128, 70, 6, 0.15),
        ]
        for (i, bb) in bubbles.enumerated() {
            let loop = p.cycle(3, offset: bb.3, rest: 0.5) + 2 * t
            let c = loop - loop.rounded(.down)
            let rise = CGFloat(c - 0.5) * 24 * (1 + CGFloat(foam))
            b.bubble(bb.0 + CGFloat(sin(c * 6 + Double(i))) * 3, bb.1 - rise, bb.2, amount: bump(c))
        }
        for (x, y) in [(CGFloat(76), CGFloat(98)), (116, 100), (70, 170), (126, 172)] {
            b.fill(disk(x, y, 3), water.opacity(0.8))
        }
    }

    // MARK: en.ice — trois glaçons ; action : ils s'entrechoquent, « cling », et brillent.

    static func ice(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let clink = max(pulse(seg(t, 0.05, 0.35)), pulse(seg(t, 0.4, 0.7)))
        let top = hex(0xEAF8FF), left = hex(0xC2E7FA), right = hex(0x9CD4F2), edge = hex(0x7FC0EA)

        b.groundShadow(100, 170, 72, 7)
        func cube(_ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat, _ rot: Double, _ phase: Double) {
            let jig = 7 * wobble(seg(t, phase, min(1, phase + 0.7)), 2)
            let hopY = CGFloat(5 * hop(seg(t, phase, phase + 0.3)))
            let c = b.moved(0, -hopY).rotated(rot + jig, cx, cy + s * 0.5)
            let k = s * 0.87
            let whole = poly([pt(cx, cy - s), pt(cx + k, cy - s / 2), pt(cx + k, cy + s / 2), pt(cx, cy + s),
                              pt(cx - k, cy + s / 2), pt(cx - k, cy - s / 2)])
            c.stroke(whole, edge, 4)
            c.fillRounded(poly([pt(cx - k, cy - s / 2), pt(cx, cy), pt(cx, cy + s), pt(cx - k, cy + s / 2)]), left, 1.5)
            c.fillRounded(poly([pt(cx, cy), pt(cx + k, cy - s / 2), pt(cx + k, cy + s / 2), pt(cx, cy + s)]), right, 1.5)
            c.fillRounded(poly([pt(cx, cy - s), pt(cx + k, cy - s / 2), pt(cx, cy), pt(cx - k, cy - s / 2)]), top, 1.5)
            c.stroke(curve([pt(cx - k + 6, cy - s / 2 + 9), pt(cx - k + 6, cy + s / 2 - 4)]), .white.opacity(0.85), 3)
            c.stroke(curve([pt(cx - k * 0.45, cy - s * 0.72), pt(cx + k * 0.15, cy - s * 0.92)]), .white, 3)
        }
        cube(66, 128, 34, -6, 0)
        cube(136, 132, 32, 8, 0.1)
        cube(100, 80, 30, 3, 0.2)
        b.fill(disk(40, 162, 3.5), edge.opacity(0.7))
        b.fill(disk(164, 164, 3), edge.opacity(0.7))
        b.sparkle(152, 104, 7, hex(0x5FB0E8), amount: 0.8)
        b.sparkle(100, 124, 12, hex(0x5FB0E8), amount: clink)
        b.sparkle(122, 98, 8, sparkleGold, amount: clink * 0.9)
        b.sparkle(78, 90, 7, hex(0x5FB0E8), amount: clink * 0.7)
    }

    // MARK: en.piece — une pièce de puzzle ; action : « clic », elle s'emboîte avec un petit éclat.

    static func piece(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let snap = seg(t, 0, 0.35)
        let rot = -10 * bump(snap)
        let sc = CGFloat(1 + 0.12 * bump(snap) - 0.05 * bump(seg(t, 0.35, 0.6)))
        let burst = pulse(seg(t, 0.3, 0.8))
        let green = hex(0x58C06B), greenDark = hex(0x3E9A4F), greenLight = hex(0x9BE2A6)

        b.groundShadow(104, 178, 58, 7)
        var shape = Path()
        var pts: [CGPoint] = [pt(52, 60), pt(93, 60)]
        pts += arcPoints(100, 46, 14, from: 120, to: 420)
        pts += [pt(107, 60), pt(148, 60), pt(148, 101)]
        pts += arcPoints(162, 108, 14, from: 210, to: 510)
        pts += [pt(148, 115), pt(148, 156), pt(107, 156)]
        pts += arcPoints(100, 142, 14, from: 60, to: -240)
        pts += [pt(93, 156), pt(52, 156), pt(52, 115)]
        pts += arcPoints(66, 108, 14, from: 150, to: -150)
        pts += [pt(52, 101)]
        shape.addLines(pts)
        shape.closeSubpath()

        let pc = b.rotated(rot, 100, 108).scaled(sc, sc, 100, 108)
        pc.moved(4, 6).fillRounded(shape, greenDark, 3)
        pc.fillRounded(shape, greenLight, 3)
        pc.clipped(shape).fill(shape.offsetBy(dx: 3, dy: 3), green)
        pc.fill(oval(76, 82, 8, 5), .white.opacity(0.35))
        for (i, a) in [-135.0, -45.0, 45.0, 135.0].enumerated() {
            let r0: CGFloat = 70, r1: CGFloat = 70 + 14 * CGFloat(burst)
            let ca = CGFloat(cos(a * .pi / 180)), sa = CGFloat(sin(a * .pi / 180))
            b.faded(burst).stroke(curve([pt(100 + ca * r0, 108 + sa * r0), pt(100 + ca * r1, 108 + sa * r1)]), sparkleGold, 4)
            b.sparkle(100 + ca * (r1 + 6), 108 + sa * (r1 + 6), 7, i.isMultiple(of: 2) ? sparkleGold : hex(0x7FC4FA), amount: burst)
        }
    }

    // MARK: en.tennis — raquette et balle de tennis ; action : « pok », la balle rebondit sur la raquette.

    static func tennis(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let frame = hex(0xE8414B), grip = hex(0x3B4A6B), ball = hex(0xD7EA3A), ballDark = hex(0xB5CB1F)
        let rest = pt(150, 58), contact = pt(116, 78)
        var bp: CGPoint
        if t <= 0.2 {
            bp = lerp(rest, contact, easeIn(seg(t, 0, 0.2)))
        } else {
            let u = seg(t, 0.2, 0.95)
            bp = lerp(contact, rest, easeOut(u))
            bp.y -= CGFloat(30 * hop(u))
        }
        let hit = pulse(seg(t, 0.15, 0.45))
        let swing = 7 * bump(seg(t, 0, 0.45))

        b.groundShadow(112, 180, 40, 5)
        let r = b.rotated(swing, 144, 170).moved(76, 74).rotated(-35, 0, 0)
        var ring = oval(0, 0, 42, 51)
        ring.addPath(oval(0, 0, 34, 43))
        let face = oval(0, 0, 34, 43)
        let net = r.clipped(face)
        net.fill(face, .white)
        for k in -4...4 {
            let v = CGFloat(k) * 7.6
            net.stroke(curve([pt(v, -46), pt(v, 46)]), hex(0xB9C3CF), 1.8)
            net.stroke(curve([pt(-40, v), pt(40, v)]), hex(0xB9C3CF), 1.8)
        }
        r.fill(capsule(pt(-15, 46), pt(0, 68), 7), frame)
        r.fill(capsule(pt(15, 46), pt(0, 68), 7), frame)
        r.fillEO(ring, frame)
        r.stroke(curve([pt(-30, -32), pt(-12, -45)]), .white.opacity(0.45), 3)
        r.fill(capsule(pt(0, 64), pt(0, 86), 12), frame)
        r.fill(capsule(pt(0, 84), pt(0, 118), 14), grip)
        for y in stride(from: CGFloat(90), through: 112, by: 8) {
            r.stroke(curve([pt(-6, y), pt(6, y + 4)]), .white.opacity(0.35), 2)
        }
        let ballPath = disk(bp.x, bp.y, 19)
        b.fill(ballPath, ball)
        let fuzz = b.clipped(ballPath)
        fuzz.fill(oval(bp.x + 6, bp.y + 8, 16, 14), ballDark.opacity(0.45))
        fuzz.stroke(curve([pt(bp.x - 17, bp.y - 10), pt(bp.x - 7, bp.y), pt(bp.x - 17, bp.y + 10)]), .white, 3)
        fuzz.stroke(curve([pt(bp.x + 17, bp.y - 10), pt(bp.x + 7, bp.y), pt(bp.x + 17, bp.y + 10)]), .white, 3)
        b.sparkle(contact.x - 6, contact.y + 6, 12, sparkleGold, amount: hit)
    }

    // MARK: en.brush — brosse à CHEVEUX (picots à boules) ; action : elle brosse, deux grands coups.

    static func brush(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let sweep = CGFloat(12 * shake(t, 2))
        let lilac = hex(0xB57BE0), lilacDark = hex(0x9559C9), lilacLight = hex(0xD6ADF4), pad = hex(0x4A4F63), pin = hex(0x8A90A6)

        b.groundShadow(100, 160, 62, 5)
        let br = b.rotated(-18, 100, 110).moved(sweep, 0)
        for k in 0..<12 {
            let x = 38 + CGFloat(k) * 7.5
            br.stroke(curve([pt(x, 98), pt(x, 74)]), pin, 3)
            br.fill(disk(x, 73, 3.4), .white)
            br.stroke(disk(x, 73, 3.4), pin, 1.2)
        }
        br.fill(box(32, 95, 92, 11, 5), pad)
        br.fill(box(28, 104, 100, 21, 10), lilac)
        br.fill(box(32, 105, 92, 6, 3), lilacLight)
        br.fill(capsule(pt(122, 114), pt(168, 121), 16), lilac)
        br.fill(capsule(pt(126, 111), pt(162, 116), 4), lilacLight.opacity(0.8))
        br.fill(disk(158, 120, 3), lilacDark)
        b.sparkle(52, 44, 8, sparkleGold, amount: pulse(seg(t, 0.15, 0.55)))
        b.sparkle(150, 52, 6, sparkleGold, amount: pulse(seg(t, 0.45, 0.9)))
    }

    // MARK: en.splash — éclaboussure d'eau en couronne ; action : « plouf », la couronne jaillit, les gouttes volent.

    static func splash(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let rise = CGFloat(0.35 * pulse(seg(t, 0, 0.6)))
        let fly = CGFloat(hop(seg(t, 0, 0.8)))
        let ripple = seg(t, 0.1, 1)
        let water = hex(0x3E9CF0), waterLight = hex(0x8FD0FF), waterPale = hex(0xCBE8FF)

        b.fill(oval(100, 160, 80, 18), waterLight)
        b.fill(oval(100, 162, 64, 12), water)
        if ripple > 0 {
            b.faded(1 - ripple).stroke(oval(100, 160, 66 + 16 * CGFloat(ripple), 13 + 4 * CGFloat(ripple)), .white, 3)
        }
        let c = b.scaled(1 + rise * 0.25, 1 + rise, 100, 160)
        let crown = blob([pt(52, 160), pt(40, 108), pt(62, 134), pt(72, 84), pt(88, 128), pt(100, 64),
                          pt(112, 128), pt(128, 84), pt(138, 134), pt(160, 108), pt(148, 160)])
        c.linear(crown, [waterPale, waterLight, water], from: pt(100, 64), to: pt(100, 162))
        c.stroke(curve([pt(99, 78), pt(97, 112)]), .white.opacity(0.85), 4)
        c.stroke(curve([pt(72, 96), pt(73, 118)]), .white.opacity(0.7), 3)
        c.stroke(curve([pt(128, 96), pt(127, 118)]), .white.opacity(0.7), 3)
        let drops: [(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (34, 86, 6, -10, -14), (68, 60, 7, -6, -22), (100, 40, 8, 0, -24), (132, 60, 7, 6, -22),
            (166, 86, 6, 10, -14), (52, 66, 4, -8, -18), (148, 66, 4, 8, -18),
        ]
        for d in drops {
            let x = d.0 + d.3 * fly, y = d.1 + d.4 * fly
            b.fill(disk(x, y, d.2), water)
            b.fill(disk(x - d.2 * 0.3, y - d.2 * 0.35, d.2 * 0.3), .white.opacity(0.8))
        }
    }
}
#endif
