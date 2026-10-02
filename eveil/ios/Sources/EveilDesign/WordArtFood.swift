// WordArtFood.swift — ce qui se mange ou se boit : pêche, tasse, glace…
//
// Repère 200 × 200, sujet dans 16…184 (cf. WordArtKit.swift). Chaque fonction
// dessine le REPOS quand p.t = 0 et joue son action pour 0 < t < 1.

#if canImport(SwiftUI)
import SwiftUI

extension WordArtPaint {

    // MARK: fr.peche — le FRUIT (pas la pêche à la ligne) ; action : il saute et retombe « ploc ».

    static func peche(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let lift = CGFloat(22 * hop(seg(t, 0, 0.55)))
        let squash = CGFloat(bump(seg(t, 0.52, 0.85)))
        b.groundShadow(100, 179, 50 - lift * 0.5, 6, darkness: 1 - Double(lift) / 44)
        let fruit = b.moved(0, -lift).scaled(1 + 0.1 * squash, 1 - 0.12 * squash, 100, 176)

        let shape = polarBlob(100, 118, count: 28) { a in
            let d = a - 1.5 * .pi
            return 58 - 8 * exp(-d * d / 0.05)
        }
        fruit.radial(shape, [hex(0xFFD57E), hex(0xFFA764), hex(0xF26A5F)], center: pt(80, 100), radius: 96)
        fruit.clipped(shape).fill(oval(146, 132, 40, 52), hex(0xE9505A, 0.35))
        fruit.stroke(curve([pt(100, 66), pt(92, 92), pt(94, 124), pt(104, 156)]), hex(0xD9534F, 0.45), 4)
        fruit.rotated(-30, 78, 94).fill(oval(78, 94, 13, 8), .white.opacity(0.55))

        fruit.fill(capsule(pt(100, 68), pt(104, 50), 6), hex(0x8B5A2B))
        let leaf = fruit.rotated(14 * wobble(t, 2), 104, 54)
        var shapeLeaf = Path()
        shapeLeaf.move(to: pt(104, 54))
        shapeLeaf.addQuadCurve(to: pt(150, 34), control: pt(116, 24))
        shapeLeaf.addQuadCurve(to: pt(104, 54), control: pt(134, 62))
        shapeLeaf.closeSubpath()
        leaf.fill(shapeLeaf, hex(0x5DBB4F))
        leaf.stroke(curve([pt(107, 52), pt(126, 43), pt(145, 36)]), hex(0x3E9A3A), 2.4)
    }

    // MARK: fr.tasse — tasse à pois sur sa soucoupe, chocolat fumant ; action : elle tinte « tink ».

    static func tasse(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let lift = CGFloat(10 * hop(seg(t, 0, 0.36)))
        let tilt = -7 * bump(seg(t, 0, 0.36))
        let ring = bump(seg(t, 0.3, 0.75))
        let cup = hex(0x3FA9DC), cupDark = hex(0x2E86BD), cupLight = hex(0x9BD8F4)

        // La soucoupe.
        b.groundShadow(100, 176, 66, 6)
        b.fill(oval(100, 164, 72, 14), hex(0xC7D3E4))
        b.fill(oval(100, 160, 72, 13), hex(0xEDF2F9))
        b.fill(oval(100, 159, 40, 6), hex(0xD9E2EE))

        // La vapeur monte en boucle (chaque volute naît et s'efface : boucle sans à-coup) ;
        // au toucher, un tour de plus, plus vite.
        for (i, x0) in [CGFloat(80), 102, 124].enumerated() {
            let loop = p.cycle(2.4, offset: Double(i) / 3, rest: 0.4 + 0.08 * Double(i)) + t
            let c = loop - loop.rounded(.down)
            let rise = CGFloat(c) * 22
            let wave = CGFloat(p.sway(1.8, offset: Double(i) * 0.3)) * 3
            let alpha = bump(c)
            let wisp = curve([pt(x0 + wave, 80 - rise), pt(x0 - 7 - wave, 66 - rise),
                              pt(x0 + 5 + wave, 51 - rise), pt(x0 - 3, 38 - rise)])
            b.faded(alpha).stroke(wisp, hex(0xC6D4E6), 7)
        }

        let c = b.moved(0, -lift).rotated(tilt, 100, 156)
        // L'anse (sous le corps de la tasse).
        c.stroke(curve([pt(144, 100), pt(168, 104), pt(168, 128), pt(142, 138)]), cup, 11)
        c.stroke(curve([pt(146, 102), pt(164, 107), pt(163, 126), pt(144, 134)]), cupLight.opacity(0.35), 3)
        var body = Path()
        body.move(to: pt(50, 88))
        body.addLine(to: pt(150, 88))
        body.addCurve(to: pt(126, 157), control1: pt(150, 130), control2: pt(144, 154))
        body.addLine(to: pt(74, 157))
        body.addCurve(to: pt(50, 88), control1: pt(56, 154), control2: pt(50, 130))
        body.closeSubpath()
        c.fill(body, cup)
        let paint = c.clipped(body)
        paint.fill(blob([pt(126, 86), pt(156, 96), pt(146, 150), pt(118, 162), pt(132, 120)]), cupDark.opacity(0.6))
        for (x, y) in [(66.0, 108.0), (92.0, 118.0), (118.0, 106.0), (78.0, 138.0), (106.0, 144.0), (136.0, 128.0), (60.0, 128.0)] {
            paint.fill(disk(CGFloat(x), CGFloat(y), 6.5), .white.opacity(0.92))
        }
        c.fill(oval(100, 88, 51, 10), cupLight)
        c.fill(oval(100, 89.5, 45, 7.5), hex(0x7A4A2E))
        c.fill(oval(90, 88, 16, 3), hex(0xA87352))
        c.stroke(curve([pt(60, 98), pt(58, 118), pt(64, 140)]), .white.opacity(0.45), 5)

        // Le « tink » de la porcelaine.
        b.sparkle(58, 150, 12, sparkleGold, amount: ring)
        b.sparkle(146, 146, 9, sparkleGold, amount: ring * 0.8)
        b.sparkle(160, 164, 6, sparkleGold, amount: ring * 0.6)
    }

