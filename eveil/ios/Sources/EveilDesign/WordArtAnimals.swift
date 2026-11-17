// WordArtAnimals.swift — les animaux du petit train : vache, mouche, biche…
//
// Repère 200 × 200, sujet dans 16…184 (cf. WordArtKit.swift). Grands yeux
// amicaux (ceux de la mascotte), silhouette caractéristique, rien d'effrayant.
// Chaque fonction dessine le REPOS quand p.t = 0 et joue son action pour 0 < t < 1.

#if canImport(SwiftUI)
import SwiftUI

extension WordArtPaint {

    // MARK: fr.vache — vache blanche à taches noires, museau rose ; action : elle lève la tête, « meuh ».

    static func vache(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let moo = hold(t, rise: 0.15, fall: 0.75)
        let nod = -9 * moo + 3 * wobble(t, 2)
        let white = hex(0xFBFBF7), whiteShade = hex(0xE3E3DA), black = hex(0x33333B)
        let pink = hex(0xF7A9B9), pinkDark = hex(0xD9788E), hoof = hex(0x5A534E), horn = hex(0xF1DFA8)

        b.groundShadow(116, 174, 66, 7)
        let tail = b.rotated(16 * wobble(t, 2.5), 170, 98)
        tail.stroke(curve([pt(170, 98), pt(183, 114), pt(181, 138)]), whiteShade, 5)
        tail.fill(blob([pt(175, 134), pt(187, 135), pt(185, 151), pt(174, 148)]), black)
        for x in [CGFloat(98), 158] {
            b.fill(box(x - 7, 124, 14, 46, 6), whiteShade)
            b.fill(box(x - 7, 160, 14, 10, 4), hoof)
        }
        let body = box(62, 82, 112, 58, 28)
        b.fill(body, white)
        let hide = b.clipped(body)
        hide.fill(blob([pt(96, 82), pt(120, 86), pt(122, 104), pt(104, 112), pt(92, 100)]), black)
        hide.fill(blob([pt(138, 108), pt(160, 104), pt(168, 124), pt(152, 140), pt(136, 128)]), black)
        hide.fill(blob([pt(150, 80), pt(174, 82), pt(172, 96), pt(156, 96)]), black)
        hide.fill(box(62, 128, 112, 14), whiteShade.opacity(0.6))
        b.fill(oval(128, 141, 12, 7), pink)
        for x in [CGFloat(122), 128, 134] { b.fill(capsule(pt(x, 144), pt(x, 150), 3.5), pinkDark) }
        for x in [CGFloat(82), 142] {
            b.fill(box(x - 7, 124, 14, 48, 6), white)
            b.fill(box(x - 7, 162, 14, 10, 4), hoof)
        }

        let head = b.rotated(nod, 78, 106)
        head.rotated(-20, 28, 70).fill(oval(28, 70, 17, 8), white)
        head.rotated(-20, 28, 70).fill(oval(31, 70, 10, 4.5), pink)
        head.rotated(20, 90, 70).fill(oval(90, 70, 17, 8), white)
        head.rotated(20, 90, 70).fill(oval(87, 70, 10, 4.5), pink)
        head.fill(capsule(pt(45, 56), pt(38, 38), 8), horn)
        head.fill(capsule(pt(73, 56), pt(80, 38), 8), horn)
        let skull = oval(59, 81, 31, 30)
        head.fill(skull, white)
        head.clipped(skull).fill(blob([pt(70, 50), pt(92, 58), pt(92, 74), pt(80, 70), pt(68, 62)]), black)
        head.fill(oval(59, 105, 30, 18), pink)
        head.fill(oval(49, 102, 4.5, 5.5), pinkDark)
        head.fill(oval(69, 102, 4.5, 5.5), pinkDark)
        if moo > 0.05 {
            head.fill(oval(59, 114, 7 + 5 * moo, 7 * moo), hex(0x8C2F45))
        } else {
            head.stroke(curve([pt(51, 113), pt(59, 116), pt(67, 113)]), pinkDark, 2.6)
        }
        head.eye(47, 81, 6.5, blink: p.blink)
        head.eye(71, 81, 6.5, blink: p.blink)
        b.soundArcs(36, 124, angle: 150, amount: moo, gap: 8)
    }

    // MARK: fr.mouche — mouche mignonne (gros yeux rouges, ailes claires) ; action : bzzz, les ailes vrombissent.

