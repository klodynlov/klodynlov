// LivingDrawing.swift — « Le dessin prend vie » : les parties bougent avec les couleurs de l'enfant.
//
// Choix de l'utilisateur (28/09/2026) pour la suite de l'atelier. Quand l'enfant touche « J'ai
// fini ! » (mode interactif), les parties du dessin bougent quelques secondes avec SES couleurs :
// les roues tournent, le soleil bat, la queue remue, les ailes battent, le feuillage se balance,
// les nuages glissent (docs/EVEIL.md § 6.4 : les couleurs de l'enfant habillent un pantin préparé
// d'avance ; ni IA, ni tirage au hasard). Le mouvement de chaque partie est une donnée de la page
// (`ColoringPart.motion`). L'algorithme est celui de eveil/outils/coloriages/vivant.py, sa
// référence, relue sur planches (et les attaches de quelques pages servent de vecteurs de parité) :
//
// 1. Les pièces : les zones d'une partie qui se touchent (de part et d'autre d'un trait) forment
//    une pièce ; s'y ajoutent les zones sans nom qui ne tiennent qu'à elle (le bout de la queue)
//    et tout ce qu'elle enferme (taches, yeux, encre) : sa silhouette.
// 2. L'attache d'une pièce qui se balance : le milieu de son contact avec le reste du dessin (ni le
//    fond, ni une autre pièce qui bouge), ou avec la partie qui la porte (le tronc ; sans contact,
//    son bas), ou son haut (la serviette à son crochet). Une roue tourne autour du centre de son
//    plus grand disque intérieur ; le reste, autour du centre de la silhouette.
// 3. Le rendu : chaque pièce est découpée dans le coloriage (ses couleurs et les traits qui la
//    bordent) ; dessous, son emplacement est rebouché avec les couleurs voisines, sans traits, et
//    la pièce bouge par-dessus. D'une roue, seul le disque intérieur tourne (rayons, moyeu, coups
//    de pinceau) : un bord uni ne montrerait rien, et rien ne se découvre. Battre ne fait que
//    grandir : rien ne se découvre non plus.
//
// Tout se calcule une fois, hors du fil principal, au moment de « J'ai fini ! » ; le mouvement est
// ensuite piloté par l'horloge (`LivingMotion`, fonctions pures).

#if canImport(CoreGraphics)
import CoreGraphics
import Foundation

// MARK: - Le temps

/// Le mouvement des pièces dans le temps : une fête de 6 s, qui monte en 0,4 s et redescend sur
/// les 0,8 dernières ; au repos avant et après. Mêmes formules que vivant.py (`transformation`).
enum LivingMotion {
    static let duration = 6.0
    static let rampIn = 0.4
    static let rampOut = 0.8

    /// Période (secondes) : assez lent pour qu'un petit suive des yeux. Une roue fait 3 tours
    /// pendant la fête, le tee-shirt 2 : un nombre entier, pour se reposer là où elle était.
    static func period(_ motion: PartMotion) -> Double {
        switch motion {
        case .roll: return 1.8
        case .spin: return 2.7
        case .pulse: return 0.7
        case .sway: return 0.8
        case .drift: return 3.0
        case .float: return 1.4
        }
    }

    /// 0 → 1 en montant, 1, puis 1 → 0 en descendant ; 0 hors de la fête.
    static func envelope(_ t: Double) -> Double {
        guard t > 0, t < duration else { return 0 }
        return min(1, t / rampIn, (duration - t) / rampOut)
    }

    /// Chemin parcouru par une roue (l'intégrale de l'enveloppe) : elle démarre et s'arrête en douceur.
    static func travel(_ time: Double) -> Double {
        let t = min(max(time, 0), duration)
        let b = duration - rampOut
        if t <= rampIn { return t * t / (2 * rampIn) }
        var s = rampIn / 2 + (min(t, b) - rampIn)
        if t > b {
            let u = t - b
            s += u - u * u / (2 * rampOut)
        }
        return s
    }

