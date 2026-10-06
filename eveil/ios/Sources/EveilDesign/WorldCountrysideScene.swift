// WorldCountrysideScene.swift — la campagne : ciel bleu, soleil, collines,
// grange rouge et moulin à vent (le décor d'accueil, en plus vivant).
//
// Mouvement : les nuages dérivent, les rayons du soleil tournent lentement,
// les ailes du moulin tournent.

#if canImport(SwiftUI)
import SwiftUI

private enum Farm {
    static let skyTop = EveilPalette.sky
    static let skyLow = EveilPalette.skyLight
    static let farHill = Color(red: 0.69, green: 0.86, blue: 0.52)
    static let farHillLight = Color(red: 0.76, green: 0.90, blue: 0.60)
    static let nearHill = Color(red: 0.49, green: 0.75, blue: 0.37)
    static let grass = EveilPalette.grass
    static let grassDeep = Color(red: 0.47, green: 0.73, blue: 0.34)
    static let grassEdge = Color(red: 0.64, green: 0.85, blue: 0.46)
    static let tuft = Color(red: 0.40, green: 0.66, blue: 0.29)
    static let barn = Color(red: 0.85, green: 0.27, blue: 0.24)
    static let barnShade = Color(red: 0.70, green: 0.19, blue: 0.18)
    static let roof = Color(red: 0.42, green: 0.27, blue: 0.27)
    static let trim = Color(red: 1.0, green: 0.97, blue: 0.92)
    static let wood = Color(red: 0.62, green: 0.42, blue: 0.27)
    static let leaf = Color(red: 0.30, green: 0.62, blue: 0.30)
    static let leafLight = Color(red: 0.45, green: 0.74, blue: 0.38)
    static let mill = Color(red: 0.99, green: 0.95, blue: 0.87)
    static let millShade = Color(red: 0.90, green: 0.84, blue: 0.74)
    static let millCap = Color(red: 0.86, green: 0.33, blue: 0.27)
    static let hay = Color(red: 0.98, green: 0.80, blue: 0.36)
    static let hayDark = Color(red: 0.88, green: 0.66, blue: 0.24)
}

struct CountrysideScene: View {
    let f: SceneryFrame

    static let clouds = [
        SceneryDriftingCloud(id: 0, y: 0.15, width: 0.27, period: 170, phase: 0.47),
        SceneryDriftingCloud(id: 1, y: 0.235, width: 0.19, period: 210, phase: 0.83, opacity: 0.85),
        SceneryDriftingCloud(id: 2, y: 0.125, width: 0.15, period: 190, phase: 0.72, opacity: 0.8),
    ]

    private var sunCenter: CGPoint { f.p(0.13, 0.19) }
    private var sunRadius: CGFloat { f.s * 0.068 }
    private var millBase: CGPoint { f.p(0.885, 0.625) }
    private var millHeight: CGFloat { f.s * 0.17 }
    private var hub: CGPoint { CGPoint(x: millBase.x, y: millBase.y - millHeight - f.s * 0.004) }

    var body: some View {
        ZStack {
            Canvas { ctx, _ in back(SketchPen(ctx: ctx)) }
            SceneryAmbient { t in
                ZStack {
                    SunRays(radius: sunRadius, color: EveilPalette.sun).equatable()
                        .rotationEffect(.degrees(t * 360 / 90))
                        .scaleEffect(1 + 0.04 * SceneryMotion.swing(t, period: 5))
                        .position(sunCenter)
                    WindmillSails(radius: f.s * 0.105).equatable()
                        .rotationEffect(.degrees(t * 360 / 26))
                        .position(hub)
                }
                .frame(width: f.w, height: f.h)
            }
            SceneryCloudLayer(frame: f, clouds: Self.clouds)
            Canvas { ctx, _ in front(SketchPen(ctx: ctx)) }
        }
    }

    // MARK: Fond : ciel, soleil, collines lointaines, moulin

