// WorldSeasideScene.swift — la mer : phare rayé, voilier sur l'horizon,
// vagues, mouettes, et une plage de sable (château, seau, parasol, étoiles de mer).
//
// Mouvement : les vagues ondulent, le voilier se balance, l'écume lèche le
// sable, les mouettes planent, les nuages dérivent, le phare luit.

#if canImport(SwiftUI)
import SwiftUI

private enum Beach {
    static let skyTop = Color(red: 0.38, green: 0.72, blue: 0.97)
    static let skyLow = Color(red: 0.87, green: 0.96, blue: 1.0)
    static let seaFar = Color(red: 0.16, green: 0.49, blue: 0.83)
    static let seaMid = Color(red: 0.24, green: 0.70, blue: 0.88)
    static let seaNear = Color(red: 0.42, green: 0.85, blue: 0.88)
    static let foam = Color.white
    static let wetSand = Color(red: 0.93, green: 0.80, blue: 0.57)
    static let sand = Color(red: 0.99, green: 0.89, blue: 0.64)
    static let sandDeep = Color(red: 0.97, green: 0.82, blue: 0.55)
    static let castle = Color(red: 0.93, green: 0.76, blue: 0.47)
    static let castleShade = Color(red: 0.85, green: 0.67, blue: 0.40)
    static let red = Color(red: 0.91, green: 0.30, blue: 0.28)
    static let rock = Color(red: 0.55, green: 0.52, blue: 0.56)
    static let rockLight = Color(red: 0.66, green: 0.63, blue: 0.67)
    static let gull = Color(red: 0.36, green: 0.40, blue: 0.50)
}

struct SeasideScene: View {
    let f: SceneryFrame

    static let clouds = [
        SceneryDriftingCloud(id: 0, y: 0.14, width: 0.24, period: 180, phase: 0.36),
        SceneryDriftingCloud(id: 1, y: 0.26, width: 0.15, period: 230, phase: 0.62, opacity: 0.85),
    ]

    private struct Gull: Identifiable {
        let id: Int
        let y: CGFloat, period: Double, phase: Double, size: CGFloat
    }

    private static let gulls = [
        Gull(id: 0, y: 0.17, period: 70, phase: 0.18, size: 0.05),
        Gull(id: 1, y: 0.21, period: 85, phase: 0.28, size: 0.035),
        Gull(id: 2, y: 0.13, period: 95, phase: 0.75, size: 0.04),
    ]

    private var sunCenter: CGPoint { f.p(0.86, 0.20) }
    private var sunRadius: CGFloat { f.s * 0.064 }
    private var lighthouse: CGPoint { f.p(0.085, 0.685) }
    private var lamp: CGPoint { CGPoint(x: lighthouse.x, y: lighthouse.y - f.s * 0.275) }
    private var horizon: CGFloat { f.y(0.57) }