    static func mouche(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let buzz = hold(t, rise: 0.08, fall: 0.85)
        let flap = 7 * p.sway(0.24) + 24 * sin(2 * .pi * 15 * t) * buzz
        let hover = CGFloat(3 * p.sway(1.4)) - CGFloat(9 * bump(t))
        let jitter = CGFloat(2.5 * sin(2 * .pi * 6 * t) * buzz)
        let dark = hex(0x3B4054), darker = hex(0x2D3142), stripe = hex(0x5B627A)
        let eyeRed = hex(0xD8353F), eyeDark = hex(0xA9222F), wing = hex(0xD8ECFF), vein = hex(0xA9CBEA)

        b.groundShadow(100, 182, 30 + hover * 0.6, 5, darkness: 0.55)
        b.soundArcs(40, 100, angle: 180, amount: buzz)
        b.soundArcs(160, 100, angle: 0, amount: buzz)
        let f = b.moved(jitter, hover)
        for side in [CGFloat(-1), 1] {
            let root = pt(100 + side * 10, 94)
            let w = f.rotated(Double(side) * -(30 + flap), root.x, root.y)
            w.fill(oval(root.x + side * 38, root.y, 38, 17), wing.opacity(0.9))
            w.stroke(curve([pt(root.x + side * 6, root.y), pt(root.x + side * 40, root.y - 2), pt(root.x + side * 66, root.y)]), vein, 2.2)
            w.stroke(curve([pt(root.x + side * 30, root.y - 1), pt(root.x + side * 48, root.y + 9)]), vein, 1.8)
        }
        for side in [CGFloat(-1), 1] {
            let legs: [[CGPoint]] = [
                [pt(100 + side * 16, 104), pt(100 + side * 34, 102), pt(100 + side * 44, 116)],
                [pt(100 + side * 18, 118), pt(100 + side * 38, 124), pt(100 + side * 42, 142)],
                [pt(100 + side * 14, 132), pt(100 + side * 28, 146), pt(100 + side * 28, 164)],
            ]
            for leg in legs { f.stroke(curve(leg), darker, 3.6) }
        }
        let belly = oval(100, 130, 27, 31)
        f.fill(belly, dark)
        let bands = f.clipped(belly)
        bands.fill(box(60, 120, 80, 7), stripe)
        bands.fill(box(60, 136, 80, 7), stripe)
        f.fill(oval(100, 100, 23, 17), darker)
        f.stroke(curve([pt(95, 50), pt(90, 40)]), darker, 3)
        f.stroke(curve([pt(105, 50), pt(110, 40)]), darker, 3)
        f.fill(disk(100, 72, 25), dark)
        for x in [CGFloat(84), 116] {
            let eye = oval(x, 67, 15, 17)
            f.fill(eye, eyeRed)
            f.clipped(eye).fill(oval(x + 3, 78, 15, 9), eyeDark)
            f.fill(disk(x - 5, 60, 4.8), .white)
            f.fill(disk(x + 4, 73, 2), .white.opacity(0.8))
        }
        f.stroke(curve([pt(92, 86), pt(100, 90), pt(108, 86)]), hex(0xF2B6C0), 2.6)
    }

    // MARK: fr.biche — biche (femelle : PAS de bois), longues pattes, grandes oreilles ; action : un bond.

    static func biche(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let air = hop(seg(t, 0.08, 0.72))
        let lift = CGFloat(13 * air)
        let twitch = 16 * wobble(seg(t, 0, 0.4), 1.5)
        let fur = hex(0xC8834A), furDark = hex(0xA9683A), cream = hex(0xF7E6CB), hoof = hex(0x4A3A30)

        b.groundShadow(116, 180, 50 - lift, 6, darkness: 1 - air * 0.5)
        // Posée un peu bas : les grandes oreilles restent dans le cadre en plein bond.
        let d = b.moved(0, 8 - lift)
        // En l'air : pattes avant tendues vers l'avant, pattes arrière vers l'arrière.
        func frontLeg(_ x: CGFloat, _ color: Color) {
            let l = d.rotated(32 * air, x, 118)
            l.fill(capsule(pt(x, 116), pt(x - 2, 168), 8), color)
            l.fill(capsule(pt(x - 2, 166), pt(x - 2, 170), 9), hoof)
        }
        func backLeg(_ x: CGFloat, _ color: Color) {
            let l = d.rotated(-30 * air, x, 110)
            l.fill(capsule(pt(x, 110), pt(x + 9, 142), 12), color)
            l.fill(capsule(pt(x + 9, 142), pt(x + 3, 168), 8), color)
            l.fill(capsule(pt(x + 3, 166), pt(x + 3, 170), 9), hoof)
        }
        frontLeg(90, furDark)
        backLeg(144, furDark)
        d.fill(blob([pt(152, 90), pt(164, 78), pt(172, 84), pt(166, 98)]), fur)
        d.fill(oval(167, 88, 3.5, 6), cream)
        let body = oval(117, 102, 44, 24)
        d.fill(body, fur)
        d.clipped(body).fill(oval(114, 124, 38, 10), cream)
        frontLeg(99, fur)
        backLeg(133, fur)

        let h = d.rotated(-7 * air, 90, 100)
        h.fill(capsule(pt(92, 98), pt(71, 62), 22), fur)
        h.rotated(-32, 80, 84).fill(oval(80, 84, 5, 13), cream)
        h.rotated(12 + twitch, 68, 46).fill(oval(66, 30, 8, 17), furDark)
        h.rotated(42 - twitch, 78, 46).fill(oval(80, 28, 9, 18), fur)
        h.rotated(42 - twitch, 78, 46).fill(oval(80, 30, 5, 12), cream)
        h.fill(oval(64, 55, 21, 17), fur)
        h.rotated(20, 47, 65).fill(oval(47, 65, 15, 10), fur)
        h.rotated(20, 43, 68).fill(oval(42, 69, 9, 6.5), cream)
        h.fill(oval(33, 66, 5, 4), ink)
        h.eye(62, 52, 6.5, blink: p.blink)
        if !p.blink {
            h.stroke(curve([pt(57, 46), pt(53, 42)]), ink, 2)
            h.stroke(curve([pt(61, 45), pt(59, 40)]), ink, 2)
        }
        h.cheek(71, 63, 5)
        h.stroke(curve([pt(40, 73), pt(45, 75), pt(50, 73)]), hex(0x8A5230), 2)
    }

