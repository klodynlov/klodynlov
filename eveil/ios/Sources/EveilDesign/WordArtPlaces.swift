// WordArtPlaces.swift — véhicules et maisons : police, carrosse, bus, niche, ruche…
//
// Repère 200 × 200, sujet dans 16…184 (cf. WordArtKit.swift). Chaque fonction
// dessine le REPOS quand p.t = 0 et joue son action pour 0 < t < 1.

#if canImport(SwiftUI)
import SwiftUI

extension WordArtPaint {

    // MARK: fr.police — voiture de police française (blanche, bande bleue, gyrophare bleu) ; action : « pin-pon ».

    static func police(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let siren = hold(t, rise: 0.05, fall: 0.9)
        // Trois éclats en 1,2 s : moins de 3 par seconde (WCAG 2.3.1), et un petit gyrophare.
        let flash = t > 0 && sin(2 * .pi * 3 * t) > 0
        let bounce = CGFloat(-3 * abs(sin(2 * .pi * 2 * t)) * (1 - t))
        let white = hex(0xFBFCFE), shade = hex(0xDCE3EC), blue = hex(0x2458D3), red = hex(0xE8414B)
        let glass = hex(0x9ED3F5), tire = hex(0x2E3440), hub = hex(0xC9D0DA)

        b.groundShadow(100, 170, 82, 6)
        let car = b.moved(0, bounce)
        // Gyrophare : socle, dôme, rayons quand il s'allume.
        car.fill(box(86, 62, 28, 9, 3), hex(0x4B5563))
        car.clipped(box(80, 40, 40, 23)).fill(oval(100, 63, 12, 13), flash ? hex(0x7CC0FF) : hex(0x2F6BFF))
        car.fill(oval(96, 56, 3, 4), .white.opacity(flash ? 0.95 : 0.6))
        if flash {
            for a in [-160.0, -125.0, -90.0, -55.0, -20.0] {
                let r0: CGFloat = 18, r1: CGFloat = 30
                let ca = CGFloat(cos(a * .pi / 180)), sa = CGFloat(sin(a * .pi / 180))
                car.faded(siren).stroke(curve([pt(100 + ca * r0, 58 + sa * r0), pt(100 + ca * r1, 58 + sa * r1)]),
                                        hex(0x6FB2FF), 5)
            }
        }
        var cabin = Path()
        cabin.move(to: pt(50, 104))
        cabin.addLine(to: pt(68, 77))
        cabin.addQuadCurve(to: pt(81, 70), control: pt(72, 70))
        cabin.addLine(to: pt(131, 70))
        cabin.addQuadCurve(to: pt(144, 77), control: pt(140, 70))
        cabin.addLine(to: pt(166, 104))
        cabin.closeSubpath()
        car.fill(cabin, white)
        car.fill(poly([pt(64, 101), pt(79, 77), pt(104, 77), pt(104, 101)]), glass)
        car.fill(poly([pt(110, 77), pt(134, 77), pt(151, 101), pt(110, 101)]), glass)
        car.fill(poly([pt(84, 77), pt(92, 77), pt(80, 101), pt(72, 101)]), .white.opacity(0.45))
        car.fill(poly([pt(118, 77), pt(124, 77), pt(118, 101), pt(112, 101)]), .white.opacity(0.45))

        let body = box(16, 100, 168, 50, 18)
        car.fill(body, white)
        let paint = car.clipped(body)
        paint.fill(box(16, 139, 168, 12), shade)
        paint.fill(box(16, 118, 168, 12), blue)
        paint.fill(box(16, 130, 168, 3.5), red)
        paint.fill(disk(56, 150, 22), hex(0x3B4252))
        paint.fill(disk(146, 150, 22), hex(0x3B4252))
        car.stroke(curve([pt(106, 104), pt(106, 138)]), shade, 2)
        car.fill(capsule(pt(112, 110), pt(121, 110), 3.5), shade)
        car.fill(oval(19, 112, 4, 6), hex(0xFFD35A))
        car.fill(box(177, 106, 7, 10, 3), red)
        for x in [CGFloat(56), 146] {
            car.fill(disk(x, 150, 17), tire)
            car.fill(disk(x, 150, 8), hub)
            car.fill(disk(x, 150, 3), tire)
        }
    }