    var body: some View {
        ZStack {
            Canvas { ctx, _ in back(SketchPen(ctx: ctx)) }
            SceneryAmbient { t in
                ZStack {
                    SunRays(radius: sunRadius, color: EveilPalette.sun).equatable()
                        .rotationEffect(.degrees(-t * 360 / 100))
                        .position(sunCenter)
                    // Le phare luit doucement.
                    Circle()
                        .fill(RadialGradient(colors: [Color(red: 1, green: 0.95, blue: 0.6).opacity(0.9),
                                                      Color(red: 1, green: 0.9, blue: 0.5).opacity(0)],
                                             center: .center, startRadius: 0, endRadius: f.s * 0.07))
                        .frame(width: f.s * 0.14, height: f.s * 0.14)
                        .opacity(0.55 + 0.45 * Double(SceneryMotion.swing(t, period: 3.2)))
                        .position(lamp)
                    ForEach(Self.gulls) { g in
                        GullShape()
                            .stroke(Beach.gull, style: StrokeStyle(lineWidth: f.s * g.size * 0.12, lineCap: .round,
                                                                   lineJoin: .round))
                            .frame(width: f.s * g.size, height: f.s * g.size * 0.4)
                            .scaleEffect(x: 1, y: 0.7 + 0.3 * SceneryMotion.swing(t, period: 1.4, phase: g.phase))
                            .position(x: SceneryMotion.loop(t, period: g.period, phase: g.phase) * (f.w + f.s * 0.2)
                                         - f.s * 0.1,
                                      y: f.y(g.y) + f.s * 0.01 * SceneryMotion.swing(t, period: 6, phase: g.phase))
                    }
                    Sailboat(size: f.s * 0.11).equatable()
                        .rotationEffect(.degrees(3 * Double(SceneryMotion.swing(t, period: 3.6))), anchor: .bottom)
                        .offset(y: f.s * 0.004 * SceneryMotion.swing(t, period: 3.6, phase: 0.25))
                        .position(x: f.x(0.875), y: horizon + f.s * 0.012 - f.s * 0.055)
                    ForEach(0..<3, id: \.self) { row in
                        let r = CGFloat(row)
                        WaveRow(width: f.w, spacing: f.s * (0.075 + r * 0.02), crest: f.s * (0.016 + r * 0.006),
                                opacity: 0.45 + Double(r) * 0.12).equatable()
                            .offset(x: f.s * 0.02 * SceneryMotion.swing(t, period: 7 + Double(r) * 1.5, phase: Double(r) * 0.3),
                                    y: f.s * 0.004 * SceneryMotion.swing(t, period: 2.8 + Double(r) * 0.4))
                            .position(x: f.w / 2, y: f.y(0.603 + 0.04 * r))
                    }
                    Foam(width: f.w, height: f.s * 0.03).equatable()
                        .offset(x: f.s * 0.015 * SceneryMotion.swing(t, period: 9),
                                y: f.s * 0.007 * SceneryMotion.swing(t, period: 4.2))
                        .position(x: f.w / 2, y: f.y(0.716))
                }
                .frame(width: f.w, height: f.h)
            }
            SceneryCloudLayer(frame: f, clouds: Self.clouds)
            Canvas { ctx, _ in front(SketchPen(ctx: ctx)) }
        }
    }

    // MARK: Fond : ciel, soleil, mer, phare

    private func back(_ pen: SketchPen) {
        let s = f.s
        pen.fill(Path(CGRect(x: 0, y: 0, width: f.w, height: horizon + 1)), top: 0, bottom: horizon,
                 [Beach.skyTop, Beach.skyLow])
        pen.glow(sunCenter, sunRadius * 3.2, EveilPalette.sun, strength: 0.45)
        pen.circle(sunCenter, sunRadius, EveilPalette.sun)
        pen.circle(CGPoint(x: sunCenter.x - sunRadius * 0.3, y: sunCenter.y - sunRadius * 0.3), sunRadius * 0.45,
                   Color.white.opacity(0.25))
        pen.fill(Path(CGRect(x: 0, y: horizon, width: f.w, height: f.h - horizon)),
                 top: horizon, bottom: f.y(0.72), [Beach.seaFar, Beach.seaMid, Beach.seaNear])
        pen.fill(Path(CGRect(x: 0, y: horizon, width: f.w, height: s * 0.004)), Color.white.opacity(0.5))
        // Reflets du soleil sur l'eau.
        for k in 0..<5 {
            let y = horizon + s * (0.012 + CGFloat(k) * 0.011)
            let half = s * (0.05 - CGFloat(k) * 0.006)
            pen.stroke(Path { p in
                p.move(to: CGPoint(x: sunCenter.x - half, y: y)); p.addLine(to: CGPoint(x: sunCenter.x + half, y: y))
            }, Color(red: 1, green: 0.95, blue: 0.7).opacity(0.55), width: s * 0.005)
        }
        // Sable mouillé, sous l'écume.
        pen.fill(Path(CGRect(x: 0, y: f.y(0.716), width: f.w, height: f.y(0.05))), Beach.wetSand)
        lighthouseTower(pen)
    }

