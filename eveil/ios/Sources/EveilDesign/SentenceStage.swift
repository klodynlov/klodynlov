// SentenceStage.swift — la page du livre où la phrase se joue.
//
// Le train des phrases remplit la scène wagon après wagon : le sujet apparaît dès qu'il
// est choisi, puis l'objet ou le lieu ; quand la phrase est complète, `playStart` lance
// le mouvement du verbe (`SentenceMotion`). Au niveau 3, le sujet commence par aller à
// sa place — DANS la boîte (entre le fond et le devant de la boîte), SUR la table,
// DERRIÈRE l'arbre… (ancres des lieux, `PictoDrawing.anchors`) — puis joue le verbe là.
//
// Tout est peint dans UN Canvas (décor, lieu, sujet, objet, petites choses qui volent),
// à partir de l'heure : aucune animation SwiftUI (cf. `WordArt`). L'horloge ne tourne que
// pendant le mouvement ; ensuite la scène reste sur son dernier instant (la pêche mangée
// a disparu). « Réduire les animations » : on montre directement la fin.

#if canImport(SwiftUI)
import SwiftUI

public struct SentenceStage: View {
    public let scene: SentenceScene
    /// L'instant où la phrase a commencé à se jouer (nil : chacun à sa place, au repos).
    public let playStart: Date?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var clockOn = false

    /// Temps pour aller jusqu'au lieu (niveau 3), avant le verbe.
    static let travel = 1.0

    public init(scene: SentenceScene, playStart: Date?) {
        self.scene = scene
        self.playStart = playStart
    }

    /// Durée totale de la scène jouée (trajet jusqu'au lieu compris).
    public static func duration(of scene: SentenceScene) -> Double {
        guard let verb = scene.verb else { return 0 }
        return (scene.place != nil ? travel : 0) + SentenceMotion.duration(verb)
    }

