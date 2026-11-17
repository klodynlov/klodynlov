// WorldDesertScene.swift — le désert : grand soleil chaud, dunes dorées,
// pyramides au loin, un chameau sur la crête, oasis à palmiers et cactus.
//
// Mouvement : l'air tremble de chaleur au-dessus des dunes, les palmes se
// balancent, les rayons du soleil palpitent.

#if canImport(SwiftUI)
import SwiftUI

private enum Dunes {
    static let skyStops: [Gradient.Stop] = [
        .init(color: Color(red: 0.46, green: 0.75, blue: 0.96), location: 0),
        .init(color: Color(red: 0.80, green: 0.91, blue: 0.95), location: 0.55),
        .init(color: Color(red: 1.0, green: 0.93, blue: 0.75), location: 1),
    ]
    static let sun = Color(red: 1.0, green: 0.78, blue: 0.22)
    static let rays = Color(red: 1.0, green: 0.70, blue: 0.22)
    static let far = Color(red: 0.99, green: 0.87, blue: 0.64)
    static let mid = Color(red: 0.99, green: 0.80, blue: 0.51)
    static let midShade = Color(red: 0.95, green: 0.72, blue: 0.43)
    static let sand = Color(red: 0.99, green: 0.84, blue: 0.56)
    static let sandDeep = Color(red: 0.96, green: 0.76, blue: 0.47)
    static let ripple = Color(red: 0.92, green: 0.70, blue: 0.42)
    static let pyramid = Color(red: 0.97, green: 0.86, blue: 0.63)
    static let pyramidShade = Color(red: 0.90, green: 0.75, blue: 0.52)
    static let camel = Color(red: 0.80, green: 0.58, blue: 0.36)
    static let cactus = Color(red: 0.40, green: 0.71, blue: 0.40)
    static let cactusLight = Color(red: 0.52, green: 0.80, blue: 0.47)
    static let palm = Color(red: 0.32, green: 0.66, blue: 0.35)
    static let palmLight = Color(red: 0.45, green: 0.76, blue: 0.42)
    static let trunk = Color(red: 0.70, green: 0.50, blue: 0.31)
    static let trunkRing = Color(red: 0.58, green: 0.40, blue: 0.24)
    static let water = Color(red: 0.36, green: 0.73, blue: 0.93)
    static let flower = Color(red: 1.0, green: 0.50, blue: 0.68)
}

struct DesertScene: View {
    let f: SceneryFrame

    private var sunCenter: CGPoint { f.p(0.85, 0.19) }
    private var sunRadius: CGFloat { f.s * 0.075 }
    private var palms: [(foot: CGPoint, top: CGPoint, size: CGFloat)] {
        [(f.p(0.05, 0.742), CGPoint(x: f.x(0.05) + f.s * 0.05, y: f.y(0.742) - f.s * 0.30), f.s * 0.13),
         (f.p(0.17, 0.748), CGPoint(x: f.x(0.17) + f.s * 0.035, y: f.y(0.748) - f.s * 0.21), f.s * 0.10)]
    }

    var body: some View {
        ZStack {
            Canvas { ctx, _ in back(SketchPen(ctx: ctx)) }
            SceneryAmbient { t in
                ZStack {
                    SunRays(radius: sunRadius, color: Dunes.rays, count: 14).equatable()
                        .scaleEffect(1 + 0.06 * SceneryMotion.swing(t, period: 3.4))
                        .rotationEffect(.degrees(t * 360 / 120))
                        .position(sunCenter)
                    ForEach(0..<4, id: \.self) { i in
                        let k = Double(i)
                        HeatShimmer(width: f.s * (0.22 + 0.04 * CGFloat(i)), amplitude: f.s * 0.004).equatable()
                            .offset(x: f.s * 0.04 * SceneryMotion.swing(t, period: 5 + k, phase: k * 0.21))
                            .opacity(0.5 * Double(SceneryMotion.twinkle(t, period: 3.2 + k * 0.7, phase: k * 0.3)))
                            .position(f.p([0.36, 0.62, 0.50, 0.80][i], [0.625, 0.645, 0.68, 0.61][i]))
                    }
                }
                .frame(width: f.w, height: f.h)
            }
            Canvas { ctx, _ in front(SketchPen(ctx: ctx)) }
            SceneryAmbient { t in
                ZStack {
                    ForEach(0..<2, id: \.self) { i in
                        PalmCrown(size: palms[i].size).equatable()
                            .rotationEffect(.degrees(3 * Double(SceneryMotion.swing(t, period: 4.5, phase: Double(i) * 0.35))))
                            .position(palms[i].top)
                    }
                }
                .frame(width: f.w, height: f.h)
            }
        }
    }