    /// La pièce à l'instant t : rotation (radians), échelle, déplacement (unité de page).
    /// Au repos : (0, 1, 0, 0). `sign` : deux ailes battent en miroir.
    static func transform(_ motion: PartMotion, at t: Double, phase: Double = 0, sign: Double = 1)
        -> (angle: Double, scale: Double, dx: Double, dy: Double) {
        let e = envelope(t)
        guard e > 0 else { return (0, 1, 0, 0) }
        let p = period(motion)
        let wave = sin(2 * .pi * t / p + phase)
        switch motion {
        case .roll, .spin:
            return (2 * .pi * travel(t) / p, 1, 0, 0)
        case let .pulse(amplitude):
            return (0, 1 + Double(amplitude) * e * (0.5 - 0.5 * cos(2 * .pi * t / p + phase)), 0, 0)
        case let .sway(degrees, _):
            return (Double(degrees) * .pi / 180 * e * wave * sign, 1, 0, 0)
        case let .drift(distance):
            return (0, 1, Double(distance) * e * wave, 0)
        case let .float(distance):
            return (0, 1, 0, -Double(distance) * e * abs(wave))
        }
    }
}

// MARK: - Le dessin vivant

/// Une pièce découpée, et comment elle bouge.
struct LivingPiece: @unchecked Sendable {
    let part: String
    let motion: PartMotion
    /// L'image de la pièce (transparente autour) et sa place, en unité de page.
    let image: CGImage
    let frame: CGRect
    /// Le point fixe (unité de page) : l'attache, le centre du disque d'une roue, ou le centre.
    let pivot: CGPoint
    let sign: Double
    let phase: Double
}

/// Le coloriage prêt à s'animer : ce qui reste immobile, et les pièces qui bougent.
/// Images immuables : d'où le `@unchecked Sendable`.
struct LivingDrawing: @unchecked Sendable {
    let base: CGImage
    let pieces: [LivingPiece]

    /// La forme d'une pièce, avant le rendu (pixels de la carte des zones).
    struct Shape {
        let part: String
        let motion: PartMotion
        let zones: Set<Int>
        /// Boîte de la silhouette (x1, y1 exclus) et silhouette sur la boîte (1 = dedans).
        let box: (x0: Int, y0: Int, x1: Int, y1: Int)
        let silhouette: [UInt8]
        let center: CGPoint
        var pivot: CGPoint
        /// Une roue : rayon de son disque intérieur (centre = `pivot`).
        var radius: CGFloat = 0
        var sign: Double = 1
        var phase: Double = 0
    }

    /// Le fond : jamais une attache, jamais une pièce.
    static let ground: Set<String> = ["le ciel", "l'herbe", "la mer", "l'eau", "le sable"]
    /// Couleur des traits (EveilPalette.ink).
    static var ink: CGColor { CGColor(srgbRed: 0.18, green: 0.20, blue: 0.29, alpha: 1) }

    /// Le dessin vivant d'une page coloriée ; `paint` : les pixels du calque de peinture (RGBA
    /// prémultiplié, à la taille de la carte). `nil` si rien ne bouge seul sur la page.
    init?(page: ColoringPage, map: ZoneMap, paint: [UInt32]) {
        let W = map.width, H = map.height
        guard paint.count == W * H else { return nil }
        let shapes = Self.shapes(for: page.parts, map: map)
        guard !shapes.isEmpty else { return nil }
        let art = page.lineArt
        let picture = Self.composite(art: art, paint: paint, width: W, height: H)
        let lines = Self.lineMask(art: art, width: W, height: H)
        let margin = Int((map.rasterLineWidth / 0.8).rounded(.up)) + 2
        var holes = [UInt8](repeating: 0, count: W * H)
        var cut: [(box: (x0: Int, y0: Int, x1: Int, y1: Int), mask: [UInt8])] = []
        for s in shapes {
            let c = Self.cutout(s, lines: lines, width: W, height: H, margin: margin)
            cut.append(c)
            if case .roll = s.motion { continue }          // le disque tourne sur lui-même
            let w = c.box.x1 - c.box.x0
            for (k, v) in c.mask.enumerated() where v != 0 {
                holes[(c.box.y0 + k / w) * W + c.box.x0 + k % w] = 1
            }
        }
        var base = picture
        Self.fill(&base, holes: holes, lines: lines, width: W, height: H)
        guard let baseImage = Self.image(base, width: W, height: H) else { return nil }
        var pieces: [LivingPiece] = []
        for (s, c) in zip(shapes, cut) {
            let w = c.box.x1 - c.box.x0, h = c.box.y1 - c.box.y0
            var pixels = [UInt32](repeating: 0, count: w * h)
            for k in 0..<(w * h) where c.mask[k] != 0 {
                pixels[k] = picture[(c.box.y0 + k / w) * W + c.box.x0 + k % w]
            }
            guard let image = Self.image(pixels, width: w, height: h) else { continue }
            let fw = CGFloat(W), fh = CGFloat(H)
            pieces.append(LivingPiece(
                part: s.part, motion: s.motion, image: image,
                frame: CGRect(x: CGFloat(c.box.x0) / fw, y: CGFloat(c.box.y0) / fh,
                              width: CGFloat(w) / fw, height: CGFloat(h) / fh),
                pivot: CGPoint(x: s.pivot.x / fw, y: s.pivot.y / fh), sign: s.sign, phase: s.phase))
        }
        guard !pieces.isEmpty else { return nil }
        self.base = baseImage
        self.pieces = pieces
    }