    private func lighthouseTower(_ pen: SketchPen) {
        let s = f.s, b = lighthouse
        // Rochers.
        for (dx, dy, r) in [(-0.05, 0.0, 0.05), (0.04, 0.008, 0.042), (-0.005, -0.01, 0.06), (0.075, 0.018, 0.03)]
            as [(CGFloat, CGFloat, CGFloat)] {
            let c = CGPoint(x: b.x + dx * s, y: b.y + dy * s)
            pen.ellipse(c, s * r, s * r * 0.62, Beach.rock)
            pen.ellipse(CGPoint(x: c.x - s * r * 0.25, y: c.y - s * r * 0.22), s * r * 0.5, s * r * 0.25, Beach.rockLight)
        }
        let ht = s * 0.24, bottom = b.y - s * 0.02
        let tower = SceneryPath.polygon([CGPoint(x: b.x - s * 0.042, y: bottom), CGPoint(x: b.x - s * 0.03, y: bottom - ht),
                                         CGPoint(x: b.x + s * 0.03, y: bottom - ht), CGPoint(x: b.x + s * 0.042, y: bottom)])
        pen.fill(tower, Color.white)
        pen.clipped(to: tower) { inside in
            for k in 0..<4 {
                let y0 = bottom - ht * (CGFloat(k) * 0.25 + 0.12)
                inside.fill(Path(CGRect(x: b.x - s * 0.05, y: y0 - ht * 0.125, width: s * 0.1, height: ht * 0.125)), Beach.red)
            }
            inside.fill(Path(CGRect(x: b.x + s * 0.012, y: bottom - ht, width: s * 0.05, height: ht)), Color.black.opacity(0.08))
        }
        // Galerie, lanterne, coupole.
        let top = bottom - ht
        pen.rect(CGRect(x: b.x - s * 0.045, y: top - s * 0.008, width: s * 0.09, height: s * 0.012), Color(white: 0.25),
                 corner: s * 0.004)
        pen.rect(CGRect(x: b.x - s * 0.024, y: top - s * 0.045, width: s * 0.048, height: s * 0.037),
                 Color(red: 1, green: 0.93, blue: 0.55), corner: s * 0.006)
        pen.stroke(Path { p in
            p.move(to: CGPoint(x: b.x, y: top - s * 0.045)); p.addLine(to: CGPoint(x: b.x, y: top - s * 0.008))
        }, Color(white: 0.3), width: s * 0.004)
        var dome = Path()
        dome.addArc(center: CGPoint(x: b.x, y: top - s * 0.045), radius: s * 0.03, startAngle: .degrees(180),
                    endAngle: .degrees(0), clockwise: false)
        dome.closeSubpath()
        pen.fill(dome, Beach.red)
        pen.circle(CGPoint(x: b.x, y: top - s * 0.078), s * 0.007, Beach.red)
        // Porte.
        var door = Path()
        door.addArc(center: CGPoint(x: b.x, y: bottom - s * 0.03), radius: s * 0.012, startAngle: .degrees(180),
                    endAngle: .degrees(0), clockwise: false)
        door.addLine(to: CGPoint(x: b.x + s * 0.012, y: bottom))
        door.addLine(to: CGPoint(x: b.x - s * 0.012, y: bottom))
        door.closeSubpath()
        pen.fill(door, Color(red: 0.25, green: 0.33, blue: 0.55))
    }

    // MARK: Premier plan : la plage

    private func front(_ pen: SketchPen) {
        let s = f.s
        let beach = SceneryPath.ridge([CGPoint(x: -10, y: f.y(0.738)), f.p(0.3, 0.733), f.p(0.62, 0.740),
                                       CGPoint(x: f.w + 10, y: f.y(0.734))], bottom: f.h + 2)
        pen.fill(beach, top: f.y(0.73), bottom: f.h, [Beach.sand, Beach.sandDeep])
        var rng = SceneryRandom(seed: 0xBEAC)
        for _ in 0..<30 {
            let x = rng.range(0, 1), y = rng.range(0.78, 0.99)
            guard !SceneryFrame.isButtonZone(x, y) else { continue }
            pen.circle(f.p(x, y), s * rng.range(0.002, 0.004), Beach.castleShade.opacity(0.6))
        }
        sandcastle(pen, base: f.p(0.11, 0.875))
        bucket(pen, base: CGPoint(x: f.x(0.11) + s * 0.1, y: f.y(0.885)))
        parasol(pen, foot: f.p(0.87, 0.93))
        starfish(pen, at: f.p(0.24, 0.965), r: s * 0.026, color: Color(red: 1, green: 0.55, blue: 0.35))
        starfish(pen, at: f.p(0.74, 0.955), r: s * 0.021, color: Color(red: 0.98, green: 0.45, blue: 0.55))
        shell(pen, at: f.p(0.05, 0.96), r: s * 0.018)
        shell(pen, at: f.p(0.62, 0.975), r: s * 0.014)
        shell(pen, at: f.p(0.95, 0.80), r: s * 0.013)
    }