    // MARK: fr.minouche — un chat roux tout simple, assis (pas le chef de gare) ; action : « miaou ».

    static func minouche(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let meow = hold(t, rise: 0.18, fall: 0.72)
        let fur = hex(0xF79E3D), furDark = hex(0xDB7321), cream = hex(0xFFEBD0), pink = hex(0xF99FAD)

        b.groundShadow(104, 178, 56, 6)
        let tail = b.rotated(10 * wobble(t, 2), 128, 168)
        tail.stroke(curve([pt(124, 170), pt(158, 172), pt(176, 150), pt(170, 124)]), fur, 15)
        tail.stroke(curve([pt(175, 142), pt(170, 124)]), furDark, 15)
        let body = blob([pt(70, 174), pt(64, 144), pt(78, 116), pt(100, 108), pt(122, 116), pt(136, 144), pt(130, 174)])
        b.fill(body, fur)
        let coat = b.clipped(body)
        coat.fill(oval(100, 140, 19, 28), cream)
        for y in [CGFloat(130), 146, 162] {
            coat.stroke(curve([pt(60, y), pt(74, y + 3)]), furDark, 5)
            coat.stroke(curve([pt(140, y), pt(126, y + 3)]), furDark, 5)
        }
        for x in [CGFloat(86), 114] {
            b.fill(capsule(pt(x, 136), pt(x, 166), 17), fur)
            b.fill(oval(x, 170, 11, 7), cream)
        }

        let head = b.rotated(-6 * meow, 100, 118)
        head.fillRounded(poly([pt(58, 70), pt(64, 30), pt(92, 50)]), fur, 4)
        head.fillRounded(poly([pt(142, 70), pt(136, 30), pt(108, 50)]), fur, 4)
        head.fill(poly([pt(67, 62), pt(69, 40), pt(84, 52)]), pink)
        head.fill(poly([pt(133, 62), pt(131, 40), pt(116, 52)]), pink)
        let face = oval(100, 80, 48, 40)
        head.fill(face, fur)
        let skin = head.clipped(face)
        skin.fill(capsule(pt(100, 42), pt(100, 54), 6), furDark)
        skin.fill(capsule(pt(88, 44), pt(91, 55), 5), furDark)
        skin.fill(capsule(pt(112, 44), pt(109, 55), 5), furDark)
        for (y0, y1) in [(CGFloat(76), CGFloat(79)), (86, 86)] {
            skin.stroke(curve([pt(52, y0), pt(64, y1)]), furDark, 4)
            skin.stroke(curve([pt(148, y0), pt(136, y1)]), furDark, 4)
        }
        head.fill(disk(90, 97, 13), cream)
        head.fill(disk(110, 97, 13), cream)
        head.cheek(68, 95, 7)
        head.cheek(132, 95, 7)
        let happy = meow > 0.45
        head.eye(82, 74, 8.5, blink: p.blink, happy: happy)
        head.eye(118, 74, 8.5, blink: p.blink, happy: happy)
        head.fillRounded(poly([pt(94, 87), pt(106, 87), pt(100, 94)]), pink, 2)
        if meow > 0.05 {
            let m = CGFloat(meow)
            head.fill(oval(100, 104 + 2 * m, 6 + 3 * m, 3 + 7 * m), hex(0x8C2A34))
            head.fill(oval(100, 108 + 3 * m, 4 + 2 * m, 1 + 3 * m), pink)
        } else {
            var mouth = Path()
            mouth.move(to: pt(100, 95))
            mouth.addQuadCurve(to: pt(90, 102), control: pt(97, 103))
            mouth.move(to: pt(100, 95))
            mouth.addQuadCurve(to: pt(110, 102), control: pt(103, 103))
            head.stroke(mouth, ink, 2.6)
        }
        var whiskers = Path()
        for (dy, ey) in [(CGFloat(-4), CGFloat(-10)), (2, 2), (8, 14)] {
            whiskers.move(to: pt(72, 96 + dy)); whiskers.addLine(to: pt(40, 96 + ey))
            whiskers.move(to: pt(128, 96 + dy)); whiskers.addLine(to: pt(160, 96 + ey))
        }
        head.stroke(whiskers, ink.opacity(0.5), 1.8)
        b.soundArcs(150, 58, angle: -40, amount: meow, gap: 8)
        b.soundArcs(50, 58, angle: 220, amount: meow, gap: 8)
    }

