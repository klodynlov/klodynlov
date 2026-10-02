// WorldIcefloeScene.swift — la banquise : ciel polaire lavande et rose, aurore
// boréale, icebergs sur une mer sombre, igloo et famille de manchots.
//
// Mouvement : la neige tombe, l'aurore ondule, le petit manchot fait coucou.

#if canImport(SwiftUI)
import SwiftUI

private enum Polar {
    static let skyStops: [Gradient.Stop] = [
        .init(color: Color(red: 0.50, green: 0.58, blue: 0.89), location: 0),
        .init(color: Color(red: 0.74, green: 0.76, blue: 0.97), location: 0.36),
        .init(color: Color(red: 0.96, green: 0.86, blue: 0.95), location: 0.76),
        .init(color: Color(red: 1.0, green: 0.90, blue: 0.87), location: 1),
    ]
    static let ice = Color(red: 0.95, green: 0.97, blue: 1.0)
    static let iceShade = Color(red: 0.80, green: 0.85, blue: 0.98)
    static let iceDeep = Color(red: 0.70, green: 0.77, blue: 0.96)
    static let sea = Color(red: 0.36, green: 0.51, blue: 0.83)
    static let seaDeep = Color(red: 0.29, green: 0.43, blue: 0.76)
    static let snow = Color(red: 0.99, green: 0.99, blue: 1.0)
    static let snowLow = Color(red: 0.87, green: 0.91, blue: 0.99)
    static let drift = Color(red: 0.82, green: 0.87, blue: 0.99)
    static let penguin = Color(red: 0.19, green: 0.22, blue: 0.35)
    static let chick = Color(red: 0.66, green: 0.69, blue: 0.78)
    static let chickFlipper = Color(red: 0.56, green: 0.59, blue: 0.70)
    static let beak = Color(red: 1.0, green: 0.62, blue: 0.20)
    static let mint = Color(red: 0.52, green: 0.96, blue: 0.80)
    static let lilac = Color(red: 0.93, green: 0.62, blue: 0.95)
}

struct IcefloeScene: View {
    let f: SceneryFrame

    private struct Flake: Identifiable {
        let id: Int
        let x: CGFloat, period: Double, phase: Double, size: CGFloat
    }

    private static let flakes: [Flake] = {
        var rng = SceneryRandom(seed: 0x5A0)
        return (0..<30).map { i in
            Flake(id: i, x: rng.range(0, 1), period: Double(rng.range(11, 19)), phase: Double(rng.unit()),
                  size: rng.range(0.004, 0.009))
        }
    }()

    private var chick: CGPoint { f.p(0.915, 0.922) }

    var body: some View {
        ZStack {
            Canvas { ctx, _ in sky(SketchPen(ctx: ctx)) }
            SceneryAmbient { t in
                ZStack {
                    AuroraRibbon(width: f.w, height: f.s * 0.16, color: Polar.mint).equatable()
                        .offset(x: -SceneryMotion.loop(t, period: 38) * f.w / 2)
                        .opacity(0.55 + 0.25 * Double(SceneryMotion.swing(t, period: 11)))
                        .position(x: f.w * 0.75, y: f.y(0.20))
                    AuroraRibbon(width: f.w, height: f.s * 0.12, color: Polar.lilac).equatable()
                        .offset(x: -SceneryMotion.loop(t, period: 52, phase: 0.3) * f.w / 2)
                        .opacity(0.35 + 0.2 * Double(SceneryMotion.swing(t, period: 14, phase: 0.4)))
                        .position(x: f.w * 0.75, y: f.y(0.255))
                }
                .frame(width: f.w, height: f.h)
            }
            Canvas { ctx, _ in shelf(SketchPen(ctx: ctx)) }
            SceneryAmbient { t in
                ZStack {
                    // Le petit manchot agite sa nageoire (vers l'extérieur, en dehors du corps).
                    Capsule().fill(Polar.chickFlipper)
                        .frame(width: f.s * 0.013, height: f.s * 0.034)
                        .rotationEffect(.degrees(40 + 30 * Double(max(0, SceneryMotion.swing(t, period: 1.6)))),
                                        anchor: .bottom)
                        .position(x: chick.x + f.s * 0.027, y: chick.y - f.s * 0.052)
                    ForEach(Self.flakes) { flake in
                        let fall = SceneryMotion.loop(t, period: flake.period, phase: flake.phase)
                        Circle().fill(Color.white.opacity(0.92))
                            .frame(width: f.s * flake.size * 2, height: f.s * flake.size * 2)
                            .position(x: f.x(flake.x) + f.s * 0.018 * SceneryMotion.swing(t, period: flake.period / 3,
                                                                                         phase: flake.phase),
                                      y: -f.s * 0.02 + fall * (f.h * 0.98))
                    }
                }
                .frame(width: f.w, height: f.h)
            }
        }
    }

