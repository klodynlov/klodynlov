// WordArtKit.swift — la boîte à crayons des dessins de mots (`WordArt`).
//
// Même technique que la mascotte : chaque dessin est peint dans un repère FIXE de
// 200 × 200 points (marge ≈ 8 % : le sujet tient dans 16…184), puis mis à
// l'échelle du carré demandé. Formes plates et arrondies, couleurs vives mais
// accordées, pas de contour noir ; les yeux des animaux reprennent ceux du chat
// chef de gare (ovale sombre + reflet blanc).
//
// Un dessin est une fonction PURE de sa pose (`WordArtPose`) : ni état ni horloge
// ici, c'est `WordArt` qui lit l'heure (TimelineView) et fait avancer `t` quand
// l'enfant touche l'image. On peint dans un `Canvas` (un seul calque, redessiné
// d'un bloc) : peu coûteux, même pendant l'action à 120 images/s sur iPad Pro.
//
// Tous les noms commencent par `WordArt` (module partagé avec les mondes et les
// bestioles) ; les petites fonctions de tracé vivent dans l'espace `WordArtPaint`.

#if canImport(SwiftUI)
import SwiftUI

/// Un instant du dessin.
struct WordArtPose: Sendable, Equatable {
    /// Avancement de l'« action » déclenchée par le toucher : 0 = repos, puis 0 → 1.
    /// Chaque action revient EXACTEMENT au repos en t = 1 (pas de saut en fin d'animation).
    var t: Double = 0
    /// Paupières baissées (clignement au repos, animaux seulement).
    var blink: Bool = false
    /// Horloge du mouvement de repos, en secondes (0 = immobile : « Réduire les animations »).
    var idle: Double = 0

    init(t: Double = 0, blink: Bool = false, idle: Double = 0) {
        self.t = t
        self.blink = blink
        self.idle = idle
    }

    /// Oscillation de repos -1…1 de période `period` secondes (0 quand l'horloge est arrêtée).
    func sway(_ period: Double, offset: Double = 0) -> Double {
        guard idle != 0 else { return 0 }
        return sin(2 * .pi * (idle / period + offset))
    }

    /// Avancement cyclique 0…1 de période `period` secondes (gouttes qui tombent, vapeur qui monte).
    /// Immobile : `rest` (la position dessinée sur la planche).
    func cycle(_ period: Double, offset: Double = 0, rest: Double = 0.5) -> Double {
        guard idle != 0 else { return rest }
        let x = idle / period + offset
        return x - x.rounded(.down)
    }
}

/// Le pinceau : un contexte de `Canvas` déjà placé dans le repère 200 × 200.
/// Les transformations renvoient un NOUVEAU pinceau (l'original ne bouge pas).
struct WordArtBrush {
    var gc: GraphicsContext

    init(_ gc: GraphicsContext) { self.gc = gc }

    // MARK: Peindre

    func fill(_ path: Path, _ color: Color) {
        gc.fill(path, with: .color(color))
    }

    /// Remplissage pair-impair : les trous (anneaux, cibles, fenêtres) restent vides.
    func fillEO(_ path: Path, _ color: Color) {
        gc.fill(path, with: .color(color), style: FillStyle(eoFill: true))
    }

    func linear(_ path: Path, _ colors: [Color], from: CGPoint, to: CGPoint) {
        gc.fill(path, with: .linearGradient(Gradient(colors: colors), startPoint: from, endPoint: to))
    }

    func radial(_ path: Path, _ colors: [Color], center: CGPoint, radius: CGFloat) {
        gc.fill(path, with: .radialGradient(Gradient(colors: colors), center: center,
                                            startRadius: 0, endRadius: radius))
    }

    /// Polygone aux coins adoucis : un trait de même couleur arrondit les angles (oreilles, toit, bec…).
    func fillRounded(_ path: Path, _ color: Color, _ radius: CGFloat) {
        fill(path, color)
        gc.stroke(path, with: .color(color),
                  style: StrokeStyle(lineWidth: radius * 2, lineCap: .round, lineJoin: .round))
    }