    // MARK: Fond : ciel, soleil, pyramides, dunes lointaines, chameau

    private func back(_ pen: SketchPen) {
        let s = f.s
        pen.fill(Path(CGRect(x: 0, y: 0, width: f.w, height: f.h)), top: 0, bottom: f.y(0.64), stops: Dunes.skyStops)
        pen.glow(sunCenter, sunRadius * 3.6, Dunes.sun, strength: 0.5)
        pen.circle(sunCenter, sunRadius, Dunes.sun)
        pen.circle(sunCenter, sunRadius * 0.8, Color(red: 1, green: 0.86, blue: 0.35))
        pen.circle(CGPoint(x: sunCenter.x - sunRadius * 0.3, y: sunCenter.y - sunRadius * 0.3), sunRadius * 0.4,
                   Color.white.opacity(0.25))

        pyramid(pen, center: f.x(0.27), base: f.y(0.64), width: s * 0.27, height: s * 0.155)
        pyramid(pen, center: f.x(0.42), base: f.y(0.645), width: s * 0.17, height: s * 0.10)
        let far = SceneryPath.ridge([f.p(-0.05, 0.64), f.p(0.18, 0.625), f.p(0.40, 0.642), f.p(0.62, 0.618),
                                     f.p(0.85, 0.636), f.p(1.05, 0.622)], bottom: f.h)
        pen.fill(far, Dunes.far)
        camel(pen, foot: f.p(0.64, 0.622), size: s * 0.06)
    }

    private func pyramid(_ pen: SketchPen, center x: CGFloat, base: CGFloat, width wd: CGFloat, height ht: CGFloat) {
        let apex = CGPoint(x: x + wd * 0.06, y: base - ht)
        pen.fill(SceneryPath.polygon([CGPoint(x: x - wd / 2, y: base), apex, CGPoint(x: x + wd * 0.15, y: base)]), Dunes.pyramid)
        pen.fill(SceneryPath.polygon([CGPoint(x: x + wd * 0.15, y: base), apex, CGPoint(x: x + wd / 2, y: base)]),
                 Dunes.pyramidShade)
        var lines = Path()
        for k in 1..<4 {
            let u = CGFloat(k) / 4
            let y = base - ht * u
            lines.move(to: CGPoint(x: x - wd / 2 + (apex.x - (x - wd / 2)) * u, y: y))
            lines.addLine(to: CGPoint(x: x + wd * 0.15 + (apex.x - (x + wd * 0.15)) * u, y: y))
        }
        pen.stroke(lines, Dunes.pyramidShade.opacity(0.6), width: f.s * 0.002)
    }

