// WorldCityScene.swift — la ville : ciel de fin d'après-midi, immeubles aux
// façades pastel, tour de l'horloge, lampadaire, feu tricolore et rue.
//
// Mouvement : des fenêtres s'allument et s'éteignent doucement, la lumière de
// l'antenne clignote, le feu change de couleur, les nuages dérivent.

#if canImport(SwiftUI)
import SwiftUI

private enum Town {
    static let skyStops: [Gradient.Stop] = [
        .init(color: Color(red: 0.56, green: 0.73, blue: 0.97), location: 0),
        .init(color: Color(red: 0.93, green: 0.86, blue: 0.94), location: 0.55),
        .init(color: Color(red: 1.0, green: 0.84, blue: 0.72), location: 1),
    ]
    static let skylineFar = Color(red: 0.82, green: 0.78, blue: 0.93)
    static let skylineNear = Color(red: 0.74, green: 0.70, blue: 0.89)
    static let coral = Color(red: 0.96, green: 0.56, blue: 0.48)
    static let mint = Color(red: 0.52, green: 0.80, blue: 0.72)
    static let lavender = Color(red: 0.72, green: 0.63, blue: 0.91)
    static let butter = Color(red: 0.99, green: 0.83, blue: 0.46)
    static let roof = Color(red: 0.30, green: 0.62, blue: 0.66)
    static let windowOff = Color(red: 0.82, green: 0.91, blue: 1.0)
    static let windowOn = Color(red: 1.0, green: 0.87, blue: 0.42)
    static let frame = Color(red: 1.0, green: 1.0, blue: 1.0).opacity(0.55)
    static let sidewalk = Color(red: 0.89, green: 0.87, blue: 0.91)
    static let curb = Color(red: 0.72, green: 0.70, blue: 0.78)
    static let asphalt = Color(red: 0.55, green: 0.57, blue: 0.66)
    static let asphaltDeep = Color(red: 0.49, green: 0.51, blue: 0.61)
    static let metal = Color(red: 0.26, green: 0.33, blue: 0.43)
    static let leaf = Color(red: 0.36, green: 0.68, blue: 0.40)
    static let leafLight = Color(red: 0.47, green: 0.77, blue: 0.47)
}

struct CityScene: View {
    let f: SceneryFrame

    static let clouds = [
        SceneryDriftingCloud(id: 0, y: 0.15, width: 0.22, period: 190, phase: 0.42),
        SceneryDriftingCloud(id: 1, y: 0.24, width: 0.16, period: 230, phase: 0.70, opacity: 0.85),
    ]

    /// Un immeuble du premier plan (x en fractions de w, haut en fraction de h).
    private struct Block {
        let x0: CGFloat, x1: CGFloat, top: CGFloat, color: Color, cols: Int
    }

    private var blocks: [Block] {
        [Block(x0: -0.01, x1: 0.105, top: 0.20, color: Town.coral, cols: 2),
         Block(x0: 0.095, x1: 0.20, top: 0.50, color: Town.mint, cols: 2),
         Block(x0: 0.785, x1: 0.885, top: 0.52, color: Town.lavender, cols: 2),
         Block(x0: 0.875, x1: 1.01, top: 0.25, color: Town.butter, cols: 2)]
    }

    private var sidewalkTop: CGFloat { f.y(0.738) }

    /// Fenêtres de tous les immeubles (le fond les peint éteintes, certaines s'allument).
    private var windows: [CGRect] {
        var out: [CGRect] = []
        let s = f.s
        for b in blocks {
            let x0 = f.x(b.x0), x1 = f.x(b.x1)
            let wd = x1 - x0
            let winW = min(wd / CGFloat(b.cols) * 0.46, s * 0.034), winH = winW * 1.3
            let clockTower = b.x1 > 1
            var y = f.y(b.top) + s * (clockTower ? 0.13 : (b.top < 0.3 ? 0.07 : 0.035))
            while y + winH < sidewalkTop - s * 0.07 {
                for c in 0..<b.cols {
                    let cx = x0 + wd * (CGFloat(c) + 0.5) / CGFloat(b.cols)
                    out.append(CGRect(x: cx - winW / 2, y: y, width: winW, height: winH))
                }
                y += winH + s * 0.022
            }
        }
        return out
    }

    private var antenna: CGPoint { CGPoint(x: f.x(0.045), y: f.y(0.20) - f.s * 0.07) }
    private var trafficLight: CGPoint { f.p(0.70, 0.738) }

