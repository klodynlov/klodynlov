// LouGesturePainter.swift — peindre Lou en grand (portrait 260 × 300) à un instant d'un geste.
//
// Les parties fixes (buste, tête, bouches, table, signes de vibration) sont GÉNÉRÉES par
// `eveil/outils/gestes/generer.py` (`LouGestureArt.swift`) avec des jetons de couleur calculés
// depuis la peau (`ombre_de`, `levres_de`). Le bras et la main sont CALCULÉS ici à chaque image :
// portage de `lou_portrait.bras` et `lou_portrait.main` (et de `coloriages.dessin.tube`, `courbe`,
// `lisse`, `arc`), plus le passage d'une forme de main à une autre.
// Ordre de peinture (celui de `dessins.portrait`) : bras caché derrière le dos, buste, tête, bouche,
// table, vibration, puis chaque bras et sa main. Un bras qui arrive ou repart apparaît en fondu
// (calque entier, sans couture).

#if canImport(SwiftUI)
import SwiftUI

/// Le portrait (constantes et parties fixes générées : `LouGestureArt.swift`).
enum LouArt {}

// MARK: - Couleurs

/// Une couleur du portrait : fixe, ou calculée depuis la peau.
struct LouPaint: Sendable {
    enum Base: Sendable {
        case fixed(UInt32)       // 0xRRGGBB
        case skin                // la peau
        case shade               // `ombre_de(peau)`
        case lips                // `levres_de(peau)`
        case lipsInk             // `melange(levres_de(peau), ENCRE, 0,4)`
    }
    let base: Base
    let alpha: UInt8
}

/// Les couleurs qui dépendent de la peau (mêmes arrondis que `lou_portrait.melange`).
struct LouColors: Sendable {
    typealias RGB = (r: Int, g: Int, b: Int)
    let skin: RGB
    let shade: RGB
    let lips: RGB
    let lipsInk: RGB
    let nail: RGB

    init(hex: String) {
        let p = LouColors.rgb(hex)
        skin = p
        shade = LouColors.mix(p, LouColors.rgb(0x2A1208), 0.28)
        lips = LouColors.mix(p, LouColors.rgb(0xB8344A), 0.45)
        lipsInk = LouColors.mix(lips, LouColors.rgb(0x292B3D), 0.4)
        nail = LouColors.mix(p, LouColors.rgb(0xFFFFFF), 0.35)
    }

    static func rgb(_ v: UInt32) -> RGB { (Int((v >> 16) & 0xFF), Int((v >> 8) & 0xFF), Int(v & 0xFF)) }

    static func rgb(_ hex: String) -> RGB {
        rgb(UInt32(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0xB8784E)
    }

    /// `melange` : Python arrondit au pair le plus proche (`round`).
    static func mix(_ a: RGB, _ b: RGB, _ t: Double) -> RGB {
        func m(_ x: Int, _ y: Int) -> Int { Int((Double(x) + Double(y - x) * t).rounded(.toNearestOrEven)) }
        return (m(a.r, b.r), m(a.g, b.g), m(a.b, b.b))
    }

    func rgb(_ base: LouPaint.Base) -> RGB {
        switch base {
        case .fixed(let v): return LouColors.rgb(v)
        case .skin: return skin
        case .shade: return shade
        case .lips: return lips
        case .lipsInk: return lipsInk
        }
    }

    static func color(_ c: RGB, _ alpha: Double = 1) -> Color {
        Color(.sRGB, red: Double(c.r) / 255, green: Double(c.g) / 255, blue: Double(c.b) / 255, opacity: alpha)
    }

    func color(_ paint: LouPaint) -> Color { LouColors.color(rgb(paint.base), Double(paint.alpha) / 255) }
}

// MARK: - Parties fixes

/// Des aplats et des traits (bouts ronds), du fond vers l'avant ; `lift` = déplacement vertical
/// par unité de tête levée.
struct LouShape: Sendable {
    struct Op: Sendable {
        let path: Path
        let paint: LouPaint
        let width: CGFloat       // 0 = aplat
        let lift: CGFloat
    }

    private(set) var ops: [Op] = []

    init() {}