    // MARK: Ciel

    private func sky(_ pen: SketchPen) {
        pen.fill(Path(CGRect(x: 0, y: 0, width: f.w, height: f.h)), top: 0, bottom: f.y(0.66), stops: Polar.skyStops)
        pen.glow(f.p(0.5, 0.66), f.s * 0.6, Color(red: 1, green: 0.85, blue: 0.8), strength: 0.5)
    }

    // MARK: Icebergs, mer, banquise, igloo, manchots

    private func shelf(_ pen: SketchPen) {
        let s = f.s
        // Icebergs lointains sur l'horizon.
        for (fx, wf, hf, pointy) in [(0.04, 0.16, 0.10, false), (0.24, 0.10, 0.06, true), (0.47, 0.13, 0.045, false),
                                     (0.66, 0.08, 0.075, true), (0.83, 0.18, 0.085, false)]
            as [(CGFloat, CGFloat, CGFloat, Bool)] {
            iceberg(pen, center: f.x(fx), base: f.y(0.655), width: s * wf, height: s * hf, pointy: pointy)
        }
        // Mer sombre et glaçons.
        let sea = Path(CGRect(x: 0, y: f.y(0.65), width: f.w, height: f.y(0.08)))
        pen.fill(sea, top: f.y(0.65), bottom: f.y(0.72), [Polar.sea, Polar.seaDeep])
        var rng = SceneryRandom(seed: 0x1CE)
        for k in 0..<7 {
            let c = f.p(CGFloat(k) / 7 + rng.range(0.02, 0.1), rng.range(0.668, 0.695))
            pen.stroke(Path { p in p.move(to: CGPoint(x: c.x - s * 0.03, y: c.y)); p.addLine(to: CGPoint(x: c.x + s * 0.03, y: c.y)) },
                       Color.white.opacity(0.35), width: s * 0.004)
        }
        for (fx, fy, z) in [(0.33, 0.69, 0.035), (0.58, 0.675, 0.025), (0.74, 0.695, 0.03)] as [(CGFloat, CGFloat, CGFloat)] {
            let c = f.p(fx, fy)
            pen.ellipse(CGPoint(x: c.x, y: c.y + s * 0.004), s * z, s * z * 0.3, Polar.iceShade)
            pen.ellipse(c, s * z, s * z * 0.28, Polar.ice)
        }
        // La banquise : le sol où roule le train.
        let floe = SceneryPath.ridge([CGPoint(x: -10, y: f.y(0.712)), f.p(0.2, 0.705), f.p(0.45, 0.713), f.p(0.7, 0.704),
                                      CGPoint(x: f.w + 10, y: f.y(0.71))], bottom: f.h + 2)
        pen.fill(floe, top: f.y(0.70), bottom: f.h, [Polar.snow, Polar.snowLow])
        pen.fill(Path(CGRect(x: 0, y: f.y(0.708), width: f.w, height: s * 0.008)), Polar.iceShade.opacity(0.6))
        // Congères bleutées dans les coins du bas.
        pen.fill(SceneryPath.ridge([CGPoint(x: -10, y: f.y(0.90)), f.p(0.12, 0.875), f.p(0.26, 0.93), f.p(0.36, 1.01)],
                                   bottom: f.h + 2), Polar.drift.opacity(0.7))
        pen.fill(SceneryPath.ridge([f.p(0.66, 1.01), f.p(0.8, 0.905), f.p(0.92, 0.885), CGPoint(x: f.w + 10, y: f.y(0.9))],
                                   bottom: f.h + 2), Polar.drift.opacity(0.7))
        for (fx, fy, r) in [(0.06, 0.82, 0.012), (0.18, 0.95, 0.009), (0.84, 0.84, 0.011), (0.95, 0.97, 0.009),
                            (0.24, 0.80, 0.007), (0.74, 0.97, 0.008)] as [(CGFloat, CGFloat, CGFloat)] {
            pen.fill(SceneryPath.star(f.p(fx, fy), outer: s * r, inner: s * r * 0.3, branches: 4), Color.white)
            pen.fill(SceneryPath.star(f.p(fx, fy), outer: s * r * 0.5, inner: s * r * 0.15, branches: 4),
                     Color(red: 0.7, green: 0.8, blue: 1.0))
        }
        // Au premier plan, dans les coins du sol : le train (≈ 90 % de la largeur vers 0,55–0,75 h)
        // ne les cache jamais, et le bouton du centre reste dégagé.
        let penguinFoot = f.p(0.82, 0.915)
        pen.ellipse(CGPoint(x: f.x(0.14), y: f.y(0.915)), min(s * 0.14, f.w * 0.12), s * 0.018, Polar.iceShade)
        pen.ellipse(CGPoint(x: (penguinFoot.x + chick.x) / 2, y: f.y(0.92)), s * 0.1, s * 0.014, Polar.iceShade)
        igloo(pen, base: f.p(0.14, 0.915))
        penguin(pen, foot: penguinFoot, height: s * 0.15)
        babyPenguin(pen, foot: chick, height: s * 0.085)
    }

