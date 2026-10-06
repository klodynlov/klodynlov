// WorldSpaceScene.swift — l'espace : ciel nuit profond, étoiles, croissant de
// lune, planète à anneaux, petite planète bleue, comète ; au sol, une lune
// lilas à cratères, des cristaux et une fusée posée.
//
// Mouvement : les étoiles scintillent, la comète traverse lentement le ciel,
// la lumière de la fusée clignote. Le ciel est SOMBRE (`World.isDark`).

#if canImport(SwiftUI)
import SwiftUI

private enum Cosmos {
    static let skyStops: [Gradient.Stop] = [
        .init(color: Color(red: 0.07, green: 0.08, blue: 0.24), location: 0),
        .init(color: Color(red: 0.15, green: 0.13, blue: 0.40), location: 0.5),
        .init(color: Color(red: 0.34, green: 0.23, blue: 0.54), location: 1),
    ]
    static let star = Color(red: 1.0, green: 0.97, blue: 0.86)
    static let moon = Color(red: 1.0, green: 0.93, blue: 0.66)
    static let planetA = Color(red: 1.0, green: 0.67, blue: 0.47)
    static let planetB = Color(red: 0.92, green: 0.42, blue: 0.56)
    static let ring = Color(red: 0.99, green: 0.86, blue: 0.62)
    static let ground = Color(red: 0.72, green: 0.69, blue: 0.87)
    static let groundDeep = Color(red: 0.56, green: 0.53, blue: 0.75)
    static let ridge = Color(red: 0.52, green: 0.47, blue: 0.74)
    static let craterRim = Color(red: 0.83, green: 0.81, blue: 0.95)
    static let craterIn = Color(red: 0.60, green: 0.57, blue: 0.79)
    static let track = Color(red: 0.45, green: 0.95, blue: 1.0)
    static let rocket = Color(red: 0.97, green: 0.96, blue: 0.99)
    static let rocketRed = Color(red: 0.94, green: 0.32, blue: 0.38)
}

struct SpaceScene: View {
    let f: SceneryFrame

    private struct Sparkle: Identifiable {
        let id: Int
        let x: CGFloat, y: CGFloat, size: CGFloat, period: Double, phase: Double
    }

    private static let sparkles: [Sparkle] = {
        var rng = SceneryRandom(seed: 0x57A2)
        let spots: [(CGFloat, CGFloat)] = [(0.06, 0.34), (0.26, 0.10), (0.44, 0.19), (0.62, 0.08), (0.70, 0.21),
                                           (0.95, 0.46), (0.10, 0.55), (0.90, 0.60), (0.30, 0.61), (0.56, 0.63),
                                           (0.05, 0.13), (0.93, 0.36)]
        return spots.enumerated().map { i, p in
            Sparkle(id: i, x: p.0, y: p.1, size: rng.range(0.012, 0.022), period: Double(rng.range(2.2, 4.2)),
                    phase: Double(rng.unit()))
        }
    }()

    private var moonCenter: CGPoint { f.p(0.13, 0.20) }
    private var planetCenter: CGPoint { f.p(0.855, 0.205) }
    private var rocketFoot: CGPoint { f.p(0.875, 0.945) }
    /// La fusée tient dans la bande de sol, en portrait comme en paysage.
    private var rocketHeight: CGFloat { min(f.s * 0.25, f.h * 0.2) }

    var body: some View {
        ZStack {
            Canvas { ctx, _ in sky(SketchPen(ctx: ctx)) }
            SceneryAmbient { t in ambient(t) }
            Canvas { ctx, _ in ground(SketchPen(ctx: ctx)) }
            SceneryAmbient { t in
                Circle().fill(Color(red: 1, green: 0.35, blue: 0.4))
                    .frame(width: f.s * 0.012, height: f.s * 0.012)
                    .opacity(SceneryMotion.loop(t, period: 1.6) < 0.5 ? 1 : 0.2)
                    .position(x: rocketFoot.x, y: rocketFoot.y - rocketHeight * 1.048)
                    .frame(width: f.w, height: f.h)
            }
        }
    }

