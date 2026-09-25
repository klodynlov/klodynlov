// Critters.swift — les bestioles (et petites choses) qui volent derrière le mot.
//
// Exemple fondateur (utilisateur, 25/09/2026) : pour « mouche », des mouches
// volent en arrière-plan ; l'enfant en attrape une et entend son « bzzz ».
// Ce fichier ne fait que les DESSINER (tournées vers la droite, ailes qui
// battent) ; le vol et la capture vivent dans l'écran de jeu.
//
// Dessins vectoriels dans un repère 100 × 100 (`CritterDrawing`), mis à
// l'échelle de `size` : lisibles de 50 à 90 pt, sur fond clair comme sombre.
// Animaux : grands yeux gentils. Objets : sans visage.
//
// Mouvement : piloté par le TEMPS (`TimelineView`, 30 images/s au plus), jamais
// par une animation `repeatForever` lancée dans `onAppear` (elle capturerait la
// transition d'insertion de l'écran de jeu). Mouche et abeille : battement
// bourdonnant (deux positions alternées + ailes fantômes, période ≈ 0,067 s) ;
// oiseau ≈ 0,3 s ; papillon ≈ 0,55 s. Les objets ont une petite vie à eux
// (scintiller, battre, tournoyer…). `flapping == false` ou « Réduire les
// animations » : pose de repos, aucune horloge.

#if canImport(SwiftUI)
import SwiftUI

public enum CritterKind: String, CaseIterable, Sendable {
    case fly, bee, bird, butterfly, bubble, drop, note, spark, leaf, star, feather, paint, heart, snowflake

    /// Les bestioles qui ont des ailes (les autres « vivent » autrement quand `flapping`).
    public var hasWings: Bool { [.fly, .bee, .bird, .butterfly].contains(self) }

    /// Les dessins qui prennent la couleur `tint` (les autres gardent leur couleur naturelle).
    public var usesTint: Bool { [.butterfly, .note, .paint, .bird, .leaf, .feather].contains(self) }
}