    // MARK: Les pièces (géométrie seule : testée sur toutes les pages)

    /// Les pièces qui bougent, dans l'ordre des parties ; attaches et rayons en pixels de la carte.
    static func shapes(for parts: [ColoringPart], map: ZoneMap) -> [Shape] {
        let zoneCount = map.zoneCount
        guard zoneCount > 0, parts.contains(where: { $0.motion != nil && !ground.contains($0.fr) }) else { return [] }
        let corner = map.zone(at: CGPoint(x: 0.004, y: 0.004))
        let reach = Int(map.rasterLineWidth * 2) + 3
        let near = neighborhood(map, reach: reach)
        var zonesOf: [String: Set<Int>] = [:]
        for part in parts {
            zonesOf[part.fr, default: []].formUnion(part.points.map { map.zone(at: $0) }.filter { $0 != 0 })
        }
        let named = zonesOf.values.reduce(into: Set<Int>()) { $0.formUnion($1) }
        var soil: Set<Int> = corner != 0 ? [corner] : []
        for name in ground { soil.formUnion(zonesOf[name] ?? []) }
        // Une très grande zone sans nom est un fond (un mur, une table) ; une grande partie nommée
        // (le feuillage du pommier) reste une pièce.
        let subject = zonesOf.filter { !ground.contains($0.key) }.values.reduce(into: Set<Int>()) { $0.formUnion($1) }
        for z in 1...zoneCount where map.fraction(of: z) > 0.2 && !subject.contains(z) { soil.insert(z) }
        let boxes = zoneBoxes(map)

        var out: [Shape] = []
        var moving = Set<Int>()
        for part in parts {
            guard let motion = part.motion, !ground.contains(part.fr) else { continue }
            var rest = (zonesOf[part.fr] ?? []).subtracting(soil)
            while let first = rest.min() {
                // Les zones de la partie qui se touchent forment une pièce.
                rest.remove(first)
                var group: Set<Int> = [first]
                var stack = [first]
                while let z = stack.popLast() {
                    for z2 in near.neighbors[z] ?? [] where rest.contains(z2) {
                        rest.remove(z2)
                        group.insert(z2)
                        stack.append(z2)
                    }
                }
                // Les zones sans nom qui ne tiennent qu'à elle (le bout de la queue).
                let area = group.reduce(0) { $0 + map.areas[$1] }
                let around = group.reduce(into: Set<Int>()) { $0.formUnion(near.neighbors[$1] ?? []) }
                for z2 in around.sorted() where !group.contains(z2) && !named.contains(z2) && !soil.contains(z2) {
                    if (near.neighbors[z2] ?? []).isSubset(of: group.union(soil)) && map.areas[z2] <= area {
                        group.insert(z2)
                    }
                }
                let box = (x0: group.map { boxes.x0[$0] }.min() ?? 0, y0: group.map { boxes.y0[$0] }.min() ?? 0,
                           x1: group.map { boxes.x1[$0] }.max() ?? 0, y1: group.map { boxes.y1[$0] }.max() ?? 0)
                guard box.x1 > box.x0, box.y1 > box.y0 else { continue }
                let sil = silhouette(map, zones: group, box: box)
                let w = box.x1 - box.x0
                var sx = 0, sy = 0, n = 0
                for (k, v) in sil.enumerated() where v != 0 {
                    sx += k % w
                    sy += k / w
                    n += 1
                }
                guard n > 0 else { continue }
                let center = CGPoint(x: CGFloat(box.x0) + CGFloat(sx) / CGFloat(n) + 0.5,
                                     y: CGFloat(box.y0) + CGFloat(sy) / CGFloat(n) + 0.5)
                var shape = Shape(part: part.fr, motion: motion, zones: group, box: box, silhouette: sil,
                                  center: center, pivot: center)
                if case .roll = motion {
                    let disk = innerDisk(sil, width: w, height: box.y1 - box.y0)
                    shape.pivot = CGPoint(x: CGFloat(box.x0) + disk.x, y: CGFloat(box.y0) + disk.y)
                    shape.radius = disk.radius
                }
                out.append(shape)
                moving.formUnion(group)
            }
        }
        // Les attaches, une fois toutes les pièces connues (une pièce ne s'attache pas à une autre
        // qui bouge, sauf s'il n'y a rien d'autre).
        let all = Set(1...zoneCount)
        for k in out.indices {
            out[k].phase = 0.9 * Double(k)
            guard case let .sway(_, pivot) = out[k].motion else { continue }
            let s = out[k]
            let bottom = CGPoint(x: CGFloat(s.box.x0 + s.box.x1) / 2, y: CGFloat(s.box.y1))
            let trials: [Set<Int>]
            switch pivot {
            case .top:
                out[k].pivot = CGPoint(x: CGFloat(s.box.x0 + s.box.x1) / 2, y: CGFloat(s.box.y0))
                out[k].sign = 1
                continue
            case let .part(name):
                // La partie qui la porte ; sans contact, elle est posée dessus : depuis son bas.
                trials = [all.subtracting(zonesOf[name] ?? [])]
            case .contact:
                trials = [soil.union(moving), soil]
            }
            out[k].pivot = bottom
            for forbidden in trials {
                var sx = 0, sy = 0, n = 0
                for z in s.zones {
                    for z2 in near.neighbors[z] ?? [] where !s.zones.contains(z2) && !forbidden.contains(z2) {
                        if let c = near.contacts[ZonePair(a: z, b: z2)] {
                            sx += c.x
                            sy += c.y
                            n += c.n
                        }
                    }
                }
                if n > 0 {
                    out[k].pivot = CGPoint(x: CGFloat(sx) / CGFloat(n) + 0.5, y: CGFloat(sy) / CGFloat(n) + 0.5)
                    break
                }
            }
            out[k].sign = s.center.x >= out[k].pivot.x ? 1 : -1
        }
        return out
    }

