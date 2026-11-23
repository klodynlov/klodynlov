// WorldMountainsScene.swift — la montagne : sommets enneigés en deux plans,
// alpage fleuri, sapins et chalet de bois.
//
// Mouvement : les nuages glissent entre les sommets, la cheminée du chalet fume.

#if canImport(SwiftUI)
import SwiftUI

private enum Alps {
    static let skyTop = Color(red: 0.43, green: 0.70, blue: 0.97)
    static let skyLow = Color(red: 0.90, green: 0.96, blue: 1.0)
    static let far = Color(red: 0.77, green: 0.82, blue: 0.96)
    static let farShade = Color(red: 0.70, green: 0.75, blue: 0.92)
    static let near = Color(red: 0.56, green: 0.65, blue: 0.86)
    static let nearShade = Color(red: 0.47, green: 0.56, blue: 0.79)
    static let snow = Color(red: 0.99, green: 1.0, blue: 1.0)
    static let snowShade = Color(red: 0.86, green: 0.90, blue: 0.99)
    static let pasture = Color(red: 0.62, green: 0.84, blue: 0.47)
    static let pastureDeep = Color(red: 0.51, green: 0.76, blue: 0.39)
    static let hill = Color(red: 0.55, green: 0.79, blue: 0.43)
    static let pine = Color(red: 0.25, green: 0.53, blue: 0.40)
    static let pineLight = Color(red: 0.34, green: 0.62, blue: 0.46)
    static let wood = Color(red: 0.76, green: 0.50, blue: 0.30)
    static let woodDark = Color(red: 0.58, green: 0.36, blue: 0.22)
    static let roof = Color(red: 0.52, green: 0.27, blue: 0.22)
    static let rock = Color(red: 0.66, green: 0.68, blue: 0.74)
    static let tuft = Color(red: 0.45, green: 0.70, blue: 0.34)
}

struct MountainsScene: View {
    let f: SceneryFrame

    static let clouds = [
        SceneryDriftingCloud(id: 0, y: 0.17, width: 0.24, period: 200, phase: 0.40),
        SceneryDriftingCloud(id: 1, y: 0.25, width: 0.17, period: 240, phase: 0.86, opacity: 0.85),
    ]

    private var chalet: CGPoint { f.p(0.80, 0.742) }
    private var chimneyTop: CGPoint { CGPoint(x: chalet.x + f.s * 0.045, y: chalet.y - f.s * 0.175) }