    private func sandcastle(_ pen: SketchPen, base b: CGPoint) {
        let s = f.s
        let wall = CGRect(x: b.x - s * 0.07, y: b.y - s * 0.055, width: s * 0.14, height: s * 0.055)
        pen.rect(wall, Beach.castle, corner: s * 0.006)
        for (dx, ht) in [(-0.055, 0.1), (0.055, 0.1), (0.0, 0.135)] as [(CGFloat, CGFloat)] {
            let tower = CGRect(x: b.x + dx * s - s * 0.024, y: b.y - s * ht, width: s * 0.048, height: s * ht)
            pen.rect(tower, Beach.castle, corner: s * 0.005)
            pen.rect(CGRect(x: tower.maxX - s * 0.012, y: tower.minY, width: s * 0.012, height: tower.height),
                     Beach.castleShade)
            for k in 0..<3 {
                pen.rect(CGRect(x: tower.minX + CGFloat(k) * s * 0.018 - s * 0.001, y: tower.minY - s * 0.012,
                                width: s * 0.013, height: s * 0.014), Beach.castle, corner: s * 0.003)
            }
        }
        // Porte et drapeau.
        var door = Path()
        door.addArc(center: CGPoint(x: b.x, y: b.y - s * 0.022), radius: s * 0.014, startAngle: .degrees(180),
                    endAngle: .degrees(0), clockwise: false)
        door.addLine(to: CGPoint(x: b.x + s * 0.014, y: b.y))
        door.addLine(to: CGPoint(x: b.x - s * 0.014, y: b.y))
        door.closeSubpath()
        pen.fill(door, Beach.castleShade)
        let mast = CGPoint(x: b.x, y: b.y - s * 0.147)
        pen.stroke(Path { p in p.move(to: mast); p.addLine(to: CGPoint(x: mast.x, y: mast.y - s * 0.05)) },
                   Color(white: 0.35), width: s * 0.004)
        pen.fill(SceneryPath.polygon([CGPoint(x: mast.x, y: mast.y - s * 0.05), CGPoint(x: mast.x + s * 0.035, y: mast.y - s * 0.04),
                                      CGPoint(x: mast.x, y: mast.y - s * 0.03)]), Beach.red)
    }

    private func bucket(_ pen: SketchPen, base b: CGPoint) {
        let s = f.s
        let body = SceneryPath.polygon([CGPoint(x: b.x - s * 0.028, y: b.y - s * 0.055), CGPoint(x: b.x + s * 0.028, y: b.y - s * 0.055),
                                        CGPoint(x: b.x + s * 0.021, y: b.y), CGPoint(x: b.x - s * 0.021, y: b.y)])
        pen.fill(body, Color(red: 0.25, green: 0.58, blue: 0.95))
        pen.stroke(body, Color(red: 0.25, green: 0.58, blue: 0.95), width: s * 0.006)
        pen.ellipse(CGPoint(x: b.x, y: b.y - s * 0.055), s * 0.029, s * 0.008, Color(red: 0.18, green: 0.45, blue: 0.82))
        var handle = Path()
        handle.addArc(center: CGPoint(x: b.x, y: b.y - s * 0.052), radius: s * 0.026, startAngle: .degrees(200),
                      endAngle: .degrees(340), clockwise: false)
        pen.stroke(handle, Color(white: 0.4), width: s * 0.004)
        // Pelle rouge plantée à côté.
        pen.local(at: CGPoint(x: b.x + s * 0.05, y: b.y), rotation: .degrees(18)) { sp in
            sp.rect(CGRect(x: -s * 0.004, y: -s * 0.07, width: s * 0.008, height: s * 0.06), Color(red: 1, green: 0.8, blue: 0.2),
                    corner: s * 0.003)
            sp.fill(Path(roundedRect: CGRect(x: -s * 0.014, y: -s * 0.016, width: s * 0.028, height: s * 0.03),
                         cornerRadius: s * 0.01), Beach.red)
        }
    }