    struct ZonePair: Hashable {
        let a: Int
        let b: Int
    }

    /// Qui touche qui de part et d'autre d'un trait, et où : pour chaque pixel de bord d'une zone,
    /// on traverse le trait tout droit (au plus `reach` pixels).
    static func neighborhood(_ map: ZoneMap, reach: Int)
        -> (neighbors: [Int: Set<Int>], contacts: [ZonePair: (x: Int, y: Int, n: Int)]) {
        let W = map.width, H = map.height
        var neighbors: [Int: Set<Int>] = [:]
        var contacts: [ZonePair: (x: Int, y: Int, n: Int)] = [:]
        map.labels.withUnsafeBufferPointer { lab in
            func walk(_ x: Int, _ y: Int, _ z: Int, _ dx: Int, _ dy: Int) {
                var nx = x + dx, ny = y + dy
                guard nx >= 0, ny >= 0, nx < W, ny < H, lab[ny * W + nx] == 0 else { return }
                for _ in 0..<reach {
                    nx += dx
                    ny += dy
                    guard nx >= 0, ny >= 0, nx < W, ny < H else { return }
                    let z2 = Int(lab[ny * W + nx])
                    guard z2 != 0 else { continue }
                    if z2 != z {
                        neighbors[z, default: []].insert(z2)
                        let key = ZonePair(a: z, b: z2)
                        let c = contacts[key] ?? (0, 0, 0)
                        contacts[key] = (c.x + x, c.y + y, c.n + 1)
                    }
                    return
                }
            }
            for y in 0..<H {
                for x in 0..<W {
                    let z = Int(lab[y * W + x])
                    guard z != 0 else { continue }
                    walk(x, y, z, 1, 0)
                    walk(x, y, z, -1, 0)
                    walk(x, y, z, 0, 1)
                    walk(x, y, z, 0, -1)
                }
            }
        }
        return (neighbors, contacts)
    }

