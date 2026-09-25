// PaintLayer.swift — la couche de couleurs, SOUS les traits : remplir, peindre, annuler.
//
// Une image RGBA (prémultipliée, octets R,G,B,A) de la taille de la carte des
// zones. Les traits vectoriels sont dessinés par-dessus à l'écran : aucune couleur
// ne les recouvre jamais, rien ne « fusionne ».
//
// - Remplir : toute la zone prend la couleur, en O(taille de la zone) grâce aux
//   segments de la carte ; l'annulation garde les anciennes valeurs compressées
//   (plages de valeurs identiques : une zone blanche = une seule plage).
// - Pinceau-pochoir (EVEIL.md § 6.3) : le trait ne peint QUE la zone où il a
//   commencé. Pinceau rond, bord anticrénelé ; entre deux points du doigt on suit
//   une courbe lissée (quadratiques par les milieux) : un geste rapide reste
//   continu. Chaque pixel garde sa valeur d'avant le trait : annuler retire le
//   trait entier.
// - Historique borné (nombre de pas et mémoire) : les plus anciens pas s'effacent.
// - Instantanés compressés : la page retrouve ses couleurs quand on y revient.
//
// Pure logique (CoreGraphics seulement) : testée sur Mac (`swift test`).

#if canImport(CoreGraphics)
import CoreGraphics
import Foundation

/// Une couleur de peinture (opaque) et son nom, pour la voix off d'accessibilité.
public struct PaintColor: Hashable, Sendable {
    public let red: UInt8
    public let green: UInt8
    public let blue: UInt8
    public let nameFR: String
    public let nameEN: String

    public init(_ red: UInt8, _ green: UInt8, _ blue: UInt8, fr: String, en: String) {
        self.red = red
        self.green = green
        self.blue = blue
        self.nameFR = fr
        self.nameEN = en
    }

    public func name(locale: String) -> String { locale.hasPrefix("fr") ? nameFR : nameEN }

    /// Valeur du pixel : octets R, G, B, A en mémoire (Apple = petit-boutiste).
    var packed: UInt32 { UInt32(red) | UInt32(green) << 8 | UInt32(blue) << 16 | 0xFF00_0000 }
}

/// Plages de valeurs identiques (compression des pixels d'avant un geste).
struct PixelRuns: Sendable {
    var counts: [Int32] = []
    var values: [UInt32] = []

    mutating func push(_ value: UInt32, _ count: Int32) {
        guard count > 0 else { return }
        counts.append(count)
        values.append(value)
    }

    var bytes: Int { counts.count * 8 }
    var isBlank: Bool { values.allSatisfy { $0 == 0 } }
}

/// Instantané compressé d'une page coloriée.
public struct PaintSnapshot: Sendable {
    let runs: PixelRuns
    public var isBlank: Bool { runs.isBlank }
}

final class PaintLayer {
    let width: Int
    let height: Int
    let maxHistoryBytes: Int
    let maxSteps: Int
    private let count: Int
    private let pixels: UnsafeMutablePointer<UInt32>
    /// Couverture du trait en cours (0 = pas encore touché par ce trait).
    private let coverage: UnsafeMutablePointer<UInt8>
    /// Valeur de chaque pixel avant le trait en cours.
    private let before: UnsafeMutablePointer<UInt32>
    private var touched: [Int32] = []
    private var stroke: Stroke?
    private var history: [Step] = []
    private(set) var historyBytes = 0

    private struct Stroke {
        let zone: UInt16
        let color: UInt32
        let radius: Double
        var points: [CGPoint]
    }

    private enum Step {
        case zone(Int, PixelRuns)            // remplissage : anciennes valeurs le long de la zone
        case pixels([Int32], [UInt32])       // trait de pinceau : pixels touchés et leurs valeurs
        case all(PixelRuns)                  // tout effacer : toute l'image d'avant

        var bytes: Int {
            switch self {
            case let .zone(_, runs), let .all(runs): return runs.bytes + 16
            case let .pixels(indices, _): return indices.count * 8 + 16
            }
        }
    }