    // MARK: fr.niche — niche en bois au toit rouge, un chien passe la tête ; action : « ouaf ouaf ».

    static func niche(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let out = CGFloat(hold(t, rise: 0.15, fall: 0.8))
        let woof = CGFloat(max(pulse(seg(t, 0.12, 0.42)), pulse(seg(t, 0.5, 0.8))))
        let flap = 16 * shake(t, 4)
        let wood = hex(0xE9A45B), woodDark = hex(0xCF8840), roof = hex(0xE8414B), roofDark = hex(0xC22F3B)
        let hole = hex(0x5A3522), fur = hex(0xFFF1DE), ear = hex(0xB77B4F), muzzle = hex(0xFFE0BF)

        b.groundShadow(100, 179, 76, 7)
        let walls = poly([pt(38, 175), pt(38, 92), pt(100, 50), pt(162, 92), pt(162, 175)])
        b.fill(walls, wood)
        let planks = b.clipped(walls)
        for y in stride(from: CGFloat(106), through: 170, by: 16) {
            planks.stroke(curve([pt(38, y), pt(162, y)]), woodDark.opacity(0.6), 2.5)
        }
        // (addLines ouvre son propre sous-chemin : le point de départ fait partie de la liste.)
        var door = Path()
        door.addLines([pt(68, 175), pt(68, 120)] + arcPoints(100, 120, 32, from: 180, to: 360) + [pt(132, 175)])
        door.closeSubpath()
        b.fill(door, hole)
        b.fill(capsule(pt(100, 38), pt(24, 100), 18), roof)
        b.fill(capsule(pt(100, 38), pt(176, 100), 18), roof)
        b.fill(disk(100, 38, 10), roofDark)

        // Le chien : il sort la tête et aboie.
        let dog = b.moved(0, -8 * out).scaled(1 + 0.08 * out, 1 + 0.08 * out, 100, 172)
        dog.fill(oval(86, 171, 11, 7), fur)
        dog.fill(oval(114, 171, 11, 7), fur)
        dog.rotated(18 + flap, 80, 122).fill(oval(76, 138, 9, 18), ear)
        dog.rotated(-18 - flap, 120, 122).fill(oval(124, 138, 9, 18), ear)
        let face = oval(100, 138, 25, 23)
        dog.fill(face, fur)
        dog.clipped(face).fill(oval(112, 126, 11, 10), ear.opacity(0.45))
        dog.fill(oval(100, 149, 13, 9), muzzle)
        if woof > 0.05 {
            dog.fill(oval(100, 154, 5 + 3 * woof, 2 + 6 * woof), hex(0x8C2F45))
        } else {
            dog.stroke(curve([pt(93, 152), pt(100, 155), pt(107, 152)]), hex(0x8A5A3A), 2.2)
            dog.fill(oval(102, 158, 3.5, 4.5), hex(0xF58CA0))
        }
        dog.fill(oval(100, 144, 5.5, 4), ink)
        dog.eye(91, 132, 5.5, blink: p.blink)
        dog.eye(109, 132, 5.5, blink: p.blink)
        b.soundArcs(56, 126, angle: 200, amount: Double(woof), gap: 7)
        b.soundArcs(144, 126, angle: -20, amount: Double(woof), gap: 7)
    }

    // MARK: fr.ruche — ruche en paille et son abeille ; action : l'abeille fait le tour de la ruche, bzzz.