    // MARK: Animé : scintillements, comète

    private func ambient(_ t: Double) -> some View {
        let s = f.s
        // La comète traverse en 30 s, puis reste cachée 20 s (cycle de 50 s).
        let u = SceneryMotion.loop(t, period: 50, phase: 0.22) * 50 / 30
        let start = f.p(1.12, 0.08), end = f.p(-0.15, 0.30)
        let head = CGPoint(x: start.x + (end.x - start.x) * u, y: start.y + (end.y - start.y) * u)
        let angle = Angle(radians: Double(atan2(start.y - end.y, start.x - end.x)))
        return ZStack {
            ForEach(Self.sparkles) { sp in
                let k = SceneryMotion.twinkle(t, period: sp.period, phase: sp.phase)
                SparkleShape().fill(Cosmos.star)
                    .frame(width: s * sp.size * 2, height: s * sp.size * 2)
                    .scaleEffect(0.55 + 0.45 * k)
                    .opacity(0.45 + 0.55 * Double(k))
                    .position(f.p(sp.x, sp.y))
            }
            if u <= 1 {
                CometView(length: s * 0.26, head: s * 0.016).equatable()
                    .rotationEffect(angle, anchor: .leading)
                    .position(x: head.x + s * 0.13, y: head.y)
            }
        }
        .frame(width: f.w, height: f.h)
    }

    // MARK: Ciel

    private func sky(_ pen: SketchPen) {
        let s = f.s
        pen.fill(Path(CGRect(x: 0, y: 0, width: f.w, height: f.h)), top: 0, bottom: f.y(0.74), stops: Cosmos.skyStops)
        pen.glow(f.p(0.18, 0.44), s * 0.5, Color(red: 0.95, green: 0.45, blue: 0.80), strength: 0.2)
        pen.glow(f.p(0.84, 0.58), s * 0.55, Color(red: 0.35, green: 0.62, blue: 1.0), strength: 0.2)
        pen.glow(f.p(0.55, 0.12), s * 0.4, Color(red: 0.62, green: 0.45, blue: 0.98), strength: 0.14)
        var rng = SceneryRandom(seed: 0x5EA)
        for _ in 0..<90 {
            let x = rng.range(0, 1), y = rng.range(0.02, 0.70), r = rng.range(0.0012, 0.0032)
            let alpha = Double(rng.range(0.45, 0.95))
            // Moins d'étoiles derrière la carte, le chat et la bulle.
            let middle = x > 0.15 && x < 0.85 && y > 0.25 && y < 0.55
            if middle && rng.unit() < 0.7 { continue }
            pen.circle(f.p(x, y), s * (middle ? r * 0.7 : r), Cosmos.star.opacity(middle ? alpha * 0.6 : alpha))
        }
        // Croissant de lune, avec son halo.
        let r = s * 0.058
        pen.glow(moonCenter, r * 2.4, Cosmos.moon, strength: 0.28)
        var crescent = pen.ctx
        crescent.clip(to: SceneryPath.circle(CGPoint(x: moonCenter.x + r * 0.48, y: moonCenter.y - r * 0.28), r * 0.9),
                      options: .inverse)
        crescent.fill(SceneryPath.circle(moonCenter, r), with: .color(Cosmos.moon))
        crescent.fill(SceneryPath.circle(CGPoint(x: moonCenter.x - r * 0.55, y: moonCenter.y + r * 0.25), r * 0.13),
                      with: .color(Color(red: 0.95, green: 0.84, blue: 0.55)))
        // Petite planète bleue.
        let blue = f.p(0.33, 0.15), br = s * 0.024
        pen.circle(blue, br, Color(red: 0.36, green: 0.62, blue: 0.98))
        pen.clipped(to: SceneryPath.circle(blue, br)) { inside in
            inside.ellipse(CGPoint(x: blue.x - br * 0.3, y: blue.y - br * 0.2), br * 0.5, br * 0.35, Color(red: 0.45, green: 0.86, blue: 0.56))
            inside.ellipse(CGPoint(x: blue.x + br * 0.45, y: blue.y + br * 0.4), br * 0.35, br * 0.25, Color(red: 0.45, green: 0.86, blue: 0.56))
            inside.circle(CGPoint(x: blue.x + br * 0.5, y: blue.y + br * 0.5), br * 0.9, Color.black.opacity(0.15))
        }
        ringedPlanet(pen)
    }