    // MARK: fr.saucisse — une saucisse grillée piquée sur une fourchette ; action : elle grésille.

    static func saucisse(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let sizzle = hold(t, rise: 0.1, fall: 0.8)
        let jiggle = 4 * shake(t, 5)
        let meat = hex(0xD65A3C), meatLight = hex(0xF08A66), meatDark = hex(0xA93F2A), grill = hex(0x8A3322)
        let steel = hex(0xC9D1DB), steelLight = hex(0xEEF2F6)

        b.groundShadow(100, 182, 30, 5)
        // La vapeur (boucle douce au repos, plus forte quand ça grésille).
        for (i, x0) in [CGFloat(78), 118].enumerated() {
            let loop = p.cycle(2.2, offset: Double(i) / 2, rest: 0.45 + 0.1 * Double(i)) + t
            let c = loop - loop.rounded(.down)
            let rise = CGFloat(c) * 18
            let wave = CGFloat(p.sway(1.6, offset: Double(i) * 0.4)) * 3
            let wisp = curve([pt(x0 + wave, 62 - rise), pt(x0 - 6 - wave, 51 - rise),
                              pt(x0 + 5 + wave, 40 - rise), pt(x0 - 2, 30 - rise)])
            b.faded(bump(c) * (0.7 + 0.3 * sizzle)).stroke(wisp, hex(0xC6D4E6), 6)
        }
        // La fourchette (ses dents plantées derrière la saucisse).
        b.fill(capsule(pt(100, 178), pt(100, 118), 13), steel)
        b.stroke(curve([pt(97, 172), pt(97, 124)]), steelLight, 3)
        b.fill(box(81, 100, 38, 20, 10), steel)
        for x in [CGFloat(85), 95.5, 104.5, 115] {
            b.fill(capsule(pt(x, 106), pt(x, 76), 6), steel)
        }
        // La saucisse, un peu arquée, grillée.
        let s = b.rotated(jiggle, 100, 86)
        let sausage = curve([pt(40, 94), pt(100, 76), pt(160, 94)]).strokedPath(StrokeStyle(lineWidth: 38, lineCap: .round))
        s.fill(capsule(pt(22, 97), pt(16, 99), 7), meatDark)
        s.fill(capsule(pt(178, 97), pt(184, 99), 7), meatDark)
        s.fill(sausage, meat)
        let skin = s.clipped(sausage)
        skin.stroke(curve([pt(30, 114), pt(100, 96), pt(170, 114)]), meatDark.opacity(0.45), 14)
        for x in [CGFloat(66), 94, 122] {
            skin.stroke(curve([pt(x - 5, 70), pt(x + 7, 104)]), grill, 5)
        }
        s.stroke(curve([pt(46, 84), pt(100, 66), pt(154, 84)]), meatLight.opacity(0.8), 6)
        // Petites étincelles du grésillement.
        for (i, spot) in [pt(40, 62), pt(158, 64), pt(26, 124), pt(174, 122), pt(128, 50)].enumerated() {
            let a = pulse(seg(t, 0.05 + Double(i) * 0.12, 0.35 + Double(i) * 0.12))
            b.sparkle(spot.x, spot.y, 7, i.isMultiple(of: 2) ? sparkleGold : hex(0xFF8A3D), amount: a)
        }
    }