    /// Trait à bouts ronds (moustaches, pattes d'insecte, traits de son).
    func stroke(_ path: Path, _ color: Color, _ width: CGFloat) {
        gc.stroke(path, with: .color(color),
                  style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    /// Trait pointillé ; `phase` fait défiler les tirets (eau qui coule, fermeture éclair).
    func dashed(_ path: Path, _ color: Color, _ width: CGFloat, dash: [CGFloat], phase: CGFloat = 0) {
        gc.stroke(path, with: .color(color),
                  style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round, dash: dash, dashPhase: phase))
    }

    // MARK: Transformer

    func moved(_ dx: CGFloat, _ dy: CGFloat) -> WordArtBrush {
        var g = gc
        g.translateBy(x: dx, y: dy)
        return WordArtBrush(g)
    }

    /// Rotation (degrés, sens horaire à l'écran) autour du point (x, y).
    func rotated(_ degrees: Double, _ x: CGFloat, _ y: CGFloat) -> WordArtBrush {
        guard degrees != 0 else { return self }
        var g = gc
        g.translateBy(x: x, y: y)
        g.rotate(by: .degrees(degrees))
        g.translateBy(x: -x, y: -y)
        return WordArtBrush(g)
    }

    /// Mise à l'échelle autour du point (x, y) (écrasement / étirement).
    func scaled(_ sx: CGFloat, _ sy: CGFloat, _ x: CGFloat, _ y: CGFloat) -> WordArtBrush {
        guard sx != 1 || sy != 1 else { return self }
        var g = gc
        g.translateBy(x: x, y: y)
        g.scaleBy(x: sx, y: sy)
        g.translateBy(x: -x, y: -y)
        return WordArtBrush(g)
    }

    /// Opacité appliquée à CHAQUE forme (à réserver aux formes qui ne se chevauchent pas).
    func faded(_ opacity: Double) -> WordArtBrush {
        var g = gc
        g.opacity *= opacity
        return WordArtBrush(g)
    }

    /// Tout ce qui suit est découpé par `path` (taches de la vache, rayures…).
    func clipped(_ path: Path) -> WordArtBrush {
        var g = gc
        g.clip(to: path)
        return WordArtBrush(g)
    }

    /// Un groupe fondu d'un bloc (pas de coutures entre formes qui se chevauchent).
    func layer(opacity: Double, _ draw: (WordArtBrush) -> Void) {
        guard opacity > 0.001 else { return }
        gc.drawLayer { layer in
            layer.opacity = opacity
            draw(WordArtBrush(layer))
        }
    }

    // MARK: Motifs communs

    /// Ombre douce au sol : ancre l'objet sur la carte blanche.
    func groundShadow(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat = 7, darkness: Double = 1) {
        fill(WordArtPaint.oval(cx, cy, rx, ry), Color.black.opacity(0.09 * darkness))
    }

    /// Un œil de la famille de la mascotte : ovale sombre + reflet. `blink` : paupière
    /// baissée (trait arrondi) ; `happy` : œil rieur (^).
    func eye(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, blink: Bool = false, happy: Bool = false,
             lookX: CGFloat = 0, lookY: CGFloat = 0) {
        if blink {
            var p = Path()
            p.move(to: CGPoint(x: x - r * 0.95, y: y))
            p.addQuadCurve(to: CGPoint(x: x + r * 0.95, y: y), control: CGPoint(x: x, y: y + r * 0.75))
            stroke(p, WordArtPaint.ink, max(1.6, r * 0.42))
        } else if happy {
            var p = Path()
            p.move(to: CGPoint(x: x - r * 0.95, y: y + r * 0.35))
            p.addQuadCurve(to: CGPoint(x: x + r * 0.95, y: y + r * 0.35), control: CGPoint(x: x, y: y - r * 0.85))
            stroke(p, WordArtPaint.ink, max(1.6, r * 0.42))
        } else {
            fill(WordArtPaint.oval(x, y, r * 0.84, r), WordArtPaint.ink)
            fill(WordArtPaint.disk(x - r * 0.3 + lookX, y - r * 0.38 + lookY, r * 0.34), .white)
        }
    }

    /// Joue rose (animaux, princesse).
    func cheek(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) {
        fill(WordArtPaint.disk(x, y, r), WordArtPaint.blush.opacity(0.5))
    }

    /// Étincelle à quatre branches (tintement, magie, déclic). `amount` : 0 = rien, 1 = pleine.
    func sparkle(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ color: Color, amount: Double = 1) {
        guard amount > 0.01 else { return }
        fill(WordArtPaint.star4(x, y, r * amount), color)
    }

    /// Arcs de son « ))) » partant de (x, y) vers `angle` (degrés, 0 = droite, 90 = bas).
    /// `amount` (0…1) fait apparaître les arcs un à un.
    func soundArcs(_ x: CGFloat, _ y: CGFloat, angle: Double, amount: Double,
                   color: Color = WordArtPaint.soundColor, spread: Double = 34, gap: CGFloat = 9) {
        guard amount > 0.01 else { return }
        for i in 0..<3 {
            let local = WordArtPaint.clamp01(amount * 3 - Double(i))
            guard local > 0.01 else { continue }
            let r = CGFloat(10) + CGFloat(i) * gap
            var p = Path()
            p.addArc(center: CGPoint(x: x, y: y), radius: r,
                     startAngle: .degrees(angle - spread), endAngle: .degrees(angle + spread), clockwise: false)
            faded(local).stroke(p, color, 3.6)
        }
    }

    /// Traits de vitesse horizontaux (poussée, flèche qui file).
    func speedLines(_ x: CGFloat, _ y: CGFloat, length: CGFloat, amount: Double, color: Color = WordArtPaint.soundColor) {
        guard amount > 0.01 else { return }
        for (i, dy) in [CGFloat(-14), 0, 14].enumerated() {
            let l = length * CGFloat(amount) * (i == 1 ? 1 : 0.7)
            var p = Path()
            p.move(to: CGPoint(x: x, y: y + dy))
            p.addLine(to: CGPoint(x: x - l, y: y + dy))
            faded(amount).stroke(p, color, 4)
        }
    }

    /// Une bulle de savon : disque translucide, liseré et reflet.
    func bubble(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, tint: Color = WordArtPaint.bubbleTint, amount: Double = 1) {
        guard amount > 0.01, r > 0.5 else { return }
        let b = faded(amount)
        b.fill(WordArtPaint.disk(x, y, r), tint.opacity(0.28))
        b.stroke(WordArtPaint.disk(x, y, r), tint.opacity(0.9), max(1.2, r * 0.16))
        b.fill(WordArtPaint.oval(x - r * 0.36, y - r * 0.4, r * 0.3, r * 0.2), .white.opacity(0.95))
    }
}

/// L'espace de noms des tracés, des couleurs et des courbes de mouvement.
enum WordArtPaint {
    // MARK: Couleurs communes