    static func ruche(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let straw = hex(0xF5B942), strawDark = hex(0xD9962A), strawLight = hex(0xFFD978), board = hex(0xA8733F)
        let honey = hex(0xFFB300)

        b.groundShadow(96, 181, 66, 6)
        b.fill(box(36, 166, 120, 11, 5), board)
        b.fill(disk(96, 62, 11), straw)
        b.fill(disk(96, 62, 11).offsetBy(dx: 0, dy: -2), strawLight.opacity(0.5))
        let bands: [(y: CGFloat, w: CGFloat)] = [(78, 60), (96, 84), (115, 102), (134, 114), (153, 120)]
        for band in bands {
            let shape = box(96 - band.w / 2, band.y - 12, band.w, 24, 12)
            b.fill(shape, straw)
            let fibre = b.clipped(shape)
            fibre.fill(box(0, band.y + 5, 200, 10), strawDark.opacity(0.55))
            fibre.stroke(curve([pt(96 - band.w / 2 + 10, band.y - 6), pt(96 + band.w / 2 - 12, band.y - 6)]), strawLight, 3)
        }
        b.clipped(box(80, 146, 32, 19)).fill(oval(96, 165, 13, 13), hex(0x5A3417))
        b.fill(capsule(pt(126, 125), pt(126, 136), 7), honey)
        b.fill(disk(126, 138, 5), honey)
        b.fill(disk(124.5, 126, 1.6), .white.opacity(0.7))

        // L'abeille : vol stationnaire au repos ; au toucher, un tour complet de la ruche,
        // en laissant derrière elle un petit pointillé de vol.
        func loop(_ u: Double) -> (point: CGPoint, phi: Double) {
            let phi = -0.5 - 2 * .pi * easeInOut(u)
            return (pt(98 + 60 * CGFloat(cos(phi)), 94 + 38 * CGFloat(sin(phi))), phi)
        }
        for k in 1...5 where t > 0 {
            let past = t - 0.035 * Double(k)
            guard past > 0 else { break }
            let dot = loop(past).point
            b.faded(bump(t) * (1 - Double(k) / 6)).fill(disk(dot.x, dot.y, 2.4), soundColor)
        }
        let (center, phi) = loop(t)
        var pos = center
        pos.x += CGFloat(5 * p.sway(2.2))
        pos.y += CGFloat(4 * p.sway(1.4))
        let facingRight = t > 0 && sin(phi) > 0
        let flap = 18 * p.sway(0.2) + 28 * sin(2 * .pi * 18 * t) * bump(t)
        let bee = b.scaled(facingRight ? -1 : 1, 1, pos.x, pos.y)
        let wing = hex(0xDFF1FF)
        bee.rotated(-20 + flap, pos.x + 2, pos.y - 8).fill(oval(pos.x + 2, pos.y - 19, 8, 12), wing.opacity(0.95))
        bee.rotated(22 - flap, pos.x + 8, pos.y - 8).fill(oval(pos.x + 11, pos.y - 17, 7, 10), wing.opacity(0.85))
        let body = oval(pos.x + 4, pos.y, 16, 12)
        bee.fill(body, hex(0xFFD23F))
        bee.clipped(body).fill(box(pos.x + 1, pos.y - 14, 5.5, 28), ink)
        bee.clipped(body).fill(box(pos.x + 11, pos.y - 14, 5.5, 28), ink)
        bee.fillRounded(poly([pt(pos.x + 19, pos.y - 3), pt(pos.x + 26, pos.y), pt(pos.x + 19, pos.y + 3)]), ink, 1)
        bee.stroke(curve([pt(pos.x - 14, pos.y - 8), pt(pos.x - 18, pos.y - 17)]), ink, 2)
        bee.stroke(curve([pt(pos.x - 9, pos.y - 9), pt(pos.x - 9, pos.y - 19)]), ink, 2)
        bee.fill(disk(pos.x - 12, pos.y, 9.5), hex(0xFFE27A))
        bee.eye(pos.x - 15, pos.y - 2, 3.6, blink: p.blink)
        bee.cheek(pos.x - 9, pos.y + 4, 2.6)
    }

    // MARK: fr.carrosse — carrosse de conte, doré, couronné ; action : les roues tournent, il cahote.

