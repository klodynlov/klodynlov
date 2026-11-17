// WorldForestScene.swift — la forêt : ciel vert d'eau, grands arbres sur les
// côtés, sous-bois de sapins au fond, champignons et fougères au sol.
//
// Mouvement : des feuilles d'automne tombent en se balançant, les rayons de
// soleil respirent doucement.

#if canImport(SwiftUI)
import SwiftUI

private enum Woods {
    static let skyTop = Color(red: 0.62, green: 0.86, blue: 0.85)
    static let skyLow = Color(red: 0.93, green: 0.98, blue: 0.89)
    static let canopyFar = Color(red: 0.70, green: 0.86, blue: 0.72)
    static let canopyMid = Color(red: 0.55, green: 0.76, blue: 0.58)
    static let pine = Color(red: 0.31, green: 0.58, blue: 0.43)
    static let pineLight = Color(red: 0.40, green: 0.67, blue: 0.49)
    static let bush = Color(red: 0.36, green: 0.62, blue: 0.34)
    static let bushLight = Color(red: 0.46, green: 0.72, blue: 0.40)
    static let oak = Color(red: 0.33, green: 0.62, blue: 0.33)
    static let oakLight = Color(red: 0.45, green: 0.73, blue: 0.40)
    static let fir = Color(red: 0.24, green: 0.52, blue: 0.40)
    static let firLight = Color(red: 0.32, green: 0.61, blue: 0.46)
    static let bark = Color(red: 0.55, green: 0.38, blue: 0.26)
    static let barkDark = Color(red: 0.45, green: 0.30, blue: 0.21)
    static let moss = Color(red: 0.52, green: 0.72, blue: 0.36)
    static let mossDeep = Color(red: 0.42, green: 0.62, blue: 0.30)
    static let path = Color(red: 0.84, green: 0.73, blue: 0.52)
    static let mushroom = Color(red: 0.92, green: 0.27, blue: 0.25)
    static let stem = Color(red: 1.0, green: 0.96, blue: 0.88)
    static let fern = Color(red: 0.36, green: 0.64, blue: 0.32)
    static let autumn = [Color(red: 0.98, green: 0.60, blue: 0.20), Color(red: 0.99, green: 0.80, blue: 0.26),
                         Color(red: 0.91, green: 0.38, blue: 0.24), Color(red: 0.76, green: 0.80, blue: 0.30)]
}

struct ForestScene: View {
    let f: SceneryFrame

    /// Une feuille qui tombe : colonne, période de chute, balancement.
    private struct Falling: Identifiable {
        let id: Int
        let x: CGFloat, period: Double, phase: Double, size: CGFloat, sway: CGFloat, color: Color
    }

    private static let leaves: [Falling] = [
        Falling(id: 0, x: 0.07, period: 17, phase: 0.10, size: 0.030, sway: 0.030, color: Woods.autumn[0]),
        Falling(id: 1, x: 0.17, period: 21, phase: 0.55, size: 0.024, sway: 0.025, color: Woods.autumn[1]),
        Falling(id: 2, x: 0.86, period: 19, phase: 0.30, size: 0.028, sway: 0.030, color: Woods.autumn[2]),
        Falling(id: 3, x: 0.95, period: 23, phase: 0.78, size: 0.022, sway: 0.020, color: Woods.autumn[1]),
        Falling(id: 4, x: 0.31, period: 26, phase: 0.62, size: 0.020, sway: 0.030, color: Woods.autumn[3]),
        Falling(id: 5, x: 0.70, period: 24, phase: 0.05, size: 0.022, sway: 0.028, color: Woods.autumn[0]),
        Falling(id: 6, x: 0.52, period: 29, phase: 0.40, size: 0.018, sway: 0.024, color: Woods.autumn[2]),
    ]