    /// Chameau de profil (tourné vers la gauche), minuscule sur la crête lointaine.
    private func camel(_ pen: SketchPen, foot b: CGPoint, size z: CGFloat) {
        var legs = Path()
        for dx: CGFloat in [-0.32, -0.18, 0.18, 0.32] {
            legs.move(to: CGPoint(x: b.x + dx * z, y: b.y - z * 0.45)); legs.addLine(to: CGPoint(x: b.x + dx * z, y: b.y))
        }
        pen.stroke(legs, Dunes.camel, width: z * 0.075)
        pen.ellipse(CGPoint(x: b.x, y: b.y - z * 0.5), z * 0.42, z * 0.17, Dunes.camel)
        pen.ellipse(CGPoint(x: b.x + z * 0.03, y: b.y - z * 0.64), z * 0.22, z * 0.2, Dunes.camel)     // bosse
        var neck = Path()
        neck.move(to: CGPoint(x: b.x - z * 0.34, y: b.y - z * 0.52))
        neck.addQuadCurve(to: CGPoint(x: b.x - z * 0.55, y: b.y - z * 0.86), control: CGPoint(x: b.x - z * 0.62, y: b.y - z * 0.5))
        pen.stroke(neck, Dunes.camel, width: z * 0.12)
        pen.ellipse(CGPoint(x: b.x - z * 0.62, y: b.y - z * 0.88), z * 0.12, z * 0.07, Dunes.camel)
        pen.stroke(Path { p in
            p.move(to: CGPoint(x: b.x + z * 0.4, y: b.y - z * 0.52))
            p.addQuadCurve(to: CGPoint(x: b.x + z * 0.48, y: b.y - z * 0.32), control: CGPoint(x: b.x + z * 0.5, y: b.y - z * 0.45))
        }, Dunes.camel, width: z * 0.04)
    }

    // MARK: Premier plan : dunes, oasis, cactus, sable

    private func front(_ pen: SketchPen) {
        let s = f.s
        // Dunes du milieu : des bosses qui se chevauchent, chacune ombrée sur son flanc droit.
        for (cx, top, half) in [(0.20, 0.672, 0.42), (0.74, 0.668, 0.40), (0.47, 0.698, 0.26)]
            as [(CGFloat, CGFloat, CGFloat)] {
            var mound = Path()
            mound.move(to: f.p(cx - half, 0.77))
            mound.addCurve(to: f.p(cx, top), control1: f.p(cx - half * 0.55, 0.77), control2: f.p(cx - half * 0.35, top))
            mound.addCurve(to: f.p(cx + half, 0.77), control1: f.p(cx + half * 0.3, top), control2: f.p(cx + half * 0.5, 0.77))
            mound.closeSubpath()
            pen.fill(mound, Dunes.mid)
            pen.clipped(to: mound) { inside in
                var shade = Path()
                shade.move(to: f.p(cx, top - 0.01))
                shade.addQuadCurve(to: f.p(cx + half * 0.45, 0.78), control: f.p(cx + half * 0.05, 0.74))
                shade.addLine(to: f.p(cx + half + 0.05, 0.78))
                shade.addLine(to: f.p(cx + half + 0.05, top - 0.01))
                shade.closeSubpath()
                inside.fill(shade, Dunes.midShade.opacity(0.75))
            }
        }
        // L'oasis : mare, touffes, troncs de palmiers (les palmes bougent à part).
        pen.ellipse(f.p(0.115, 0.744), s * 0.13, s * 0.024, Color(red: 0.55, green: 0.80, blue: 0.45))
        pen.ellipse(f.p(0.115, 0.743), s * 0.11, s * 0.017, Dunes.water)
        pen.ellipse(CGPoint(x: f.x(0.115) - s * 0.03, y: f.y(0.740)), s * 0.03, s * 0.004, Color.white.opacity(0.6))
        for (foot, top, _) in palms {
            var trunk = Path()
            trunk.move(to: foot)
            trunk.addQuadCurve(to: top, control: CGPoint(x: foot.x - s * 0.01, y: (foot.y + top.y) / 2))
            pen.stroke(trunk, Dunes.trunk, width: s * 0.028)
            for k in 1..<8 {
                let u = CGFloat(k) / 8
                let x = (1 - u) * (1 - u) * foot.x + 2 * u * (1 - u) * (foot.x - s * 0.01) + u * u * top.x
                let y = foot.y + (top.y - foot.y) * u
                pen.stroke(Path { p in
                    p.move(to: CGPoint(x: x - s * 0.013, y: y)); p.addLine(to: CGPoint(x: x + s * 0.013, y: y - s * 0.004))
                }, Dunes.trunkRing, width: s * 0.004)
            }
        }
        for (fx, fy) in [(0.02, 0.75), (0.21, 0.752), (0.13, 0.757)] as [(CGFloat, CGFloat)] {
            SceneryMotif.tuft(pen, at: f.p(fx, fy), size: s * 0.02, Color(red: 0.45, green: 0.70, blue: 0.36))
        }
        saguaro(pen, foot: f.p(0.885, 0.768), height: s * 0.27)
        barrel(pen, foot: f.p(0.775, 0.772), r: s * 0.03)

        let ground = SceneryPath.ridge([CGPoint(x: -10, y: f.y(0.752)), f.p(0.3, 0.746), f.p(0.62, 0.753),
                                        CGPoint(x: f.w + 10, y: f.y(0.747))], bottom: f.h + 2)
        pen.fill(ground, top: f.ground, bottom: f.h, [Dunes.sand, Dunes.sandDeep])
        // Rides du sable, sur les côtés.
        for (fx, fy, wf) in [(0.12, 0.83, 0.16), (0.08, 0.90, 0.2), (0.16, 0.965, 0.18), (0.86, 0.84, 0.16),
                             (0.90, 0.91, 0.2), (0.80, 0.975, 0.16), (0.50, 0.95, 0.2)] as [(CGFloat, CGFloat, CGFloat)] {
            let c = f.p(fx, fy), half = s * wf / 2
            var ripple = Path()
            ripple.move(to: CGPoint(x: c.x - half, y: c.y))
            ripple.addCurve(to: CGPoint(x: c.x + half, y: c.y), control1: CGPoint(x: c.x - half * 0.3, y: c.y - s * 0.02),
                            control2: CGPoint(x: c.x + half * 0.3, y: c.y + s * 0.02))
            pen.stroke(ripple, Dunes.ripple.opacity(0.55), width: s * 0.005)
        }
        var rng = SceneryRandom(seed: 0xD35)
        for _ in 0..<10 {
            let x = rng.range(0, 1), y = rng.range(0.8, 0.99)
            guard !SceneryFrame.isButtonZone(x, y) else { continue }
            SceneryMotif.pebble(pen, at: f.p(x, y), size: s * rng.range(0.007, 0.013),
                                Color(red: 0.80, green: 0.62, blue: 0.45), light: Color.white.opacity(0.35))
        }
    }