    var body: some View {
        ZStack {
            Canvas { ctx, _ in back(SketchPen(ctx: ctx)) }
            SceneryCloudLayer(frame: f, clouds: Self.clouds)
            Canvas { ctx, _ in front(SketchPen(ctx: ctx)) }
            SceneryAmbient { t in
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        let u = SceneryMotion.loop(t, period: 4.5, phase: Double(i) / 3)
                        Circle().fill(Color.white.opacity(0.85 * Double(1 - u)))
                            .frame(width: f.s * (0.018 + 0.03 * u), height: f.s * (0.018 + 0.03 * u))
                            .position(x: chimneyTop.x + f.s * 0.03 * u + f.s * 0.006 * SceneryMotion.swing(t, period: 3),
                                      y: chimneyTop.y - f.s * 0.11 * u)
                    }
                }
                .frame(width: f.w, height: f.h)
            }
        }
    }

    // MARK: Fond : ciel et sommets lointains

    private func back(_ pen: SketchPen) {
        pen.fill(Path(CGRect(x: 0, y: 0, width: f.w, height: f.h)), top: 0, bottom: f.y(0.6), [Alps.skyTop, Alps.skyLow])
        let farPts = [f.p(-0.06, 0.62), f.p(0.07, 0.30), f.p(0.22, 0.53), f.p(0.36, 0.455), f.p(0.50, 0.575),
                      f.p(0.65, 0.445), f.p(0.80, 0.54), f.p(0.93, 0.285), f.p(1.07, 0.52)]
        range(pen, farPts, fill: Alps.far, shade: Alps.farShade, snowDepth: 0.30)
    }

    /// Une chaîne : silhouette, flanc droit dans l'ombre, calottes de neige.
    private func range(_ pen: SketchPen, _ pts: [CGPoint], fill: Color, shade: Color, snowDepth: CGFloat) {
        let body = SceneryPath.range(pts, bottom: f.h, roundness: 0.10)
        pen.fill(body, fill)
        pen.clipped(to: body) { inside in
            for i in stride(from: 1, to: pts.count - 1, by: 2) {
                let peak = pts[i], valley = pts[i + 1], before = pts[i - 1]
                // Flanc à l'ombre (à droite du sommet).
                inside.fill(SceneryPath.polygon([peak, valley, CGPoint(x: valley.x, y: f.h),
                                                 CGPoint(x: peak.x + (valley.x - peak.x) * 0.15, y: f.h)]), shade)
                // Calotte : sous le sommet, bord inférieur en dents arrondies.
                let depth = (max(valley.y, before.y) - peak.y) * snowDepth
                let left = peak.x - (peak.x - before.x) * 0.55, right = peak.x + (valley.x - peak.x) * 0.55
                var cap = Path()
                cap.move(to: CGPoint(x: left, y: peak.y - 10))
                cap.addLine(to: CGPoint(x: left, y: peak.y + depth * 0.8))
                let teeth = 4
                for k in 0..<teeth {
                    let x0 = left + (right - left) * CGFloat(k) / CGFloat(teeth)
                    let x1 = left + (right - left) * CGFloat(k + 1) / CGFloat(teeth)
                    let low = peak.y + depth * (k.isMultiple(of: 2) ? 1.15 : 0.95)
                    cap.addQuadCurve(to: CGPoint(x: x1, y: peak.y + depth * 0.75), control: CGPoint(x: (x0 + x1) / 2, y: low))
                }
                cap.addLine(to: CGPoint(x: right, y: peak.y - 10))
                cap.closeSubpath()
                inside.fill(cap, Alps.snow)
                inside.clipped(to: SceneryPath.polygon([peak, valley, CGPoint(x: valley.x, y: f.h),
                                                        CGPoint(x: peak.x, y: f.h)])) { shadow in
                    shadow.fill(cap, Alps.snowShade)
                }
            }
        }
    }

    // MARK: Premier plan : sommets proches, alpage, sapins, chalet

    private func front(_ pen: SketchPen) {
        let s = f.s
        let nearPts = [f.p(-0.06, 0.60), f.p(0.12, 0.47), f.p(0.28, 0.635), f.p(0.43, 0.575), f.p(0.56, 0.655),
                       f.p(0.73, 0.555), f.p(0.87, 0.64), f.p(0.99, 0.475), f.p(1.08, 0.58)]
        range(pen, nearPts, fill: Alps.near, shade: Alps.nearShade, snowDepth: 0.26)

        let hills = SceneryPath.ridge([f.p(-0.05, 0.695), f.p(0.18, 0.66), f.p(0.45, 0.692), f.p(0.72, 0.668),
                                       f.p(1.05, 0.688)], bottom: f.h)
        pen.fill(hills, top: f.y(0.66), bottom: f.y(0.76), [Alps.hill, Alps.pastureDeep])

        for (fx, fy, hf) in [(0.015, 0.745, 0.20), (0.10, 0.725, 0.15), (0.19, 0.735, 0.11), (0.255, 0.722, 0.08),
                             (0.66, 0.715, 0.08), (0.93, 0.735, 0.17), (0.995, 0.75, 0.13)] as [(CGFloat, CGFloat, CGFloat)] {
            SceneryMotif.pine(pen, base: f.p(fx, fy), height: s * hf, leaf: Alps.pine, leafLight: Alps.pineLight,
                              trunk: Alps.woodDark)
        }
        chaletHouse(pen, base: chalet)

        let pasture = SceneryPath.ridge([CGPoint(x: -10, y: f.y(0.75)), f.p(0.3, 0.744), f.p(0.6, 0.75),
                                         CGPoint(x: f.w + 10, y: f.y(0.745))], bottom: f.h + 2)
        pen.fill(pasture, top: f.ground, bottom: f.h, [Alps.pasture, Alps.pastureDeep])

        var rng = SceneryRandom(seed: 0xA1F)
        for _ in 0..<22 {
            let x = rng.range(0, 1), y = rng.range(0.785, 0.99)
            guard !SceneryFrame.isButtonZone(x, y) else { continue }
            SceneryMotif.tuft(pen, at: f.p(x, y), size: s * rng.range(0.013, 0.02), Alps.tuft)
        }
        for _ in 0..<20 {
            let x = rng.range(0, 1), y = rng.range(0.79, 0.99)
            guard !SceneryFrame.isButtonZone(x, y) else { continue }
            let c = f.p(x, y)
            if rng.unit() < 0.5 {
                edelweiss(pen, at: c, r: s * rng.range(0.011, 0.015))
            } else {
                gentian(pen, at: c, r: s * rng.range(0.010, 0.014))
            }
        }
        for (fx, fy, z) in [(0.06, 0.95, 0.05), (0.12, 0.97, 0.03), (0.93, 0.86, 0.04)] as [(CGFloat, CGFloat, CGFloat)] {
            SceneryMotif.pebble(pen, at: f.p(fx, fy), size: s * z, Alps.rock, light: Color.white.opacity(0.45))
        }
    }

    private func chaletHouse(_ pen: SketchPen, base b: CGPoint) {
        let s = f.s
        let wd = s * 0.16, ht = s * 0.085
        let body = CGRect(x: b.x - wd / 2, y: b.y - ht, width: wd, height: ht)
        pen.rect(body, Alps.wood)
        var planks = Path()
        for k in 1..<5 {
            let y = body.minY + ht * CGFloat(k) / 5
            planks.move(to: CGPoint(x: body.minX, y: y)); planks.addLine(to: CGPoint(x: body.maxX, y: y))
        }
        pen.stroke(planks, Alps.woodDark.opacity(0.45), width: s * 0.0025)
        // Pignon + grand toit débordant.
        let apex = CGPoint(x: b.x, y: body.minY - s * 0.07)
        pen.rect(CGRect(x: chimneyTop.x - s * 0.011, y: chimneyTop.y, width: s * 0.022, height: s * 0.06),
                 Alps.rock, corner: s * 0.003)
        pen.fill(SceneryPath.polygon([CGPoint(x: body.minX, y: body.minY), apex, CGPoint(x: body.maxX, y: body.minY)]),
                 Alps.wood)
        var roof = Path()
        roof.move(to: CGPoint(x: body.minX - s * 0.03, y: body.minY + s * 0.012))
        roof.addLine(to: CGPoint(x: apex.x, y: apex.y - s * 0.012))
        roof.addLine(to: CGPoint(x: body.maxX + s * 0.03, y: body.minY + s * 0.012))
        pen.stroke(roof, Alps.roof, width: s * 0.022)
        // Fenêtres à volets rouges et jardinières.
        for dx: CGFloat in [-0.3, 0.3] {
            let c = CGPoint(x: b.x + wd * dx, y: body.minY + ht * 0.42)
            pen.rect(CGRect(x: c.x - s * 0.013, y: c.y - s * 0.015, width: s * 0.026, height: s * 0.03),
                     Color(red: 0.85, green: 0.93, blue: 1.0), corner: s * 0.004)
            for side: CGFloat in [-1, 1] {
                pen.rect(CGRect(x: c.x + side * s * 0.02 - s * 0.006, y: c.y - s * 0.015, width: s * 0.012, height: s * 0.03),
                         Color(red: 0.85, green: 0.25, blue: 0.24), corner: s * 0.003)
            }
            pen.rect(CGRect(x: c.x - s * 0.017, y: c.y + s * 0.015, width: s * 0.034, height: s * 0.008), Alps.woodDark)
            for k in 0..<4 {
                pen.circle(CGPoint(x: c.x - s * 0.013 + CGFloat(k) * s * 0.0087, y: c.y + s * 0.013), s * 0.005,
                           k.isMultiple(of: 2) ? Color(red: 0.95, green: 0.30, blue: 0.40) : Color(red: 1, green: 0.8, blue: 0.2))
            }
        }
        // Petite fenêtre ronde du pignon, porte.
        pen.circle(CGPoint(x: b.x, y: body.minY - s * 0.028), s * 0.011, Color(red: 0.85, green: 0.93, blue: 1.0))
        pen.rect(CGRect(x: b.x - s * 0.012, y: body.maxY - s * 0.04, width: s * 0.024, height: s * 0.04), Alps.woodDark,
                 corner: s * 0.006)
    }

    private func edelweiss(_ pen: SketchPen, at c: CGPoint, r: CGFloat) {
        pen.fill(SceneryPath.star(c, outer: r, inner: r * 0.45, branches: 6), Color.white)
        pen.circle(c, r * 0.3, Color(red: 1, green: 0.85, blue: 0.35))
    }

    private func gentian(_ pen: SketchPen, at c: CGPoint, r: CGFloat) {
        var bell = Path()
        bell.move(to: CGPoint(x: c.x - r * 0.7, y: c.y - r * 1.2))
        bell.addLine(to: CGPoint(x: c.x - r * 0.25, y: c.y - r * 0.8))
        bell.addLine(to: CGPoint(x: c.x, y: c.y - r * 1.3))
        bell.addLine(to: CGPoint(x: c.x + r * 0.25, y: c.y - r * 0.8))
        bell.addLine(to: CGPoint(x: c.x + r * 0.7, y: c.y - r * 1.2))
        bell.addQuadCurve(to: CGPoint(x: c.x - r * 0.7, y: c.y - r * 1.2), control: CGPoint(x: c.x, y: c.y + r * 0.4))
        pen.fill(bell, Color(red: 0.32, green: 0.45, blue: 0.92))
        pen.stroke(Path { p in p.move(to: c); p.addLine(to: CGPoint(x: c.x, y: c.y + r * 0.6)) }, Alps.tuft, width: r * 0.25)
    }
}
#endif