    private func back(_ pen: SketchPen) {
        let sky = Path(CGRect(x: 0, y: 0, width: f.w, height: f.h))
        pen.fill(sky, top: 0, bottom: f.y(0.72), [Farm.skyTop, Farm.skyLow])
        pen.glow(sunCenter, sunRadius * 3.2, EveilPalette.sun, strength: 0.42)
        pen.circle(sunCenter, sunRadius, EveilPalette.sun)
        pen.circle(CGPoint(x: sunCenter.x - sunRadius * 0.3, y: sunCenter.y - sunRadius * 0.3), sunRadius * 0.45,
                   Color.white.opacity(0.25))

        let far = SceneryPath.ridge([f.p(-0.05, 0.625), f.p(0.16, 0.585), f.p(0.40, 0.628), f.p(0.62, 0.597),
                                     f.p(0.86, 0.622), f.p(1.05, 0.600)], bottom: f.h)
        pen.fill(far, top: f.y(0.58), bottom: f.y(0.72), [Farm.farHillLight, Farm.farHill])
        // Haies et bosquets lointains, posés sur la crête.
        for (fx, fy, count) in [(0.27, 0.614, 4), (0.50, 0.622, 3), (0.66, 0.603, 5)] as [(CGFloat, CGFloat, Int)] {
            for k in 0..<count {
                let r = f.s * (k.isMultiple(of: 2) ? 0.014 : 0.011)
                pen.circle(CGPoint(x: f.x(fx) + CGFloat(k) * f.s * 0.019, y: f.y(fy) - r * 0.5), r,
                           Farm.leafLight.opacity(0.95))
            }
        }
        windmillTower(pen)
    }

    private func windmillTower(_ pen: SketchPen) {
        let b = millBase, hgt = millHeight, s = f.s
        var tower = Path()
        tower.move(to: CGPoint(x: b.x - s * 0.042, y: b.y))
        tower.addLine(to: CGPoint(x: b.x - s * 0.026, y: b.y - hgt))
        tower.addLine(to: CGPoint(x: b.x + s * 0.026, y: b.y - hgt))
        tower.addLine(to: CGPoint(x: b.x + s * 0.042, y: b.y))
        tower.closeSubpath()
        pen.fill(tower, Farm.mill)
        var shade = Path()
        shade.move(to: CGPoint(x: b.x + s * 0.012, y: b.y))
        shade.addLine(to: CGPoint(x: b.x + s * 0.008, y: b.y - hgt))
        shade.addLine(to: CGPoint(x: b.x + s * 0.026, y: b.y - hgt))
        shade.addLine(to: CGPoint(x: b.x + s * 0.042, y: b.y))
        shade.closeSubpath()
        pen.fill(shade, Farm.millShade)
        // Chapeau rouge, porte et lucarne.
        pen.fill(Path(ellipseIn: CGRect(x: b.x - s * 0.036, y: b.y - hgt - s * 0.03, width: s * 0.072, height: s * 0.05)),
                 Farm.millCap)
        pen.rect(CGRect(x: b.x - s * 0.036, y: b.y - hgt - s * 0.006, width: s * 0.072, height: s * 0.014),
                 Farm.millCap, corner: s * 0.005)
        pen.rect(CGRect(x: b.x - s * 0.012, y: b.y - s * 0.034, width: s * 0.024, height: s * 0.034),
                 Farm.wood, corner: s * 0.01)
        pen.circle(CGPoint(x: b.x, y: b.y - hgt * 0.6), s * 0.009, Farm.wood.opacity(0.8))
    }

    // MARK: Premier plan : collines, grange, arbres, clôture, prairie