    /// Les bruitages de la scène : (instant depuis `playStart`, son).
    public static func cues(of scene: SentenceScene) -> [(Double, SceneSound)] {
        guard let verb = scene.verb else { return [] }
        let shift = scene.place != nil ? travel : 0
        var out = SentenceMotion.cues(verb).map { ($0.0 + shift, $0.1) }
        if scene.place != nil { out.insert((0.15, .hop), at: 0) }
        return out
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60, paused: !clockOn || reduceMotion)) { timeline in
            Canvas { context, size in
                let t: Double? = playStart.map { start in
                    reduceMotion ? Self.duration(of: scene)
                                 : min(Self.duration(of: scene), max(0, timeline.date.timeIntervalSince(start)))
                }
                StagePainter.paint(context, size: size, scene: scene, t: t)
            }
        }
        .task(id: playStart) {
            guard let playStart, !reduceMotion else {
                clockOn = false
                return
            }
            clockOn = true
            let left = Self.duration(of: scene) - Date().timeIntervalSince(playStart) + 0.15
            if left > 0 { try? await Task.sleep(nanoseconds: UInt64(left * 1_000_000_000)) }
            if !Task.isCancelled { clockOn = false }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Le peintre

enum StagePainter {
    private typealias P = WordArtPaint

    /// Côté des carrés des personnages au repos (fraction de la hauteur de la scène).
    static let soloSize: CGFloat = 0.66
    static let subjectSize: CGFloat = 0.6
    static let objectSize: CGFloat = 0.36
    static let placeSize: CGFloat = 0.8
    static let ground: CGFloat = 0.9
    /// Dans un carré de dessin (200 × 200), les pieds sont vers y = 179.
    static let feet: CGFloat = 179.0 / 200

    /// Les objets tenus passent DEVANT le sujet ; les autres derrière lui.
    static let heldObject: Set<String> = ["porter", "attraper", "lancer"]

    static func paint(_ context: GraphicsContext, size: CGSize, scene: SentenceScene, t: Double?) {
        guard size.height > 1 else { return }
        var g = context
        g.scaleBy(x: size.height, y: size.height)
        let width = size.width / size.height
        backdrop(g, width: width)

        let place = scene.place.flatMap(PictoLibrary.drawing)
        let anchor = scene.preposition.flatMap { place?.anchors[$0] }
        let placeBox = Self.placeBox(width: width)

        // Où est le sujet au repos, et où serait l'objet.
        var layout: SceneLayout
        if scene.object != nil {
            layout = SceneLayout(width: width, subjectBase: CGPoint(x: width * 0.3, y: ground), subjectSize: subjectSize,
                                 objectBase: CGPoint(x: width * 0.72, y: ground), objectSize: objectSize)
        } else if place != nil {
            layout = SceneLayout(width: width, subjectBase: CGPoint(x: width * 0.2, y: ground), subjectSize: subjectSize * 0.9)
        } else {
            layout = SceneLayout(width: width, subjectBase: CGPoint(x: width / 2, y: ground), subjectSize: soloSize)
        }

        // Le trajet jusqu'au lieu (niveau 3) : petits bonds, taille de l'ancre à l'arrivée.
        var travelPose = ActorPose()
        var arrived = false
        var verbTime: Double?
        if let t {
            if let anchor, scene.verb != nil {
                let (target, targetSize) = stand(at: anchor, in: placeBox)
                let go = P.easeInOut(P.seg(t, 0, SentenceStage.travel))
                let hops = P.hop(SentenceMotion.cycle(min(t, SentenceStage.travel), SentenceStage.travel / 3))
                travelPose.dx = (target.x - layout.subjectBase.x) * CGFloat(go)
                travelPose.dy = (target.y - layout.subjectBase.y) * CGFloat(go) - 0.08 * CGFloat(hops) * CGFloat(1 - go)
                travelPose.scale = 1 + (targetSize / layout.subjectSize - 1) * CGFloat(go)
                arrived = go > 0.8
                if t >= SentenceStage.travel {
                    layout.subjectBase = target
                    layout.subjectSize = targetSize
                    travelPose = ActorPose()
                    verbTime = t - SentenceStage.travel
                }
            } else {
                verbTime = t
            }
        }

        var frame = SceneFrame()
        if let verb = scene.verb, let vt = verbTime {
            frame = SentenceMotion.frame(verb: verb, t: vt, layout: layout)
            if anchor != nil {
                // Au lieu : le lieu cache déjà (pas de buisson), l'eau du bain est dessinée.
                frame.front.removeAll { $0.kind == .bush || $0.kind == .waves }
                frame.behind.removeAll { $0.kind == .bush }
            }
        } else {
            frame.subject = travelPose
        }
        if verbTime == nil { frame.subject = travelPose }

        // L'ordre de dessin : derrière le lieu, dedans, ou devant.
        let order: PictoOrder = (anchor != nil && (arrived || verbTime != nil)) ? anchor!.order : .front
        let subjectID = scene.subject
        let verb = scene.verb ?? ""

        func drawSubject() {
            guard let subjectID else { return }
            actor(g, subjectID, base: layout.subjectBase, size: layout.subjectSize, pose: frame.subject,
                  facesLeft: scene.subjectFacesLeft, playing: t != nil)
        }
        func drawObject() {
            guard let objectID = scene.object, let base = layout.objectBase else { return }
            // L'objet regarde le sujet (vers la gauche) : on retourne ceux qui regardent à droite.
            actor(g, objectID, base: base, size: layout.objectSize, pose: frame.object,
                  facesLeft: !scene.objectFacesLeft, playing: t != nil)
        }

        for p in frame.behind { particle(g, p) }
        if let place {
            let placed = placeContext(g, placeBox)
            switch order {
            case .behind:
                drawSubject()
                place.paint(placed, layers: .all)
            case .inside:
                place.paint(placed, layers: .back)
                drawSubject()
                place.paint(placed, layers: .front)
            case .front:
                place.paint(placed, layers: .all)
                drawSubject()
            }
        } else if heldObject.contains(verb) {
            drawSubject()
            drawObject()
        } else {
            drawObject()
            drawSubject()
        }
        for p in frame.front { particle(g, p) }
    }

    /// Le carré du lieu dans la scène : ses pieds (y = 179/200) sur le sol, à droite.
    static func placeBox(width: CGFloat) -> CGRect {
        CGRect(x: width * 0.62 - placeSize / 2, y: ground - feet * placeSize, width: placeSize, height: placeSize)
    }

    /// Le sujet posé à l'ancre : ses pieds et le côté de son carré. L'ancre est le bas-milieu du
    /// carré du personnage (eveil/outils/pictos/lieux.py) ; ses pieds sont 21/200 plus haut.
    static func stand(at anchor: PictoAnchor, in box: CGRect) -> (base: CGPoint, size: CGFloat) {
        let side = anchor.size * box.height
        return (CGPoint(x: box.minX + anchor.x / 200 * box.width,
                        y: box.minY + anchor.y / 200 * box.height - (1 - feet) * side), side)
    }

    private static func placeContext(_ g: GraphicsContext, _ box: CGRect) -> GraphicsContext {
        var c = g
        c.translateBy(x: box.minX, y: box.minY)
        c.scaleBy(x: box.width / 200, y: box.height / 200)
        return c
    }

    /// Un personnage (dessin d'un mot, ou picto) : pieds en `base`, carré de côté `size`,
    /// regardant vers la droite (retourné s'il regarde à gauche), dans sa pose.
    static func actor(_ g: GraphicsContext, _ id: String, base: CGPoint, size: CGFloat, pose: ActorPose,
                      facesLeft: Bool, playing: Bool) {
        guard pose.opacity > 0.01, pose.scale > 0.01 else { return }
        var c = g
        c.opacity *= pose.opacity
        let s = size * pose.scale
        let foot = CGPoint(x: base.x + pose.dx, y: base.y + pose.dy)
        c.translateBy(x: foot.x, y: foot.y)
        c.rotate(by: .degrees(pose.rotation))
        let flip: CGFloat = (facesLeft != pose.turned) ? -1 : 1
        c.scaleBy(x: pose.sx * flip, y: pose.sy)
        // Repère du dessin : 200 × 200, pieds (100, 179) au point de base.
        c.scaleBy(x: s / 200, y: s / 200)
        c.translateBy(x: -100, y: -179)
        if let subject = WordArtSubject(rawValue: id) {
            let clock = playing ? Date().timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600) + 1 : 0
            let artPose = WordArtPose(t: pose.act, blink: pose.eyesClosed && subject.hasEyes,
                                      idle: subject.idle == .flow ? clock : 0)
            WordArtPaint.paint(subject, WordArtBrush(c), artPose)
        } else if let drawing = PictoLibrary.drawing(id) {
            drawing.paint(c)
        }
    }

    // MARK: Décor

    static func backdrop(_ g: GraphicsContext, width: CGFloat) {
        let all = CGRect(x: 0, y: 0, width: width, height: 1)
        g.fill(Path(all), with: .linearGradient(Gradient(colors: [EveilPalette.skyLight, EveilPalette.sky.opacity(0.55)]),
                                                 startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: ground)))
        g.fill(P.disk(width * 0.1, 0.14, 0.07), with: .color(EveilPalette.sun))
        g.fill(P.oval(width * 0.2, ground + 0.08, width * 0.45, 0.28), with: .color(EveilPalette.hill.opacity(0.55)))
        g.fill(P.oval(width * 0.85, ground + 0.1, width * 0.4, 0.24), with: .color(EveilPalette.hill.opacity(0.45)))
        g.fill(Path(CGRect(x: 0, y: ground - 0.03, width: width, height: 1 - ground + 0.03)),
               with: .color(EveilPalette.grass))
        g.fill(Path(CGRect(x: 0, y: ground - 0.03, width: width, height: 0.012)),
               with: .color(EveilPalette.hill.opacity(0.7)))
    }

    // MARK: Petites choses qui volent

    static let zColor = WordArtPaint.hex(0x7C8CD6)
    static let noteColors: [Color] = [WordArtPaint.hex(0x9457DB), WordArtPaint.hex(0xE84393), WordArtPaint.hex(0x3E7BD6)]
    static let heartColor = WordArtPaint.hex(0xFF5E8A)
    static let dropColor = WordArtPaint.hex(0x4AA8F0)
    static let crumbColor = WordArtPaint.hex(0xC98B4E)
    static let puffColor = WordArtPaint.hex(0xEDE7DC)
    static let windColor = WordArtPaint.hex(0x8CAADC)
    static let leafColors: [Color] = [WordArtPaint.hex(0x4FA83D), WordArtPaint.hex(0x67C04F), WordArtPaint.hex(0x3D8C31)]
    static let ropeColor = WordArtPaint.hex(0x9C6B3C)
    static let waterColor = WordArtPaint.hex(0x4AA8F0)

    static func particle(_ g: GraphicsContext, _ p: Particle) {
        guard p.opacity > 0.01 else { return }
        var c = g
        c.opacity *= p.opacity
        let s = p.size
        switch p.kind {
        case .zzz:
            var z = Path()
            z.move(to: CGPoint(x: p.x - s / 2, y: p.y - s / 2))
            z.addLine(to: CGPoint(x: p.x + s / 2, y: p.y - s / 2))
            z.addLine(to: CGPoint(x: p.x - s / 2, y: p.y + s / 2))
            z.addLine(to: CGPoint(x: p.x + s / 2, y: p.y + s / 2))
            c.stroke(z, with: .color(zColor), style: StrokeStyle(lineWidth: s * 0.2, lineCap: .round, lineJoin: .round))
        case .note:
            let color = noteColors[abs(Int(p.rotation * 7)) % noteColors.count]
            c.fill(P.oval(p.x - s * 0.18, p.y + s * 0.32, s * 0.24, s * 0.18), with: .color(color))
            var stem = Path()
            stem.move(to: CGPoint(x: p.x + s * 0.04, y: p.y + s * 0.3))
            stem.addLine(to: CGPoint(x: p.x + s * 0.04, y: p.y - s * 0.4))
            stem.addQuadCurve(to: CGPoint(x: p.x + s * 0.32, y: p.y - s * 0.12),
                              control: CGPoint(x: p.x + s * 0.3, y: p.y - s * 0.34))
            c.stroke(stem, with: .color(color), style: StrokeStyle(lineWidth: s * 0.1, lineCap: .round))
        case .heart:
            c.fill(P.heart(p.x, p.y, s / 2), with: .color(heartColor))
        case .bubble:
            c.fill(P.disk(p.x, p.y, s), with: .color(P.bubbleTint.opacity(0.28)))
            c.stroke(P.disk(p.x, p.y, s), with: .color(P.bubbleTint.opacity(0.9)), lineWidth: max(0.002, s * 0.16))
            c.fill(P.oval(p.x - s * 0.36, p.y - s * 0.4, s * 0.3, s * 0.2), with: .color(.white.opacity(0.95)))
        case .drop:
            var d = Path()
            d.move(to: CGPoint(x: p.x, y: p.y - s * 1.2))
            d.addQuadCurve(to: CGPoint(x: p.x + s * 0.7, y: p.y + s * 0.2), control: CGPoint(x: p.x + s * 0.6, y: p.y - s * 0.4))
            d.addArc(center: CGPoint(x: p.x, y: p.y + s * 0.2), radius: s * 0.7, startAngle: .degrees(0),
                     endAngle: .degrees(180), clockwise: false)
            d.addQuadCurve(to: CGPoint(x: p.x, y: p.y - s * 1.2), control: CGPoint(x: p.x - s * 0.6, y: p.y - s * 0.4))
            c.fill(d, with: .color(dropColor))
        case .crumb:
            c.fill(P.disk(p.x, p.y, s), with: .color(crumbColor))
        case .spark:
            c.fill(P.star4(p.x, p.y, s), with: .color(P.sparkleGold))
        case .puff:
            c.fill(P.disk(p.x, p.y, s), with: .color(puffColor))
            c.fill(P.disk(p.x + s * 0.7, p.y + s * 0.2, s * 0.7), with: .color(puffColor))
        case .swirl:
            var r = c
            r.translateBy(x: p.x, y: p.y)
            r.rotate(by: .degrees(p.rotation))
            var arc = Path()
            arc.addArc(center: .zero, radius: s / 2, startAngle: .degrees(20), endAngle: .degrees(150), clockwise: false)
            var arc2 = Path()
            arc2.addArc(center: .zero, radius: s / 2, startAngle: .degrees(200), endAngle: .degrees(330), clockwise: false)
            let style = StrokeStyle(lineWidth: s * 0.05, lineCap: .round)
            r.stroke(arc, with: .color(windColor), style: style)
            r.stroke(arc2, with: .color(windColor), style: style)
        case .joy:
            for k in 0..<2 {
                var a = Path()
                let x = p.x + CGFloat(k) * s * 0.9
                a.addArc(center: CGPoint(x: x, y: p.y), radius: s * 0.45, startAngle: .degrees(200),
                         endAngle: .degrees(340), clockwise: false)
                c.stroke(a, with: .color(P.ink.opacity(0.55)), style: StrokeStyle(lineWidth: s * 0.14, lineCap: .round))
            }
        case .scent:
            var w = Path()
            for k in 0...16 {
                let u = CGFloat(k) / 16
                let pt = CGPoint(x: p.x - s * 0.5 + s * u, y: p.y + s * 0.12 * CGFloat(sin(Double(u) * 4 * .pi)))
                if k == 0 { w.move(to: pt) } else { w.addLine(to: pt) }
            }
            c.stroke(w, with: .color(heartColor.opacity(0.8)), style: StrokeStyle(lineWidth: s * 0.08, lineCap: .round))
        case .wind:
            for (k, dy) in [CGFloat(-0.035), 0, 0.035].enumerated() {
                var line = Path()
                let len = s * (k == 1 ? 1 : 0.7)
                line.move(to: CGPoint(x: p.x, y: p.y + dy))
                line.addLine(to: CGPoint(x: p.x + p.x2 * len, y: p.y + dy))
                c.stroke(line, with: .color(windColor), style: StrokeStyle(lineWidth: 0.012, lineCap: .round))
            }
        case .bush:
            // Des boules de feuillage posées au sol, devant le personnage.
            let h = s * 0.62
            for k in 0..<5 {
                let fx = p.x + s * CGFloat([-0.36, -0.16, 0.06, 0.26, 0.4][k])
                let fy = p.y - h * CGFloat([0.35, 0.6, 0.7, 0.55, 0.32][k])
                c.fill(P.disk(fx, fy, s * CGFloat([0.2, 0.24, 0.26, 0.23, 0.18][k])),
                       with: .color(leafColors[k % leafColors.count]))
            }
            c.fill(Path(CGRect(x: p.x - s * 0.5, y: p.y - h * 0.32, width: s, height: h * 0.32 + 0.02)),
                   with: .color(leafColors[1]))
        case .rope:
            var rope = Path()
            rope.move(to: CGPoint(x: p.x, y: p.y))
            rope.addQuadCurve(to: CGPoint(x: p.x2, y: p.y2),
                              control: CGPoint(x: (p.x + p.x2) / 2, y: max(p.y, p.y2) + 0.02))
            c.stroke(rope, with: .color(ropeColor), style: StrokeStyle(lineWidth: s, lineCap: .round))
        case .waves:
            var water = Path()
            let left = p.x - s / 2, right = p.x + s / 2
            water.move(to: CGPoint(x: left, y: ground + 0.06))
            for k in 0...24 {
                let u = CGFloat(k) / 24
                water.addLine(to: CGPoint(x: left + (right - left) * u,
                                          y: p.y + 0.015 * CGFloat(sin(Double(u) * 6 * .pi + p.rotation * 4))))
            }
            water.addLine(to: CGPoint(x: right, y: ground + 0.06))
            water.closeSubpath()
            c.fill(water, with: .color(waterColor.opacity(0.85)))
        }
    }
}
#endif