    var body: some View {
        ZStack {
            Canvas { ctx, _ in back(SketchPen(ctx: ctx)) }
            SceneryCloudLayer(frame: f, clouds: Self.clouds, color: Color(red: 1, green: 0.95, blue: 0.96))
            Canvas { ctx, _ in front(SketchPen(ctx: ctx)) }
            SceneryAmbient { t in ambient(t) }
        }
    }

    // MARK: Animé : fenêtres, antenne, feu

    private func ambient(_ t: Double) -> some View {
        let wins = windows
        let s = f.s
        let cycle = SceneryMotion.loop(t, period: 14)          // vert 0–0,45, orange 0,45–0,55, rouge 0,55–1
        let lit = cycle < 0.45 ? 2 : (cycle < 0.55 ? 1 : 0)
        let lamps = [Color(red: 0.95, green: 0.30, blue: 0.30), Color(red: 1, green: 0.72, blue: 0.2),
                     Color(red: 0.30, green: 0.85, blue: 0.45)]
        return ZStack {
            ForEach(Array(stride(from: 1, to: wins.count, by: 3)), id: \.self) { i in
                let r = wins[i]
                let wave = SceneryMotion.swing(t, period: 9 + Double(i % 7) * 2.3, phase: Double(i) * 0.137)
                RoundedRectangle(cornerRadius: r.width * 0.2).fill(Town.windowOn)
                    .frame(width: r.width, height: r.height)
                    .opacity(Double(min(1, max(0, wave * 3 + 0.5))))
                    .position(x: r.midX, y: r.midY)
            }
            Circle().fill(Color(red: 1, green: 0.25, blue: 0.3))
                .frame(width: s * 0.014, height: s * 0.014)
                .opacity(SceneryMotion.loop(t, period: 1.8) < 0.5 ? 1 : 0.25)
                .position(antenna)
            ForEach(0..<3, id: \.self) { k in
                Circle().fill(k == lit ? lamps[k] : Color(white: 0.2))
                    .frame(width: s * 0.018, height: s * 0.018)
                    .position(x: trafficLight.x, y: trafficLight.y - s * 0.15 + CGFloat(k) * s * 0.024)
            }
        }
        .frame(width: f.w, height: f.h)
    }

    // MARK: Fond : ciel et silhouettes lointaines

    private func back(_ pen: SketchPen) {
        pen.fill(Path(CGRect(x: 0, y: 0, width: f.w, height: f.h)), top: 0, bottom: f.y(0.72), stops: Town.skyStops)
        pen.glow(f.p(0.5, 0.74), f.s * 0.7, Color(red: 1, green: 0.85, blue: 0.7), strength: 0.45)
        skyline(pen, seed: 7, color: Town.skylineFar, low: 0.54, high: 0.36, step: 0.07)
        skyline(pen, seed: 8, color: Town.skylineNear, low: 0.60, high: 0.47, step: 0.085)
    }

    /// Silhouette d'immeubles : bas au centre (bande du milieu dégagée), plus hauts sur les côtés.
    private func skyline(_ pen: SketchPen, seed: UInt64, color: Color, low: CGFloat, high: CGFloat, step: CGFloat) {
        var rng = SceneryRandom(seed: seed)
        var x: CGFloat = -0.02
        var p = Path()
        while x < 1.02 {
            let wd = step * rng.range(0.7, 1.2)
            let mid = x + wd / 2
            let edge = abs(2 * mid - 1)                                  // 0 au centre, 1 aux bords
            let top = low - (low - high) * edge * rng.range(0.6, 1.0)
            let rect = CGRect(x: f.x(x), y: f.y(top), width: f.x(wd) + 1, height: f.h - f.y(top))
            p.addRoundedRect(in: rect, cornerSize: CGSize(width: f.s * 0.008, height: f.s * 0.008))
            if rng.unit() < 0.3 {                                         // une antenne ou un dôme
                p.addEllipse(in: CGRect(x: rect.midX - rect.width * 0.25, y: rect.minY - rect.width * 0.22,
                                        width: rect.width * 0.5, height: rect.width * 0.44))
            }
            x += wd
        }
        pen.fill(p, color)
    }

    // MARK: Premier plan : immeubles, rue

