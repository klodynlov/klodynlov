// ZoneMap.swift — la carte des zones d'une page : chaque aire fermée par les traits.
//
// Comme le pot de peinture sur un coloriage papier : on rastérise les traits dans
// un masque 8 bits (1024 × 1024), puis chaque composante connexe de pixels HORS
// trait (4-connexité : deux pixels ne communiquent que par un côté, jamais par un
// coin — un trait en diagonale reste une vraie barrière) devient une zone. Le
// fond autour du dessin est une zone comme les autres.
//
// Choix :
// - trait rastérisé ≈ 0,8 × le trait affiché (et au moins 1,5 px plus fin de
//   chaque côté) : la couleur d'une zone glisse SOUS le trait visible, sans
//   liseré blanc, et le trait vectoriel reste net par-dessus ;
// - étiquetage par segments horizontaux (« runs ») et union-find : le travail par
//   pixel se réduit à lire le masque puis écrire l'étiquette ; boucles sur
//   pointeurs bruts, rapides même en Debug (objectif < 100 ms sur iPad M1) ;
// - les miettes de rastérisation (< 0,02 % de la page, aux jonctions aiguës) sont
//   rattachées à la zone voisine majoritaire, de l'autre côté du trait ;
// - chaque zone garde la liste de ses segments : remplir coûte O(taille de la zone).
//
// Pure logique (CoreGraphics seulement) : testée sur Mac (`swift test`).

#if canImport(CoreGraphics)
import CoreGraphics
import Foundation

public struct ZoneMap: Sendable {
    /// Côté de la carte, en pixels.
    public static let defaultSize = 1024
    /// En dessous de cette part de la page, une zone est une miette (fusionnée à une voisine).
    public static let crumbFraction = 0.0002

    public let width: Int
    public let height: Int
    /// Zone de chaque pixel, ligne après ligne : 0 = trait, 1…`zoneCount` = zones.
    public let labels: [UInt16]
    public let zoneCount: Int
    /// Aire (en pixels) de chaque zone ; `areas[0]` = pixels de trait.
    public let areas: [Int]
    /// Épaisseur du trait rastérisé, en pixels.
    public let rasterLineWidth: CGFloat
    /// Segments de chaque zone : zone z → indices `runOffsets[z] ..< runOffsets[z + 1]`.
    let runStarts: [Int32]
    let runLengths: [Int32]
    let runOffsets: [Int32]

    /// Carte des zones d'un dessin au trait.
    public init(lineArt: LineArt, size: Int = ZoneMap.defaultSize) {
        let raster = Self.rasterize(lineArt, size: size)
        self.init(mask: raster.mask, width: size, height: size, rasterLineWidth: raster.lineWidth)
    }