    private func front(_ pen: SketchPen) {
        let s = f.s
        let near = SceneryPath.ridge([f.p(-0.05, 0.70), f.p(0.14, 0.668), f.p(0.36, 0.712), f.p(0.60, 0.698),
                                      f.p(0.83, 0.664), f.p(1.05, 0.690)], bottom: f.h)
        pen.fill(near, top: f.y(0.66), bottom: f.y(0.76), [Farm.nearHill.opacity(0.92), Farm.nearHill])

        SceneryMotif.roundTree(pen, base: f.p(0.265, 0.722), height: s * 0.12,
                               leaf: Farm.leaf, leafLight: Farm.leafLight, trunk: Farm.wood)
        barn(pen, base: f.p(0.115, 0.742))
        hayBale(pen, at: CGPoint(x: f.x(0.115) + s * 0.145, y: f.y(0.742) - s * 0.028), r: s * 0.03)
        fence(pen, from: f.x(0.31), to: f.x(0.43), base: f.y(0.738))
        SceneryMotif.roundTree(pen, base: f.p(0.775, 0.735), height: s * 0.15,
                               leaf: Farm.leaf, leafLight: Farm.leafLight, trunk: Farm.wood)
        SceneryMotif.roundTree(pen, base: f.p(0.955, 0.748), height: s * 0.21,
                               leaf: Farm.leaf, leafLight: Farm.leafLight, trunk: Farm.wood)

        // La prairie : le sol où roule le train.
        let meadow = SceneryPath.ridge([CGPoint(x: -10, y: f.y(0.748)), f.p(0.25, 0.744), f.p(0.5, 0.75),
                                        f.p(0.75, 0.744), CGPoint(x: f.w + 10, y: f.y(0.748))], bottom: f.h + 2)
        pen.fill(meadow, top: f.ground, bottom: f.h, [Farm.grass, Farm.grassDeep])
        pen.fill(Path(CGRect(x: 0, y: f.y(0.748), width: f.w, height: s * 0.012)), Farm.grassEdge.opacity(0.7))

        var rng = SceneryRandom(seed: 0xC0FFEE)
        for _ in 0..<26 {
            let x = rng.range(0, 1), y = rng.range(0.78, 0.99)
            guard !SceneryFrame.isButtonZone(x, y) else { continue }
            SceneryMotif.tuft(pen, at: f.p(x, y), size: s * rng.range(0.014, 0.022), Farm.tuft)
        }
        let petals = [Color.white, Color(red: 1, green: 0.62, blue: 0.72), Color(red: 1, green: 0.85, blue: 0.3),
                      Color(red: 0.72, green: 0.62, blue: 0.98)]
        for _ in 0..<22 {
            let x = rng.range(0, 1), y = rng.range(0.79, 0.99)
            guard !SceneryFrame.isButtonZone(x, y) else { continue }
            SceneryMotif.flower(pen, at: f.p(x, y), radius: s * rng.range(0.011, 0.017),
                                petal: rng.pick(petals), heart: Color(red: 1, green: 0.78, blue: 0.2))
        }
    }

    private func barn(_ pen: SketchPen, base b: CGPoint) {
        let s = f.s
        let bw = s * 0.19, bh = s * 0.115, roofH = s * 0.075
        let body = CGRect(x: b.x - bw / 2, y: b.y - bh, width: bw, height: bh)
        pen.rect(body, Farm.barn, corner: s * 0.006)
        pen.rect(CGRect(x: body.maxX - bw * 0.16, y: body.minY, width: bw * 0.16, height: bh), Farm.barnShade)
        // Toit en pente douce, rebord blanc.
        var roof = Path()
        roof.move(to: CGPoint(x: body.minX - s * 0.016, y: body.minY + s * 0.004))
        roof.addLine(to: CGPoint(x: b.x - bw * 0.2, y: body.minY - roofH))
        roof.addQuadCurve(to: CGPoint(x: b.x + bw * 0.2, y: body.minY - roofH),
                          control: CGPoint(x: b.x, y: body.minY - roofH - s * 0.012))
        roof.addLine(to: CGPoint(x: body.maxX + s * 0.016, y: body.minY + s * 0.004))
        roof.closeSubpath()
        pen.fill(roof, Farm.roof)
        pen.stroke(roof, Farm.roof, width: s * 0.008)
        // Pignon : fenêtre ronde.
        let win = CGPoint(x: b.x, y: body.minY + bh * 0.24)
        pen.circle(win, s * 0.017, Farm.trim)
        pen.circle(win, s * 0.012, Farm.roof.opacity(0.85))
        // Porte à croix blanche.
        let door = CGRect(x: b.x - bw * 0.2, y: body.maxY - bh * 0.56, width: bw * 0.4, height: bh * 0.56)
        pen.rect(door, Farm.barnShade)
        var cross = Path()
        cross.addRect(door.insetBy(dx: s * 0.004, dy: s * 0.004))
        cross.move(to: CGPoint(x: door.minX, y: door.minY))
        cross.addLine(to: CGPoint(x: door.maxX, y: door.maxY))
        cross.move(to: CGPoint(x: door.maxX, y: door.minY))
        cross.addLine(to: CGPoint(x: door.minX, y: door.maxY))
        pen.stroke(cross, Farm.trim, width: s * 0.0065)
        pen.stroke(Path(CGRect(x: body.minX, y: body.minY, width: bw, height: bh)), Farm.trim, width: s * 0.005)
    }