    init(width: Int = ZoneMap.defaultSize, height: Int = ZoneMap.defaultSize,
         maxHistoryBytes: Int = 48 << 20, maxSteps: Int = 80) {
        self.width = width
        self.height = height
        self.maxHistoryBytes = maxHistoryBytes
        self.maxSteps = maxSteps
        count = width * height
        pixels = .allocate(capacity: count)
        coverage = .allocate(capacity: count)
        before = .allocate(capacity: count)
        memset(pixels, 0, count * 4)
        memset(coverage, 0, count)
        memset(before, 0, count * 4)
    }

    deinit {
        pixels.deallocate()
        coverage.deallocate()
        before.deallocate()
    }

    var canUndo: Bool { !history.isEmpty }
    var stepCount: Int { history.count }
    var isPainting: Bool { stroke != nil }

    func pixel(_ index: Int) -> UInt32 { pixels[index] }

    func copyPixels() -> [UInt32] { Array(UnsafeBufferPointer(start: pixels, count: count)) }

    // MARK: Remplir

    /// Remplit toute la zone `zone` ; `false` si elle avait déjà cette couleur partout.
    @discardableResult
    func fill(zone: Int, color: UInt32, in map: ZoneMap) -> Bool {
        let range = map.runRange(of: zone)
        guard !range.isEmpty, map.width == width, map.height == height else { return false }
        endStroke(in: map)
        var previous = PixelRuns()
        map.runStarts.withUnsafeBufferPointer { s in
            map.runLengths.withUnsafeBufferPointer { l in
                guard let S = s.baseAddress, let L = l.baseAddress else { return }
                var current = pixels[Int(S[range.lowerBound])]
                var run: Int32 = 0
                for r in range {
                    var i = Int(S[r])
                    let end = i + Int(L[r])
                    while i < end {
                        let v = pixels[i]
                        if v == current { run &+= 1 } else { previous.push(current, run); current = v; run = 1 }
                        pixels[i] = color
                        i &+= 1
                    }
                }
                previous.push(current, run)
            }
        }
        if previous.values.count == 1 && previous.values[0] == color { return false }
        push(.zone(zone, previous))
        return true
    }

    // MARK: Pinceau-pochoir

    /// Commence un trait dans la zone `zone` (point en pixels de la carte).
    func beginStroke(at p: CGPoint, zone: Int, color: UInt32, radius: CGFloat, in map: ZoneMap) {
        endStroke(in: map)
        guard zone > 0, zone <= map.zoneCount, map.width == width, map.height == height else { return }
        stroke = Stroke(zone: UInt16(clamping: zone), color: color, radius: Double(radius), points: [p])
        stamp(from: p, to: p, map)
    }

    /// Prolonge le trait jusqu'à `p` (pixels), en suivant une courbe lissée.
    func continueStroke(to p: CGPoint, in map: ZoneMap) {
        guard var s = stroke, let last = s.points.last else { return }
        guard hypot(p.x - last.x, p.y - last.y) >= 0.75 else { return }
        s.points.append(p)
        if s.points.count > 3 { s.points.removeFirst(s.points.count - 3) }
        stroke = s
        let q = s.points
        if q.count == 2 {
            stamp(from: q[0], to: Self.mid(q[0], q[1]), map)
        } else {
            curve(from: Self.mid(q[0], q[1]), control: q[1], to: Self.mid(q[1], q[2]), map)
        }
    }

    /// Termine le trait ; `true` s'il a peint quelque chose (un pas d'annulation).
    @discardableResult
    func endStroke(in map: ZoneMap) -> Bool {
        guard let s = stroke else { return false }
        if s.points.count >= 2 {
            let n = s.points.count
            stamp(from: Self.mid(s.points[n - 2], s.points[n - 1]), to: s.points[n - 1], map)
        }
        stroke = nil
        guard !touched.isEmpty else { return false }
        var previous = [UInt32](repeating: 0, count: touched.count)
        for k in touched.indices {
            let i = Int(touched[k])
            previous[k] = before[i]
            coverage[i] = 0
        }
        push(.pixels(touched, previous))
        touched = []
        return true
    }