    /// La boîte de chaque zone (x1, y1 exclus), indexée par zone.
    static func zoneBoxes(_ map: ZoneMap) -> (x0: [Int], y0: [Int], x1: [Int], y1: [Int]) {
        let n = map.zoneCount + 1, W = map.width, H = map.height
        var x0 = [Int](repeating: Int.max, count: n), y0 = [Int](repeating: Int.max, count: n)
        var x1 = [Int](repeating: 0, count: n), y1 = [Int](repeating: 0, count: n)
        map.labels.withUnsafeBufferPointer { lab in
            for y in 0..<H {
                for x in 0..<W {
                    let z = Int(lab[y * W + x])
                    guard z != 0 else { continue }
                    if x < x0[z] { x0[z] = x }
                    if y < y0[z] { y0[z] = y }
                    if x + 1 > x1[z] { x1[z] = x + 1 }
                    if y + 1 > y1[z] { y1[z] = y + 1 }
                }
            }
        }
        return (x0, y0, x1, y1)
    }

    /// Les zones et tout ce qu'elles enferment (trous bouchés), sur la boîte : 1 = dedans.
    static func silhouette(_ map: ZoneMap, zones: Set<Int>, box: (x0: Int, y0: Int, x1: Int, y1: Int)) -> [UInt8] {
        let W = map.width
        let w = box.x1 - box.x0, h = box.y1 - box.y0
        var member = [Bool](repeating: false, count: map.zoneCount + 1)
        for z in zones where z < member.count { member[z] = true }
        var inside = [UInt8](repeating: 0, count: w * h)
        map.labels.withUnsafeBufferPointer { lab in
            for y in 0..<h {
                let row = (box.y0 + y) * W + box.x0
                for x in 0..<w where member[Int(lab[row + x])] {
                    inside[y * w + x] = 1
                }
            }
        }
        // Dehors : ce qu'on atteint depuis le bord de la boîte sans traverser les zones.
        var outside = [UInt8](repeating: 0, count: w * h)
        var queue: [Int] = []
        queue.reserveCapacity(w * h)
        func seed(_ k: Int) {
            if inside[k] == 0 && outside[k] == 0 {
                outside[k] = 1
                queue.append(k)
            }
        }
        for x in 0..<w {
            seed(x)
            seed((h - 1) * w + x)
        }
        for y in 0..<h {
            seed(y * w)
            seed(y * w + w - 1)
        }
        var head = 0
        while head < queue.count {
            let k = queue[head]
            head += 1
            let x = k % w, y = k / w
            if x + 1 < w { seed(k + 1) }
            if x > 0 { seed(k - 1) }
            if y + 1 < h { seed(k + w) }
            if y > 0 { seed(k - w) }
        }
        return outside.map { $0 == 0 ? 1 : 0 }
    }

    /// Le plus grand disque dans la silhouette : centre (dans la boîte, pixels) et rayon. Distance
    /// « chanfrein » 3-4 (deux passes), divisée par 3 : proche de l'euclidienne.
    static func innerDisk(_ sil: [UInt8], width w: Int, height h: Int) -> (x: CGFloat, y: CGFloat, radius: CGFloat) {
        let far = 1 << 30
        var d = sil.map { $0 == 0 ? 0 : far }
        for y in 0..<h {
            for x in 0..<w {
                let k = y * w + x
                guard d[k] != 0 else { continue }
                let a = x > 0 ? d[k - 1] + 3 : 3
                let b = y > 0 ? d[k - w] + 3 : 3
                let c = x > 0 && y > 0 ? d[k - w - 1] + 4 : 4
                let e = y > 0 && x < w - 1 ? d[k - w + 1] + 4 : 4
                d[k] = min(d[k], a, b, c, e)
            }
        }
        for y in stride(from: h - 1, through: 0, by: -1) {
            for x in stride(from: w - 1, through: 0, by: -1) {
                let k = y * w + x
                guard d[k] != 0 else { continue }
                let a = x < w - 1 ? d[k + 1] + 3 : 3
                let b = y < h - 1 ? d[k + w] + 3 : 3
                let c = x < w - 1 && y < h - 1 ? d[k + w + 1] + 4 : 4
                let e = y < h - 1 && x > 0 ? d[k + w - 1] + 4 : 4
                d[k] = min(d[k], a, b, c, e)
            }
        }
        var best = 0
        for k in d.indices where d[k] > d[best] { best = k }
        return (CGFloat(best % w) + 0.5, CGFloat(best / w) + 0.5, CGFloat(d[best]) / 3)
    }

    // MARK: Le rendu