    var body: some View {
        ZStack {
            Canvas { ctx, _ in back(SketchPen(ctx: ctx)) }
            SceneryAmbient { t in
                SunbeamsView(frame: f).equatable()
                    .opacity(0.75 + 0.25 * Double(SceneryMotion.swing(t, period: 9)))
            }
            Canvas { ctx, _ in front(SketchPen(ctx: ctx)) }
            SceneryAmbient { t in
                ZStack {
                    ForEach(Self.leaves) { leaf in
                        let fall = SceneryMotion.loop(t, period: leaf.period, phase: leaf.phase)
                        let sway = SceneryMotion.swing(t, period: leaf.period / 4, phase: leaf.phase)
                        SceneryLeafShape().fill(leaf.color)
                            .frame(width: f.s * leaf.size * 1.6, height: f.s * leaf.size)
                            .rotationEffect(.degrees(Double(sway) * 50 + 20))
                            .position(x: f.x(leaf.x) + sway * f.s * leaf.sway * 2,
                                      y: -f.s * 0.05 + fall * (f.ground + f.s * 0.05))
                            .opacity(fall > 0.93 ? Double((1 - fall) / 0.07) : 1)
                    }
                }
                .frame(width: f.w, height: f.h)
            }
        }
    }

    // MARK: Fond : ciel, lumière, sous-bois lointain

    private func back(_ pen: SketchPen) {
        pen.fill(Path(CGRect(x: 0, y: 0, width: f.w, height: f.h)), top: 0, bottom: f.y(0.64),
                 [Woods.skyTop, Woods.skyLow])
        pen.glow(f.p(0.86, -0.02), f.s * 0.75, Color(red: 1, green: 0.97, blue: 0.75), strength: 0.5)

        // Deux rangées de cimes lointaines (plus hautes sur les côtés).
        canopyRow(pen, base: 0.60, rise: 0.05, radius: 0.060, step: 0.050, color: Woods.canopyFar, seed: 11)
        canopyRow(pen, base: 0.655, rise: 0.035, radius: 0.050, step: 0.042, color: Woods.canopyMid, seed: 12)
    }

    private func canopyRow(_ pen: SketchPen, base: CGFloat, rise: CGFloat, radius: CGFloat, step: CGFloat,
                           color: Color, seed: UInt64) {
        var rng = SceneryRandom(seed: seed)
        var p = Path()
        var x: CGFloat = -0.05
        while x < 1.08 {
            let edge = 1 - abs(2 * x - 1)                    // 0 aux bords, 1 au centre
            let y = f.y(base - rise * (1 - edge))
            let r = f.s * radius * rng.range(0.8, 1.2)
            p.addEllipse(in: CGRect(x: f.x(x) - r, y: y - r, width: 2 * r, height: 2 * r))
            x += step * rng.range(0.8, 1.2)
        }
        p.addRect(CGRect(x: 0, y: f.y(base), width: f.w, height: f.h - f.y(base)))
        pen.fill(p, color)
    }

    // MARK: Premier plan : sapins, grands arbres, sol