    private func parasol(_ pen: SketchPen, foot b: CGPoint) {
        let s = f.s
        // Serviette rayée.
        let towel = CGRect(x: b.x - s * 0.12, y: b.y - s * 0.004, width: s * 0.13, height: s * 0.035)
        pen.rect(towel, Color.white, corner: s * 0.006)
        pen.clipped(to: Path(roundedRect: towel, cornerRadius: s * 0.006)) { inside in
            for k in 0..<4 {
                inside.fill(Path(CGRect(x: towel.minX + CGFloat(k) * s * 0.034, y: towel.minY, width: s * 0.017,
                                        height: towel.height)), Color(red: 0.35, green: 0.6, blue: 0.98))
            }
        }
        let top = CGPoint(x: b.x, y: b.y - s * 0.16)
        pen.stroke(Path { p in p.move(to: b); p.addLine(to: top) }, Color(white: 0.95), width: s * 0.008)
        // Toile en dôme, quartiers rouges et blancs.
        let r = s * 0.11
        var canopy = Path()
        canopy.addArc(center: top, radius: r, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        canopy.addQuadCurve(to: CGPoint(x: top.x - r, y: top.y), control: CGPoint(x: top.x, y: top.y - r * 0.2))
        pen.fill(canopy, Color.white)
        pen.clipped(to: canopy) { inside in
            for k in stride(from: 0, to: 6, by: 2) {
                let a0 = Angle.degrees(180 + Double(k) * 30), a1 = Angle.degrees(180 + Double(k + 1) * 30)
                var wedge = Path()
                wedge.move(to: CGPoint(x: top.x, y: top.y - r * 0.1))
                wedge.addArc(center: top, radius: r * 1.2, startAngle: a0, endAngle: a1, clockwise: false)
                wedge.closeSubpath()
                inside.fill(wedge, Beach.red)
            }
        }
        pen.circle(CGPoint(x: top.x, y: top.y - r), s * 0.008, Beach.red)
    }

    private func starfish(_ pen: SketchPen, at c: CGPoint, r: CGFloat, color: Color) {
        let star = SceneryPath.star(c, outer: r, inner: r * 0.45, branches: 5, rotation: 0.3)
        pen.fill(star, color)
        pen.stroke(star, color, width: r * 0.25)
        for i in 0..<5 {
            let a = -CGFloat.pi / 2 + 0.3 + CGFloat(i) * 2 * .pi / 5
            pen.circle(CGPoint(x: c.x + cos(a) * r * 0.5, y: c.y + sin(a) * r * 0.5), r * 0.08, Color.white.opacity(0.7))
        }
    }

    private func shell(_ pen: SketchPen, at c: CGPoint, r: CGFloat) {
        var fan = Path()
        fan.move(to: CGPoint(x: c.x, y: c.y + r * 0.6))
        fan.addArc(center: CGPoint(x: c.x, y: c.y + r * 0.2), radius: r, startAngle: .degrees(200), endAngle: .degrees(-20),
                   clockwise: false)
        fan.closeSubpath()
        pen.fill(fan, Color(red: 1, green: 0.78, blue: 0.80))
        var ribs = Path()
        for k in 0..<5 {
            let a = Angle.degrees(210 + Double(k) * 30).radians
            ribs.move(to: CGPoint(x: c.x, y: c.y + r * 0.6))
            ribs.addLine(to: CGPoint(x: c.x + CGFloat(cos(a)) * r * 0.9, y: c.y + r * 0.2 + CGFloat(sin(a)) * r * 0.9))
        }
        pen.stroke(ribs, Color(red: 0.93, green: 0.58, blue: 0.62), width: r * 0.08)
    }
}

/// Mouette de loin : deux ailes arquées.
struct GullShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.35))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.maxY * 0.9 + r.minY * 0.1),
                       control: CGPoint(x: r.minX + r.width * 0.3, y: r.minY - r.height * 0.1))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.35),
                       control: CGPoint(x: r.maxX - r.width * 0.3, y: r.minY - r.height * 0.1))
        return p
    }
}

/// Un rang de crêtes d'écume : petits arcs blancs réguliers (le rang glisse d'avant en arrière).
struct WaveRow: View, Equatable {
    let width: CGFloat
    let spacing: CGFloat
    let crest: CGFloat
    let opacity: Double