    // MARK: fr.os — UN os de chien ; action : croc-croc, il tremble et perd des miettes.

    static func os(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let shiver = 9 * wobble(t, 2.5)
        let lift = CGFloat(8 * hop(seg(t, 0, 0.35)))
        let bone = hex(0xF8ECD4), boneShade = hex(0xE3CBA0), boneLight = hex(0xFFFBF2), outline = hex(0xD5B886)

        b.groundShadow(100, 150, 64, 7)
        // Miettes qui sautent du bout mordillé.
        let u = seg(t, 0.15, 0.85)
        if u > 0 && u < 1 {
            for (i, v) in [(CGFloat(26), CGFloat(-40)), (40, -22), (14, -30), (34, -48), (46, -34)].enumerated() {
                let x = 150 + v.0 * CGFloat(u)
                let y = 84 + v.1 * CGFloat(u) + 70 * CGFloat(u * u)
                b.faded(1 - u).fill(disk(x, y, CGFloat(3 + i % 3)), boneShade)
            }
        }
        let o = b.moved(0, -lift).rotated(-16 + shiver, 100, 102)
        func shape(_ dy: CGFloat) -> Path {
            var path = Path()
            path.addPath(box(54, 90 + dy, 92, 24, 12))
            for (x, y) in [(CGFloat(52), CGFloat(86)), (52, 118), (148, 86), (148, 118)] {
                path.addPath(disk(x, y + dy, 17))
            }
            return path
        }
        o.stroke(shape(5), outline, 5)
        o.fill(shape(5), boneShade)
        o.stroke(shape(0), outline, 5)
        // Face du dessus claire, ombrée en bas à droite.
        o.fill(shape(0), boneShade)
        o.clipped(shape(0)).fill(shape(0).offsetBy(dx: -3, dy: -5), bone)
        o.stroke(curve([pt(62, 96), pt(138, 96)]), boneLight, 5)
        o.stroke(curve([pt(42, 78), pt(50, 72)]), boneLight, 4)
        o.stroke(curve([pt(138, 76), pt(146, 72)]), boneLight, 4)
    }

    // MARK: fr.glace — cornet gaufré, boule fraise, boule chocolat, cerise ; action : la glace tremblote.