    /// Grand cactus candélabre, bras vers le centre et vers l'extérieur.
    private func saguaro(_ pen: SketchPen, foot b: CGPoint, height ht: CGFloat) {
        let wd = ht * 0.2
        func arm(_ side: CGFloat, from y0: CGFloat, out: CGFloat, up: CGFloat) {
            var p = Path()
            p.move(to: CGPoint(x: b.x, y: b.y - ht * y0))
            p.addLine(to: CGPoint(x: b.x + side * ht * out, y: b.y - ht * y0))
            p.addLine(to: CGPoint(x: b.x + side * ht * out, y: b.y - ht * (y0 + up)))
            pen.stroke(p, Dunes.cactus, width: wd * 0.72)
            pen.stroke(Path { q in
                q.move(to: CGPoint(x: b.x + side * ht * out - wd * 0.12, y: b.y - ht * y0 - wd * 0.2))
                q.addLine(to: CGPoint(x: b.x + side * ht * out - wd * 0.12, y: b.y - ht * (y0 + up) + wd * 0.1))
            }, Dunes.cactusLight, width: wd * 0.12)
        }
        arm(-1, from: 0.38, out: 0.24, up: 0.3)
        arm(1, from: 0.55, out: 0.2, up: 0.22)
        pen.rect(CGRect(x: b.x - wd / 2, y: b.y - ht, width: wd, height: ht), Dunes.cactus, corner: wd / 2)
        for dx: CGFloat in [-0.22, 0.12] {
            pen.stroke(Path { p in
                p.move(to: CGPoint(x: b.x + dx * wd, y: b.y - ht + wd * 0.5)); p.addLine(to: CGPoint(x: b.x + dx * wd, y: b.y - wd * 0.2))
            }, Dunes.cactusLight, width: wd * 0.1)
        }
        SceneryMotif.flower(pen, at: CGPoint(x: b.x, y: b.y - ht - wd * 0.05), radius: wd * 0.4, petal: Dunes.flower,
                            heart: Color(red: 1, green: 0.85, blue: 0.3))
    }