    static func carrosse(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let roll = 90 * t                     // 8 rayons : un quart de tour = deux rayons, pas de saut à la fin
        let bounce = CGFloat(-4 * abs(sin(2 * .pi * 2 * t)) * (1 - t))
        let rock = 2.5 * wobble(t, 2)
        let gold = hex(0xF9C74F), goldDark = hex(0xE0A12E), goldLight = hex(0xFFE39A), rib = hex(0xEFA23A)
        let glass = hex(0xCDEBFF), curtain = hex(0xF48FB8), wheelRim = hex(0x8E5BD9), gem = hex(0xF2557A)

        b.groundShadow(100, 180, 78, 6)
        let c = b.moved(0, bounce).rotated(rock, 100, 150)
        c.stroke(curve([pt(44, 146), pt(70, 155), pt(130, 155), pt(156, 146)]), goldDark, 7)
        c.stroke(curve([pt(46, 147), pt(34, 140), pt(36, 128), pt(47, 130)]), goldDark, 6)
        c.stroke(curve([pt(154, 147), pt(166, 140), pt(164, 128), pt(153, 130)]), goldDark, 6)
        let body = oval(100, 100, 62, 50)
        c.fill(body, gold)
        let shell = c.clipped(body)
        shell.fill(oval(130, 112, 44, 48), goldDark.opacity(0.3))
        for dx in [CGFloat(-44), -24, 24, 44] {
            shell.stroke(curve([pt(100 + dx * 0.5, 52), pt(100 + dx, 100), pt(100 + dx * 0.5, 148)]), rib.opacity(0.75), 3)
        }
        c.fill(box(72, 72, 56, 54, 22), goldDark)
        let window = box(77, 77, 46, 44, 18)
        c.fill(window, glass)
        let w = c.clipped(window)
        w.fill(blob([pt(76, 76), pt(95, 76), pt(86, 100), pt(80, 122), pt(74, 122)]), curtain)
        w.fill(blob([pt(124, 76), pt(105, 76), pt(114, 100), pt(120, 122), pt(126, 122)]), curtain)
        c.stroke(curve([pt(52, 88), pt(56, 72), pt(70, 60)]), goldLight, 6)
        c.fillRounded(poly([pt(82, 54), pt(84, 34), pt(92, 45), pt(100, 28), pt(108, 45), pt(116, 34), pt(118, 54)]), gold, 2.5)
        for (x, y) in [(CGFloat(84), CGFloat(33)), (100, 27), (116, 33)] { c.fill(disk(x, y, 3.8), goldLight) }
        c.fill(disk(100, 45, 4.5), gem)
        for (x, y, r) in [(CGFloat(56), CGFloat(154), CGFloat(22)), (146, 152, 25)] {
            c.stroke(disk(x, y, r - 3), wheelRim, 6)
            let spokes = c.rotated(roll, x, y)
            for k in 0..<4 {
                let a = Double(k) * .pi / 4
                let dx = CGFloat(cos(a)) * (r - 5), dy = CGFloat(sin(a)) * (r - 5)
                spokes.stroke(curve([pt(x - dx, y - dy), pt(x + dx, y + dy)]), goldDark, 3.2)
            }
            c.fill(disk(x, y, 6.5), gold)
            c.fill(disk(x, y, 2.5), goldDark)
        }
    }

    // MARK: en.bus — bus scolaire jaune ; action : « tut-tut », il cahote, phare allumé.