    static func glace(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let w = wobble(t, 3)
        let sx = CGFloat(1 + 0.07 * w), sy = CGFloat(1 - 0.07 * w)
        let cherryHop = CGFloat(7 * hop(seg(t, 0.05, 0.4)))
        let cone = hex(0xF2B866), coneDark = hex(0xD9953F), waffle = hex(0xC98534)
        let straw = hex(0xFF9CBB), strawDark = hex(0xF07AA2), choco = hex(0x8B5A3C), chocoDark = hex(0x6E4430)

        var c = Path()
        c.move(to: pt(64, 104))
        c.addLine(to: pt(136, 104))
        c.addLine(to: pt(104, 176))
        c.addQuadCurve(to: pt(96, 176), control: pt(100, 183))
        c.closeSubpath()
        b.fill(c, cone)
        let grid = b.clipped(c)
        for k in -7...7 {
            let x = 100 + CGFloat(k) * 12
            grid.stroke(curve([pt(x - 50, 96), pt(x + 50, 186)]), waffle, 2.4)
            grid.stroke(curve([pt(x + 50, 96), pt(x - 50, 186)]), waffle, 2.4)
        }
        grid.fill(poly([pt(112, 100), pt(140, 100), pt(104, 184)]), coneDark.opacity(0.35))

        let s = b.scaled(sx, sy, 100, 106)
        // Boule fraise, bord qui coule sur le cornet.
        s.fill(disk(100, 86, 36), straw)
        for (x, y) in [(CGFloat(68), CGFloat(100)), (84, 106), (100, 108), (116, 106), (132, 100)] {
            s.fill(disk(x, y, 10), straw)
        }
        s.fill(capsule(pt(86, 106), pt(86, 120), 9), straw)
        s.fill(capsule(pt(122, 104), pt(122, 113), 8), straw)
        s.clipped(disk(100, 86, 36)).fill(oval(124, 100, 26, 22), strawDark.opacity(0.45))
        s.fill(oval(80, 74, 9, 6), .white.opacity(0.5))
        // Boule chocolat et vermicelles.
        s.fill(disk(100, 54, 28), choco)
        for (x, y) in [(CGFloat(78), CGFloat(66)), (92, 72), (108, 72), (122, 66)] {
            s.fill(disk(x, y, 8.5), choco)
        }
        s.clipped(disk(100, 54, 28)).fill(oval(118, 64, 18, 16), chocoDark.opacity(0.5))
        let sprinkles: [(CGFloat, CGFloat, Double, UInt32)] = [(88, 44, 30, 0xFFD23F), (106, 40, -40, 0x6FD3F7), (116, 54, 70, 0xF7F7F7),
                                                              (84, 58, -60, 0x7EE0A0), (100, 62, 10, 0xFF8FB1), (118, 38, 20, 0x7EE0A0)]
        for sp in sprinkles {
            s.rotated(sp.2, sp.0, sp.1).fill(capsule(pt(sp.0 - 4, sp.1), pt(sp.0 + 4, sp.1), 3.4), hex(sp.3))
        }
        s.fill(oval(86, 42, 7, 4.5), .white.opacity(0.35))
        // La cerise (elle saute au toucher).
        let ch = s.moved(0, -cherryHop)
        ch.stroke(curve([pt(104, 24), pt(108, 17), pt(115, 13)]), hex(0x5E8C31), 2.6)
        ch.fill(disk(103, 31, 9), hex(0xE8414B))
        ch.fill(disk(100, 28, 2.6), .white.opacity(0.7))
    }

    // MARK: en.radish — radis rond rouge, bout blanc, fanes vertes ; action : il saute hors de terre.

    static func radish(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let lift = CGFloat(16 * hop(seg(t, 0, 0.5)))
        let squash = CGFloat(pulse(seg(t, 0.46, 0.8)))
        let red = hex(0xE8445E), redLight = hex(0xF7788C), redDark = hex(0xC7304A)
        let leaf = hex(0x5DBB4F), leafDark = hex(0x3E9A3A), stem = hex(0x8FD06F)

        b.groundShadow(100, 181, 40 - lift * 0.6, 6)
        let r = b.moved(0, -lift).scaled(1 + 0.08 * squash, 1 - 0.1 * squash, 100, 178)
        for (i, fan) in [(-34.0, CGFloat(60)), (34.0, 60), (0.0, 72)].enumerated() {
            let l = r.rotated(fan.0 + 10 * wobble(t, 2.5) * (i == 1 ? -1 : 1), 100, 92)
            let top = 92 - fan.1
            l.stroke(curve([pt(100, 94), pt(100, 92 - fan.1 * 0.4)]), stem, 6)
            let blade = blob([pt(100, 92 - fan.1 * 0.3), pt(86, 92 - fan.1 * 0.55), pt(84, top + 14), pt(100, top),
                              pt(116, top + 14), pt(114, 92 - fan.1 * 0.55)])
            l.fill(blade, leaf)
            l.stroke(curve([pt(100, 92 - fan.1 * 0.3), pt(100, top + 6)]), leafDark, 2.4)
        }
        let bulb = blob([pt(100, 88), pt(134, 100), pt(144, 130), pt(126, 158), pt(100, 166), pt(74, 158), pt(56, 130), pt(66, 100)])
        r.radial(bulb, [redLight, red, redDark], center: pt(84, 112), radius: 84)
        r.clipped(bulb).fill(oval(100, 170, 36, 17), hex(0xFFF3F5))
        r.fill(capsule(pt(100, 164), pt(103, 180), 4), hex(0xF1DDE2))
        r.rotated(-30, 80, 112).fill(oval(80, 112, 10, 6), .white.opacity(0.55))
    }

    // MARK: en.juice — verre de jus d'orange, paille rayée, rondelle d'orange ; action : « slurp ».