    // MARK: fr.perruche — perruche verte à tête jaune, sur son perchoir ; action : cui-cui.

    static func perruche(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let chirp = max(bump(seg(t, 0.05, 0.4)), bump(seg(t, 0.5, 0.85)))
        let bob = 8 * wobble(t, 2)
        let green = hex(0x6CC24A), greenLight = hex(0xA6E07A), greenDark = hex(0x4E9E36), yellow = hex(0xFFE14D)
        let bar = hex(0x2B2F3A), blue = hex(0x5B7BE0), beak = hex(0xF4C98A), tail = hex(0x2F7A99), wood = hex(0xA8733F)

        b.fillRounded(poly([pt(110, 132), pt(126, 128), pt(148, 178), pt(140, 181)]), tail, 3)
        b.fill(capsule(pt(22, 150), pt(178, 150), 12), wood)
        b.stroke(curve([pt(28, 154), pt(172, 154)]), hex(0x8A5A2E), 3)
        var leaf = Path()
        leaf.move(to: pt(160, 148))
        leaf.addQuadCurve(to: pt(182, 128), control: pt(162, 128))
        leaf.addQuadCurve(to: pt(160, 148), control: pt(180, 146))
        b.fill(leaf, hex(0x5DBB4F))
        b.rotated(22, 104, 112).fill(oval(104, 112, 30, 40), green)
        b.rotated(22, 97, 120).fill(oval(97, 121, 19, 27), greenLight)
        let wing = blob([pt(106, 88), pt(130, 96), pt(140, 126), pt(126, 142), pt(110, 118)])
        b.fill(wing, greenDark)
        let feathers = b.clipped(wing)
        for y in [CGFloat(98), 110, 122, 134] {
            feathers.stroke(curve([pt(104, y), pt(122, y + 6), pt(146, y + 2)]), bar, 3)
            feathers.stroke(curve([pt(104, y + 4), pt(122, y + 10), pt(146, y + 6)]), yellow.opacity(0.8), 2)
        }
        for x in [CGFloat(96), 112] {
            b.stroke(curve([pt(x, 138), pt(x - 3, 150), pt(x + 3, 152)]), hex(0xC9A1B4), 5)
        }

        let head = b.rotated(bob, 94, 92)
        head.fill(disk(84, 70, 26), yellow)
        let crown = head.clipped(disk(84, 70, 26))
        for (a, c) in [(pt(92, 46), pt(108, 56)), (pt(97, 57), pt(110, 66)), (pt(99, 68), pt(111, 76))] {
            crown.stroke(curve([a, pt((a.x + c.x) / 2, a.y + 6), c]), bar, 3)
        }
        for x in [CGFloat(74), 82, 90] { head.fill(disk(x, 93, 2.6), bar) }
        head.fill(oval(70, 85, 5, 4), blue)
        head.fill(oval(66, 63, 5, 3.5), blue)
        head.rotated(24 * chirp, 67, 76).fillRounded(poly([pt(60, 76), pt(67, 84), pt(70, 76)]), hex(0xE3B06E), 1.5)
        var upper = Path()
        upper.move(to: pt(62, 66))
        upper.addQuadCurve(to: pt(59, 81), control: pt(54, 70))
        upper.addQuadCurve(to: pt(70, 74), control: pt(64, 74))
        upper.closeSubpath()
        head.fillRounded(upper, beak, 1.5)
        head.eye(78, 63, 6, blink: p.blink)
        b.soundArcs(46, 56, angle: 210, amount: chirp, gap: 7)
    }

    // MARK: fr.caniche — caniche abricot à pompons (tête, oreilles, chevilles, queue) ; action : il jappe et remue la queue.