    private func ringedPlanet(_ pen: SketchPen) {
        let s = f.s, c = planetCenter, r = s * 0.085
        pen.glow(c, r * 2.2, Cosmos.planetA, strength: 0.18)
        let tilt = Angle.degrees(-16)
        func ring(_ half: Bool) {
            pen.local(at: c, rotation: tilt) { local in
                var band = Path()
                band.addEllipse(in: CGRect(x: -r * 1.8, y: -r * 0.45, width: r * 3.6, height: r * 0.9))
                band.addEllipse(in: CGRect(x: -r * 1.3, y: -r * 0.28, width: r * 2.6, height: r * 0.56))
                let clip = Path(CGRect(x: -r * 2, y: half ? 0 : -r, width: r * 4, height: r))
                local.clipped(to: clip) { inside in
                    inside.ctx.fill(band, with: .color(Cosmos.ring), style: FillStyle(eoFill: true))
                }
            }
        }
        ring(false)                                    // moitié arrière de l'anneau
        pen.fill(SceneryPath.circle(c, r), from: CGPoint(x: c.x - r, y: c.y - r), to: CGPoint(x: c.x + r, y: c.y + r),
                 [Cosmos.planetA, Cosmos.planetB])
        pen.clipped(to: SceneryPath.circle(c, r)) { inside in
            for (dy, hgt) in [(-0.45, 0.14), (0.05, 0.18), (0.5, 0.12)] as [(CGFloat, CGFloat)] {
                inside.fill(Path(CGRect(x: c.x - r, y: c.y + dy * r, width: 2 * r, height: hgt * r)),
                            Color.white.opacity(0.18))
            }
            inside.circle(CGPoint(x: c.x - r * 0.35, y: c.y - r * 0.4), r * 0.35, Color.white.opacity(0.15))
        }
        ring(true)                                     // moitié avant
    }

    // MARK: Sol lunaire, cristaux, fusée

    private func ground(_ pen: SketchPen) {
        let s = f.s
        let ridge = SceneryPath.ridge([f.p(-0.05, 0.715), f.p(0.15, 0.69), f.p(0.32, 0.708), f.p(0.55, 0.685),
                                       f.p(0.78, 0.704), f.p(1.05, 0.688)], bottom: f.h)
        pen.fill(ridge, Cosmos.ridge)
        for (fx, fy, z) in [(0.2, 0.703, 0.03), (0.6, 0.698, 0.025), (0.86, 0.71, 0.02)] as [(CGFloat, CGFloat, CGFloat)] {
            pen.ellipse(f.p(fx, fy), s * z, s * z * 0.25, Cosmos.craterIn.opacity(0.6))
        }

        let floor = SceneryPath.ridge([CGPoint(x: -10, y: f.y(0.745)), f.p(0.3, 0.741), f.p(0.64, 0.747),
                                       CGPoint(x: f.w + 10, y: f.y(0.742))], bottom: f.h + 2)
        pen.fill(floor, top: f.ground, bottom: f.h, [Cosmos.ground, Cosmos.groundDeep])
        // La voie lumineuse où roule le train.
        pen.fill(Path(CGRect(x: 0, y: f.y(0.737), width: f.w, height: s * 0.03)), top: f.y(0.737), bottom: f.y(0.737) + s * 0.03,
                 [Cosmos.track.opacity(0), Cosmos.track.opacity(0.35), Cosmos.track.opacity(0)])
        pen.fill(Path(CGRect(x: 0, y: f.y(0.737) + s * 0.013, width: f.w, height: s * 0.004)), Cosmos.track.opacity(0.85))

        for (fx, fy, z) in [(0.21, 0.83, 0.05), (0.33, 0.95, 0.04), (0.74, 0.84, 0.045), (0.64, 0.965, 0.035),
                            (0.48, 0.93, 0.05), (0.06, 0.985, 0.03)] as [(CGFloat, CGFloat, CGFloat)] {
            crater(pen, at: f.p(fx, fy), r: s * z)
        }
        var rng = SceneryRandom(seed: 0x3007)
        for _ in 0..<12 {
            let x = rng.range(0, 1), y = rng.range(0.8, 0.99)
            guard !SceneryFrame.isButtonZone(x, y) else { continue }
            SceneryMotif.pebble(pen, at: f.p(x, y), size: s * rng.range(0.006, 0.011), Cosmos.craterIn,
                                light: Cosmos.craterRim.opacity(0.6))
        }
        // Au premier plan, dans les coins du sol : le train ne les cache jamais.
        pen.ellipse(CGPoint(x: rocketFoot.x, y: rocketFoot.y), s * 0.07, s * 0.014, Cosmos.craterIn)
        crystals(pen, foot: f.p(0.09, 0.925))
        rocket(pen, foot: rocketFoot)
    }