    private func front(_ pen: SketchPen) {
        let s = f.s
        // Petits sapins du sous-bois, derrière le train.
        for (fx, fy, hf) in [(0.03, 0.735, 0.15), (0.20, 0.728, 0.11), (0.29, 0.735, 0.085), (0.43, 0.728, 0.10),
                             (0.58, 0.735, 0.08), (0.66, 0.73, 0.12), (0.76, 0.735, 0.09)] as [(CGFloat, CGFloat, CGFloat)] {
            SceneryMotif.pine(pen, base: f.p(fx, fy), height: s * hf, leaf: Woods.pine, leafLight: Woods.pineLight,
                              trunk: Woods.barkDark)
        }
        // Buissons ronds le long de la voie.
        var rng = SceneryRandom(seed: 21)
        var bx: CGFloat = -0.02
        while bx < 1.03 {
            let r = s * rng.range(0.022, 0.036)
            pen.circle(CGPoint(x: f.x(bx), y: f.y(0.752) - r * 0.35), r, Woods.bush)
            pen.circle(CGPoint(x: f.x(bx) - r * 0.3, y: f.y(0.752) - r * 0.65), r * 0.4, Woods.bushLight)
            bx += rng.range(0.05, 0.09)
        }
        oak(pen)
        firTree(pen)

        // Le sol de la forêt : mousse, et un chemin clair où roule le train.
        let floor = SceneryPath.ridge([CGPoint(x: -10, y: f.y(0.750)), f.p(0.3, 0.745), f.p(0.62, 0.752),
                                       CGPoint(x: f.w + 10, y: f.y(0.746))], bottom: f.h + 2)
        pen.fill(floor, top: f.ground, bottom: f.h, [Woods.moss, Woods.mossDeep])
        var trail = Path()
        trail.move(to: CGPoint(x: -10, y: f.y(0.756)))
        trail.addCurve(to: CGPoint(x: f.w + 10, y: f.y(0.758)), control1: f.p(0.35, 0.750), control2: f.p(0.7, 0.764))
        trail.addLine(to: CGPoint(x: f.w + 10, y: f.y(0.782)))
        trail.addCurve(to: CGPoint(x: -10, y: f.y(0.784)), control1: f.p(0.66, 0.790), control2: f.p(0.32, 0.776))
        trail.closeSubpath()
        pen.fill(trail, Woods.path.opacity(0.85))

        var seed = SceneryRandom(seed: 31)
        for _ in 0..<26 {
            let x = seed.range(0, 1), y = seed.range(0.80, 0.99)
            guard !SceneryFrame.isButtonZone(x, y) else { continue }
            let c = f.p(x, y)
            var leaf = pen
            leaf.ctx.translateBy(x: c.x, y: c.y)
            leaf.ctx.rotate(by: .degrees(Double(seed.range(-60, 60))))
            leaf.fill(SceneryLeafShape().path(in: CGRect(x: -s * 0.014, y: -s * 0.008, width: s * 0.028, height: s * 0.016)),
                      seed.pick(Woods.autumn).opacity(0.9))
        }
        stump(pen, at: f.p(0.19, 0.835))
        mushrooms(pen, at: f.p(0.07, 0.93), scale: 1.1)
        mushrooms(pen, at: f.p(0.88, 0.845), scale: 0.85)
        fern(pen, at: f.p(0.02, 0.84), size: s * 0.09, flip: false)
        fern(pen, at: f.p(0.98, 0.95), size: s * 0.11, flip: true)
        SceneryMotif.pebble(pen, at: f.p(0.80, 0.96), size: s * 0.018, Color(red: 0.70, green: 0.72, blue: 0.70),
                            light: Color.white.opacity(0.4))
    }

    /// Grand chêne à gauche : tronc épais, couronne sur le côté (jamais dans le coin haut).
    private func oak(_ pen: SketchPen) {
        let s = f.s, x = f.x(0.055), r = min(s * 0.13, f.w * 0.09)
        let top = f.y(0.29)
        var trunk = Path()
        trunk.move(to: CGPoint(x: x - r * 0.5, y: f.y(0.775)))
        trunk.addQuadCurve(to: CGPoint(x: x - r * 0.26, y: top + r * 0.4), control: CGPoint(x: x - r * 0.22, y: f.y(0.62)))
        trunk.addLine(to: CGPoint(x: x + r * 0.26, y: top + r * 0.4))
        trunk.addQuadCurve(to: CGPoint(x: x + r * 0.58, y: f.y(0.775)), control: CGPoint(x: x + r * 0.2, y: f.y(0.62)))
        trunk.closeSubpath()
        pen.fill(trunk, Woods.bark)
        pen.stroke(Path { p in
            p.move(to: CGPoint(x: x - r * 0.05, y: f.y(0.72))); p.addLine(to: CGPoint(x: x - r * 0.08, y: f.y(0.56)))
            p.move(to: CGPoint(x: x + r * 0.16, y: f.y(0.67))); p.addLine(to: CGPoint(x: x + r * 0.13, y: f.y(0.52)))
        }, Woods.barkDark, width: s * 0.006)
        // Un creux dans le tronc (maison d'écureuil).
        pen.ellipse(CGPoint(x: x + r * 0.02, y: f.y(0.50)), r * 0.13, r * 0.18, Woods.barkDark)
        // Couronne touffue, posée sur le tronc.
        for (dx, dy, k) in [(-0.7, 0.65, 0.95), (0.62, 0.72, 0.92), (0.0, 0.05, 1.12), (1.1, 1.05, 0.62),
                            (-0.95, -0.3, 0.82), (0.6, -0.28, 0.78), (0.05, 1.0, 0.8)] as [(CGFloat, CGFloat, CGFloat)] {
            pen.circle(CGPoint(x: x + dx * r, y: top + dy * r), r * k, Woods.oak)
        }
        for (dx, dy, k) in [(-0.25, -0.35, 0.42), (0.78, 0.35, 0.3), (-1.0, 0.25, 0.3), (0.2, 0.62, 0.22)]
            as [(CGFloat, CGFloat, CGFloat)] {
            pen.circle(CGPoint(x: x + dx * r, y: top + dy * r), r * k, Woods.oakLight)
        }
    }