    /// Carte des zones d'un masque (≠ 0 = trait), ligne après ligne.
    public init(mask: [UInt8], width: Int, height: Int, crumbFraction: Double = ZoneMap.crumbFraction,
                rasterLineWidth: CGFloat = 3) {
        precondition(width > 0 && height > 0 && mask.count == width * height, "masque de taille incohérente")
        self.width = width
        self.height = height
        self.rasterLineWidth = rasterLineWidth
        let n = width * height

        // 1. Les segments hors trait, ligne par ligne (triés par x dans chaque ligne).
        var rowFirst = [Int32](repeating: 0, count: height + 1)
        var x0s: [Int32] = []
        var x1s: [Int32] = []
        x0s.reserveCapacity(height * 24)
        x1s.reserveCapacity(height * 24)
        mask.withUnsafeBufferPointer { m in
            guard let base = m.baseAddress else { return }
            var y = 0
            while y < height {
                rowFirst[y] = Int32(x0s.count)
                let row = base + y * width
                var x = 0
                while x < width {
                    while x < width && row[x] != 0 { x &+= 1 }
                    if x == width { break }
                    let start = x
                    while x < width && row[x] == 0 { x &+= 1 }
                    x0s.append(Int32(start))
                    x1s.append(Int32(x))
                }
                y &+= 1
            }
        }
        rowFirst[height] = Int32(x0s.count)
        let runCount = x0s.count

        // 2. Union-find : deux segments de lignes voisines qui se chevauchent en x se
        //    touchent par un côté. La racine d'un ensemble est son premier segment.
        var parent = [Int32](repeating: 0, count: max(runCount, 1))
        var runId = [Int32](repeating: 0, count: max(runCount, 1))
        var provisionalArea: [Int] = [0]
        parent.withUnsafeMutableBufferPointer { par in
            runId.withUnsafeMutableBufferPointer { ids in
                x0s.withUnsafeBufferPointer { a0 in
                    x1s.withUnsafeBufferPointer { a1 in
                        guard runCount > 0, let P = par.baseAddress, let I = ids.baseAddress,
                              let X0 = a0.baseAddress, let X1 = a1.baseAddress else { return }
                        var i = 0
                        while i < runCount { P[i] = Int32(i); i &+= 1 }
                        func find(_ start: Int) -> Int {
                            var i = start
                            while Int(P[i]) != i {
                                let grand = P[Int(P[i])]
                                P[i] = grand
                                i = Int(grand)
                            }
                            return i
                        }
                        var y = 1
                        while y < height {
                            var a = Int(rowFirst[y - 1])
                            let aEnd = Int(rowFirst[y])
                            var b = aEnd
                            let bEnd = Int(rowFirst[y + 1])
                            while a < aEnd && b < bEnd {
                                if X1[a] <= X0[b] { a &+= 1; continue }
                                if X1[b] <= X0[a] { b &+= 1; continue }
                                let ra = find(a), rb = find(b)
                                if ra < rb { P[rb] = Int32(ra) } else if rb < ra { P[ra] = Int32(rb) }
                                if X1[a] < X1[b] { a &+= 1 } else { b &+= 1 }
                            }
                            y &+= 1
                        }
                        // 3. Identifiants provisoires, dans l'ordre de lecture.
                        var r = 0
                        while r < runCount {
                            let root = find(r)
                            if root == r {
                                provisionalArea.append(0)
                                I[r] = Int32(provisionalArea.count - 1)
                            } else {
                                I[r] = I[root]
                            }
                            provisionalArea[Int(I[r])] += Int(X1[r] - X0[r])
                            r &+= 1
                        }
                    }
                }
            }
        }
        let provisionalCount = provisionalArea.count - 1

        // 4. Les miettes rejoignent la zone voisine majoritaire, de l'autre côté du trait.
        var target = [Int32](0...Int32(provisionalCount))
        let crumbLimit = Int(crumbFraction * Double(n))
        var isCrumb = [Bool](repeating: false, count: provisionalCount + 1)
        var anyCrumb = false
        if provisionalCount > 1 {
            for id in 1...provisionalCount where provisionalArea[id] < crumbLimit {
                isCrumb[id] = true
                anyCrumb = true
            }
        }
        if anyCrumb {
            let maxStep = max(8, Int(rasterLineWidth * 4))
            // Zone provisoire du pixel libre (x, y), par recherche dichotomique dans sa ligne.
            func idAt(_ x: Int, _ y: Int) -> Int32 {
                var lo = Int(rowFirst[y]), hi = Int(rowFirst[y + 1]) - 1
                while lo <= hi {
                    let mid = (lo + hi) / 2
                    if Int(x1s[mid]) <= x { lo = mid + 1 } else if Int(x0s[mid]) > x { hi = mid - 1 } else { return runId[mid] }
                }
                return 0
            }
            // Traverse le trait depuis (x, y) dans la direction (dx, dy).
            func across(_ x: Int, _ y: Int, _ dx: Int, _ dy: Int) -> Int32 {
                var x = x + dx, y = y + dy, steps = 0
                while x >= 0 && x < width && y >= 0 && y < height && steps < maxStep {
                    if mask[y * width + x] == 0 { return idAt(x, y) }
                    x += dx
                    y += dy
                    steps += 1
                }
                return 0
            }
            var votes: [Int32: [Int32: Int]] = [:]
            for y in 0..<height {
                for r in Int(rowFirst[y])..<Int(rowFirst[y + 1]) {
                    let id = runId[r]
                    guard isCrumb[Int(id)] else { continue }
                    let x0 = Int(x0s[r]), x1 = Int(x1s[r]) - 1, xm = (x0 + x1) / 2
                    for found in [across(x0, y, -1, 0), across(x1, y, 1, 0), across(xm, y, 0, -1), across(xm, y, 0, 1),
                                  across(x0, y, -1, -1), across(x1, y, 1, 1), across(x0, y, -1, 1), across(x1, y, 1, -1)]
                    where found != 0 && found != id && !isCrumb[Int(found)] {
                        votes[id, default: [:]][found, default: 0] += 1
                    }
                }
            }
            for (crumb, tally) in votes {
                if let best = tally.max(by: { $0.value < $1.value || ($0.value == $1.value && $0.key > $1.key) }) {
                    target[Int(crumb)] = best.key
                }
            }
        }

        // 5. Numéros définitifs, compacts, dans l'ordre de lecture.
        var finalOf = [Int32](repeating: 0, count: provisionalCount + 1)
        var zones: Int32 = 0
        if provisionalCount > 0 {
            for id in 1...provisionalCount where target[id] == Int32(id) {
                zones += 1
                finalOf[id] = zones
            }
            for id in 1...provisionalCount where target[id] != Int32(id) {
                finalOf[id] = finalOf[Int(target[id])]
            }
        }
        let zoneCount = min(Int(zones), Int(UInt16.max))
        self.zoneCount = zoneCount

        // 6. Étiquettes par pixel, aires, et segments regroupés par zone.
        var labels = [UInt16](repeating: 0, count: n)
        var areas = [Int](repeating: 0, count: zoneCount + 1)
        var perZone = [Int32](repeating: 0, count: zoneCount + 2)
        var zoneOfRun = [UInt16](repeating: 0, count: max(runCount, 1))
        labels.withUnsafeMutableBufferPointer { lab in
            guard let L = lab.baseAddress else { return }
            for y in 0..<height {
                let rowBase = y * width
                for r in Int(rowFirst[y])..<Int(rowFirst[y + 1]) {
                    let z = UInt16(clamping: finalOf[Int(runId[r])])
                    zoneOfRun[r] = z
                    var i = rowBase + Int(x0s[r])
                    let end = rowBase + Int(x1s[r])
                    areas[Int(z)] += end - i
                    perZone[Int(z) + 1] += 1
                    while i < end { L[i] = z; i &+= 1 }
                }
            }
        }
        areas[0] = n - areas.dropFirst().reduce(0, +)
        for z in 1..<perZone.count { perZone[z] += perZone[z - 1] }
        var starts = [Int32](repeating: 0, count: runCount)
        var lengths = [Int32](repeating: 0, count: runCount)
        var cursor = perZone
        for y in 0..<height {
            for r in Int(rowFirst[y])..<Int(rowFirst[y + 1]) {
                let z = Int(zoneOfRun[r])
                let k = Int(cursor[z])
                starts[k] = Int32(y * width) + x0s[r]
                lengths[k] = x1s[r] - x0s[r]
                cursor[z] += 1
            }
        }
        self.labels = labels
        self.areas = areas
        self.runStarts = starts
        self.runLengths = lengths
        self.runOffsets = perZone
    }