    static func juice(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let sip = CGFloat(hold(t, rise: 0.2, fall: 0.75))
        let glass = hex(0xDCEEFC), glassEdge = hex(0xA9CCEB), orange = hex(0xFFA11F), orangeLight = hex(0xFFC766)

        b.groundShadow(100, 181, 44, 6)
        var cup = Path()
        cup.move(to: pt(56, 50))
        cup.addLine(to: pt(144, 50))
        cup.addLine(to: pt(136, 168))
        cup.addQuadCurve(to: pt(126, 178), control: pt(135, 178))
        cup.addLine(to: pt(74, 178))
        cup.addQuadCurve(to: pt(64, 168), control: pt(65, 178))
        cup.closeSubpath()
        b.fill(cup, glass)
        // La paille (derrière le jus, elle dépasse et se tortille pendant le slurp).
        let st = b.rotated(3 * shake(t, 3), 116, 110)
        var straw = Path()
        straw.move(to: pt(112, 160))
        straw.addLine(to: pt(122, 42))
        straw.addQuadCurve(to: pt(136, 24), control: pt(124, 26))
        straw.addLine(to: pt(160, 16))
        st.stroke(straw, .white, 9)
        st.dashed(straw, hex(0xE8414B), 9, dash: [7, 7])
        // Le jus : son niveau baisse quand on aspire.
        let level = 74 + 10 * sip
        let juice = b.clipped(cup)
        juice.fill(box(40, level, 120, 140), orange)
        juice.fill(box(126, level, 30, 140), hex(0xF08A12, 0.35))
        juice.fill(oval(100, level, 45, 6), orangeLight)
        for (x, y, r) in [(CGFloat(84), CGFloat(120), CGFloat(3)), (102, 146, 2.5), (90, 160, 2)] {
            juice.fill(disk(x, y, r), orangeLight.opacity(0.8))
        }
        for k in 0..<4 {
            let u = seg(t, 0.08 + 0.12 * Double(k), 0.55 + 0.12 * Double(k))
            guard u > 0 && u < 1 else { continue }
            let y = 164 - CGFloat(u) * (164 - level - 8)
            b.bubble(110 - CGFloat(k % 2) * 10, y, 3 + CGFloat(k), tint: hex(0xFFE3A8), amount: bump(u))
        }
        b.stroke(curve([pt(70, 62), pt(78, 164)]), .white.opacity(0.75), 6)
        b.stroke(oval(100, 50, 44, 5), glassEdge, 2.5)
        // La rondelle d'orange accrochée au bord.
        let slice = b.rotated(-15, 62, 52)
        slice.fill(disk(62, 52, 20), hex(0xF7931E))
        slice.fill(disk(62, 52, 16), hex(0xFFD36B))
        for k in 0..<6 {
            let a = Double(k) / 6 * 2 * .pi
            slice.stroke(curve([pt(62, 52), pt(62 + CGFloat(cos(a)) * 15, 52 + CGFloat(sin(a)) * 15)]), .white.opacity(0.9), 1.8)
        }
    }

    // MARK: en.dish — une assiette à bord bleu ; action : elle tournoie en tintant avant de se poser.

    static func dish(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let spin = wobble(t, 3)
        let hopY = CGFloat(6 * hop(seg(t, 0, 0.3)))
        let clink = max(pulse(seg(t, 0.25, 0.55)), 0.7 * pulse(seg(t, 0.55, 0.85)))
        let plate = hex(0xFBFCFF), side = hex(0xCFD9E6), rim = hex(0x7FB3EA), well = hex(0xE9F0F9)
        let outline = hex(0xB9C6D8)

        b.groundShadow(100, 160, 80, 9)
        let d = b.moved(0, -hopY).rotated(7 * spin, 100, 156).scaled(1, 1 - 0.07 * CGFloat(abs(spin)), 100, 110)
        d.fill(oval(100, 112, 83, 50), side)
        d.fill(oval(100, 105, 83, 51), outline)
        d.fill(oval(100, 105, 81, 49), plate)
        var ring = oval(100, 105, 81, 49)
        ring.addPath(oval(100, 108, 58, 33))
        d.fillEO(ring, rim)
        for k in 0..<20 {
            let a = Double(k) / 20 * 2 * .pi
            d.fill(disk(100 + CGFloat(cos(a)) * 69.5, 106.5 + CGFloat(sin(a)) * 41, 3.4), .white)
        }
        d.fill(oval(100, 108, 58, 33), well)
        d.fill(oval(100, 111, 51, 27), plate)
        d.stroke(curve([pt(44, 88), pt(62, 72), pt(92, 62)]), .white.opacity(0.85), 5)
        b.sparkle(26, 118, 11, sparkleGold, amount: clink)
        b.sparkle(174, 116, 9, sparkleGold, amount: clink)
        b.sparkle(160, 70, 7, sparkleGold, amount: clink * 0.7)
    }
}
#endif