    private func iceberg(_ pen: SketchPen, center x: CGFloat, base: CGFloat, width wd: CGFloat, height ht: CGFloat,
                         pointy: Bool) {
        let pts: [CGPoint]
        if pointy {
            pts = [CGPoint(x: x - wd / 2, y: base), CGPoint(x: x - wd * 0.15, y: base - ht),
                   CGPoint(x: x + wd * 0.05, y: base - ht * 0.75), CGPoint(x: x + wd / 2, y: base)]
        } else {
            pts = [CGPoint(x: x - wd / 2, y: base), CGPoint(x: x - wd * 0.42, y: base - ht),
                   CGPoint(x: x + wd * 0.38, y: base - ht * 0.96), CGPoint(x: x + wd / 2, y: base)]
        }
        let body = SceneryPath.polygon(pts)
        pen.fill(body, Polar.ice)
        pen.stroke(body, Polar.ice, width: f.s * 0.01)
        pen.clipped(to: body) { inside in
            inside.fill(SceneryPath.polygon([CGPoint(x: x + wd * 0.1, y: base - ht * 1.2), CGPoint(x: x + wd, y: base - ht),
                                             CGPoint(x: x + wd, y: base), CGPoint(x: x + wd * 0.2, y: base)]), Polar.iceShade)
        }
    }