    // MARK: Questions

    /// Zone du pixel (x, y), 0 sur un trait ou hors de la carte.
    public func zone(atPixel x: Int, _ y: Int) -> Int {
        guard x >= 0, y >= 0, x < width, y < height else { return 0 }
        return Int(labels[y * width + x])
    }

    /// Pixel d'un point en coordonnées unité.
    public func pixel(of unit: CGPoint) -> (x: Int, y: Int) {
        (min(max(Int(unit.x * CGFloat(width)), 0), width - 1), min(max(Int(unit.y * CGFloat(height)), 0), height - 1))
    }

    /// Zone sous un point (coordonnées unité), 0 sur un trait.
    public func zone(at unit: CGPoint) -> Int {
        let p = pixel(of: unit)
        return zone(atPixel: p.x, p.y)
    }

    /// Zone sous le doigt, ou la plus proche si le doigt est posé sur un trait.
    public func zone(near unit: CGPoint) -> Int {
        let p = pixel(of: unit)
        let here = zone(atPixel: p.x, p.y)
        if here != 0 { return here }
        let reach = Int(rasterLineWidth * 2.5) + 2
        for r in 1...reach {
            var best = 0
            var bestDistance = Int.max
            func consider(_ x: Int, _ y: Int) {
                let z = zone(atPixel: x, y)
                guard z != 0 else { return }
                let d = (x - p.x) * (x - p.x) + (y - p.y) * (y - p.y)
                if d < bestDistance { bestDistance = d; best = z }
            }
            for dx in -r...r {
                consider(p.x + dx, p.y - r)
                consider(p.x + dx, p.y + r)
            }
            for dy in (-r + 1)..<r {
                consider(p.x - r, p.y + dy)
                consider(p.x + r, p.y + dy)
            }
            if best != 0 { return best }
        }
        return 0
    }

    /// Part de la page couverte par une zone (0…1).
    public func fraction(of zone: Int) -> Double {
        guard zone >= 0, zone < areas.count else { return 0 }
        return Double(areas[zone]) / Double(width * height)
    }

    /// Indices des segments de la zone `z` dans `runStarts` / `runLengths`.
    func runRange(of z: Int) -> Range<Int> {
        guard z > 0, z <= zoneCount else { return 0..<0 }
        return Int(runOffsets[z])..<Int(runOffsets[z + 1])
    }

    // MARK: Rastérisation

    /// Masque des traits (255 = trait), sans anticrénelage : trait ≈ 0,8 × l'affiché.
    public static func rasterize(_ art: LineArt, size: Int) -> (mask: [UInt8], lineWidth: CGFloat) {
        let shown = art.lineWidth * CGFloat(size)
        let raster = max(3, min(shown * 0.8, shown - 3))
        var mask = [UInt8](repeating: 0, count: size * size)
        mask.withUnsafeMutableBytes { raw in
            guard let ctx = CGContext(data: raw.baseAddress, width: size, height: size, bitsPerComponent: 8,
                                      bytesPerRow: size, space: CGColorSpaceCreateDeviceGray(),
                                      bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return }
            ctx.setShouldAntialias(false)
            // Repère unité, y vers le bas : la ligne 0 du masque est le haut de la page.
            ctx.translateBy(x: 0, y: CGFloat(size))
            ctx.scaleBy(x: CGFloat(size), y: -CGFloat(size))
            ctx.setFillColor(gray: 1, alpha: 1)
            ctx.setStrokeColor(gray: 1, alpha: 1)
            ctx.setLineWidth(raster / CGFloat(size))
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)
            ctx.addPath(art.strokes)
            ctx.strokePath()
            ctx.addPath(art.ink)
            ctx.fillPath()
        }
        return (mask, raster)
    }
}
#endif