    static func bus(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let honk = max(pulse(seg(t, 0.05, 0.4)), pulse(seg(t, 0.45, 0.8)))
        let bounce = CGFloat(-3 * abs(sin(2 * .pi * 2 * t)) * (1 - t))
        let yellow = hex(0xFFC928), yellowDark = hex(0xE8A915), black = hex(0x2E3440)
        let glass = hex(0x9ED3F5), glassLight = hex(0xD4EEFD)

        b.groundShadow(102, 172, 82, 6)
        let v = b.moved(0, bounce)
        v.fill(box(20, 104, 40, 48, 12), yellow)
        v.fill(box(40, 58, 144, 94, 16), yellow)
        v.fill(box(40, 58, 144, 8, 4), yellowDark.opacity(0.6))
        for i in 0..<5 {
            let x = 64 + CGFloat(i) * 23.5
            v.fill(box(x, 72, 18, 28, 4), glass)
            v.fill(box(x + 2, 74, 5, 24, 2), glassLight.opacity(0.8))
        }
        v.fill(box(44, 70, 15, 72, 4), glass)
        v.stroke(curve([pt(51.5, 72), pt(51.5, 140)]), yellowDark, 2.5)
        v.fill(box(20, 112, 164, 5), black)
        v.fill(box(20, 124, 164, 4), black)
        v.fill(box(14, 146, 172, 9, 4), black)
        v.faded(honk).fill(disk(24, 120, 12), hex(0xFFE680).opacity(0.7))
        v.fill(disk(24, 120, 5.5), hex(0xFFF3B0))
        v.fill(disk(47, 64, 3.5), hex(0xE8414B))
        v.fill(disk(176, 64, 3.5), hex(0xE8414B))
        for x in [CGFloat(64), 152] {
            v.fill(disk(x, 150, 21), black.opacity(0.85))
            v.fill(disk(x, 152, 17), black)
            v.fill(disk(x, 152, 8), hex(0xC9D0DA))
            v.fill(disk(x, 152, 3), black)
        }
        b.soundArcs(26, 94, angle: -145, amount: honk, gap: 6)
    }

    // MARK: en.house — maison au toit rouge, cheminée qui fume ; action : « ding-dong », la porte s'ouvre, les fenêtres s'allument.

    static func house(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let open = CGFloat(hold(t, rise: 0.2, fall: 0.8))
        let lit = hold(t, rise: 0.1, fall: 0.85)
        let wall = hex(0xFFE3A3), wallDark = hex(0xF0C779), roof = hex(0xE8414B), roofDark = hex(0xC22F3B)
        let brick = hex(0xB85C4A), door = hex(0x3F7FD6), glass = hex(0x9ED3F5), warm = hex(0xFFE27A)

        b.groundShadow(100, 179, 74, 6)
        for k in 0..<3 {
            let loop = p.cycle(3.2, offset: Double(k) / 3, rest: [0.2, 0.5, 0.8][k]) + t
            let c = loop - loop.rounded(.down)
            let r = 5 + CGFloat(c) * 5
            b.fill(disk(137 + CGFloat(sin(c * 5)) * 4 + CGFloat(c) * 8, 42 - CGFloat(c) * 20, r),
                   hex(0xD5DDE8).opacity(bump(c)))
        }
        b.fill(box(128, 50, 18, 38, 2), brick)
        b.fill(box(125, 46, 24, 8, 3), roofDark)
        b.fill(box(40, 92, 120, 83, 4), wall)
        b.fill(box(40, 92, 120, 10), wallDark.opacity(0.7))
        b.fillRounded(poly([pt(30, 98), pt(100, 38), pt(170, 98)]), roof, 5)
        b.fill(capsule(pt(26, 102), pt(174, 102), 8), roofDark)
        b.fill(disk(100, 76, 10), glass)
        b.fill(disk(100, 76, 10), warm.opacity(lit))
        b.stroke(curve([pt(90, 76), pt(110, 76)]), .white, 2.5)
        b.stroke(curve([pt(100, 66), pt(100, 86)]), .white, 2.5)
        for x in [CGFloat(52), 118] {
            b.fill(box(x, 112, 30, 28, 4), glass)
            b.fill(box(x, 112, 30, 28, 4), warm.opacity(lit))
            b.stroke(curve([pt(x + 15, 112), pt(x + 15, 140)]), .white, 3)
            b.stroke(curve([pt(x, 126), pt(x + 30, 126)]), .white, 3)
            b.fill(box(x - 3, 140, 36, 5, 2), wallDark)
        }
        var doorShape = Path()
        doorShape.addLines([pt(87, 175), pt(87, 142)] + arcPoints(100, 142, 13, from: 180, to: 360) + [pt(113, 175)])
        doorShape.closeSubpath()
        b.fill(doorShape, hex(0x5A3522))
        b.fill(doorShape, warm.opacity(lit * 0.8))
        let leaf = b.scaled(1 - 0.6 * open, 1, 87, 160)
        leaf.fill(doorShape, door)
        leaf.fill(disk(108, 160, 2.8), sparkleGold)
        b.fill(box(80, 173, 40, 5, 2), hex(0xC9C2B5))
    }