    /// Grand sapin à droite, étagé jusqu'à mi-hauteur de l'écran.
    private func firTree(_ pen: SketchPen) {
        let s = f.s, x = f.x(0.945), base = f.y(0.775)
        let hgt = base - f.y(0.17)
        let half = min(s * 0.15, f.w * 0.10)
        pen.rect(CGRect(x: x - s * 0.025, y: base - hgt * 0.2, width: s * 0.05, height: hgt * 0.2), Woods.barkDark)
        for tier in 0..<5 {
            let k = CGFloat(tier) / 4
            let bottom = base - hgt * (0.12 + k * 0.62)
            let width = half * (1.25 - k * 0.72)
            let top = bottom - hgt * 0.28
            var p = Path()
            p.move(to: CGPoint(x: x - width, y: bottom))
            p.addQuadCurve(to: CGPoint(x: x + width, y: bottom), control: CGPoint(x: x, y: bottom + hgt * 0.04))
            p.addLine(to: CGPoint(x: x + width * 0.1, y: top))
            p.addQuadCurve(to: CGPoint(x: x - width * 0.1, y: top), control: CGPoint(x: x, y: top - hgt * 0.02))
            p.closeSubpath()
            pen.fill(p, Woods.fir)
            var light = Path()
            light.move(to: CGPoint(x: x - width * 0.8, y: bottom - hgt * 0.01))
            light.addLine(to: CGPoint(x: x - width * 0.1, y: top + hgt * 0.03))
            light.addLine(to: CGPoint(x: x - width * 0.35, y: bottom))
            light.closeSubpath()
            pen.fill(light, Woods.firLight)
        }
    }

    private func stump(_ pen: SketchPen, at c: CGPoint) {
        let s = f.s
        pen.rect(CGRect(x: c.x - s * 0.045, y: c.y - s * 0.05, width: s * 0.09, height: s * 0.055), Woods.bark,
                 corner: s * 0.01)
        pen.ellipse(CGPoint(x: c.x, y: c.y - s * 0.05), s * 0.045, s * 0.014, Color(red: 0.93, green: 0.80, blue: 0.58))
        pen.stroke(SceneryPath.ellipse(CGPoint(x: c.x, y: c.y - s * 0.05), s * 0.026, s * 0.007),
                   Color(red: 0.78, green: 0.62, blue: 0.42), width: s * 0.003)
        pen.ellipse(CGPoint(x: c.x - s * 0.03, y: c.y - s * 0.02), s * 0.012, s * 0.008, Woods.moss)
    }

    private func mushrooms(_ pen: SketchPen, at c: CGPoint, scale k: CGFloat) {
        let s = f.s * k
        for (dx, z) in [(-0.035, 1.0), (0.02, 0.72)] as [(CGFloat, CGFloat)] {
            let x = c.x + dx * s, r = s * 0.034 * z
            pen.rect(CGRect(x: x - r * 0.35, y: c.y - r * 1.3, width: r * 0.7, height: r * 1.3), Woods.stem,
                     corner: r * 0.3)
            var cap = Path()
            cap.move(to: CGPoint(x: x - r * 1.2, y: c.y - r * 1.15))
            cap.addQuadCurve(to: CGPoint(x: x + r * 1.2, y: c.y - r * 1.15), control: CGPoint(x: x, y: c.y - r * 3.1))
            cap.addQuadCurve(to: CGPoint(x: x - r * 1.2, y: c.y - r * 1.15), control: CGPoint(x: x, y: c.y - r * 0.95))
            pen.fill(cap, Woods.mushroom)
            pen.circle(CGPoint(x: x - r * 0.45, y: c.y - r * 1.75), r * 0.2, Woods.stem)
            pen.circle(CGPoint(x: x + r * 0.35, y: c.y - r * 2.0), r * 0.16, Woods.stem)
            pen.circle(CGPoint(x: x + r * 0.7, y: c.y - r * 1.45), r * 0.13, Woods.stem)
        }
    }