    mutating func fill(_ base: LouPaint.Base, _ alpha: UInt8, _ data: String, lift: CGFloat = 0) {
        ops.append(Op(path: PictoPath.parse(data), paint: LouPaint(base: base, alpha: alpha), width: 0, lift: lift))
    }

    mutating func stroke(_ base: LouPaint.Base, _ alpha: UInt8, _ width: CGFloat, _ data: String, lift: CGFloat = 0) {
        ops.append(Op(path: PictoPath.parse(data), paint: LouPaint(base: base, alpha: alpha), width: width,
                      lift: lift))
    }

    func paint(_ context: GraphicsContext, colors: LouColors, lift: Double = 0, extraLift: CGFloat = 0,
               opacity: (Int) -> Double = { _ in 1 }) {
        for (i, op) in ops.enumerated() {
            var g = context
            let a = opacity(i)
            if a <= 0.001 { continue }
            if a < 0.999 { g.opacity = a }
            let dy = op.lift * CGFloat(lift) + extraLift
            let path = dy == 0 ? op.path : op.path.offsetBy(dx: 0, dy: dy)
            if op.width > 0 {
                g.stroke(path, with: .color(colors.color(op.paint)),
                         style: StrokeStyle(lineWidth: op.width, lineCap: .round, lineJoin: .round))
            } else {
                g.fill(path, with: .color(colors.color(op.paint)))
            }
        }
    }
}

// MARK: - Géométrie (portage de `coloriages.dessin`)

enum LouGeo {
    /// Segments de Bézier d'une ligne douce ouverte passant par les points (`courbe`).
    static func curveSegments(_ pts: [CGPoint], tension: Double = 1) -> [(CGPoint, CGPoint, CGPoint)] {
        let t = tension / 6
        let ext = [pts[0]] + pts + [pts[pts.count - 1]]
        var out: [(CGPoint, CGPoint, CGPoint)] = []
        out.reserveCapacity(pts.count)
        for i in 1..<(ext.count - 2) {
            let p0 = ext[i - 1], p1 = ext[i], p2 = ext[i + 1], p3 = ext[i + 2]
            let c1 = CGPoint(x: Double(p1.x) + Double(p2.x - p0.x) * t, y: Double(p1.y) + Double(p2.y - p0.y) * t)
            let c2 = CGPoint(x: Double(p2.x) - Double(p3.x - p1.x) * t, y: Double(p2.y) - Double(p3.y - p1.y) * t)
            out.append((c1, c2, p2))
        }
        return out
    }

    static func openCurve(_ pts: [CGPoint]) -> Path {
        var path = Path()
        path.move(to: pts[0])
        for (c1, c2, p) in curveSegments(pts) { path.addCurve(to: p, control1: c1, control2: c2) }
        return path
    }

    /// Courbe fermée douce passant par tous les points (`lisse`, Catmull-Rom).
    static func smoothClosed(_ pts: [CGPoint], tension: Double = 1) -> Path {
        let n = pts.count
        let t = tension / 6
        var path = Path()
        path.move(to: pts[0])
        for i in 0..<n {
            let p0 = pts[(i - 1 + n) % n], p1 = pts[i], p2 = pts[(i + 1) % n], p3 = pts[(i + 2) % n]
            let c1 = CGPoint(x: Double(p1.x) + Double(p2.x - p0.x) * t, y: Double(p1.y) + Double(p2.y - p0.y) * t)
            let c2 = CGPoint(x: Double(p2.x) - Double(p3.x - p1.x) * t, y: Double(p2.y) - Double(p3.y - p1.y) * t)
            path.addCurve(to: p2, control1: c1, control2: c2)
        }
        path.closeSubpath()
        return path
    }

    /// Arc d'ellipse (degrés, 0 = droite, 90 = bas), ajouté au chemin (`arc`).
    static func addArc(_ path: inout Path, center c: CGPoint, r: Double, from a0: Double, to a1: Double) {
        let n = max(1, Int((abs(a1 - a0) / 90).rounded(.up)))
        let step = (a1 - a0) / Double(n)
        for i in 0..<n {
            let t1 = (a0 + Double(i) * step) * .pi / 180, t2 = (a0 + Double(i + 1) * step) * .pi / 180
            let k = 4 / 3 * tan((t2 - t1) / 4)
            let p1 = (x: Double(c.x) + r * cos(t1), y: Double(c.y) + r * sin(t1))
            let p2 = CGPoint(x: Double(c.x) + r * cos(t2), y: Double(c.y) + r * sin(t2))
            path.addCurve(to: p2,
                          control1: CGPoint(x: p1.x - k * r * sin(t1), y: p1.y + k * r * cos(t1)),
                          control2: CGPoint(x: Double(p2.x) + k * r * sin(t2), y: Double(p2.y) - k * r * cos(t2)))
        }
    }