    private func barrel(_ pen: SketchPen, foot b: CGPoint, r: CGFloat) {
        pen.ellipse(CGPoint(x: b.x, y: b.y - r * 0.9), r, r * 0.95, Dunes.cactus)
        for dx: CGFloat in [-0.5, 0, 0.5] {
            pen.stroke(Path { p in
                p.move(to: CGPoint(x: b.x + dx * r, y: b.y - r * 1.7)); p.addQuadCurve(to: CGPoint(x: b.x + dx * r, y: b.y - r * 0.1),
                                                                                         control: CGPoint(x: b.x + dx * r * 1.4, y: b.y - r * 0.9))
            }, Dunes.cactusLight, width: r * 0.1)
        }
        SceneryMotif.flower(pen, at: CGPoint(x: b.x, y: b.y - r * 1.82), radius: r * 0.45, petal: Dunes.flower,
                            heart: Color(red: 1, green: 0.85, blue: 0.3))
    }
}

/// Couronne de palmes : sept feuilles qui retombent autour du cœur (tourne un peu, d'un bloc).
struct PalmCrown: View, Equatable {
    let size: CGFloat

    var body: some View {
        Canvas { ctx, sz in
            let c = CGPoint(x: sz.width / 2, y: sz.height / 2)
            for (angle, len) in [(-150.0, 1.0), (-110.0, 0.85), (-70.0, 0.85), (-30.0, 1.0), (10.0, 0.9), (170.0, 0.9),
                                 (-90.0, 0.7)] as [(Double, CGFloat)] {
                var leaf = ctx
                leaf.translateBy(x: c.x, y: c.y)
                leaf.rotate(by: .degrees(angle))
                let l = size * len
                var p = Path()
                p.move(to: .zero)
                p.addQuadCurve(to: CGPoint(x: l, y: l * 0.18), control: CGPoint(x: l * 0.5, y: -l * 0.28))
                p.addQuadCurve(to: .zero, control: CGPoint(x: l * 0.55, y: l * 0.12))
                leaf.fill(p, with: .color(Color(red: 0.32, green: 0.66, blue: 0.35)))
                var rib = Path()
                rib.move(to: .zero)
                rib.addQuadCurve(to: CGPoint(x: l * 0.95, y: l * 0.16), control: CGPoint(x: l * 0.5, y: -l * 0.12))
                leaf.stroke(rib, with: .color(Color(red: 0.45, green: 0.76, blue: 0.42)), lineWidth: size * 0.03)
            }
            for (dx, dy) in [(-0.1, 0.12), (0.1, 0.14), (0.0, 0.2)] as [(CGFloat, CGFloat)] {
                ctx.fill(SceneryPath.circle(CGPoint(x: c.x + dx * size, y: c.y + dy * size), size * 0.08),
                         with: .color(Color(red: 0.55, green: 0.36, blue: 0.22)))
            }
        }
        .frame(width: size * 2.4, height: size * 2.4)
    }
}

/// Un trait d'air chaud qui ondule (mirage).
struct HeatShimmer: View, Equatable {
    let width: CGFloat
    let amplitude: CGFloat

    var body: some View {
        Canvas { ctx, sz in
            var p = Path()
            let steps = 24
            for i in 0...steps {
                let x = sz.width * CGFloat(i) / CGFloat(steps)
                let y = sz.height / 2 + amplitude * sin(CGFloat(i) / CGFloat(steps) * 6 * .pi)
                if i == 0 { p.move(to: CGPoint(x: x, y: y)) } else { p.addLine(to: CGPoint(x: x, y: y)) }
            }
            ctx.stroke(p, with: .linearGradient(Gradient(colors: [.white.opacity(0), .white, .white.opacity(0)]),
                                                startPoint: .zero, endPoint: CGPoint(x: sz.width, y: 0)),
                       style: StrokeStyle(lineWidth: max(1.5, amplitude * 0.7), lineCap: .round))
        }
        .frame(width: width, height: amplitude * 4)
        .allowsHitTesting(false)
    }
}
#endif