public struct CritterView: View {
    public let kind: CritterKind
    public let size: CGFloat
    public let flapping: Bool
    public let tint: Color?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.sceneryFrozenTime) private var frozenTime
    /// Décalage propre à chaque bestiole : deux mouches ne battent pas des ailes en même temps.
    @State private var phase = Double.random(in: 0..<60)

    /// `flapping` : ailes qui battent (faux quand la bestiole se pose, pendant l'écoute).
    /// `tint` : variante de couleur (papillons, notes, gouttes de peinture ; voir `CritterKind.usesTint`).
    public init(kind: CritterKind, size: CGFloat = 64, flapping: Bool = true, tint: Color? = nil) {
        self.kind = kind
        self.size = size
        self.flapping = flapping
        self.tint = tint
    }

    public var body: some View {
        Group {
            if !flapping || reduceMotion {
                CritterArt(kind: kind, tint: tint, time: nil)
            } else if let frozenTime {
                CritterArt(kind: kind, tint: tint, time: frozenTime)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
                    CritterArt(kind: kind, tint: tint, time: timeline.date.timeIntervalSinceReferenceDate + phase)
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Une bestiole à un instant donné (`time` nil : pose de repos).
struct CritterArt: View {
    let kind: CritterKind
    let tint: Color?
    let time: Double?

    var body: some View {
        Canvas { ctx, size in
            let k = min(size.width, size.height) / 100
            var c = ctx
            c.translateBy(x: (size.width - 100 * k) / 2, y: (size.height - 100 * k) / 2)
            c.scaleBy(x: k, y: k)
            CritterDrawing(pen: SketchPen(ctx: c), tint: tint, time: time).draw(kind)
        }
    }
}

// MARK: - Les dessins (repère 100 × 100, tournés vers la droite)

struct CritterDrawing {
    let pen: SketchPen
    let tint: Color?
    let time: Double?

    private static let ink = Color(red: 0.13, green: 0.13, blue: 0.20)
    private static let cheek = Color(red: 1.0, green: 0.58, blue: 0.68)

    func draw(_ kind: CritterKind) {
        switch kind {
        case .fly: fly()
        case .bee: bee()
        case .bird: bird()
        case .butterfly: butterfly()
        case .bubble: bubble()
        case .drop: drop()
        case .note: note()
        case .spark: spark()
        case .leaf: leaf()
        case .star: star()
        case .feather: feather()
        case .paint: paint()
        case .heart: heart()
        case .snowflake: snowflake()
        }
    }

    // MARK: Horloge locale

    /// Oscillation dans [-1, 1] (0 au repos).
    private func swing(_ period: Double, _ phase: Double = 0) -> CGFloat {
        guard let t = time else { return 0 }
        return SceneryMotion.swing(t, period: period, phase: phase)
    }

    /// Bourdonnement : +1 / -1 en alternance, une image sur deux (période ≈ 0,067 s).
    private var buzz: CGFloat? {
        guard let t = time else { return nil }
        return Int((t * 30).rounded(.down)).isMultiple(of: 2) ? 1 : -1
    }

    // MARK: Pièces communes

    /// Grand œil gentil : blanc, pupille, reflet. `look` décale la pupille vers l'avant.
    private func eye(_ c: CGPoint, _ r: CGFloat, look: CGFloat = 0.3) {
        pen.circle(c, r, .white)
        pen.stroke(SceneryPath.circle(c, r), Self.ink.opacity(0.35), width: max(0.8, r * 0.1))
        let pupil = CGPoint(x: c.x + r * look, y: c.y + r * 0.08)
        pen.circle(pupil, r * 0.6, Self.ink)
        pen.circle(CGPoint(x: pupil.x - r * 0.2, y: pupil.y - r * 0.24), r * 0.22, .white)
    }

    private func smile(from a: CGPoint, to b: CGPoint, depth: CGFloat, width: CGFloat = 2.2) {
        var p = Path()
        p.move(to: a)
        p.addQuadCurve(to: b, control: CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2 + depth))
        pen.stroke(p, Self.ink, width: width)
    }

    /// Aile translucide attachée en `root`, relevée de `angle` (0° : couchée vers l'arrière, 90° : dressée).
    private func wing(_ p: SketchPen, root: CGPoint, angle: Double, length: CGFloat, width: CGFloat, alpha: Double = 1) {
        p.local(at: root, rotation: .degrees(angle)) { w in
            let shape = SceneryPath.ellipse(CGPoint(x: -length / 2, y: 0), length / 2, width / 2)
            w.fill(shape, Color(red: 0.86, green: 0.94, blue: 1.0).opacity(0.62 * alpha))
            w.stroke(shape, Color(red: 0.50, green: 0.66, blue: 0.90).opacity(0.9 * alpha), width: 1.7)
            var vein = Path()
            vein.move(to: CGPoint(x: -2, y: 0))
            vein.addQuadCurve(to: CGPoint(x: -length * 0.8, y: -width * 0.12), control: CGPoint(x: -length * 0.4, y: width * 0.12))
            w.stroke(vein, Color(red: 0.50, green: 0.66, blue: 0.90).opacity(0.5 * alpha), width: 1.1)
            w.ellipse(CGPoint(x: -length * 0.62, y: -width * 0.18), length * 0.14, width * 0.12, Color.white.opacity(0.7 * alpha))
        }
    }

    /// Paire d'ailes bourdonnantes : pose courante + ailes « fantômes » de l'autre pose (flou de vitesse).
    private func buzzingWings(root: CGPoint, rest: (Double, Double), up: (Double, Double), down: (Double, Double),
                              length: CGFloat, width: CGFloat, front: Bool) {
        let pick: (Double, Double)
        if let b = buzz {
            let ghost = b > 0 ? down : up
            let ghostAngle = front ? ghost.0 : ghost.1
            wing(pen, root: root, angle: ghostAngle, length: length, width: width, alpha: 0.32)
            pick = b > 0 ? up : down
        } else {
            pick = rest
        }
        wing(pen, root: root, angle: front ? pick.0 : pick.1, length: length, width: width)
    }

    /// Dessin tourné/mis à l'échelle autour de `center` (petite vie des objets).
    private func around(_ center: CGPoint, rotation: CGFloat = 0, sx: CGFloat = 1, sy: CGFloat = 1,
                        _ draw: (SketchPen) -> Void) {
        var c = pen.ctx
        c.translateBy(x: center.x, y: center.y)
        if rotation != 0 { c.rotate(by: .degrees(Double(rotation))) }
        if sx != 1 || sy != 1 { c.scaleBy(x: sx, y: sy) }
        c.translateBy(x: -center.x, y: -center.y)
        draw(SketchPen(ctx: c))
    }

    /// Reflet brillant (ellipse blanche inclinée).
    private func shine(_ p: SketchPen, _ c: CGPoint, _ rx: CGFloat, _ ry: CGFloat, angle: Double = -35, alpha: Double = 0.75) {
        p.local(at: c, rotation: .degrees(angle)) { s in
            s.ellipse(.zero, rx, ry, Color.white.opacity(alpha))
        }
    }

    // MARK: Mouche

    private func fly() {
        let body = Color(red: 0.30, green: 0.33, blue: 0.45)
        let bodyLight = Color(red: 0.43, green: 0.47, blue: 0.60)
        let root = CGPoint(x: 55, y: 45)
        // Pattes.
        var legs = Path()
        legs.move(to: CGPoint(x: 44, y: 68)); legs.addLine(to: CGPoint(x: 39, y: 80)); legs.addLine(to: CGPoint(x: 34, y: 82))
        legs.move(to: CGPoint(x: 54, y: 70)); legs.addLine(to: CGPoint(x: 54, y: 83)); legs.addLine(to: CGPoint(x: 50, y: 86))
        legs.move(to: CGPoint(x: 64, y: 66)); legs.addLine(to: CGPoint(x: 69, y: 79)); legs.addLine(to: CGPoint(x: 74, y: 81))
        pen.stroke(legs, body, width: 2.8)
        // Aile arrière (derrière le corps).
        buzzingWings(root: root, rest: (12, 24), up: (68, 84), down: (20, 34), length: 34, width: 15, front: false)
        // Abdomen rayé, thorax, tête.
        let abdomen = SceneryPath.ellipse(CGPoint(x: 38, y: 60), 21, 16)
        pen.fill(abdomen, body)
        pen.clipped(to: abdomen) { inside in
            for x: CGFloat in [26, 36] {
                inside.fill(Path(roundedRect: CGRect(x: x, y: 40, width: 4.5, height: 40), cornerRadius: 2), bodyLight.opacity(0.8))
            }
            inside.ellipse(CGPoint(x: 34, y: 52), 12, 5, Color.white.opacity(0.12))
        }
        pen.circle(CGPoint(x: 56, y: 56), 13, body)
        pen.circle(CGPoint(x: 72, y: 51), 18, bodyLight)
        pen.circle(CGPoint(x: 66, y: 43), 6, Color.white.opacity(0.14))
        // Liseré clair : la silhouette sombre se détache aussi sur un ciel de nuit.
        var rim = Path()
        rim.addEllipse(in: CGRect(x: 17, y: 44, width: 42, height: 32))
        rim.addEllipse(in: CGRect(x: 54, y: 33, width: 36, height: 36))
        pen.stroke(rim, Color(red: 0.72, green: 0.78, blue: 0.92).opacity(0.55), width: 1.4)
        // Antennes.
        var antennae = Path()
        antennae.move(to: CGPoint(x: 74, y: 35)); antennae.addQuadCurve(to: CGPoint(x: 82, y: 25), control: CGPoint(x: 75, y: 27))
        antennae.move(to: CGPoint(x: 66, y: 35)); antennae.addQuadCurve(to: CGPoint(x: 66, y: 24), control: CGPoint(x: 63, y: 29))
        pen.stroke(antennae, body, width: 2.4)
        pen.circle(CGPoint(x: 82, y: 25), 2.6, body)
        pen.circle(CGPoint(x: 66, y: 24), 2.6, body)
        // Visage : grands yeux, joue, sourire.
        eye(CGPoint(x: 65, y: 45), 7.5, look: 0.35)
        eye(CGPoint(x: 80, y: 46), 9.5, look: 0.35)
        pen.circle(CGPoint(x: 74, y: 60), 3.6, Self.cheek.opacity(0.75))
        smile(from: CGPoint(x: 80, y: 59), to: CGPoint(x: 88, y: 57), depth: 5)
        // Aile avant (translucide, par-dessus).
        buzzingWings(root: root, rest: (12, 24), up: (68, 84), down: (20, 34), length: 34, width: 15, front: true)
    }

    // MARK: Abeille

    private func bee() {
        let yellow = Color(red: 1.0, green: 0.80, blue: 0.20)
        let yellowLight = Color(red: 1.0, green: 0.90, blue: 0.48)
        let stripe = Color(red: 0.24, green: 0.21, blue: 0.26)
        let root = CGPoint(x: 44, y: 38)
        buzzingWings(root: root, rest: (62, 78), up: (100, 112), down: (50, 64), length: 31, width: 20, front: false)
        // Dard minuscule et arrondi.
        pen.fill(SceneryPath.polygon([CGPoint(x: 17, y: 55), CGPoint(x: 7, y: 60), CGPoint(x: 17, y: 65)]), stripe)
        pen.stroke(SceneryPath.polygon([CGPoint(x: 17, y: 55), CGPoint(x: 7, y: 60), CGPoint(x: 17, y: 65)]), stripe, width: 2.5)
        let body = SceneryPath.ellipse(CGPoint(x: 47, y: 59), 32, 26)
        pen.fill(body, top: 33, bottom: 85, [yellowLight, yellow])
        pen.clipped(to: body) { inside in
            for x: CGFloat in [24, 40] {
                var band = Path()
                band.addRoundedRect(in: CGRect(x: x, y: 28, width: 9, height: 64), cornerSize: CGSize(width: 4, height: 4))
                inside.fill(band, stripe)
            }
            inside.fill(Path(CGRect(x: 0, y: 28, width: 17, height: 64)), stripe)
            inside.ellipse(CGPoint(x: 52, y: 44), 16, 6, Color.white.opacity(0.3))
        }
        pen.stroke(body, Color(red: 0.85, green: 0.60, blue: 0.10).opacity(0.6), width: 1.6)
        // Antennes.
        var antennae = Path()
        antennae.move(to: CGPoint(x: 64, y: 38)); antennae.addQuadCurve(to: CGPoint(x: 70, y: 20), control: CGPoint(x: 64, y: 26))
        antennae.move(to: CGPoint(x: 56, y: 36)); antennae.addQuadCurve(to: CGPoint(x: 56, y: 19), control: CGPoint(x: 52, y: 27))
        pen.stroke(antennae, stripe, width: 2.6)
        pen.circle(CGPoint(x: 70, y: 20), 3.4, stripe)
        pen.circle(CGPoint(x: 56, y: 19), 3.4, stripe)
        // Visage.
        eye(CGPoint(x: 59, y: 51), 6.8, look: 0.35)
        eye(CGPoint(x: 70, y: 53), 8.2, look: 0.35)
        pen.circle(CGPoint(x: 73, y: 65), 3.8, Self.cheek.opacity(0.8))
        smile(from: CGPoint(x: 62, y: 66), to: CGPoint(x: 70, y: 66), depth: 5)
        buzzingWings(root: root, rest: (62, 78), up: (100, 112), down: (50, 64), length: 31, width: 20, front: true)
    }

    // MARK: Oiseau

    private func bird() {
        let base = tint ?? Color(red: 0.30, green: 0.62, blue: 0.96)
        let beak = Color(red: 1.0, green: 0.64, blue: 0.18)
        let flap = swing(0.3)
        // Queue.
        let tail = SceneryPath.polygon([CGPoint(x: 26, y: 52), CGPoint(x: 6, y: 40), CGPoint(x: 11, y: 52),
                                        CGPoint(x: 6, y: 64), CGPoint(x: 26, y: 61)])
        pen.fill(tail, base)
        pen.stroke(tail, base, width: 3)
        pen.fill(tail, Color.black.opacity(0.15))
        // Pattes.
        var feet = Path()
        feet.move(to: CGPoint(x: 44, y: 78)); feet.addLine(to: CGPoint(x: 42, y: 88))
        feet.move(to: CGPoint(x: 53, y: 79)); feet.addLine(to: CGPoint(x: 53, y: 89))
        pen.stroke(feet, beak, width: 2.8)
        // Corps rond, ventre clair.
        let body = SceneryPath.ellipse(CGPoint(x: 48, y: 56), 29, 26)
        pen.fill(body, base)
        pen.clipped(to: body) { inside in
            inside.ellipse(CGPoint(x: 58, y: 70), 21, 15, Color(red: 1.0, green: 0.90, blue: 0.68))
            inside.ellipse(CGPoint(x: 40, y: 40), 16, 9, Color.white.opacity(0.22))
            inside.ellipse(CGPoint(x: 40, y: 80), 30, 10, Color.black.opacity(0.08))
        }
        // Houppette.
        pen.local(at: CGPoint(x: 56, y: 32), rotation: .degrees(-20)) { h in
            h.ellipse(CGPoint(x: 0, y: -5), 3.5, 6.5, base)
        }
        pen.local(at: CGPoint(x: 51, y: 32), rotation: .degrees(-45)) { h in
            h.ellipse(CGPoint(x: 0, y: -4), 3, 5.5, base)
        }
        // Bec, œil, joue.
        var bk = Path()
        bk.move(to: CGPoint(x: 74, y: 46)); bk.addLine(to: CGPoint(x: 88, y: 51.5)); bk.addLine(to: CGPoint(x: 74, y: 57))
        bk.closeSubpath()
        pen.fill(bk, beak)
        pen.stroke(bk, beak, width: 2.5)
        pen.stroke(Path { p in p.move(to: CGPoint(x: 76, y: 51.5)); p.addLine(to: CGPoint(x: 86, y: 51.5)) },
                   Color(red: 0.85, green: 0.45, blue: 0.1), width: 1.2)
        let eyeC = CGPoint(x: 64, y: 46)
        pen.ellipse(eyeC, 5.4, 6.4, Self.ink)
        pen.circle(CGPoint(x: eyeC.x - 1.6, y: eyeC.y - 2.3), 2.1, .white)
        pen.circle(CGPoint(x: eyeC.x + 1.8, y: eyeC.y + 2.2), 0.9, .white)
        pen.circle(CGPoint(x: 68, y: 58), 3.8, Self.cheek.opacity(0.75))
        // Aile : repliée le long du corps au repos ; en vol, elle se lève au-dessus du dos puis s'abaisse.
        let wingAngle = time == nil ? 0 : 22 + 42 * Double(flap)
        pen.local(at: CGPoint(x: 52, y: 50), rotation: .degrees(wingAngle)) { w in
            let shape = SceneryPath.ellipse(CGPoint(x: -13, y: 5), 17, 10)
            w.fill(shape, base)
            w.fill(shape, Color.black.opacity(0.14))
            for k in 0..<3 {
                w.stroke(Path { p in
                    p.move(to: CGPoint(x: -18 - CGFloat(k) * 5, y: 2 + CGFloat(k) * 2))
                    p.addLine(to: CGPoint(x: -24 - CGFloat(k) * 5, y: 10 + CGFloat(k) * 2))
                }, Color.white.opacity(0.35), width: 1.4)
            }
        }
    }

    // MARK: Papillon (vu de dessus, tête à droite)

    private func butterfly() {
        let wingColor = tint ?? Color(red: 0.93, green: 0.45, blue: 0.80)
        let fold = time == nil ? 1 : 0.62 + 0.38 * swing(0.55)          // 1 : ailes grandes ouvertes
        let bodyColor = Color(red: 0.28, green: 0.23, blue: 0.34)
        for upper in [true, false] {
            var c = pen.ctx
            c.translateBy(x: 0, y: 50)
            c.scaleBy(x: 1, y: (upper ? 1 : -1) * fold)
            c.translateBy(x: 0, y: -50)
            let w = SketchPen(ctx: c)
            // Aile postérieure puis antérieure.
            w.local(at: CGPoint(x: 38, y: 36), rotation: .degrees(-28)) { hind in
                let shape = SceneryPath.ellipse(.zero, 13, 16)
                hind.fill(shape, wingColor)
                hind.fill(shape, Color.white.opacity(0.22))
                hind.stroke(shape, wingColor, width: 2.4)
                hind.stroke(shape, Color.black.opacity(0.28), width: 2.4)
                hind.circle(CGPoint(x: -2, y: -5), 3.4, Color(red: 1, green: 0.88, blue: 0.4))
            }
            w.local(at: CGPoint(x: 60, y: 28), rotation: .degrees(24)) { fore in
                let shape = SceneryPath.ellipse(.zero, 15, 22)
                fore.fill(shape, wingColor)
                fore.stroke(shape, wingColor, width: 2.6)
                fore.stroke(shape, Color.black.opacity(0.28), width: 2.6)
                fore.circle(CGPoint(x: 1, y: -9), 5, Color.white.opacity(0.9))
                fore.circle(CGPoint(x: -5, y: 4), 3, Color.white.opacity(0.9))
                fore.circle(CGPoint(x: 5, y: 7), 2.2, Color(red: 1, green: 0.88, blue: 0.4))
            }
        }
        // Corps, tête, antennes, visage.
        pen.fill(Path(roundedRect: CGRect(x: 28, y: 45, width: 44, height: 10), cornerRadius: 5), bodyColor)
        for x: CGFloat in [36, 44, 52] {
            pen.stroke(Path { p in p.move(to: CGPoint(x: x, y: 46)); p.addLine(to: CGPoint(x: x, y: 54)) },
                       Color.white.opacity(0.25), width: 1.2)
        }
        var antennae = Path()
        antennae.move(to: CGPoint(x: 80, y: 44)); antennae.addQuadCurve(to: CGPoint(x: 92, y: 30), control: CGPoint(x: 90, y: 42))
        antennae.move(to: CGPoint(x: 80, y: 56)); antennae.addQuadCurve(to: CGPoint(x: 92, y: 70), control: CGPoint(x: 90, y: 58))
        pen.stroke(antennae, bodyColor, width: 2.2)
        pen.circle(CGPoint(x: 92, y: 30), 2.8, bodyColor)
        pen.circle(CGPoint(x: 92, y: 70), 2.8, bodyColor)
        pen.circle(CGPoint(x: 76, y: 50), 10, bodyColor)
        eye(CGPoint(x: 79, y: 45.5), 4.2, look: 0.3)
        eye(CGPoint(x: 79, y: 54.5), 4.2, look: 0.3)
    }

    // MARK: Bulle de savon

    private func bubble() {
        around(CGPoint(x: 50, y: 50), sx: 1 + 0.04 * swing(1.7), sy: 1 - 0.04 * swing(1.7)) { p in
            let c = CGPoint(x: 50, y: 50), r: CGFloat = 38
            let disc = SceneryPath.circle(c, r)
            p.ctx.fill(disc, with: .radialGradient(Gradient(colors: [Color.white.opacity(0.04), Color(red: 0.7, green: 0.85, blue: 1).opacity(0.18),
                                                                     Color(red: 0.85, green: 0.7, blue: 1).opacity(0.38)]),
                                                   center: c, startRadius: 0, endRadius: r))
            p.ctx.stroke(disc, with: .conicGradient(Gradient(colors: [Color(red: 1, green: 0.55, blue: 0.8), Color(red: 1, green: 0.85, blue: 0.4),
                                                                      Color(red: 0.4, green: 0.9, blue: 0.95), Color(red: 0.6, green: 0.55, blue: 1),
                                                                      Color(red: 1, green: 0.55, blue: 0.8)]),
                                                    center: c, angle: .degrees(Double(20 + 30 * swing(3.1)))),
                         lineWidth: 3.6)
            var arc = Path()
            arc.addArc(center: c, radius: r - 7, startAngle: .degrees(195), endAngle: .degrees(250), clockwise: false)
            p.stroke(arc, Color.white.opacity(0.9), width: 5)
            p.circle(CGPoint(x: 62, y: 26), 3.6, Color.white.opacity(0.9))
            var low = Path()
            low.addArc(center: c, radius: r - 6, startAngle: .degrees(20), endAngle: .degrees(55), clockwise: false)
            p.stroke(low, Color.white.opacity(0.45), width: 3)
        }
    }

    // MARK: Goutte d'eau

    private func drop() {
        around(CGPoint(x: 50, y: 88), sx: 1 - 0.03 * swing(1.3), sy: 1 + 0.035 * swing(1.3)) { p in
            var d = Path()
            d.move(to: CGPoint(x: 50, y: 10))
            d.addCurve(to: CGPoint(x: 78, y: 62), control1: CGPoint(x: 58, y: 28), control2: CGPoint(x: 78, y: 40))
            d.addArc(center: CGPoint(x: 50, y: 62), radius: 28, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
            d.addCurve(to: CGPoint(x: 50, y: 10), control1: CGPoint(x: 22, y: 40), control2: CGPoint(x: 42, y: 28))
            d.closeSubpath()
            p.fill(d, from: CGPoint(x: 40, y: 20), to: CGPoint(x: 60, y: 90),
                   [Color(red: 0.62, green: 0.87, blue: 1.0), Color(red: 0.20, green: 0.56, blue: 0.96)])
            p.stroke(d, Color(red: 0.14, green: 0.44, blue: 0.86), width: 2.4)
            shine(p, CGPoint(x: 38, y: 58), 5.5, 11, angle: 20, alpha: 0.85)
            p.circle(CGPoint(x: 41, y: 76), 2.8, Color.white.opacity(0.7))
        }
    }

    // MARK: Note de musique

    private func note() {
        let color = tint ?? Color(red: 0.45, green: 0.36, blue: 0.95)
        around(CGPoint(x: 40, y: 72), rotation: 8 * swing(0.9)) { p in
            var flag = Path()
            flag.move(to: CGPoint(x: 56, y: 16))
            flag.addCurve(to: CGPoint(x: 76, y: 56), control1: CGPoint(x: 60, y: 30), control2: CGPoint(x: 84, y: 36))
            flag.addCurve(to: CGPoint(x: 56, y: 34), control1: CGPoint(x: 74, y: 44), control2: CGPoint(x: 64, y: 38))
            flag.closeSubpath()
            p.fill(flag, color)
            p.rect(CGRect(x: 51, y: 16, width: 6, height: 58), color, corner: 3)
            p.local(at: CGPoint(x: 40, y: 73), rotation: .degrees(-22)) { head in
                head.ellipse(.zero, 16, 11.5, color)
                head.ellipse(CGPoint(x: -3, y: -4), 7, 3.2, Color.white.opacity(0.5))
            }
            p.fill(Path(roundedRect: CGRect(x: 52.5, y: 20, width: 1.8, height: 42), cornerRadius: 1), Color.white.opacity(0.35))
        }
    }

    // MARK: Étincelle (braise)

    private func spark() {
        let flicker = time == nil ? 0 : (swing(0.37) + 0.6 * swing(0.23, 0.3)) / 1.6
        let c = CGPoint(x: 50, y: 50)
        pen.ctx.fill(SceneryPath.circle(c, 44), with: .radialGradient(
            Gradient(colors: [Color(red: 1, green: 0.62, blue: 0.2).opacity(0.75 + 0.2 * Double(flicker)),
                              Color(red: 1, green: 0.45, blue: 0.15).opacity(0.28), Color(red: 1, green: 0.4, blue: 0.1).opacity(0)]),
            center: c, startRadius: 0, endRadius: 44))
        around(c, rotation: 45 + 10 * flicker, sx: 0.9 + 0.1 * flicker, sy: 0.9 + 0.1 * flicker) { p in
            p.fill(SparkleShape().path(in: CGRect(x: 26, y: 26, width: 48, height: 48)), Color(red: 1, green: 0.52, blue: 0.16))
        }
        around(c, sx: 1 + 0.12 * flicker, sy: 1 + 0.12 * flicker) { p in
            p.fill(SparkleShape().path(in: CGRect(x: 18, y: 18, width: 64, height: 64)), Color(red: 1, green: 0.82, blue: 0.3))
            p.fill(SparkleShape().path(in: CGRect(x: 34, y: 34, width: 32, height: 32)), Color(red: 1, green: 0.98, blue: 0.85))
        }
        for (x, y, r) in [(80.0, 26.0, 2.6), (22.0, 76.0, 2.2), (78.0, 76.0, 1.8)] as [(CGFloat, CGFloat, CGFloat)] {
            pen.circle(CGPoint(x: x, y: y), r, Color(red: 1, green: 0.85, blue: 0.4).opacity(0.9))
        }
    }

    // MARK: Feuille d'automne (érable, pointe vers la droite)

    private func leaf() {
        let base = tint ?? Color(red: 0.96, green: 0.50, blue: 0.18)
        around(CGPoint(x: 50, y: 50), rotation: 72 + 12 * swing(1.5)) { p in
            // Demi-feuille droite (pointe en haut), puis son miroir.
            let right: [CGPoint] = [CGPoint(x: 0, y: -42), CGPoint(x: 7, y: -26), CGPoint(x: 19, y: -33), CGPoint(x: 16, y: -15),
                                    CGPoint(x: 35, y: -20), CGPoint(x: 27, y: -5), CGPoint(x: 40, y: 2), CGPoint(x: 22, y: 8),
                                    CGPoint(x: 25, y: 21), CGPoint(x: 7, y: 14), CGPoint(x: 3, y: 26)]
            let left = right.reversed().map { CGPoint(x: -$0.x, y: $0.y) }
            let pts = (right + left).map { CGPoint(x: $0.x + 50, y: $0.y + 48) }
            let shape = SceneryPath.polygon(pts)
            p.stroke(Path { q in q.move(to: CGPoint(x: 50, y: 70)); q.addLine(to: CGPoint(x: 50, y: 92)) },
                     Color(red: 0.62, green: 0.36, blue: 0.18), width: 3.2)
            p.fill(shape, base)
            p.stroke(shape, base, width: 7)
            p.ctx.fill(shape, with: .linearGradient(Gradient(colors: [Color(red: 1, green: 0.9, blue: 0.3).opacity(0.55),
                                                                      Color.clear, Color(red: 0.6, green: 0.1, blue: 0.1).opacity(0.25)]),
                                                    startPoint: CGPoint(x: 50, y: 8), endPoint: CGPoint(x: 50, y: 78)))
            var veins = Path()
            for tip in [CGPoint(x: 50, y: 12), CGPoint(x: 85, y: 28), CGPoint(x: 15, y: 28), CGPoint(x: 75, y: 62), CGPoint(x: 25, y: 62)] {
                veins.move(to: CGPoint(x: 50, y: 66))
                veins.addLine(to: CGPoint(x: 50 + (tip.x - 50) * 0.8, y: 66 + (tip.y - 66) * 0.8))
            }
            p.stroke(veins, Color(red: 1, green: 0.92, blue: 0.6).opacity(0.75), width: 1.8)
        }
    }

    // MARK: Étoile

    private func star() {
        let glint = time == nil ? 1 : SceneryMotion.twinkle(time ?? 0, period: 0.9)
        around(CGPoint(x: 50, y: 52), rotation: 7 * swing(1.4), sx: 1 + 0.05 * swing(1.4, 0.25), sy: 1 + 0.05 * swing(1.4, 0.25)) { p in
            let shape = SceneryPath.star(CGPoint(x: 50, y: 53), outer: 37, inner: 17)
            p.stroke(shape, Color(red: 0.93, green: 0.62, blue: 0.08), width: 10)
            p.fill(shape, top: 16, bottom: 88, [Color(red: 1, green: 0.93, blue: 0.45), Color(red: 1, green: 0.74, blue: 0.14)])
            p.stroke(shape, Color(red: 1, green: 0.86, blue: 0.3), width: 5)
            p.fill(SceneryPath.star(CGPoint(x: 46, y: 49), outer: 14, inner: 6.5), Color.white.opacity(0.35))
            shine(p, CGPoint(x: 40, y: 40), 6, 3, angle: -40, alpha: 0.8)
        }
        for (c, r) in [(CGPoint(x: 84, y: 18), 8.0), (CGPoint(x: 14, y: 30), 5.5)] as [(CGPoint, CGFloat)] {
            pen.fill(SparkleShape().path(in: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)),
                     Color(red: 1, green: 0.85, blue: 0.3).opacity(0.35 + 0.65 * Double(glint)))
        }
    }

    // MARK: Plume

    private func feather() {
        let base = tint ?? Color(red: 0.70, green: 0.84, blue: 1.0)
        around(CGPoint(x: 14, y: 78), rotation: 10 * swing(2.2)) { p in
            var vane = Path()
            vane.move(to: CGPoint(x: 22, y: 72))
            vane.addCurve(to: CGPoint(x: 90, y: 14), control1: CGPoint(x: 26, y: 40), control2: CGPoint(x: 64, y: 14))
            vane.addCurve(to: CGPoint(x: 30, y: 78), control1: CGPoint(x: 86, y: 42), control2: CGPoint(x: 60, y: 70))
            vane.closeSubpath()
            p.fill(vane, base)
            p.ctx.fill(vane, with: .linearGradient(Gradient(colors: [Color.white.opacity(0.55), Color.white.opacity(0)]),
                                                   startPoint: CGPoint(x: 30, y: 30), endPoint: CGPoint(x: 70, y: 70)))
            p.stroke(vane, base, width: 2)
            p.stroke(vane, Color.black.opacity(0.18), width: 2)
            // Encoches (barbes séparées).
            for (a, b) in [(CGPoint(x: 40, y: 40), CGPoint(x: 48, y: 47)), (CGPoint(x: 70, y: 52), CGPoint(x: 62, y: 50))] {
                p.stroke(Path { q in q.move(to: a); q.addLine(to: b) }, Color.white.opacity(0.9), width: 2.4)
            }
            var rachis = Path()
            rachis.move(to: CGPoint(x: 10, y: 88))
            rachis.addCurve(to: CGPoint(x: 88, y: 16), control1: CGPoint(x: 36, y: 62), control2: CGPoint(x: 62, y: 28))
            p.stroke(rachis, Color.white.opacity(0.95), width: 3)
            p.stroke(rachis, Color.black.opacity(0.12), width: 1)
        }
    }

    // MARK: Tache de peinture

    private func paint() {
        let color = tint ?? Color(red: 0.95, green: 0.32, blue: 0.38)
        around(CGPoint(x: 50, y: 50), sx: 1 + 0.04 * swing(1.2), sy: 1 - 0.04 * swing(1.2)) { p in
            // Éclaboussure : une flaque ronde aux bords bosselés (jamais une étoile), une coulure,
            // des gouttelettes projetées tout autour.
            let center = CGPoint(x: 49, y: 47)
            var blob = Path()
            let radii: [CGFloat] = [29, 27, 30, 28, 31, 27, 29, 28]
            let pts = radii.enumerated().map { i, r -> CGPoint in
                let a = CGFloat(i) * 2 * .pi / CGFloat(radii.count) - .pi / 2
                return CGPoint(x: center.x + cos(a) * r, y: center.y + sin(a) * r)
            }
            blob.move(to: pts[0])
            SceneryPath.addSmooth(&blob, through: pts + [pts[0], pts[1]])
            blob.closeSubpath()
            // Chaque morceau peint à part dans un calque, puis le modelé appliqué seulement sur la peinture.
            p.ctx.drawLayer { layer in
                let lp = SketchPen(ctx: layer)
                lp.fill(blob, color)
                for (angle, dist, r) in [(-65.0, 27.0, 10.0), (15.0, 28.0, 9.0), (100.0, 26.0, 8.0), (195.0, 27.0, 10.5)]
                    as [(Double, CGFloat, CGFloat)] {
                    let a = CGFloat(angle * .pi / 180)
                    lp.circle(CGPoint(x: center.x + cos(a) * dist, y: center.y + sin(a) * dist), r, color)
                }
                lp.rect(CGRect(x: 58, y: 60, width: 9, height: 24), color, corner: 4.5)
                lp.circle(CGPoint(x: 62.5, y: 85), 5.5, color)
                for (angle, dist, r) in [(-35.0, 43.0, 4.6), (45.0, 42.0, 3.6), (150.0, 42.0, 4.2), (235.0, 42.0, 3.4),
                                         (-100.0, 44.0, 2.8)] as [(Double, CGFloat, CGFloat)] {
                    let a = CGFloat(angle * .pi / 180)
                    lp.circle(CGPoint(x: center.x + cos(a) * dist, y: center.y + sin(a) * dist), r, color)
                }
                var shade = layer
                shade.blendMode = .sourceAtop
                shade.fill(Path(CGRect(x: 0, y: 0, width: 100, height: 100)),
                           with: .linearGradient(Gradient(colors: [Color.white.opacity(0.3), Color.clear, Color.black.opacity(0.16)]),
                                                 startPoint: CGPoint(x: 30, y: 16), endPoint: CGPoint(x: 70, y: 88)))
            }
            shine(p, CGPoint(x: 37, y: 36), 9, 5, angle: -35, alpha: 0.7)
            p.circle(CGPoint(x: 50, y: 29), 2.8, Color.white.opacity(0.7))
        }
    }

    // MARK: Cœur

    private func heart() {
        let beat = time == nil ? 0 : pow(max(0, swing(1.1)), 3)
        around(CGPoint(x: 50, y: 52), sx: 1 + 0.08 * beat, sy: 1 + 0.08 * beat) { p in
            var h = Path()
            h.move(to: CGPoint(x: 50, y: 86))
            h.addCurve(to: CGPoint(x: 12, y: 38), control1: CGPoint(x: 30, y: 70), control2: CGPoint(x: 12, y: 58))
            h.addCurve(to: CGPoint(x: 50, y: 28), control1: CGPoint(x: 12, y: 14), control2: CGPoint(x: 44, y: 12))
            h.addCurve(to: CGPoint(x: 88, y: 38), control1: CGPoint(x: 56, y: 12), control2: CGPoint(x: 88, y: 14))
            h.addCurve(to: CGPoint(x: 50, y: 86), control1: CGPoint(x: 88, y: 58), control2: CGPoint(x: 70, y: 70))
            h.closeSubpath()
            p.fill(h, top: 18, bottom: 86, [Color(red: 1, green: 0.55, blue: 0.70), Color(red: 0.94, green: 0.30, blue: 0.50)])
            p.stroke(h, Color(red: 0.85, green: 0.22, blue: 0.42), width: 2.2)
            shine(p, CGPoint(x: 30, y: 34), 8, 4.5, angle: -40, alpha: 0.8)
            p.circle(CGPoint(x: 23, y: 46), 2.6, Color.white.opacity(0.7))
        }
    }

    // MARK: Flocon

    private func snowflake() {
        let spin = time.map { CGFloat($0.truncatingRemainder(dividingBy: 12) * 30) } ?? 0
        around(CGPoint(x: 50, y: 50), rotation: spin) { p in
            var arms = Path()
            for i in 0..<6 {
                let a = CGFloat(i) * .pi / 3 - .pi / 2
                let dir = CGPoint(x: cos(a), y: sin(a))
                func at(_ d: CGFloat) -> CGPoint { CGPoint(x: 50 + dir.x * d, y: 50 + dir.y * d) }
                arms.move(to: at(8)); arms.addLine(to: at(38))
                for (d, len) in [(18.0, 9.0), (28.0, 7.0)] as [(CGFloat, CGFloat)] {
                    for side: CGFloat in [-1, 1] {
                        let b = a + side * .pi / 4
                        arms.move(to: at(d))
                        arms.addLine(to: CGPoint(x: at(d).x + cos(b) * len, y: at(d).y + sin(b) * len))
                    }
                }
            }
            p.stroke(arms, Color(red: 0.40, green: 0.62, blue: 0.95), width: 8)
            p.stroke(arms, Color(red: 0.92, green: 0.97, blue: 1.0), width: 4.4)
            let hex = SceneryPath.star(CGPoint(x: 50, y: 50), outer: 10, inner: 8.6, branches: 6)
            p.fill(hex, Color(red: 0.40, green: 0.62, blue: 0.95))
            p.fill(SceneryPath.star(CGPoint(x: 50, y: 50), outer: 7, inner: 6, branches: 6), Color(red: 0.92, green: 0.97, blue: 1.0))
        }
    }
}

#Preview("Bestioles") {
    LazyVGrid(columns: Array(repeating: GridItem(.fixed(96)), count: 7), spacing: 16) {
        ForEach(CritterKind.allCases, id: \.self) { CritterView(kind: $0, size: 80) }
    }
    .padding(30)
    .background(EveilPalette.skyLight)
}
#endif