    /// Boudin d'un seul contour autour d'une ligne douce, bouts arrondis (`tube`).
    static func tube(_ pts: [CGPoint], _ widths: [CGFloat]) -> Path {
        let n = pts.count
        var normals: [CGPoint] = []
        normals.reserveCapacity(n)
        for i in 0..<n {
            let a = pts[max(0, i - 1)], b = pts[min(n - 1, i + 1)]
            let tx = Double(b.x - a.x), ty = Double(b.y - a.y)
            let ln = hypot(tx, ty)
            if ln < 1e-9 {
                normals.append(normals.last ?? CGPoint(x: 0, y: 1))
            } else {
                normals.append(CGPoint(x: -ty / ln, y: tx / ln))
            }
        }
        var left: [CGPoint] = [], right: [CGPoint] = []
        for i in 0..<n {
            let h = Double(widths[i]) / 2
            left.append(CGPoint(x: Double(pts[i].x) + Double(normals[i].x) * h, y: Double(pts[i].y) + Double(normals[i].y) * h))
            right.append(CGPoint(x: Double(pts[i].x) - Double(normals[i].x) * h, y: Double(pts[i].y) - Double(normals[i].y) * h))
        }
        var path = Path()
        path.move(to: left[0])
        for (c1, c2, p) in curveSegments(left) { path.addCurve(to: p, control1: c1, control2: c2) }
        cap(&path, at: pts[n - 1], normal: normals[n - 1], r: Double(widths[n - 1]) / 2,
            toward: CGPoint(x: pts[n - 1].x - pts[n - 2].x, y: pts[n - 1].y - pts[n - 2].y))
        for (c1, c2, p) in curveSegments(right.reversed()) { path.addCurve(to: p, control1: c1, control2: c2) }
        cap(&path, at: pts[0], normal: CGPoint(x: -normals[0].x, y: -normals[0].y), r: Double(widths[0]) / 2,
            toward: CGPoint(x: pts[0].x - pts[1].x, y: pts[0].y - pts[1].y))
        path.closeSubpath()
        return path
    }

    /// Demi-cercle de c + n·r à c − n·r, bombé dans la direction `toward` (`_bout`).
    private static func cap(_ path: inout Path, at c: CGPoint, normal n: CGPoint, r: Double, toward t: CGPoint) {
        let a0 = atan2(Double(n.y), Double(n.x)) * 180 / .pi
        let sweep: Double = (-Double(n.y)) * Double(t.x) + Double(n.x) * Double(t.y) > 0 ? 180 : -180
        addArc(&path, center: c, r: r, from: a0, to: a0 + sweep)
    }

    static func ellipse(_ c: CGPoint, _ rx: Double, _ ry: Double, rotation degrees: Double = 0) -> Path {
        Path(ellipseIn: CGRect(x: -rx, y: -ry, width: 2 * rx, height: 2 * ry))
            .applying(CGAffineTransform(rotationAngle: degrees * .pi / 180)
                .concatenating(CGAffineTransform(translationX: c.x, y: c.y)))
    }