    static func caniche(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let wag = 26 * shake(t, 4)
        let yap = CGFloat(max(bump(seg(t, 0.08, 0.36)), bump(seg(t, 0.46, 0.74))))
        let nod = 5 * wobble(t, 2)
        let fluff = hex(0xFAD3B4), fluffShade = hex(0xEFB48E), skin = hex(0xFFE7D6), skinShade = hex(0xF2CDB2)
        let bow = hex(0xF26B9C)

        b.groundShadow(108, 177, 56, 6)
        let tail = b.rotated(wag, 148, 102)
        tail.fill(capsule(pt(148, 102), pt(160, 72), 7), skin)
        tail.fill(puff(162, 66, 9, bumps: 7, bumpRadius: 5.5), fluff)
        for (x0, x1) in [(CGFloat(84), CGFloat(86)), (142, 146)] {
            b.fill(capsule(pt(x0, 120), pt(x1, 166), 7), skinShade)
            b.fill(puff(x1, 162, 7, bumps: 6, bumpRadius: 4), fluffShade)
        }
        let coat = puff(84, 102, 22, bumps: 9, bumpRadius: 8)
        b.fill(puff(116, 108, 22, bumps: 9, bumpRadius: 8), fluff)
        b.fill(puff(140, 106, 16, bumps: 8, bumpRadius: 6), fluff)
        b.fill(coat, fluff)
        b.clipped(Path(CGRect(x: 60, y: 118, width: 110, height: 20))).fill(puff(116, 108, 22, bumps: 9, bumpRadius: 8), fluffShade.opacity(0.6))
        for (x0, x1) in [(CGFloat(94), CGFloat(92)), (132, 130)] {
            b.fill(capsule(pt(x0, 122), pt(x1, 168), 8), skin)
            b.fill(puff(x1, 163, 8, bumps: 7, bumpRadius: 4.5), fluff)
            b.fill(oval(x1 - 3, 172, 8, 4), skin)
        }

        let h = b.rotated(nod, 82, 98)
        h.fill(oval(60, 73, 17, 14), skin)
        h.rotated(10, 42, 80).fill(oval(42, 80, 16, 8), skin)
        h.fill(disk(27, 78, 5), hex(0x3A2E2E))
        if yap > 0.05 {
            h.rotated(14 * yap, 48, 85).fill(oval(38, 87, 9, 3 + 3 * yap), hex(0x8C2F45))
        } else {
            h.stroke(curve([pt(34, 86), pt(40, 88), pt(47, 87)]), hex(0xB27A62), 2.2)
        }
        h.fill(puff(62, 50, 15, bumps: 8, bumpRadius: 7), fluff)
        h.fill(puff(72, 80, 9, bumps: 6, bumpRadius: 5), fluffShade)
        h.fill(puff(74, 94, 9, bumps: 6, bumpRadius: 5), fluffShade)
        h.fill(puff(75, 106, 8, bumps: 6, bumpRadius: 4.5), fluffShade)
        h.eye(56, 70, 5.5, blink: p.blink)
        h.cheek(62, 81, 4.5)
        h.fillRounded(poly([pt(70, 36), pt(58, 28), pt(58, 42)]), bow, 2.5)
        h.fillRounded(poly([pt(70, 36), pt(82, 28), pt(82, 42)]), bow, 2.5)
        h.fill(disk(70, 36, 4.5), hex(0xD9487D))
        b.soundArcs(30, 104, angle: 150, amount: Double(yap), gap: 7)
    }

    // MARK: fr.limace — limace jaune-orangé SANS coquille, yeux au bout des cornes ; action : elle s'étire et glisse.

    static func limace(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let stretch = CGFloat(0.06 * pulse(seg(t, 0, 0.55)) + 0.03 * pulse(seg(t, 0.5, 0.95)))
        let sway = 10 * wobble(t, 2.5)
        let body = hex(0xF5A340), bodyLight = hex(0xFFD49A), mantle = hex(0xE08A2C), spot = hex(0xC9721E)
        let trail = hex(0xBFD9F2)

        b.stroke(curve([pt(126, 168), pt(154, 169), pt(181, 167)]), trail.opacity(0.8), 7)
        let glint = bump(seg(t, 0.3, 1))
        b.sparkle(152, 167, 7, hex(0x7FB6EC), amount: 0.5 + 0.5 * glint)
        b.sparkle(174, 165, 5, hex(0x7FB6EC), amount: glint)

        // Un corps mou d'épaisseur presque égale, couché sur le sol, la tête relevée à gauche
        // (en « J »), le manteau sur le dos, la queue qui s'effile à droite.
        let s = b.scaled(0.94 * (1 + stretch), 0.94 * (1 - stretch * 0.4), 184, 168)
        let spine = [pt(184, 163), pt(170, 161), pt(148, 158), pt(120, 154), pt(92, 151), pt(66, 146),
                     pt(48, 134), pt(40, 116), pt(39, 102), pt(38, 94)]
        let shape = tube(spine, [1, 6, 11, 15, 17, 18, 18, 17, 13, 6])
        s.fill(shape, body)
        let skin = s.clipped(shape)
        skin.fill(box(16, 160, 180, 20), bodyLight)
        skin.fill(oval(90, 138, 30, 11), mantle)
        for (x, y, r) in [(CGFloat(58), CGFloat(128), CGFloat(2.6)), (78, 132, 2.2), (100, 134, 2.6), (122, 140, 2.8),
                          (144, 146, 2.4), (160, 152, 2)] {
            skin.fill(disk(x, y, r), spot)
        }
        for x in [CGFloat(116), 134, 152] {
            skin.stroke(curve([pt(x - 3, 146 + (x - 116) * 0.1), pt(x + 3, 156)]), spot.opacity(0.55), 2.2)
        }
        for (base, tip, a) in [(pt(34, 100), pt(22, 64), sway), (pt(46, 98), pt(52, 62), -sway)] {
            let st = s.rotated(a, base.x, base.y)
            st.fill(capsule(base, tip, 7.5), body)
            st.fill(disk(tip.x, tip.y, 9.5), .white)
            st.eye(tip.x - 1, tip.y + 1, 6, blink: p.blink)
        }
        s.stroke(curve([pt(25, 118), pt(31, 123), pt(38, 121)]), hex(0x9A5A1A), 2.6)
        s.cheek(44, 124, 4.5)
    }