    /// Fougère : trois frondes en éventail, folioles rondes qui rapetissent vers la pointe.
    private func fern(_ pen: SketchPen, at c: CGPoint, size z: CGFloat, flip: Bool) {
        let d: CGFloat = flip ? -1 : 1
        let light = Color(red: 0.46, green: 0.74, blue: 0.40)
        for (angle, len, color) in [(-112.0, 0.8, Woods.fern), (-58.0, 0.85, Woods.fern), (-84.0, 1.0, light)]
            as [(Double, CGFloat, Color)] {
            var frond = pen
            frond.ctx.translateBy(x: c.x, y: c.y)
            frond.ctx.scaleBy(x: d, y: 1)
            frond.ctx.rotate(by: .degrees(angle))
            let length = z * len
            for i in 0..<6 {
                let u = CGFloat(i) / 6
                let size = z * 0.13 * (1 - u * 0.7)
                let px = length * (0.15 + u * 0.8)
                for side: CGFloat in [-1, 1] {
                    var leaflet = frond
                    leaflet.ctx.translateBy(x: px, y: 0)
                    leaflet.ctx.rotate(by: .degrees(Double(side) * 50))
                    leaflet.fill(SceneryPath.ellipse(CGPoint(x: size * 0.9, y: 0), size, size * 0.42), color)
                }
            }
            var stem = Path()
            stem.move(to: .zero)
            stem.addLine(to: CGPoint(x: length, y: 0))
            frond.stroke(stem, color, width: z * 0.035)
            frond.circle(CGPoint(x: length, y: 0), z * 0.04, color)
        }
    }
}

/// Rayons de soleil obliques venant du coin haut droit (voiles très légers).
struct SunbeamsView: View, Equatable {
    let frame: SceneryFrame

    var body: some View {
        Canvas { ctx, _ in
            let f = frame
            let origin = f.p(0.92, -0.05)
            for (angle, spread, alpha) in [(118.0, 0.05, 0.22), (132.0, 0.035, 0.16), (146.0, 0.045, 0.14)]
                as [(Double, CGFloat, Double)] {
                let a = angle * Double.pi / 180, len = f.h * 0.95
                let dir = CGPoint(x: CGFloat(cos(a)), y: CGFloat(sin(a)))
                let normal = CGPoint(x: -dir.y, y: dir.x)
                let end = CGPoint(x: origin.x + dir.x * len, y: origin.y + dir.y * len)
                let wide = f.s * spread * 3.2, narrow = f.s * spread * 0.5
                var p = Path()
                p.move(to: CGPoint(x: origin.x + normal.x * narrow, y: origin.y + normal.y * narrow))
                p.addLine(to: CGPoint(x: end.x + normal.x * wide, y: end.y + normal.y * wide))
                p.addLine(to: CGPoint(x: end.x - normal.x * wide, y: end.y - normal.y * wide))
                p.addLine(to: CGPoint(x: origin.x - normal.x * narrow, y: origin.y - normal.y * narrow))
                p.closeSubpath()
                ctx.fill(p, with: .linearGradient(Gradient(colors: [Color(red: 1, green: 0.98, blue: 0.8).opacity(alpha),
                                                                    Color(red: 1, green: 0.98, blue: 0.8).opacity(0)]),
                                                  startPoint: origin, endPoint: end))
            }
        }
        .frame(width: frame.w, height: frame.h)
        .allowsHitTesting(false)
    }
}

/// Feuille en amande avec sa nervure (feuilles qui tombent, feuilles au sol).
struct SceneryLeafShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.midY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.midY), control: CGPoint(x: r.midX, y: r.minY - r.height * 0.45))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.midY), control: CGPoint(x: r.midX, y: r.maxY + r.height * 0.45))
        p.closeSubpath()
        return p
    }
}
#endif