    /// Le coloriage tel qu'on le voit : papier blanc, couleurs, puis traits et encre (RGBA prémultiplié).
    static func composite(art: LineArt, paint: [UInt32], width W: Int, height H: Int) -> [UInt32] {
        var out = [UInt32](repeating: 0xFFFF_FFFF, count: W * H)
        out.withUnsafeMutableBufferPointer { o in
            paint.withUnsafeBufferPointer { p in
                for i in 0..<(W * H) {
                    let v = p[i]
                    let a = v >> 24
                    if a == 0 { continue }
                    if a == 255 {
                        o[i] = v
                        continue
                    }
                    let k = 255 - a              // prémultiplié, sur du blanc : c + (255 − a)
                    o[i] = ((v & 0xFF) + k) | (((v >> 8) & 0xFF) + k) << 8 | (((v >> 16) & 0xFF) + k) << 16 | 0xFF00_0000
                }
            }
        }
        out.withUnsafeMutableBytes { raw in
            guard let space = CGColorSpace(name: CGColorSpace.sRGB),
                  let ctx = CGContext(data: raw.baseAddress, width: W, height: H, bitsPerComponent: 8,
                                      bytesPerRow: W * 4, space: space,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return }
            draw(art, in: ctx, width: W, height: H)
        }
        return out
    }

    /// Les pixels des traits tels qu'affichés (épaisseur de la page) : 1 = trait.
    static func lineMask(art: LineArt, width W: Int, height H: Int) -> [UInt8] {
        var mask = [UInt8](repeating: 0, count: W * H)
        mask.withUnsafeMutableBytes { raw in
            guard let ctx = CGContext(data: raw.baseAddress, width: W, height: H, bitsPerComponent: 8,
                                      bytesPerRow: W, space: CGColorSpaceCreateDeviceGray(),
                                      bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return }
            ctx.setShouldAntialias(false)
            draw(art, in: ctx, width: W, height: H, color: CGColor(gray: 1, alpha: 1))
        }
        return mask.map { $0 == 0 ? 0 : 1 }
    }

    /// Les traits et l'encre d'une page, repère unité, y vers le bas (la ligne 0 est le haut).
    private static func draw(_ art: LineArt, in ctx: CGContext, width W: Int, height H: Int,
                             color: CGColor = LivingDrawing.ink) {
        ctx.translateBy(x: 0, y: CGFloat(H))
        ctx.scaleBy(x: CGFloat(W), y: -CGFloat(H))
        ctx.setFillColor(color)
        ctx.setStrokeColor(color)
        ctx.setLineWidth(art.lineWidth)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.addPath(art.strokes)
        ctx.strokePath()
        ctx.addPath(art.ink)
        ctx.fillPath()
    }