    // MARK: fr.autruche — autruche : corps noir, plumes blanches, long cou et longues pattes roses ; action : elle marche.

    static func autruche(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let env = bump(t).squareRoot()
        let step = sin(2 * .pi * 2 * t) * env
        let bob = CGFloat(-4 * abs(step))
        let black = hex(0x30303A), blackLight = hex(0x4A4B5E), white = Color.white, whiteShade = hex(0xDFE4EE)
        let skin = hex(0xF0B6A0), skinDark = hex(0xD9977F), beak = hex(0xF4C08E)

        b.groundShadow(116, 178, 44, 6)
        func leg(_ hip: CGPoint, _ angle: Double, _ color: Color) {
            let l = b.moved(0, bob).rotated(angle, hip.x, hip.y)
            l.fill(oval(hip.x, hip.y + 8, 9, 15), color)
            l.fill(capsule(pt(hip.x + 1, hip.y + 18), pt(hip.x - 2, 170), 7), color)
            l.fill(capsule(pt(hip.x - 2, 172), pt(hip.x - 15, 174), 7), color)
        }
        leg(pt(128, 116), -18 * step, skinDark)
        let d = b.moved(0, bob)
        d.fill(puff(160, 88, 12, bumps: 7, bumpRadius: 6), whiteShade)
        d.fill(puff(166, 104, 9, bumps: 6, bumpRadius: 5), white)
        let body = oval(124, 98, 40, 27)
        d.fill(body, black)
        let feathers = d.clipped(body)
        for (x, y) in [(CGFloat(104), CGFloat(106)), (124, 110), (144, 104), (114, 90), (136, 88)] {
            feathers.stroke(curve([pt(x - 10, y), pt(x, y + 6), pt(x + 10, y)]), blackLight, 3)
        }
        d.fill(puff(146, 116, 8, bumps: 6, bumpRadius: 4.5), white)
        d.fill(puff(158, 110, 7, bumps: 6, bumpRadius: 4), white)
        leg(pt(110, 116), 18 * step, skin)

        let n = d.rotated(6 * step, 96, 92)
        n.stroke(curve([pt(98, 92), pt(84, 80), pt(72, 58), pt(62, 40)]), skin, 12)
        n.fill(puff(94, 90, 8, bumps: 6, bumpRadius: 4.5), white)
        n.fill(oval(58, 34, 14, 12), skin)
        for x in [CGFloat(52), 57, 62] {
            n.stroke(curve([pt(x, 24), pt(x - 2, 17)]), blackLight, 2.2)
        }
        n.fill(oval(40, 40, 12, 5.5), beak)
        n.stroke(curve([pt(30, 41), pt(44, 41)]), hex(0xC98E5A), 1.6)
        n.eye(58, 31, 6.5, blink: p.blink)
        if !p.blink {
            n.stroke(curve([pt(54, 25), pt(51, 21)]), ink, 1.8)
            n.stroke(curve([pt(58, 24), pt(58, 19)]), ink, 1.8)
        }
    }

    // MARK: en.fish — poisson orange à bandes blanches ; action : il frétille et fait « blub ».

    static func fish(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let swish = 22 * wobble(t, 3) + 6 * p.sway(1.6)
        let blub = CGFloat(bump(seg(t, 0.12, 0.5)))
        let float = CGFloat(2.5 * p.sway(2.2))
        let orange = hex(0xFF8A2B), orangeLight = hex(0xFFB765), orangeDark = hex(0xEE6A1C), edge = hex(0x3A2A2A)

        for (i, x0) in [CGFloat(40), 54, 32].enumerated() {
            let c = p.cycle(3.0, offset: Double(i) / 3, rest: [0.3, 0.55, 0.8][i])
            b.bubble(x0 + CGFloat(sin(c * 6)) * 3, 78 - CGFloat(c) * 56, 4 + CGFloat(c) * 4, amount: bump(c))
        }
        for k in 0..<2 {
            let u = seg(t, 0.3 + Double(k) * 0.15, 0.9 + Double(k) * 0.08)
            if u > 0 { b.bubble(40 - CGFloat(u) * 8, 100 - CGFloat(u) * 64, 5 + CGFloat(u) * 3, amount: bump(u)) }
        }
        let f = b.moved(0, float).rotated(-4 * wobble(t, 3), 100, 102)
        f.rotated(swish, 150, 102).fillRounded(poly([pt(146, 102), pt(180, 70), pt(172, 102), pt(180, 134)]), orangeDark, 5)
        f.fillRounded(poly([pt(80, 72), pt(106, 54), pt(128, 60), pt(134, 76)]), orangeDark, 5)
        f.fillRounded(poly([pt(96, 136), pt(108, 150), pt(122, 138)]), orangeDark, 4)
        let body = oval(100, 102, 56, 40)
        f.fill(body, orange)
        let skin = f.clipped(body)
        skin.fill(oval(96, 126, 48, 18), orangeLight)
        for (x, w) in [(CGFloat(82), CGFloat(8)), (124, 7)] {
            skin.fill(oval(x, 102, w + 3, 46), edge)
            skin.fill(oval(x, 102, w, 46), .white)
        }
        f.rotated(-20 + 8 * p.sway(1.2) + 25 * wobble(t, 3), 104, 110)
            .fillRounded(poly([pt(102, 108), pt(118, 100), pt(122, 118)]), orangeDark, 4)
        f.fill(disk(62, 94, 12), .white)
        f.eye(59, 95, 8, blink: p.blink)
        if blub > 0.05 {
            f.fill(oval(46, 110, 3 + 3 * blub, 3 + 5 * blub), hex(0x8C2F2F))
        } else {
            f.stroke(curve([pt(45, 108), pt(49, 112), pt(55, 110)]), hex(0x8C2F2F), 2.6)
        }
        f.cheek(64, 114, 5)
    }