    static func line(_ a: CGPoint, _ b: CGPoint) -> Path {
        var p = Path()
        p.move(to: a)
        p.addLine(to: b)
        return p
    }
}

// MARK: - Peindre une image

enum LouPainter {
    /// Peint `frame` dans `context`, déjà mis à l'échelle du cadre 260 × 300.
    static func paint(_ frame: LouFrame, colors: LouColors, in context: GraphicsContext) {
        for arm in frame.arms where arm.setup.behind && arm.presence > 0.001 {
            layer(context, opacity: visibility(arm.presence)) { g in paintArm(arm, colors: colors, in: g) }
        }
        LouArt.bust.paint(context, colors: colors)
        LouArt.head.paint(context, colors: colors, lift: frame.lift)
        (LouArt.mouths[frame.mouth] ?? LouArt.mouths["neutre"]!)
            .paint(context, colors: colors, extraLift: LouArt.mouthLift * CGFloat(frame.lift))
        if frame.table > 0.001 {
            layer(context, opacity: frame.table) { g in LouArt.table.paint(g, colors: colors) }
        }
        if frame.vibrate {
            // Trois arcs de chaque côté du cou ; ils battent de l'intérieur vers l'extérieur.
            let t = frame.pulse
            LouArt.vibration.paint(context, colors: colors) { i in
                guard let t else { return 1 }
                let ring = Double(i / 2)
                return 0.35 + 0.65 * (0.5 + 0.5 * sin(2 * .pi * 4 * t - ring * 1.2))
            }
        }
        for arm in frame.arms where !arm.setup.behind && arm.presence > 0.001 {
            layer(context, opacity: visibility(arm.presence)) { g in
                paintArm(arm, colors: colors, in: g)
                paintHand(arm, colors: colors, in: g)
            }
        }
    }

    /// Le bras apparaît pendant le premier 40 % de son arrivée (et disparaît à la fin du départ).
    static func visibility(_ presence: Double) -> Double { min(1, max(0, presence * 2.5)) }

    private static func layer(_ context: GraphicsContext, opacity: Double, _ body: (GraphicsContext) -> Void) {
        if opacity >= 0.999 {
            body(context)
            return
        }
        var g = context
        g.opacity = opacity
        g.drawLayer { inner in body(inner) }
    }