    /// Courbe quadratique découpée en petits segments (≈ 3 px).
    private func curve(from a: CGPoint, control c: CGPoint, to b: CGPoint, _ map: ZoneMap) {
        let length = hypot(c.x - a.x, c.y - a.y) + hypot(b.x - c.x, b.y - c.y)
        let steps = max(1, Int(length / 3))
        var previous = a
        for k in 1...steps {
            let t = CGFloat(k) / CGFloat(steps), u = 1 - t
            let p = CGPoint(x: u * u * a.x + 2 * u * t * c.x + t * t * b.x,
                            y: u * u * a.y + 2 * u * t * c.y + t * t * b.y)
            stamp(from: previous, to: p, map)
            previous = p
        }
    }

    /// Peint le segment [a, b] au pinceau rond, seulement dans la zone du trait.
    /// Couverture = distance au segment (bord adouci d'un pixel) ; on garde la
    /// couverture maximale du trait, et l'on mélange toujours depuis la valeur d'avant.
    private func stamp(from a: CGPoint, to b: CGPoint, _ map: ZoneMap) {
        guard let s = stroke else { return }
        let reach = s.radius + 0.5
        let ax = Double(a.x), ay = Double(a.y), bx = Double(b.x), by = Double(b.y)
        let minX = max(0, Int((min(ax, bx) - reach).rounded(.down)))
        let maxX = min(width - 1, Int((max(ax, bx) + reach).rounded(.up)))
        let minY = max(0, Int((min(ay, by) - reach).rounded(.down)))
        let maxY = min(height - 1, Int((max(ay, by) + reach).rounded(.up)))
        guard minX <= maxX, minY <= maxY else { return }
        let dx = bx - ax, dy = by - ay
        let len2 = dx * dx + dy * dy
        let reach2 = reach * reach
        let zone = s.zone, color = s.color
        map.labels.withUnsafeBufferPointer { lab in
            guard let L = lab.baseAddress else { return }
            var y = minY
            while y <= maxY {
                let py = Double(y) + 0.5
                var x = minX
                var i = y * width + minX
                while x <= maxX {
                    if L[i] == zone {
                        let px = Double(x) + 0.5
                        var t = len2 > 0 ? ((px - ax) * dx + (py - ay) * dy) / len2 : 0
                        t = t < 0 ? 0 : (t > 1 ? 1 : t)
                        let qx = ax + t * dx - px, qy = ay + t * dy - py
                        let d2 = qx * qx + qy * qy
                        if d2 < reach2 {
                            let c = reach - d2.squareRoot()
                            let c8: UInt8 = c >= 1 ? 255 : UInt8(c * 255)
                            let old = coverage[i]
                            if c8 > old {
                                if old == 0 {
                                    before[i] = pixels[i]
                                    touched.append(Int32(i))
                                }
                                coverage[i] = c8
                                pixels[i] = c8 == 255 ? color : Self.blend(before[i], color, c8)
                            }
                        }
                    }
                    x &+= 1
                    i &+= 1
                }
                y &+= 1
            }
        }
    }

    /// Mélange prémultiplié : `over` à hauteur de `c`/255 sur `under`.
    static func blend(_ under: UInt32, _ over: UInt32, _ c: UInt8) -> UInt32 {
        let a = UInt32(c), ia = 255 - a
        let r = ((over & 0xFF) * a + (under & 0xFF) * ia + 127) / 255
        let g = (((over >> 8) & 0xFF) * a + ((under >> 8) & 0xFF) * ia + 127) / 255
        let b = (((over >> 16) & 0xFF) * a + ((under >> 16) & 0xFF) * ia + 127) / 255
        let al = (((over >> 24) & 0xFF) * a + ((under >> 24) & 0xFF) * ia + 127) / 255
        return r | g << 8 | b << 16 | al << 24
    }