    // MARK: en.goose — oie blanche au bec orange ; action : « honk », elle tend le cou et ouvre le bec.

    static func goose(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let honk = max(bump(seg(t, 0.08, 0.42)), bump(seg(t, 0.52, 0.86)))
        let s = CGFloat(hold(t, rise: 0.12, fall: 0.8))
        let flap = -14 * bump(seg(t, 0.05, 0.9))
        let white = hex(0xFBFCFE), shade = hex(0xDCE3ED), orange = hex(0xFF9A2E), orangeDark = hex(0xE6781A)

        b.groundShadow(118, 177, 50, 6)
        for x in [CGFloat(106), 128] {
            b.fill(capsule(pt(x, 146), pt(x - 2, 170), 6), orange)
            b.fillRounded(poly([pt(x - 2, 168), pt(x - 20, 176), pt(x + 4, 176)]), orange, 2)
        }
        // Blanc sur carte blanche : un liseré gris-bleu tout autour (tracé d'abord, puis recouvert
        // par les aplats : il ne reste qu'à l'extérieur de la silhouette).
        let outline = hex(0xB9C6D8)
        let body = blob([pt(66, 120), pt(92, 98), pt(140, 94), pt(176, 80), pt(172, 108), pt(152, 144), pt(104, 154), pt(74, 142)])
        var neck = Path()
        neck.move(to: pt(84, 120))
        neck.addCurve(to: pt(60 - 5 * s, 48 - 10 * s), control1: pt(62, 102 - 4 * s), control2: pt(60 - 3 * s, 70 - 8 * s))
        let head = b.moved(-5 * s, -10 * s).rotated(-10 * Double(s), 58, 44)
        b.stroke(body, outline, 5)
        b.stroke(neck, outline, 25)
        head.stroke(oval(58, 44, 16, 14), outline, 5)
        b.fill(body, white)
        b.clipped(body).fill(oval(114, 158, 58, 20), shade)
        let wing = b.rotated(flap, 100, 108)
        wing.fill(blob([pt(92, 110), pt(126, 98), pt(162, 100), pt(152, 124), pt(118, 132)]), shade)
        wing.stroke(curve([pt(116, 110), pt(140, 110), pt(154, 106)]), white, 3)
        wing.stroke(curve([pt(112, 120), pt(136, 120)]), white, 3)
        b.stroke(neck, white, 20)
        b.stroke(curve([pt(92, 118), pt(76, 98), pt(70 - 2 * s, 74 - 6 * s)]), shade.opacity(0.7), 5)
        head.fill(oval(58, 44, 16, 14), white)
        head.rotated(24 * honk, 45, 51).fillRounded(poly([pt(46, 49), pt(25, 54), pt(46, 56)]), orangeDark, 2)
        head.fillRounded(poly([pt(46, 38), pt(22, 49), pt(46, 52)]), orange, 3)
        head.eye(59, 40, 5.5, blink: p.blink)
        b.soundArcs(30, 32, angle: -125, amount: honk, gap: 6)
    }

    // MARK: en.moose — élan (orignal) de face, grands bois en palette ; action : il brame, tête levée.