    private static func contour(_ g: GraphicsContext, _ path: Path, fill: Color, stroke: Color, width: CGFloat) {
        g.fill(path, with: .color(fill))
        g.stroke(path, with: .color(stroke), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    /// `lou_portrait.bras` (coude donné) : deux segments, un coude rond, la manche courte.
    static func paintArm(_ arm: LouArmFrame, colors: LouColors, in g: GraphicsContext) {
        let skin = LouColors.color(colors.skin)
        let shade = LouColors.color(colors.shade, Double(0x80) / 255)
        let s = arm.shoulder, e = arm.elbow, w = arm.wrist
        let upper = LouGeo.tube([s, e], [28, 25])
        let fore = LouGeo.tube([e, w], [25, 19])
        contour(g, upper, fill: skin, stroke: shade, width: 1.2)
        // La manche AVANT l'avant-bras (`bras` la peint après) : quand la main remonte devant l'épaule
        // (« ou », « s »), l'avant-bras passe devant la manche au lieu d'y être coupé.
        let m = louLerp(s, e, 0.42)
        g.fill(LouGeo.tube([s, m], [40, 36]), with: .color(LouColors.color(LouColors.rgb(LouArt.shirt))))
        let ang = atan2(Double(m.y - s.y), Double(m.x - s.x)) + .pi / 2
        let r = 18.0
        g.stroke(LouGeo.line(CGPoint(x: Double(m.x) + r * cos(ang), y: Double(m.y) + r * sin(ang)),
                             CGPoint(x: Double(m.x) - r * cos(ang), y: Double(m.y) - r * sin(ang))),
                 with: .color(LouColors.color(LouColors.rgb(LouArt.shirtShade))),
                 style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
        contour(g, fore, fill: skin, stroke: shade, width: 1.2)
        g.fill(LouGeo.ellipse(e, 11.6, 11.6), with: .color(skin))
    }

    /// `lou_portrait.main` : doigts tendus derrière la paume, la paume, les doigts repliés, le pouce,
    /// puis les doigts « devant ». Entre deux formes : chemins rééchantillonnés et interpolés, un doigt
    /// qui se replie rentre sous sa phalange repliée (qui apparaît en fondu).
    static func paintHand(_ arm: LouArmFrame, colors: LouColors, in g: GraphicsContext) {
        let formA = LouHandModel.form(arm.formA), formB = LouHandModel.form(arm.formB)
        let morphing = arm.formA != arm.formB && arm.mix > 0 && arm.mix < 1
        let current = arm.mix < 0.5 ? formA : formB
        let s = Double(arm.setup.size)
        let lw = CGFloat(max(1, s * 0.04))
        let skin = LouColors.color(colors.skin)
        let shade = LouColors.color(colors.shade)
        let crease = LouColors.color(colors.shade, Double(0x90) / 255)
        let nail = LouColors.color(colors.nail)

        /// Part « repliée » d'un doigt (0 tendu, 1 replié).
        func folded(_ f: LouFinger) -> Double {
            if !morphing { return current.spec(f).isFolded ? 1 : 0 }
            return (formA.spec(f).isFolded ? 1 - arm.mix : 0) + (formB.spec(f).isFolded ? arm.mix : 0)
        }

        func path(_ f: LouFinger) -> [CGPoint] {
            if !morphing { return LouHandModel.localPath(current, f) }
            let a = LouHandModel.resample(LouHandModel.localPath(formA, f))
            let b = LouHandModel.resample(LouHandModel.localPath(formB, f))
            return zip(a, b).map { louLerp($0, $1, arm.mix) }
        }

        func fingerTube(_ f: LouFinger) {
            let pts = path(f).map(arm.screen)
            let w = Double(LouHandModel.width[f]!) * s
            let n = pts.count
            let widths = (0..<n).map { CGFloat(w * (1 - 0.12 * Double($0) / Double(max(1, n - 1)))) }
            contour(g, LouGeo.tube(pts, widths), fill: skin, stroke: shade, width: lw)
            // L'ongle clair au bout (caché quand le doigt est replié).
            let shown = 1 - folded(f)
            if shown > 0.01 {
                let a = pts[n - 2], b = pts[n - 1]
                let ang = atan2(Double(b.y - a.y), Double(b.x - a.x))
                let c = CGPoint(x: Double(b.x) - cos(ang) * w * 0.28, y: Double(b.y) - sin(ang) * w * 0.28)
                var h = g
                if shown < 0.999 { h.opacity = shown }
                h.fill(LouGeo.ellipse(c, w * 0.24, w * 0.19, rotation: ang * 180 / .pi), with: .color(nail))
            }
        }

        // 1. Les doigts tendus (sauf le pouce et ceux de « devant ») : derrière la paume.
        for f in LouFinger.fingers where folded(f) < 0.999 && !current.front.contains(f) {
            fingerTube(f)
        }
        // 2. La paume et son pli.
        contour(g, LouGeo.smoothClosed(LouHandModel.palm.map(arm.screen), tension: 0.9), fill: skin, stroke: shade,
                width: lw)
        g.stroke(LouGeo.openCurve([CGPoint(x: 0.30, y: 0.30), CGPoint(x: 0.55, y: 0.05), CGPoint(x: 0.62, y: -0.25)]
                    .map(arm.screen)),
                 with: .color(crease), style: StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round))
        // 3. Les doigts repliés : la phalange repliée sur le haut de la paume (un poing vu de face).
        for f in LouFinger.fingers where folded(f) > 0.001 {
            let v = Double(LouHandModel.base[f]!.y)
            let large = Double(LouHandModel.width[f]!)
            var h = g
            if folded(f) < 0.999 { h.opacity = folded(f) }
            let knuckle = LouGeo.tube([arm.screen(CGPoint(x: 1.10, y: v)), arm.screen(CGPoint(x: 0.66, y: v * 0.95))],
                                      [CGFloat(large * s * 1.12), CGFloat(large * s * 1.12)])
            contour(h, knuckle, fill: skin, stroke: shade, width: lw)
            h.stroke(LouGeo.line(arm.screen(CGPoint(x: 0.80, y: v - large * 0.36)),
                                 arm.screen(CGPoint(x: 0.80, y: v + large * 0.36))),
                     with: .color(shade), style: StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round))
        }
        // 4. Le pouce (replié : en travers des doigts repliés), puis les doigts de « devant ».
        if !morphing && current.thumb.isFolded {
            let w = CGFloat(Double(LouHandModel.width[.thumb]!) * s)
            contour(g, LouGeo.tube(LouHandModel.foldedThumb.map(arm.screen), [w, w, w * 0.92, w * 0.86]),
                    fill: skin, stroke: shade, width: lw)
        } else if !current.front.contains(.thumb) {
            fingerTube(.thumb)
        }
        for f in current.front { fingerTube(f) }
    }
}
#endif