    private static func mid(_ a: CGPoint, _ b: CGPoint) -> CGPoint { CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2) }

    // MARK: Annuler, tout effacer

    /// Annule le dernier geste. `map` : la carte de la page (pour un remplissage).
    @discardableResult
    func undo(in map: ZoneMap?) -> Bool {
        if let map { endStroke(in: map) }
        guard let step = history.popLast() else { return false }
        historyBytes -= step.bytes
        switch step {
        case let .zone(zone, previous):
            guard let map else { return false }
            let range = map.runRange(of: zone)
            guard !range.isEmpty, !previous.counts.isEmpty else { return false }
            var k = 0
            var left = previous.counts[0]
            var value = previous.values[0]
            for r in range {
                var i = Int(map.runStarts[r])
                let end = i + Int(map.runLengths[r])
                while i < end {
                    pixels[i] = value
                    left -= 1
                    if left == 0, k + 1 < previous.counts.count {
                        k += 1
                        left = previous.counts[k]
                        value = previous.values[k]
                    }
                    i &+= 1
                }
            }
        case let .pixels(indices, previous):
            for k in indices.indices { pixels[Int(indices[k])] = previous[k] }
        case let .all(previous):
            decode(previous)
        }
        return true
    }

    /// Efface toute la page (annulable) ; `false` si elle était déjà blanche.
    @discardableResult
    func clear(in map: ZoneMap?) -> Bool {
        if let map { endStroke(in: map) }
        let before = encode()
        guard !before.isBlank else { return false }
        push(.all(before))
        memset(pixels, 0, count * 4)
        return true
    }

    private func push(_ step: Step) {
        history.append(step)
        historyBytes += step.bytes
        while history.count > 1 && (historyBytes > maxHistoryBytes || history.count > maxSteps) {
            historyBytes -= history.removeFirst().bytes
        }
    }

    // MARK: Instantanés

    func snapshot() -> PaintSnapshot { PaintSnapshot(runs: encode()) }

    /// Remet une page (ou une page blanche) ; l'historique repart de zéro.
    func restore(_ snapshot: PaintSnapshot?) {
        stroke = nil
        for i in touched { coverage[Int(i)] = 0 }
        touched = []
        history = []
        historyBytes = 0
        if let snapshot { decode(snapshot.runs) } else { memset(pixels, 0, count * 4) }
    }

    private func encode() -> PixelRuns {
        var runs = PixelRuns()
        var current = pixels[0]
        var run: Int32 = 0
        var i = 0
        while i < count {
            let v = pixels[i]
            if v == current { run &+= 1 } else { runs.push(current, run); current = v; run = 1 }
            i &+= 1
        }
        runs.push(current, run)
        return runs
    }

    private func decode(_ runs: PixelRuns) {
        var i = 0
        for k in runs.counts.indices {
            let value = runs.values[k]
            let end = min(count, i + Int(runs.counts[k]))
            while i < end { pixels[i] = value; i &+= 1 }
        }
        if i < count { memset(pixels + i, 0, (count - i) * 4) }
    }

    // MARK: Images

    /// L'image des couleurs (copie : la couche peut continuer à changer).
    func makeImage() -> CGImage? {
        Self.image(from: Data(bytes: pixels, count: count * 4), width: width, height: height)
    }

    /// Vignette réduite (moyenne de blocs, échantillonnée) pour le choix des pages.
    func thumbnail(side: Int) -> CGImage? {
        let f = max(1, width / max(side, 1))
        let tw = width / f, th = height / f
        let step = max(1, f / 2)
        let samples = UInt32((f + step - 1) / step * ((f + step - 1) / step))
        var out = [UInt32](repeating: 0, count: tw * th)
        for ty in 0..<th {
            for tx in 0..<tw {
                var r: UInt32 = 0, g: UInt32 = 0, b: UInt32 = 0, a: UInt32 = 0
                var y = ty * f
                while y < ty * f + f {
                    var x = tx * f
                    while x < tx * f + f {
                        let v = pixels[y * width + x]
                        r += v & 0xFF
                        g += (v >> 8) & 0xFF
                        b += (v >> 16) & 0xFF
                        a += v >> 24
                        x += step
                    }
                    y += step
                }
                out[ty * tw + tx] = (r / samples) | (g / samples) << 8 | (b / samples) << 16 | (a / samples) << 24
            }
        }
        return out.withUnsafeBytes { Self.image(from: Data($0), width: tw, height: th) }
    }

    static func image(from data: Data, width: Int, height: Int) -> CGImage? {
        guard let provider = CGDataProvider(data: data as CFData),
              let space = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
                       space: space, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                       provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
    }
}
#endif