    /// Encre des yeux et des petits traits (celle de l'univers Éveil).
    static let ink = Color(red: 0.16, green: 0.17, blue: 0.24)
    static let blush = Color(red: 0.98, green: 0.52, blue: 0.60)
    /// Traits de son et de vitesse : gris-bleu doux, lisible sur la carte blanche.
    static let soundColor = Color(red: 0.55, green: 0.67, blue: 0.86)
    static let bubbleTint = Color(red: 0.55, green: 0.78, blue: 0.98)
    static let sparkleGold = Color(red: 1.0, green: 0.80, blue: 0.20)

    /// Couleur à partir d'un code hexadécimal 0xRRGGBB.
    static func hex(_ value: UInt32, _ opacity: Double = 1) -> Color {
        Color(red: Double((value >> 16) & 0xFF) / 255,
              green: Double((value >> 8) & 0xFF) / 255,
              blue: Double(value & 0xFF) / 255,
              opacity: opacity)
    }

    // MARK: Tracés

    static func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

    static func oval(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: 2 * rx, height: 2 * ry))
    }

    static func disk(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> Path { oval(cx, cy, r, r) }

    /// Rectangle arrondi (coins continus, comme les cartes du jeu).
    static func box(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat = 0) -> Path {
        let rect = CGRect(x: x, y: y, width: w, height: h)
        guard r > 0 else { return Path(rect) }
        return Path(roundedRect: rect, cornerRadius: min(r, min(w, h) / 2), style: .continuous)
    }

    /// Capsule entre deux points (bras, pattes, tiges, crayons…).
    static func capsule(_ a: CGPoint, _ b: CGPoint, _ width: CGFloat) -> Path {
        var p = Path()
        p.move(to: a)
        p.addLine(to: b)
        return p.strokedPath(StrokeStyle(lineWidth: width, lineCap: .round))
    }

    /// Polygone fermé.
    static func poly(_ points: [CGPoint]) -> Path {
        var p = Path()
        p.addLines(points)
        p.closeSubpath()
        return p
    }

    /// Forme lisse FERMÉE passant par les points (spline de Catmull-Rom).
    static func blob(_ pts: [CGPoint]) -> Path {
        var p = Path()
        let n = pts.count
        guard n > 2 else { return poly(pts) }
        p.move(to: pts[0])
        for i in 0..<n {
            let p0 = pts[(i - 1 + n) % n], p1 = pts[i], p2 = pts[(i + 1) % n], p3 = pts[(i + 2) % n]
            p.addCurve(to: p2,
                       control1: CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6),
                       control2: CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6))
        }
        p.closeSubpath()
        return p
    }

    /// Courbe lisse OUVERTE passant par les points (queues, jets d'eau, vapeur).
    static func curve(_ pts: [CGPoint]) -> Path {
        var p = Path()
        let n = pts.count
        guard n > 1 else { return p }
        p.move(to: pts[0])
        for i in 0..<(n - 1) {
            let p0 = pts[max(i - 1, 0)], p1 = pts[i], p2 = pts[i + 1], p3 = pts[min(i + 2, n - 1)]
            p.addCurve(to: p2,
                       control1: CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6),
                       control2: CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6))
        }
        return p
    }

    /// Un « boudin » d'épaisseur variable le long d'une ligne (corps de la limace…) :
    /// `halfWidths[i]` est la demi-épaisseur au point `points[i]`.
    static func tube(_ points: [CGPoint], _ halfWidths: [CGFloat]) -> Path {
        let n = min(points.count, halfWidths.count)
        guard n > 1 else { return Path() }
        var left: [CGPoint] = [], right: [CGPoint] = []
        for i in 0..<n {
            let a = points[max(i - 1, 0)], c = points[min(i + 1, n - 1)]
            let dx = c.x - a.x, dy = c.y - a.y
            let len = max((dx * dx + dy * dy).squareRoot(), 0.001)
            let nx = -dy / len, ny = dx / len
            let w = halfWidths[i]
            left.append(CGPoint(x: points[i].x + nx * w, y: points[i].y + ny * w))
            right.append(CGPoint(x: points[i].x - nx * w, y: points[i].y - ny * w))
        }
        return blob(left + right.reversed())
    }

    /// Forme lisse fermée autour de (cx, cy) dont le rayon dépend de l'angle (taches, éclaboussures).
    static func polarBlob(_ cx: CGFloat, _ cy: CGFloat, count: Int, radius: (Double) -> Double) -> Path {
        let pts = (0..<count).map { i -> CGPoint in
            let a = Double(i) / Double(count) * 2 * .pi
            let r = radius(a)
            return CGPoint(x: cx + CGFloat(cos(a) * r), y: cy + CGFloat(sin(a) * r))
        }
        return blob(pts)
    }

    /// Nuage de bosses : disque central + petits disques sur le pourtour (mousse, poils du caniche).
    static func puff(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, bumps: Int, bumpRadius: CGFloat, phase: Double = 0) -> Path {
        var p = Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r))
        for i in 0..<bumps {
            let a = phase + Double(i) / Double(bumps) * 2 * .pi
            let x = cx + CGFloat(cos(a)) * r, y = cy + CGFloat(sin(a)) * r
            p.addEllipse(in: CGRect(x: x - bumpRadius, y: y - bumpRadius, width: 2 * bumpRadius, height: 2 * bumpRadius))
        }
        return p
    }

    /// Points d'un arc de cercle, de `from` à `to` degrés (0 = droite, 90 = bas, sens de l'écran).
    /// Calculés à la main : pas d'ambiguïté sur le sens « horaire » d'un repère inversé.
    static func arcPoints(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, from a0: Double, to a1: Double,
                          steps: Int = 20) -> [CGPoint] {
        (0...steps).map { i in
            let a = (a0 + (a1 - a0) * Double(i) / Double(steps)) * .pi / 180
            return CGPoint(x: cx + r * CGFloat(cos(a)), y: cy + r * CGFloat(sin(a)))
        }
    }

    /// Étoile à quatre branches aux flancs creusés (étincelle).
    static func star4(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> Path {
        var p = Path()
        let c = CGPoint(x: cx, y: cy)
        p.move(to: CGPoint(x: cx, y: cy - r))
        p.addQuadCurve(to: CGPoint(x: cx + r, y: cy), control: c)
        p.addQuadCurve(to: CGPoint(x: cx, y: cy + r), control: c)
        p.addQuadCurve(to: CGPoint(x: cx - r, y: cy), control: c)
        p.addQuadCurve(to: CGPoint(x: cx, y: cy - r), control: c)
        p.closeSubpath()
        return p
    }

    /// Étoile à cinq branches (couronne, chapiteau).
    static func star5(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, inner: CGFloat = 0.45) -> Path {
        let pts = (0..<10).map { i -> CGPoint in
            let a = -Double.pi / 2 + Double(i) * .pi / 5
            let rr = i.isMultiple(of: 2) ? r : r * inner
            return CGPoint(x: cx + CGFloat(cos(a)) * rr, y: cy + CGFloat(sin(a)) * rr)
        }
        return poly(pts)
    }

    /// Cœur (bisou de la bouche, princesse).
    static func heart(_ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: cx, y: cy + s * 0.9))
        p.addCurve(to: CGPoint(x: cx - s, y: cy - s * 0.2),
                   control1: CGPoint(x: cx - s * 0.5, y: cy + s * 0.55), control2: CGPoint(x: cx - s, y: cy + s * 0.25))
        p.addCurve(to: CGPoint(x: cx, y: cy - s * 0.35),
                   control1: CGPoint(x: cx - s, y: cy - s * 0.85), control2: CGPoint(x: cx - s * 0.15, y: cy - s * 0.9))
        p.addCurve(to: CGPoint(x: cx + s, y: cy - s * 0.2),
                   control1: CGPoint(x: cx + s * 0.15, y: cy - s * 0.9), control2: CGPoint(x: cx + s, y: cy - s * 0.85))
        p.addCurve(to: CGPoint(x: cx, y: cy + s * 0.9),
                   control1: CGPoint(x: cx + s, y: cy + s * 0.25), control2: CGPoint(x: cx + s * 0.5, y: cy + s * 0.55))
        p.closeSubpath()
        return p
    }

    // MARK: Courbes de mouvement (toutes nulles en t = 0 ET en t = 1)

    static func clamp01(_ x: Double) -> Double { min(1, max(0, x)) }

    /// Avancement local de `t` entre `a` et `b` (0 avant, 1 après).
    static func seg(_ t: Double, _ a: Double, _ b: Double) -> Double { clamp01((t - a) / (b - a)) }

    /// Cloche douce 0 → 1 → 0.
    static func bump(_ t: Double) -> Double { sin(.pi * clamp01(t)) }

    /// Cloche encore plus douce (pente nulle aux deux bouts) : pour les gestes amples
    /// qui doivent se poser sans à-coup (bouche qui se referme, sauts).
    static func pulse(_ t: Double) -> Double {
        let s = sin(.pi * clamp01(t))
        return s * s
    }

    /// Saut parabolique 0 → 1 → 0.
    static func hop(_ t: Double) -> Double {
        let u = clamp01(t)
        return 4 * u * (1 - u)
    }

    /// `n` oscillations dont l'amplitude s'éteint jusqu'à 0 en t = 1 (balancier, frétillement).
    static func wobble(_ t: Double, _ n: Double) -> Double {
        let u = clamp01(t)
        return sin(2 * .pi * n * u) * (1 - u)
    }

    /// `n` oscillations d'amplitude constante, adoucies aux deux bouts (battement d'ailes).
    static func shake(_ t: Double, _ n: Double) -> Double {
        let u = clamp01(t)
        return sin(2 * .pi * n * u) * bump(u).squareRoot()
    }

    /// Monte, tient, redescend : 0 → 1 (en `rise`) … 1 → 0 (après `fall`).
    static func hold(_ t: Double, rise: Double = 0.15, fall: Double = 0.8) -> Double {
        let up = seg(t, 0, rise), down = 1 - seg(t, fall, 1)
        return easeInOut(min(up, down))
    }

    static func easeInOut(_ x: Double) -> Double {
        let u = clamp01(x)
        return u * u * (3 - 2 * u)
    }

    static func easeOut(_ x: Double) -> Double {
        let u = clamp01(x)
        return 1 - (1 - u) * (1 - u)
    }

    static func easeIn(_ x: Double) -> Double {
        let u = clamp01(x)
        return u * u
    }

    static func lerp(_ a: CGFloat, _ b: CGFloat, _ t: Double) -> CGFloat { a + (b - a) * CGFloat(t) }

    static func lerp(_ a: CGPoint, _ b: CGPoint, _ t: Double) -> CGPoint {
        CGPoint(x: lerp(a.x, b.x, t), y: lerp(a.y, b.y, t))
    }
}
#endif