    static func moose(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let call = hold(t, rise: 0.15, fall: 0.75)
        let lift = CGFloat(-7 * call)
        let quiver = 3 * shake(t, 6)
        let fur = hex(0x8B5B3E), furDark = hex(0x6B4430), furLight = hex(0xA87556), muzzle = hex(0xB58766)
        let antler = hex(0xEBD5A8), antlerShade = hex(0xD3B581)

        b.fill(blob([pt(36, 184), pt(50, 160), pt(100, 150), pt(150, 160), pt(164, 184)]), furDark)
        b.fill(box(74, 116, 52, 56, 20), fur)
        let h = b.moved(0, lift)
        h.fill(blob([pt(92, 150), pt(108, 150), pt(110, 170), pt(100, 178), pt(90, 170)]), furDark)
        let left: [CGPoint] = [pt(66, 64), pt(42, 66), pt(24, 60), pt(15, 48), pt(24, 46), pt(17, 32), pt(29, 38),
                               pt(27, 21), pt(39, 33), pt(43, 17), pt(51, 33), pt(59, 23), pt(62, 42), pt(68, 52)]
        for side in [CGFloat(1), -1] {
            let pts = left.map { side > 0 ? $0 : pt(200 - $0.x, $0.y) }
            let a = h.rotated(Double(side) * -quiver, side > 0 ? 80 : 120, 62)
            a.fill(capsule(pt(side > 0 ? 82 : 118, 66), pt(side > 0 ? 60 : 140, 58), 11), antlerShade)
            a.fillRounded(poly(pts), antler, 3)
            a.stroke(curve(side > 0 ? [pt(62, 58), pt(40, 58), pt(26, 52)] : [pt(138, 58), pt(160, 58), pt(174, 52)]),
                     antlerShade, 3)
        }
        for side in [CGFloat(1), -1] {
            let ear = h.rotated(Double(side) * -24, 100 - side * 34, 84)
            ear.fill(oval(100 - side * 46, 84, 16, 8), fur)
            ear.fill(oval(100 - side * 46, 84, 10, 4.5), furLight)
        }
        h.fill(blob([pt(72, 66), pt(100, 58), pt(128, 66), pt(134, 96), pt(122, 124), pt(78, 124), pt(66, 96)]), fur)
        h.fill(oval(100, 72, 20, 9), furDark.opacity(0.5))
        h.fill(oval(100, 132, 31, 25), muzzle)
        h.fill(oval(90, 131, 5, 7.5), hex(0x4A2E22))
        h.fill(oval(110, 131, 5, 7.5), hex(0x4A2E22))
        if call > 0.05 {
            h.fill(oval(100, 150, 8 + 4 * call, 2 + 8 * call), hex(0x5A2230))
        } else {
            h.stroke(curve([pt(91, 148), pt(100, 152), pt(109, 148)]), hex(0x6B4430), 3)
        }
        h.eye(83, 92, 7, blink: p.blink)
        h.eye(117, 92, 7, blink: p.blink)
        h.cheek(76, 110, 5)
        h.cheek(124, 110, 5)
        b.soundArcs(144, 146, angle: 25, amount: call, gap: 8)
        b.soundArcs(56, 146, angle: 155, amount: call, gap: 8)
    }

    // MARK: en.mouse — petite souris grise, grandes oreilles rondes ; action : « couic », elle sautille.

    static func mouse(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let jump = CGFloat(-9 * hop(seg(t, 0, 0.45)))
        let squeak = bump(seg(t, 0.05, 0.55))
        let perk = 1 + 0.12 * CGFloat(squeak)
        let grey = hex(0xA8ADBF), light = hex(0xDADDE7), pink = hex(0xF7A5B4), pinkDark = hex(0xE98597)

        b.groundShadow(110, 178, 44 + jump, 6)
        let m = b.moved(0, jump)
        m.rotated(10 * wobble(t, 2), 138, 164)
            .stroke(curve([pt(134, 166), pt(166, 168), pt(182, 150), pt(174, 128), pt(160, 124)]), pink, 5)
        let body = blob([pt(84, 172), pt(80, 140), pt(96, 116), pt(124, 116), pt(142, 144), pt(138, 172)])
        m.fill(body, grey)
        m.clipped(body).fill(oval(104, 150, 20, 26), light)
        m.fill(oval(94, 173, 11, 5), pink)
        m.fill(oval(126, 173, 11, 5), pink)
        m.fill(oval(92, 138, 6, 5), pink)
        m.fill(oval(106, 141, 6, 5), pink)
        let ears = m.scaled(perk, perk, 84, 80)
        ears.fill(disk(98, 58, 19), grey)
        ears.fill(disk(98, 59, 12), pink)
        m.fill(oval(80, 96, 30, 26), grey)
        m.rotated(12, 54, 106).fill(oval(54, 106, 24, 13), grey)
        ears.fill(disk(70, 64, 21), grey)
        ears.fill(disk(70, 65, 13.5), pink)
        m.fill(disk(33, 110, 5.5), pinkDark)
        m.eye(66, 93, 7, blink: p.blink)
        m.cheek(80, 110, 6)
        let w = CGFloat(3 * shake(t, 5))
        var whiskers = Path()
        for (dy, ey) in [(CGFloat(-4), CGFloat(-10)), (0, 0), (4, 10)] {
            whiskers.move(to: pt(44, 108 + dy))
            whiskers.addLine(to: pt(18, 106 + ey + w))
        }
        m.stroke(whiskers, ink.opacity(0.5), 1.8)
        if squeak > 0.05 {
            m.fill(oval(45, 118, 3 + 2 * squeak, 4 * squeak), hex(0x8C2F45))
        }
        b.soundArcs(44, 70, angle: -150, amount: squeak, gap: 6)
    }
}
#endif