    private func crater(_ pen: SketchPen, at c: CGPoint, r: CGFloat) {
        pen.ellipse(c, r, r * 0.34, Cosmos.craterRim)
        pen.ellipse(CGPoint(x: c.x, y: c.y + r * 0.03), r * 0.82, r * 0.25, Cosmos.craterIn)
        pen.ellipse(CGPoint(x: c.x + r * 0.15, y: c.y + r * 0.08), r * 0.5, r * 0.12, Cosmos.groundDeep.opacity(0.6))
    }

    private func crystals(_ pen: SketchPen, foot b: CGPoint) {
        let s = f.s
        for (dx, ht, tilt, color) in [(-0.03, 0.10, -14.0, Color(red: 0.62, green: 0.50, blue: 0.98)),
                                      (0.025, 0.14, 8.0, Color(red: 0.42, green: 0.86, blue: 0.98)),
                                      (0.06, 0.075, 24.0, Color(red: 0.93, green: 0.55, blue: 0.95)),
                                      (-0.065, 0.06, -30.0, Color(red: 0.42, green: 0.86, blue: 0.98))]
            as [(CGFloat, CGFloat, Double, Color)] {
            pen.local(at: CGPoint(x: b.x + dx * s, y: b.y), rotation: .degrees(tilt)) { local in
                let w = s * 0.022, h = s * ht
                let body = SceneryPath.polygon([CGPoint(x: -w, y: 0), CGPoint(x: -w, y: -h * 0.78), CGPoint(x: 0, y: -h),
                                                CGPoint(x: w, y: -h * 0.78), CGPoint(x: w, y: 0)])
                local.glow(CGPoint(x: 0, y: -h * 0.5), h * 0.8, color, strength: 0.25)
                local.fill(body, color)
                local.fill(SceneryPath.polygon([CGPoint(x: -w, y: 0), CGPoint(x: -w, y: -h * 0.78), CGPoint(x: 0, y: -h),
                                                CGPoint(x: -w * 0.2, y: -h * 0.7), CGPoint(x: -w * 0.2, y: 0)]),
                           Color.white.opacity(0.35))
            }
        }
    }