    private func igloo(_ pen: SketchPen, base b: CGPoint) {
        let r = min(f.s * 0.12, f.w * 0.105)
        var dome = Path()
        dome.addArc(center: b, radius: r, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        dome.closeSubpath()
        pen.fill(dome, from: CGPoint(x: b.x - r, y: b.y - r), to: CGPoint(x: b.x + r, y: b.y), [Polar.ice, Polar.iceShade])
        // Les blocs de glace.
        pen.clipped(to: dome) { inside in
            var joints = Path()
            for k in 1..<4 {
                let y = b.y - r * CGFloat(k) * 0.26
                joints.move(to: CGPoint(x: b.x - r, y: y)); joints.addLine(to: CGPoint(x: b.x + r, y: y))
                let n = 5 - k
                for j in 0...n {
                    let x = b.x - r + (2 * r) * (CGFloat(j) + (k.isMultiple(of: 2) ? 0.5 : 0)) / CGFloat(n)
                    joints.move(to: CGPoint(x: x, y: y)); joints.addLine(to: CGPoint(x: x, y: y + r * 0.26))
                }
            }
            inside.stroke(joints, Polar.iceDeep.opacity(0.7), width: r * 0.03)
        }
        // Liseré bleuté : le dôme blanc se détache de la neige blanche.
        pen.stroke(dome, Polar.iceDeep.opacity(0.75), width: r * 0.035)
        // Le tunnel d'entrée, tourné vers le centre.
        let door = CGPoint(x: b.x + r * 0.78, y: b.y)
        var tunnel = Path()
        tunnel.addArc(center: door, radius: r * 0.42, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        tunnel.closeSubpath()
        pen.fill(tunnel, Polar.ice)
        pen.stroke(tunnel, Polar.iceShade, width: r * 0.03)
        var hole = Path()
        hole.addArc(center: CGPoint(x: door.x + r * 0.05, y: b.y), radius: r * 0.25, startAngle: .degrees(180),
                    endAngle: .degrees(0), clockwise: false)
        hole.closeSubpath()
        pen.fill(hole, Color(red: 0.27, green: 0.36, blue: 0.62))
    }

    /// Manchot adulte, tourné vers la gauche (vers le train).
    private func penguin(_ pen: SketchPen, foot b: CGPoint, height ht: CGFloat) {
        let wd = ht * 0.62
        pen.ellipse(CGPoint(x: b.x - wd * 0.22, y: b.y), wd * 0.2, ht * 0.05, Polar.beak)
        pen.ellipse(CGPoint(x: b.x + wd * 0.2, y: b.y), wd * 0.2, ht * 0.05, Polar.beak)
        pen.ellipse(CGPoint(x: b.x, y: b.y - ht * 0.45), wd / 2, ht * 0.46, Polar.penguin)
        pen.ellipse(CGPoint(x: b.x - wd * 0.08, y: b.y - ht * 0.36), wd * 0.36, ht * 0.34, Color.white)
        // Nageoires.
        pen.local(at: CGPoint(x: b.x + wd * 0.44, y: b.y - ht * 0.5), rotation: .degrees(-18)) { fl in
            fl.ellipse(CGPoint(x: 0, y: ht * 0.12), wd * 0.1, ht * 0.2, Polar.penguin)
        }
        pen.local(at: CGPoint(x: b.x - wd * 0.46, y: b.y - ht * 0.5), rotation: .degrees(18)) { fl in
            fl.ellipse(CGPoint(x: 0, y: ht * 0.12), wd * 0.1, ht * 0.2, Polar.penguin)
        }
        // Visage : grands yeux, joues roses, bec.
        let face = CGPoint(x: b.x - wd * 0.1, y: b.y - ht * 0.72)
        pen.ellipse(face, wd * 0.3, ht * 0.14, Color.white)
        for dx: CGFloat in [-0.13, 0.11] {
            let e = CGPoint(x: face.x + wd * dx, y: face.y - ht * 0.01)
            pen.circle(e, ht * 0.036, Polar.penguin)
            pen.circle(CGPoint(x: e.x - ht * 0.012, y: e.y - ht * 0.013), ht * 0.012, Color.white)
        }
        pen.fill(SceneryPath.polygon([CGPoint(x: face.x - wd * 0.02, y: face.y + ht * 0.035),
                                      CGPoint(x: face.x - wd * 0.3, y: face.y + ht * 0.07),
                                      CGPoint(x: face.x - wd * 0.02, y: face.y + ht * 0.095)]), Polar.beak)
        for dx: CGFloat in [-0.26, 0.2] {
            pen.circle(CGPoint(x: face.x + wd * dx, y: face.y + ht * 0.06), ht * 0.022,
                       Color(red: 1, green: 0.62, blue: 0.7).opacity(0.7))
        }
    }

    /// Petit manchot duveteux (sa nageoire droite est animée à part).
    private func babyPenguin(_ pen: SketchPen, foot b: CGPoint, height ht: CGFloat) {
        let wd = ht * 0.72
        pen.ellipse(CGPoint(x: b.x - wd * 0.2, y: b.y), wd * 0.18, ht * 0.05, Polar.beak)
        pen.ellipse(CGPoint(x: b.x + wd * 0.18, y: b.y), wd * 0.18, ht * 0.05, Polar.beak)
        pen.ellipse(CGPoint(x: b.x, y: b.y - ht * 0.44), wd / 2, ht * 0.45, Polar.chick)
        pen.local(at: CGPoint(x: b.x - wd * 0.46, y: b.y - ht * 0.45), rotation: .degrees(16)) { fl in
            fl.ellipse(CGPoint(x: 0, y: ht * 0.1), wd * 0.1, ht * 0.18, Polar.chickFlipper)
        }
        let face = CGPoint(x: b.x - wd * 0.04, y: b.y - ht * 0.58)
        pen.ellipse(face, wd * 0.40, ht * 0.23, Color.white)
        for dx: CGFloat in [-0.17, 0.13] {
            let e = CGPoint(x: face.x + wd * dx, y: face.y - ht * 0.03)
            pen.circle(e, ht * 0.05, Polar.penguin)
            pen.circle(CGPoint(x: e.x - ht * 0.016, y: e.y - ht * 0.018), ht * 0.016, Color.white)
        }
        pen.fill(SceneryPath.polygon([CGPoint(x: face.x - wd * 0.03, y: face.y + ht * 0.04),
                                      CGPoint(x: face.x - wd * 0.24, y: face.y + ht * 0.08),
                                      CGPoint(x: face.x - wd * 0.03, y: face.y + ht * 0.11)]), Polar.beak)
        pen.circle(CGPoint(x: face.x + wd * 0.2, y: face.y + ht * 0.08), ht * 0.03,
                   Color(red: 1, green: 0.62, blue: 0.7).opacity(0.7))
        pen.ellipse(CGPoint(x: b.x + wd * 0.04, y: b.y - ht * 0.93), wd * 0.07, ht * 0.06, Polar.chick)     // houppette
    }
}

/// Un rideau d'aurore : des traits verticaux posés sur un bord inférieur ondulé,
/// lumineux en bas et qui s'effacent vers le haut. Le motif se répète à chaque
/// longueur d'onde (w / 2) : la couche glisse d'une longueur d'onde sans raccord.
struct AuroraRibbon: View, Equatable {
    let width: CGFloat
    let height: CGFloat
    let color: Color

    var body: some View {
        Canvas { ctx, size in
            let lambda = width / 2
            let perWave = 26
            let count = perWave * 3                                  // la toile couvre 3 longueurs d'onde
            let step = lambda / CGFloat(perWave)
            let gradient = Gradient(colors: [color.opacity(0), color.opacity(0.45), color.opacity(0.95)])
            for i in 0..<count {
                let x = CGFloat(i) * step
                let u = 2 * CGFloat.pi * x / lambda
                let bottom = size.height * 0.80 + size.height * 0.10 * sin(u)
                let tall = size.height * (0.50 + 0.22 * (0.5 + 0.5 * sin(3 * u + 0.8)) + 0.1 * sin(5 * u))
                let rect = CGRect(x: x - step * 0.2, y: bottom - tall, width: step * 1.4, height: tall)
                ctx.fill(Path(roundedRect: rect, cornerRadius: step * 0.5),
                         with: .linearGradient(gradient, startPoint: CGPoint(x: 0, y: rect.minY),
                                               endPoint: CGPoint(x: 0, y: rect.maxY)))
            }
        }
        .frame(width: width * 1.5, height: height)
        .allowsHitTesting(false)
    }
}
#endif