    var body: some View {
        Canvas { ctx, size in
            var p = Path()
            var x: CGFloat = -spacing
            var odd = false
            while x < size.width + spacing {
                let c = CGPoint(x: x + (odd ? spacing * 0.5 : 0), y: size.height / 2)
                p.move(to: CGPoint(x: c.x - crest, y: c.y + crest * 0.2))
                p.addQuadCurve(to: CGPoint(x: c.x + crest, y: c.y + crest * 0.2), control: CGPoint(x: c.x, y: c.y - crest * 0.7))
                x += spacing
                odd.toggle()
            }
            ctx.stroke(p, with: .color(Color.white.opacity(opacity)),
                       style: StrokeStyle(lineWidth: max(1.5, crest * 0.32), lineCap: .round))
        }
        .frame(width: width + spacing * 2, height: crest * 2.5)
        .allowsHitTesting(false)
    }
}

/// L'écume au bord de l'eau : une bande blanche festonnée.
struct Foam: View, Equatable {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Canvas { ctx, size in
            var p = Path()
            let bump = height * 0.9
            p.move(to: CGPoint(x: 0, y: size.height * 0.35))
            var x: CGFloat = 0
            while x < size.width {
                p.addQuadCurve(to: CGPoint(x: x + bump, y: size.height * 0.35),
                               control: CGPoint(x: x + bump / 2, y: size.height * 0.35 + height * 0.45))
                x += bump
            }
            p.addLine(to: CGPoint(x: size.width, y: 0))
            p.addLine(to: CGPoint(x: 0, y: 0))
            p.closeSubpath()
            ctx.fill(p, with: .color(Color.white.opacity(0.92)))
        }
        .frame(width: width + height * 4, height: height)
        .allowsHitTesting(false)
    }
}

/// Le voilier de l'horizon : coque rouge, grand-voile rayée, fanion.
struct Sailboat: View, Equatable {
    let size: CGFloat

    var body: some View {
        Canvas { ctx, sz in
            let s = size, cx = sz.width / 2, bottom = sz.height
            var hull = Path()
            hull.move(to: CGPoint(x: cx - s * 0.45, y: bottom - s * 0.2))
            hull.addLine(to: CGPoint(x: cx + s * 0.5, y: bottom - s * 0.2))
            hull.addLine(to: CGPoint(x: cx + s * 0.34, y: bottom - s * 0.02))
            hull.addLine(to: CGPoint(x: cx - s * 0.32, y: bottom - s * 0.02))
            hull.closeSubpath()
            ctx.fill(hull, with: .color(Color(red: 0.91, green: 0.30, blue: 0.28)))
            ctx.fill(Path(CGRect(x: cx - s * 0.42, y: bottom - s * 0.2, width: s * 0.9, height: s * 0.04)),
                     with: .color(Color.white.opacity(0.9)))
            ctx.fill(Path(CGRect(x: cx - s * 0.015, y: bottom - s * 0.98, width: s * 0.03, height: s * 0.8)),
                     with: .color(Color(white: 0.35)))
            let sail = SceneryPath.polygon([CGPoint(x: cx + s * 0.03, y: bottom - s * 0.95), CGPoint(x: cx + s * 0.42, y: bottom - s * 0.26),
                                            CGPoint(x: cx + s * 0.03, y: bottom - s * 0.26)])
            ctx.fill(sail, with: .color(.white))
            var stripes = ctx
            stripes.clip(to: sail)
            stripes.fill(Path(CGRect(x: cx, y: bottom - s * 0.55, width: s * 0.5, height: s * 0.1)),
                         with: .color(Color(red: 0.25, green: 0.55, blue: 0.95)))
            let jib = SceneryPath.polygon([CGPoint(x: cx - s * 0.03, y: bottom - s * 0.85), CGPoint(x: cx - s * 0.03, y: bottom - s * 0.26),
                                           CGPoint(x: cx - s * 0.36, y: bottom - s * 0.26)])
            ctx.fill(jib, with: .color(Color(red: 1, green: 0.97, blue: 0.9)))
            ctx.fill(SceneryPath.polygon([CGPoint(x: cx, y: bottom - s * 0.98), CGPoint(x: cx + s * 0.16, y: bottom - s * 0.93),
                                          CGPoint(x: cx, y: bottom - s * 0.88)]),
                     with: .color(Color(red: 1, green: 0.8, blue: 0.2)))
        }
        .frame(width: size * 1.1, height: size)
    }
}
#endif