    private func front(_ pen: SketchPen) {
        let s = f.s
        let wins = windows
        for b in blocks { building(pen, b) }
        for (i, r) in wins.enumerated() {
            pen.rect(r, i % 5 == 0 ? Town.windowOn : Town.windowOff, corner: r.width * 0.2)
            pen.fill(Path(CGRect(x: r.minX, y: r.midY - s * 0.0015, width: r.width, height: s * 0.003)), Town.frame)
        }
        clockTower(pen)
        // Antenne sur le toit corail.
        pen.stroke(Path { p in p.move(to: CGPoint(x: antenna.x, y: f.y(0.20))); p.addLine(to: antenna) },
                   Town.metal, width: s * 0.005)
        // Auvent rayé de la boutique (immeuble menthe).
        let shopX0 = f.x(0.095), shopX1 = f.x(0.20), awningY = sidewalkTop - s * 0.07
        let awning = Path(roundedRect: CGRect(x: shopX0 + s * 0.006, y: awningY, width: shopX1 - shopX0 - s * 0.012,
                                              height: s * 0.028), cornerRadius: s * 0.008)
        pen.fill(awning, Color.white)
        pen.clipped(to: awning) { inside in
            var x = shopX0
            while x < shopX1 {
                inside.fill(Path(CGRect(x: x, y: awningY, width: s * 0.012, height: s * 0.03)), Color(red: 0.93, green: 0.33, blue: 0.36))
                x += s * 0.024
            }
        }
        pen.rect(CGRect(x: (shopX0 + shopX1) / 2 - s * 0.018, y: sidewalkTop - s * 0.04, width: s * 0.036, height: s * 0.04),
                 Color(red: 0.36, green: 0.45, blue: 0.62), corner: s * 0.005)

        // Trottoir, bordure, chaussée.
        pen.fill(Path(CGRect(x: 0, y: sidewalkTop, width: f.w, height: f.y(0.775) - sidewalkTop)), Town.sidewalk)
        var slabs = Path()
        var x: CGFloat = 0
        while x < f.w {
            slabs.move(to: CGPoint(x: x, y: sidewalkTop)); slabs.addLine(to: CGPoint(x: x, y: f.y(0.775)))
            x += s * 0.07
        }
        pen.stroke(slabs, Town.curb.opacity(0.35), width: s * 0.002)
        pen.fill(Path(CGRect(x: 0, y: f.y(0.772), width: f.w, height: s * 0.012)), Town.curb)
        let road = Path(CGRect(x: 0, y: f.y(0.772) + s * 0.012, width: f.w, height: f.h))
        pen.fill(road, top: f.y(0.78), bottom: f.h, [Town.asphalt, Town.asphaltDeep])
        var dashes = Path()
        x = s * 0.02
        while x < f.w {
            dashes.addRoundedRect(in: CGRect(x: x, y: f.y(0.935), width: s * 0.09, height: s * 0.012),
                                  cornerSize: CGSize(width: s * 0.006, height: s * 0.006))
            x += s * 0.16
        }
        pen.fill(dashes, Color.white.opacity(0.85))
        // Passage piéton, sur le côté droit.
        for k in 0..<5 {
            pen.rect(CGRect(x: f.x(0.80) + CGFloat(k) * s * 0.04, y: f.y(0.80), width: s * 0.022, height: f.y(0.10)),
                     Color.white.opacity(0.8), corner: s * 0.004)
        }

        streetLamp(pen, foot: f.p(0.27, 0.745))
        pottedTree(pen, foot: f.p(0.225, 0.748), size: s * 0.1)
        pottedTree(pen, foot: f.p(0.745, 0.748), size: s * 0.085)
        trafficLightBody(pen, foot: trafficLight)
    }

    private func building(_ pen: SketchPen, _ b: Block) {
        let s = f.s
        let rect = CGRect(x: f.x(b.x0), y: f.y(b.top), width: f.x(b.x1) - f.x(b.x0), height: sidewalkTop - f.y(b.top))
        pen.rect(rect, b.color, corner: s * 0.01)
        pen.rect(CGRect(x: rect.maxX - rect.width * 0.12, y: rect.minY, width: rect.width * 0.12, height: rect.height),
                 Color.black.opacity(0.06))
        // Corniche.
        pen.rect(CGRect(x: rect.minX - s * 0.006, y: rect.minY - s * 0.008, width: rect.width + s * 0.012, height: s * 0.018),
                 Color.white.opacity(0.7), corner: s * 0.006)
    }