    private func hayBale(_ pen: SketchPen, at c: CGPoint, r: CGFloat) {
        pen.circle(c, r, Farm.hay)
        pen.stroke(SceneryPath.circle(c, r * 0.62), Farm.hayDark, width: r * 0.12)
        pen.stroke(SceneryPath.circle(c, r * 0.28), Farm.hayDark, width: r * 0.12)
    }

    private func fence(_ pen: SketchPen, from x0: CGFloat, to x1: CGFloat, base y: CGFloat) {
        let s = f.s, postH = s * 0.042
        var rails = Path()
        rails.move(to: CGPoint(x: x0, y: y - postH * 0.72)); rails.addLine(to: CGPoint(x: x1, y: y - postH * 0.72))
        rails.move(to: CGPoint(x: x0, y: y - postH * 0.34)); rails.addLine(to: CGPoint(x: x1, y: y - postH * 0.34))
        pen.stroke(rails, Farm.trim, width: s * 0.007)
        var x = x0
        while x <= x1 + 1 {
            pen.rect(CGRect(x: x - s * 0.006, y: y - postH, width: s * 0.012, height: postH), Farm.trim, corner: s * 0.004)
            x += s * 0.03
        }
    }
}

/// Les rayons du soleil (tournent lentement ; le disque est peint dans le fond).
struct SunRays: View, Equatable {
    let radius: CGFloat
    let color: Color
    var count = 12

    var body: some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            var rays = Path()
            for i in 0..<count {
                let a = CGFloat(i) * 2 * .pi / CGFloat(count)
                let r0 = radius * 1.28, r1 = radius * (i.isMultiple(of: 2) ? 1.62 : 1.5)
                rays.move(to: CGPoint(x: c.x + cos(a) * r0, y: c.y + sin(a) * r0))
                rays.addLine(to: CGPoint(x: c.x + cos(a) * r1, y: c.y + sin(a) * r1))
            }
            ctx.stroke(rays, with: .color(color.opacity(0.9)),
                       style: StrokeStyle(lineWidth: radius * 0.16, lineCap: .round))
        }
        .frame(width: radius * 3.6, height: radius * 3.6)
    }
}

/// Les quatre ailes du moulin (croisillons de bois et toile claire).
struct WindmillSails: View, Equatable {
    let radius: CGFloat

    var body: some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            for i in 0..<4 {
                var blade = ctx
                blade.translateBy(x: c.x, y: c.y)
                blade.rotate(by: .degrees(Double(i) * 90 + 20))
                let arm = Path(roundedRect: CGRect(x: -radius * 0.03, y: -radius, width: radius * 0.06, height: radius),
                               cornerRadius: radius * 0.03)
                blade.fill(arm, with: .color(Color(red: 0.55, green: 0.37, blue: 0.24)))
                let sail = CGRect(x: radius * 0.03, y: -radius * 0.96, width: radius * 0.24, height: radius * 0.7)
                blade.fill(Path(roundedRect: sail, cornerRadius: radius * 0.04),
                           with: .color(Color(red: 1.0, green: 0.98, blue: 0.93)))
                var lattice = Path()
                for k in 1..<4 {
                    let y = sail.minY + sail.height * CGFloat(k) / 4
                    lattice.move(to: CGPoint(x: sail.minX, y: y)); lattice.addLine(to: CGPoint(x: sail.maxX, y: y))
                }
                lattice.move(to: CGPoint(x: sail.midX, y: sail.minY)); lattice.addLine(to: CGPoint(x: sail.midX, y: sail.maxY))
                blade.stroke(lattice, with: .color(Color(red: 0.75, green: 0.60, blue: 0.45)), lineWidth: radius * 0.02)
            }
            ctx.fill(SceneryPath.circle(c, radius * 0.1), with: .color(Color(red: 0.55, green: 0.37, blue: 0.24)))
            ctx.fill(SceneryPath.circle(c, radius * 0.045), with: .color(EveilPalette.sun))
        }
        .frame(width: radius * 2.1, height: radius * 2.1)
    }
}
#endif