    // MARK: en.circus — chapiteau rayé rouge et blanc, fanion ; action : fanfare, étoiles qui jaillissent.

    static func circus(_ b: WordArtBrush, _ p: WordArtPose) {
        let t = p.t
        let red = hex(0xE8414B), yellow = hex(0xFFC53D), blue = hex(0x3F7FD6), dark = hex(0x4A2560)
        let squash = CGFloat(0.05 * wobble(t, 2))
        let wave = p.sway(0.9) + 2.5 * shake(t, 4)

        b.groundShadow(100, 179, 76, 6)
        let tent = b.scaled(1 + squash, 1 - squash, 100, 176)
        tent.stroke(curve([pt(100, 40), pt(100, 16)]), hex(0x8A5A2E), 3.5)
        let f1 = CGFloat(3 * wave), f2 = CGFloat(-3 * wave)
        tent.fill(blob([pt(101, 16), pt(114, 17 + f1), pt(128, 21 + f2), pt(114, 25 + f1), pt(101, 29)]), blue)
        let apex = pt(100, 36)
        var roofPath = Path()
        roofPath.move(to: apex)
        roofPath.addQuadCurve(to: pt(24, 100), control: pt(74, 78))
        roofPath.addLine(to: pt(176, 100))
        roofPath.addQuadCurve(to: apex, control: pt(126, 78))
        roofPath.closeSubpath()
        tent.fill(roofPath, .white)
        let roofPaint = tent.clipped(roofPath)
        for i in stride(from: 0, to: 8, by: 2) {
            let x0 = 24 + CGFloat(i) * 19, x1 = x0 + 19
            roofPaint.fill(poly([apex, pt(x0, 104), pt(x1, 104)]), red)
        }
        let walls = box(34, 98, 132, 78, 3)
        tent.fill(walls, .white)
        let wallPaint = tent.clipped(walls)
        for x in stride(from: CGFloat(34), to: 166, by: 22) {
            wallPaint.fill(box(x, 98, 11, 78), red)
        }
        for i in 0..<9 {
            let x = 31 + CGFloat(i) * 17.25
            tent.clipped(box(18, 100, 164, 12)).fill(disk(x, 100, 9), i.isMultiple(of: 2) ? yellow : blue)
        }
        var door = Path()
        door.addLines([pt(82, 176), pt(82, 132)] + arcPoints(100, 132, 18, from: 180, to: 360) + [pt(118, 176)])
        door.closeSubpath()
        tent.fill(door, dark)
        tent.fillRounded(poly([pt(80, 116), pt(98, 116), pt(84, 146), pt(84, 176), pt(78, 176)]), yellow, 2)
        tent.fillRounded(poly([pt(120, 116), pt(102, 116), pt(116, 146), pt(116, 176), pt(122, 176)]), yellow, 2)
        tent.fillRounded(star5(58, 140, 8), yellow, 1)
        tent.fillRounded(star5(142, 140, 8), yellow, 1)
        // La fanfare : des étoiles jaillissent de part et d'autre.
        let colors = [yellow, blue, red, yellow, blue, red]
        for k in 0..<6 {
            let u = seg(t, 0.05 + 0.05 * Double(k), 0.7 + 0.04 * Double(k))
            guard u > 0 && u < 1 else { continue }
            let side: CGFloat = k.isMultiple(of: 2) ? -1 : 1
            let a = Double(k / 2) * 0.35 + 0.35
            let d = CGFloat(easeOut(u)) * 66
            let pos = pt(100 + side * CGFloat(cos(a)) * d, 64 - CGFloat(sin(a)) * d * 0.55)
            b.fillRounded(star5(pos.x, pos.y, 7), colors[k].opacity(bump(u)), 1)
        }
    }
}
#endif