    private func rocket(_ pen: SketchPen, foot b: CGPoint) {
        let ht = rocketHeight, wd = ht * 0.3
        // Ailerons.
        for side: CGFloat in [-1, 1] {
            pen.fill(SceneryPath.polygon([CGPoint(x: b.x + side * wd * 0.45, y: b.y - ht * 0.42),
                                          CGPoint(x: b.x + side * wd * 0.95, y: b.y - ht * 0.12),
                                          CGPoint(x: b.x + side * wd * 0.95, y: b.y),
                                          CGPoint(x: b.x + side * wd * 0.45, y: b.y - ht * 0.1)]), Cosmos.rocketRed)
        }
        // Fuselage en ogive.
        var hull = Path()
        hull.move(to: CGPoint(x: b.x - wd / 2, y: b.y - ht * 0.06))
        hull.addLine(to: CGPoint(x: b.x - wd / 2, y: b.y - ht * 0.62))
        hull.addQuadCurve(to: CGPoint(x: b.x, y: b.y - ht), control: CGPoint(x: b.x - wd / 2, y: b.y - ht * 0.9))
        hull.addQuadCurve(to: CGPoint(x: b.x + wd / 2, y: b.y - ht * 0.62), control: CGPoint(x: b.x + wd / 2, y: b.y - ht * 0.9))
        hull.addLine(to: CGPoint(x: b.x + wd / 2, y: b.y - ht * 0.06))
        hull.closeSubpath()
        pen.fill(hull, Cosmos.rocket)
        pen.clipped(to: hull) { inside in
            inside.fill(Path(CGRect(x: b.x - wd, y: b.y - ht * 1.1, width: wd * 2, height: ht * 0.3)), Cosmos.rocketRed)
            inside.fill(Path(CGRect(x: b.x + wd * 0.18, y: b.y - ht, width: wd, height: ht)), Color.black.opacity(0.07))
        }
        // Hublot.
        let port = CGPoint(x: b.x, y: b.y - ht * 0.5)
        pen.circle(port, wd * 0.3, Color(red: 0.78, green: 0.80, blue: 0.9))
        pen.circle(port, wd * 0.22, Color(red: 0.35, green: 0.62, blue: 0.98))
        pen.circle(CGPoint(x: port.x - wd * 0.07, y: port.y - wd * 0.07), wd * 0.07, Color.white.opacity(0.8))
        // Tuyère.
        pen.rect(CGRect(x: b.x - wd * 0.28, y: b.y - ht * 0.07, width: wd * 0.56, height: ht * 0.07),
                 Color(red: 0.45, green: 0.45, blue: 0.55), corner: wd * 0.06)
    }
}

/// Étincelle à quatre branches (étoiles qui scintillent).
struct SparkleShape: Shape {
    func path(in r: CGRect) -> Path {
        let c = CGPoint(x: r.midX, y: r.midY), a = r.width / 2, b = r.width * 0.12
        var p = Path()
        p.move(to: CGPoint(x: c.x, y: c.y - a))
        p.addQuadCurve(to: CGPoint(x: c.x + a, y: c.y), control: CGPoint(x: c.x + b, y: c.y - b))
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y + a), control: CGPoint(x: c.x + b, y: c.y + b))
        p.addQuadCurve(to: CGPoint(x: c.x - a, y: c.y), control: CGPoint(x: c.x - b, y: c.y + b))
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y - a), control: CGPoint(x: c.x - b, y: c.y - b))
        p.closeSubpath()
        return p
    }
}

/// La comète : tête lumineuse à gauche, queue qui s'efface vers la droite
/// (la vue est tournée dans le sens de sa course).
struct CometView: View, Equatable {
    let length: CGFloat
    let head: CGFloat

    var body: some View {
        Canvas { ctx, sz in
            let y = sz.height / 2
            var tail = Path()
            tail.move(to: CGPoint(x: head, y: y - head * 0.9))
            tail.addQuadCurve(to: CGPoint(x: length, y: y), control: CGPoint(x: length * 0.5, y: y - head * 1.1))
            tail.addQuadCurve(to: CGPoint(x: head, y: y + head * 0.9), control: CGPoint(x: length * 0.5, y: y + head * 1.1))
            tail.closeSubpath()
            ctx.fill(tail, with: .linearGradient(Gradient(colors: [Color(red: 0.75, green: 0.95, blue: 1.0).opacity(0.9),
                                                                   Color(red: 0.75, green: 0.95, blue: 1.0).opacity(0)]),
                                                 startPoint: CGPoint(x: head, y: y), endPoint: CGPoint(x: length, y: y)))
            let c = CGPoint(x: head, y: y)
            ctx.fill(SceneryPath.circle(c, head * 2.2),
                     with: .radialGradient(Gradient(colors: [Color.white.opacity(0.7), Color.white.opacity(0)]),
                                           center: c, startRadius: 0, endRadius: head * 2.2))
            ctx.fill(SceneryPath.circle(c, head), with: .color(.white))
        }
        .frame(width: length, height: head * 4.4)
    }
}
#endif