    /// Le masque d'une pièce, sur une boîte agrandie : une roue, son disque intérieur ; sinon sa
    /// silhouette, les traits qui la bordent (au plus `margin` pixels), et un pixel de plus.
    static func cutout(_ s: Shape, lines: [UInt8], width W: Int, height H: Int, margin: Int)
        -> (box: (x0: Int, y0: Int, x1: Int, y1: Int), mask: [UInt8]) {
        if case .roll = s.motion {
            let r = max(0, s.radius - 0.5)
            let x0 = max(0, Int(s.pivot.x - r) - 1), y0 = max(0, Int(s.pivot.y - r) - 1)
            let x1 = min(W, Int(s.pivot.x + r) + 2), y1 = min(H, Int(s.pivot.y + r) + 2)
            let w = x1 - x0
            var mask = [UInt8](repeating: 0, count: max(0, w * (y1 - y0)))
            for k in mask.indices {
                let dx = CGFloat(x0 + k % w) + 0.5 - s.pivot.x, dy = CGFloat(y0 + k / w) + 0.5 - s.pivot.y
                if dx * dx + dy * dy <= r * r { mask[k] = 1 }
            }
            return ((x0, y0, x1, y1), mask)
        }
        let X0 = max(0, s.box.x0 - margin), Y0 = max(0, s.box.y0 - margin)
        let X1 = min(W, s.box.x1 + margin), Y1 = min(H, s.box.y1 + margin)
        let w = X1 - X0, h = Y1 - Y0
        var mask = [UInt8](repeating: 0, count: w * h)
        var depth = [Int](repeating: 0, count: w * h)
        var queue: [Int] = []
        let sw = s.box.x1 - s.box.x0
        for (k, v) in s.silhouette.enumerated() where v != 0 {
            let j = (s.box.y0 + k / sw - Y0) * w + (s.box.x0 + k % sw - X0)
            mask[j] = 1
            queue.append(j)
        }
        var head = 0
        while head < queue.count {
            let j = queue[head]
            head += 1
            guard depth[j] < margin else { continue }
            let x = j % w, y = j / w
            for (nx, ny) in [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)] where nx >= 0 && ny >= 0 && nx < w && ny < h {
                let k = ny * w + nx
                if mask[k] == 0 && lines[(Y0 + ny) * W + X0 + nx] != 0 {
                    mask[k] = 1
                    depth[k] = depth[j] + 1
                    queue.append(k)
                }
            }
        }
        var grown = mask
        for j in mask.indices where mask[j] == 0 {
            let x = j % w, y = j / w
            if (x + 1 < w && mask[j + 1] != 0) || (x > 0 && mask[j - 1] != 0)
                || (y + 1 < h && mask[j + w] != 0) || (y > 0 && mask[j - w] != 0) {
                grown[j] = 1
            }
        }
        return ((X0, Y0, X1, Y1), grown)
    }

    /// Rebouche les trous avec les couleurs voisines (hors traits), de proche en proche.
    static func fill(_ image: inout [UInt32], holes: [UInt8], lines: [UInt8], width W: Int, height H: Int) {
        let n = W * H
        var done = [UInt8](repeating: 0, count: n)
        var queue: [Int32] = []
        holes.withUnsafeBufferPointer { hole in
            lines.withUnsafeBufferPointer { line in
                for i in 0..<n where hole[i] == 0 && line[i] == 0 {
                    let x = i % W, y = i / W
                    if (x + 1 < W && hole[i + 1] != 0) || (x > 0 && hole[i - 1] != 0)
                        || (y + 1 < H && hole[i + W] != 0) || (y > 0 && hole[i - W] != 0) {
                        done[i] = 1
                        queue.append(Int32(i))
                    }
                }
            }
        }
        image.withUnsafeMutableBufferPointer { img in
            var head = 0
            while head < queue.count {
                let i = Int(queue[head])
                head += 1
                let x = i % W, y = i / W
                func spread(_ j: Int) {
                    if holes[j] != 0 && done[j] == 0 {
                        done[j] = 1
                        img[j] = img[i]
                        queue.append(Int32(j))
                    }
                }
                if x + 1 < W { spread(i + 1) }
                if x > 0 { spread(i - 1) }
                if y + 1 < H { spread(i + W) }
                if y > 0 { spread(i - W) }
            }
        }
    }

    static func image(_ pixels: [UInt32], width: Int, height: Int) -> CGImage? {
        guard width > 0, height > 0 else { return nil }
        return pixels.withUnsafeBytes { raw in
            raw.baseAddress.flatMap { PaintLayer.image(from: Data(bytes: $0, count: raw.count), width: width, height: height) }
        }
    }

    // MARK: Une image de la fête (planches, vignettes)

    /// Le dessin à l'instant t (secondes depuis le début de la fête), en `size` pixels.
    func frame(at t: Double, size: Int) -> CGImage? {
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        let k = CGFloat(size)
        ctx.interpolationQuality = .medium
        ctx.draw(base, in: CGRect(x: 0, y: 0, width: k, height: k))
        // Repère unité × taille, y vers le bas ; une image se dessine à l'endroit en retournant son cadre.
        ctx.translateBy(x: 0, y: k)
        ctx.scaleBy(x: 1, y: -1)
        for piece in pieces {
            let m = LivingMotion.transform(piece.motion, at: t, phase: piece.phase, sign: piece.sign)
            ctx.saveGState()
            ctx.translateBy(x: (piece.pivot.x + CGFloat(m.dx)) * k, y: (piece.pivot.y + CGFloat(m.dy)) * k)
            ctx.rotate(by: CGFloat(m.angle))
            ctx.scaleBy(x: CGFloat(m.scale), y: CGFloat(m.scale))
            ctx.translateBy(x: -piece.pivot.x * k, y: -piece.pivot.y * k)
            let r = CGRect(x: piece.frame.minX * k, y: piece.frame.minY * k,
                           width: piece.frame.width * k, height: piece.frame.height * k)
            ctx.translateBy(x: 0, y: r.minY + r.maxY)
            ctx.scaleBy(x: 1, y: -1)
            ctx.draw(piece.image, in: r)
            ctx.restoreGState()
        }
        return ctx.makeImage()
    }
}
#endif