    private func clockTower(_ pen: SketchPen) {
        let s = f.s
        let x0 = f.x(0.875), x1 = f.x(1.01), top = f.y(0.25)
        let mid = (x0 + x1) / 2
        // Toit pointu turquoise.
        var roof = Path()
        roof.move(to: CGPoint(x: x0 - s * 0.01, y: top))
        roof.addLine(to: CGPoint(x: mid, y: top - s * 0.1))
        roof.addLine(to: CGPoint(x: x1 + s * 0.01, y: top))
        roof.closeSubpath()
        pen.fill(roof, Town.roof)
        pen.stroke(roof, Town.roof, width: s * 0.008)
        pen.circle(CGPoint(x: mid, y: top - s * 0.105), s * 0.008, Color(red: 1, green: 0.8, blue: 0.3))
        // Cadran.
        let c = CGPoint(x: mid, y: top + s * 0.06), r = min(s * 0.045, (x1 - x0) * 0.36)
        pen.circle(c, r * 1.12, Color.white.opacity(0.7))
        pen.circle(c, r, Color.white)
        for k in 0..<12 {
            let a = CGFloat(k) * .pi / 6
            pen.circle(CGPoint(x: c.x + cos(a) * r * 0.8, y: c.y + sin(a) * r * 0.8), r * 0.06, Town.metal)
        }
        pen.stroke(Path { p in
            p.move(to: c); p.addLine(to: CGPoint(x: c.x - r * 0.35, y: c.y - r * 0.4))
            p.move(to: c); p.addLine(to: CGPoint(x: c.x + r * 0.5, y: c.y - r * 0.45))
        }, Town.metal, width: r * 0.1)
        pen.circle(c, r * 0.08, Town.metal)
    }

    private func streetLamp(_ pen: SketchPen, foot b: CGPoint) {
        let s = f.s
        var pole = Path()
        pole.move(to: b)
        pole.addLine(to: CGPoint(x: b.x, y: b.y - s * 0.16))
        pole.addQuadCurve(to: CGPoint(x: b.x + s * 0.04, y: b.y - s * 0.17), control: CGPoint(x: b.x, y: b.y - s * 0.19))
        pen.stroke(pole, Town.metal, width: s * 0.008)
        pen.glow(CGPoint(x: b.x + s * 0.042, y: b.y - s * 0.155), s * 0.05, Town.windowOn, strength: 0.6)
        var shade = Path()
        shade.move(to: CGPoint(x: b.x + s * 0.02, y: b.y - s * 0.16))
        shade.addLine(to: CGPoint(x: b.x + s * 0.064, y: b.y - s * 0.16))
        shade.addLine(to: CGPoint(x: b.x + s * 0.052, y: b.y - s * 0.172))
        shade.addLine(to: CGPoint(x: b.x + s * 0.032, y: b.y - s * 0.172))
        shade.closeSubpath()
        pen.fill(shade, Town.metal)
        pen.circle(CGPoint(x: b.x + s * 0.042, y: b.y - s * 0.156), s * 0.008, Town.windowOn)
    }

    private func pottedTree(_ pen: SketchPen, foot b: CGPoint, size z: CGFloat) {
        pen.rect(CGRect(x: b.x - z * 0.2, y: b.y - z * 0.22, width: z * 0.4, height: z * 0.22),
                 Color(red: 0.82, green: 0.52, blue: 0.36), corner: z * 0.05)
        pen.stroke(Path { p in p.move(to: CGPoint(x: b.x, y: b.y - z * 0.2)); p.addLine(to: CGPoint(x: b.x, y: b.y - z * 0.6)) },
                   Color(red: 0.55, green: 0.38, blue: 0.26), width: z * 0.07)
        pen.circle(CGPoint(x: b.x, y: b.y - z * 0.75), z * 0.3, Town.leaf)
        pen.circle(CGPoint(x: b.x - z * 0.1, y: b.y - z * 0.84), z * 0.12, Town.leafLight)
    }

    private func trafficLightBody(_ pen: SketchPen, foot b: CGPoint) {
        let s = f.s
        pen.stroke(Path { p in p.move(to: b); p.addLine(to: CGPoint(x: b.x, y: b.y - s * 0.12)) }, Town.metal, width: s * 0.008)
        pen.rect(CGRect(x: b.x - s * 0.016, y: b.y - s * 0.165, width: s * 0.032, height: s * 0.078), Town.metal,
                 corner: s * 0.008)
    }
}
#endif
