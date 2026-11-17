// SentenceMotion.swift — la phrase JOUÉE : ce que fait chaque verbe, instant après instant.
//
// Le train des phrases (demande de l'utilisateur, 28/09/2026 : « au niveau d'OrthoPicto,
// voire plus ») : quand la phrase est construite, la scène la joue. Pas une vidéo par
// phrase : un MOUVEMENT par verbe, qui marche avec n'importe quel sujet, n'importe quel
// objet, n'importe quel lieu (« la vache mange la bûche » : elle croque, les miettes volent).
//
// Tout est une fonction PURE du temps (secondes depuis le début), comme les dessins des
// mots : `frame(verb:t:layout:)` → où est le sujet, où est l'objet, ce qui vole autour
// (Zzz, notes, miettes, bulles…). `SentenceStage` peint ; rien ici ne lit l'heure.
// Chaque mouvement revient EXACTEMENT au repos à la fin (pas de saut quand il s'arrête),
// sauf ce que le verbe change pour de bon : la pêche mangée a disparu, le bus poussé a avancé.
//
// Repère : la scène fait 1 de haut ; x va de 0 à `layout.width` ; le sol est à y = 0,9.

#if canImport(SwiftUI)
import SwiftUI

/// Ce que la scène doit montrer (le train des phrases le remplit wagon après wagon).
public struct SentenceScene: Equatable, Sendable {
    public var subject: String?
    public var subjectFacesLeft: Bool
    public var verb: String?
    public var object: String?
    public var objectFacesLeft: Bool
    public var place: String?
    public var preposition: PictoPreposition?

    public init(subject: String? = nil, subjectFacesLeft: Bool = false, verb: String? = nil,
                object: String? = nil, objectFacesLeft: Bool = false,
                place: String? = nil, preposition: PictoPreposition? = nil) {
        self.subject = subject
        self.subjectFacesLeft = subjectFacesLeft
        self.verb = verb
        self.object = object
        self.objectFacesLeft = objectFacesLeft
        self.place = place
        self.preposition = preposition
    }
}

/// Les bruitages de la scène (le train des phrases les joue avec `EveilSounds`).
public enum SceneSound: String, Sendable {
    case bite, slurp, whoosh, splash, pop, sparkle, hop, snore, voice, swish, bell
}

// MARK: - Poses

/// La pose d'un personnage (ou d'un objet) : décalage, rotation et écrasement autour de son
/// point bas-milieu, action de son dessin, yeux fermés.
struct ActorPose: Equatable {
    var dx: CGFloat = 0
    var dy: CGFloat = 0
    var rotation: Double = 0
    var sx: CGFloat = 1
    var sy: CGFloat = 1
    var opacity: Double = 1
    /// Avancement de l'action propre du dessin (la vache meugle…) : 0 = repos.
    var act: Double = 0
    var eyesClosed = false
    /// Se retourne (en plus du sens que lui donne la scène).
    var turned = false
    /// Taille relative (le personnage qui entre dans un lieu rétrécit jusqu'à l'ancre).
    var scale: CGFloat = 1
}

enum ParticleKind: Equatable {
    case zzz, note, heart, bubble, drop, crumb, spark, puff, swirl, joy, scent, wind, bush, rope, waves
}

/// Une petite chose qui vole (repère de la scène). `x2, y2` : second point (corde, vent).
struct Particle: Equatable {
    var kind: ParticleKind
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double = 1
    var rotation: Double = 0
    var x2: CGFloat = 0
    var y2: CGFloat = 0
}

struct SceneFrame: Equatable {
    var subject = ActorPose()
    var object = ActorPose()
    /// Derrière les personnages (vent, corde…) et devant eux (eau, buisson, Zzz, notes…).
    var behind: [Particle] = []
    var front: [Particle] = []
}

/// Où sont les personnages au repos (repère de la scène).
struct SceneLayout: Equatable {
    var width: CGFloat
    var ground: CGFloat = 0.9
    /// Sujet : point bas-milieu et côté de son carré (200 × 200 dans le dessin).
    var subjectBase: CGPoint
    var subjectSize: CGFloat
    var objectBase: CGPoint?
    var objectSize: CGFloat = 0.34

    /// Le haut de la tête du sujet (à peu près : les dessins tiennent dans 8 %…92 % du carré).
    func head(_ pose: ActorPose) -> CGPoint {
        CGPoint(x: subjectBase.x + pose.dx, y: subjectBase.y + pose.dy - subjectSize * pose.scale * 0.78)
    }

    /// La bouche (le devant du sujet, du côté de l'objet).
    func mouth(_ pose: ActorPose) -> CGPoint {
        CGPoint(x: subjectBase.x + pose.dx + subjectSize * pose.scale * 0.22,
                y: subjectBase.y + pose.dy - subjectSize * pose.scale * 0.55)
    }

    /// Distance à parcourir pour que le sujet touche l'objet.
    var reach: CGFloat {
        guard let o = objectBase else { return 0 }
        return max(0, o.x - subjectBase.x - (subjectSize * 0.36 + objectSize * 0.34))
    }
}

// MARK: - Les mouvements

enum SentenceMotion {
    /// Les verbes qui ont un mouvement (ceux du lexique du train des phrases).
    static let verbs = ["dormir", "sauter", "danser", "courir", "chanter", "nager", "voler", "tourner", "rire",
                        "se_cacher", "manger", "boire", "pousser", "porter", "lancer", "laver", "attraper", "lecher",
                        "sentir", "tirer"]

    /// Ce que le verbe CHANGE pour de bon (la fin n'est pas le repos) : l'objet mangé disparaît,
    /// l'objet porté reste sur le dos, l'objet attrapé dans les bras, le sujet qui pousse reste
    /// contre l'objet poussé.
    static let lastingSubject: Set<String> = ["pousser"]
    static let lastingObject: Set<String> = ["manger", "porter", "attraper", "pousser"]

    /// Durée du mouvement d'un verbe (secondes).
    static func duration(_ verb: String) -> Double {
        switch verb {
        case "dormir", "nager", "manger", "porter", "laver", "tirer": return 3.0
        case "danser", "voler", "boire", "pousser", "lancer": return 2.8
        case "courir", "chanter", "se_cacher", "attraper", "lecher", "sentir": return 2.6
        default: return 2.4
        }
    }

    /// Les bruitages d'un verbe : (instant, son).
    static func cues(_ verb: String) -> [(Double, SceneSound)] {
        switch verb {
        case "manger": return [(0.8, .bite), (1.4, .bite), (2.0, .bite)]
        case "boire": return [(0.9, .slurp)]
        case "lancer": return [(0.9, .whoosh)]
        case "attraper": return [(0.2, .whoosh), (1.3, .pop)]
        case "nager": return [(0.3, .splash), (1.6, .splash)]
        case "laver": return [(0.6, .pop), (1.2, .pop), (1.8, .pop), (2.4, .sparkle)]
        case "sauter": return [(0.46, .hop), (1.26, .hop), (2.06, .hop)]
        case "dormir": return [(0.6, .snore)]
        case "chanter", "rire", "lecher", "sentir": return [(0.3, .voice)]
        case "pousser", "tirer", "porter", "courir": return [(0.5, .swish)]
        case "tourner", "danser", "voler": return [(0.2, .swish)]
        default: return []
        }
    }

    /// La scène à l'instant `t` du mouvement du verbe.
    static func frame(verb: String, t: Double, layout: SceneLayout) -> SceneFrame {
        let d = duration(verb)
        let u = WordArtPaint.clamp01(t / d)      // 0 → 1 sur la durée
        var f = SceneFrame()
        switch verb {
        case "dormir": sleep(&f, t, u, layout)
        case "sauter": jump(&f, t, u, layout)
        case "danser": dance(&f, t, u, layout)
        case "courir": run(&f, t, u, layout)
        case "chanter": sing(&f, t, u, layout)
        case "nager": swim(&f, t, u, layout)
        case "voler": fly(&f, t, u, layout)
        case "tourner": spin(&f, t, u, layout)
        case "rire": laugh(&f, t, u, layout)
        case "se_cacher": hide(&f, t, u, layout)
        case "manger": eat(&f, t, u, layout)
        case "boire": drink(&f, t, u, layout)
        case "pousser": push(&f, t, u, layout)
        case "porter": carry(&f, t, u, layout)
        case "lancer": toss(&f, t, u, layout)
        case "laver": wash(&f, t, u, layout)
        case "attraper": catchIt(&f, t, u, layout)
        case "lecher": lick(&f, t, u, layout)
        case "sentir": smell(&f, t, u, layout)
        case "tirer": pull(&f, t, u, layout)
        default: break
        }
        return f
    }

    // MARK: Courbes

    private typealias P = WordArtPaint

    /// Avancement cyclique 0…1 de période `period`, décalé de `offset` (secondes).
    static func cycle(_ t: Double, _ period: Double, _ offset: Double = 0) -> Double {
        let x = (t - offset) / period
        return x - x.rounded(.down)
    }

    /// Une volée qui monte en s'estompant (Zzz, notes, cœurs, parfum) : `count` éléments décalés,
    /// émis entre `from` et `to` (secondes), chacun visible `life` secondes.
    static func rising(_ kind: ParticleKind, from origin: CGPoint, t: Double, start: Double, end: Double,
                       count: Int, life: Double = 1.3, rise: CGFloat = 0.32, drift: CGFloat = 0.1,
                       size: CGFloat = 0.06) -> [Particle] {
        var out: [Particle] = []
        guard count > 0, end > start else { return out }
        let spacing = (end - start - life) / Double(max(1, count - 1))
        for k in 0..<count {
            let born = start + spacing * Double(k)
            let age = (t - born) / life
            guard age > 0, age < 1 else { continue }
            let side: CGFloat = k % 2 == 0 ? 1 : -0.6
            out.append(Particle(kind: kind,
                                x: origin.x + drift * side * CGFloat(age) + 0.02 * CGFloat(sin(age * 9 + Double(k))),
                                y: origin.y - rise * CGFloat(age),
                                size: size * CGFloat(0.7 + 0.5 * age),
                                opacity: P.bump(age) > 0.6 ? 1 : P.bump(age) / 0.6,
                                rotation: 12 * sin(Double(k) + age * 4)))
        }
        return out
    }

    /// Une gerbe qui jaillit d'un point et retombe (miettes, gouttes, étincelles).
    static func burst(_ kind: ParticleKind, at p: CGPoint, t: Double, start: Double, count: Int,
                      spread: CGFloat = 0.16, life: Double = 0.7, size: CGFloat = 0.022) -> [Particle] {
        let age = (t - start) / life
        guard age > 0, age < 1 else { return [] }
        return (0..<count).map { k in
            let a = -Double.pi / 2 + (Double(k) / Double(max(1, count - 1)) - 0.5) * 2.4
            let r = spread * CGFloat(age)
            return Particle(kind: kind, x: p.x + CGFloat(cos(a)) * r,
                            y: p.y + CGFloat(sin(a)) * r + 0.25 * CGFloat(age * age),
                            size: size, opacity: 1 - age, rotation: 90 * age * Double(k % 3 - 1))
        }
    }

    // MARK: Sans complément

    private static func sleep(_ f: inout SceneFrame, _ t: Double, _ u: Double, _ l: SceneLayout) {
        let settle = P.easeInOut(P.seg(t, 0, 0.5)) * (1 - P.easeInOut(P.seg(t, 2.7, 3.0)))
        f.subject.eyesClosed = t > 0.35 && t < 2.8
        f.subject.sy = 1 - 0.07 * CGFloat(settle) + 0.02 * CGFloat(sin(t * 3.2) * settle)
        f.subject.rotation = -6 * settle
        var head = l.head(f.subject)
        head.x += l.subjectSize * 0.2
        f.front += rising(.zzz, from: head, t: t, start: 0.5, end: 2.95, count: 3, life: 1.1, rise: 0.28, size: 0.07)
    }

    private static func jump(_ f: inout SceneFrame, _ t: Double, _ u: Double, _ l: SceneLayout) {
        // Trois bonds (0,8 s chacun), écrasé au départ et à l'arrivée.
        let k = min(2, Int(t / 0.8)), local = (t - Double(k) * 0.8) / 0.8
        let air = P.seg(local, 0.18, 0.82)
        f.subject.dy = -0.24 * CGFloat(P.hop(air)) * (t < 2.4 ? 1 : 0)
        let squash = t < 2.4 ? max(P.bump(P.seg(local, 0, 0.18)), P.bump(P.seg(local, 0.82, 1))) : 0
        f.subject.sy = 1 - 0.14 * CGFloat(squash) + 0.08 * CGFloat(P.bump(air))
        f.subject.sx = 1 + 0.1 * CGFloat(squash)
        for landing in [0.66, 1.46, 2.26] {
            f.behind += burst(.puff, at: CGPoint(x: l.subjectBase.x, y: l.ground), t: t, start: landing, count: 4,
                              spread: 0.12, life: 0.5, size: 0.035)
        }
    }

    private static func dance(_ f: inout SceneFrame, _ t: Double, _ u: Double, _ l: SceneLayout) {
        let env = P.hold(u, rise: 0.08, fall: 0.85)
        f.subject.rotation = 13 * sin(2 * .pi * t / 0.7) * env
        f.subject.dy = -0.05 * CGFloat(abs(sin(2 * .pi * t / 0.7)) * env)
        f.subject.dx = 0.04 * CGFloat(sin(2 * .pi * t / 1.4) * env)
        f.front += rising(.note, from: l.head(f.subject), t: t, start: 0.1, end: 2.8, count: 5, life: 1.2, rise: 0.3,
                          drift: 0.22, size: 0.06)
    }

    private static func run(_ f: inout SceneFrame, _ t: Double, _ u: Double, _ l: SceneLayout) {
        // Il file vers la droite, fait demi-tour, et revient à sa place.
        let go = P.easeInOut(P.seg(t, 0, 1.2)), back = P.easeInOut(P.seg(t, 1.4, 2.6))
        let span = min(0.34, l.width - l.subjectBase.x - l.subjectSize * 0.45)
        f.subject.dx = span * CGFloat(go - back)
        f.subject.turned = t > 1.3 && t < 2.6
        let moving = (t < 1.2 || (t > 1.4 && t < 2.6)) ? 1.0 : 0.0
        f.subject.dy = -0.035 * CGFloat(abs(sin(2 * .pi * t / 0.3)) * moving)
        // Penché dans sa course, redressé au départ, au demi-tour et à l'arrivée.
        f.subject.rotation = 6 * P.bump(P.seg(t, 0, 1.2)) - 6 * P.bump(P.seg(t, 1.4, 2.6))
        if moving > 0 {
            let behindX = l.subjectBase.x + f.subject.dx + (f.subject.turned ? 1 : -1) * l.subjectSize * 0.42
            f.behind.append(Particle(kind: .wind, x: behindX, y: l.subjectBase.y - l.subjectSize * 0.45,
                                     size: 0.12, x2: f.subject.turned ? 1 : -1))
        }
    }

    private static func sing(_ f: inout SceneFrame, _ t: Double, _ u: Double, _ l: SceneLayout) {
        let env = P.hold(u, rise: 0.08, fall: 0.9)
        f.subject.act = cycle(t, 1.25)
        if t > 2.5 { f.subject.act = 0 }
        f.subject.rotation = 5 * sin(2 * .pi * t / 1.25) * env
        f.subject.sy = 1 + 0.03 * CGFloat(sin(2 * .pi * t / 0.62) * env)
        f.front += rising(.note, from: l.mouth(f.subject), t: t, start: 0.15, end: 2.6, count: 6, life: 1.1,
                          rise: 0.34, drift: 0.18, size: 0.065)
    }

    private static func swim(_ f: inout SceneFrame, _ t: Double, _ u: Double, _ l: SceneLayout) {
        // L'eau monte, le nageur ondule dedans, puis l'eau redescend.
        let water = P.easeInOut(P.seg(t, 0, 0.5)) * (1 - P.easeInOut(P.seg(t, 2.5, 3.0)))
        f.subject.dy = 0.03 * CGFloat(sin(2 * .pi * t / 0.9) * water)
        f.subject.rotation = 8 * sin(2 * .pi * t / 0.9 + 1) * water
        f.subject.dx = 0.05 * CGFloat(sin(2 * .pi * t / 1.8) * water)
        let level = l.ground - l.subjectSize * 0.36 * CGFloat(water)
        f.front.append(Particle(kind: .waves, x: l.subjectBase.x, y: level, size: l.subjectSize * 1.25,
                                opacity: water, rotation: t))
        for k in 0..<2 {
            f.front += burst(.drop, at: CGPoint(x: l.subjectBase.x + (k == 0 ? -0.1 : 0.12), y: level),
                             t: t, start: 0.4 + 1.1 * Double(k), count: 5, spread: 0.14, life: 0.7, size: 0.02)
        }
    }

    private static func fly(_ f: inout SceneFrame, _ t: Double, _ u: Double, _ l: SceneLayout) {
        let up = P.easeInOut(P.seg(t, 0, 0.7)) * (1 - P.easeInOut(P.seg(t, 2.1, 2.8)))
        f.subject.dy = -0.26 * CGFloat(up) - 0.04 * CGFloat(sin(2 * .pi * t / 0.8) * up)
        f.subject.dx = 0.08 * CGFloat(sin(2 * .pi * t / 1.4) * up)
        f.subject.rotation = 7 * sin(2 * .pi * t / 0.8) * up
        if up > 0.2 {
            let p = CGPoint(x: l.subjectBase.x + f.subject.dx - l.subjectSize * 0.45, y: l.subjectBase.y + f.subject.dy - 0.1)
            f.behind.append(Particle(kind: .wind, x: p.x, y: p.y, size: 0.14, opacity: up, x2: -1))
        }
        f.behind += burst(.puff, at: CGPoint(x: l.subjectBase.x, y: l.ground), t: t, start: 0.05, count: 4,
                          spread: 0.12, life: 0.5, size: 0.035)
    }

    private static func spin(_ f: inout SceneFrame, _ t: Double, _ u: Double, _ l: SceneLayout) {
        // Deux tours sur lui-même : la largeur passe par zéro (il se retourne), puis revient.
        let turns = 2 * P.easeInOut(P.seg(t, 0.1, 2.2))
        let c = cos(2 * .pi * turns)
        f.subject.sx = CGFloat(max(0.12, abs(c)))
        f.subject.turned = c < 0
        f.subject.dy = -0.03 * CGFloat(P.bump(P.seg(t, 0.1, 2.2)))
        if t > 0.1 && t < 2.3 {
            let h = l.head(f.subject)
            f.front.append(Particle(kind: .swirl, x: l.subjectBase.x, y: (h.y + l.subjectBase.y) / 2,
                                    size: l.subjectSize * 0.62, opacity: P.bump(P.seg(t, 0.1, 2.3)),
                                    rotation: 360 * turns))
        }
    }

    private static func laugh(_ f: inout SceneFrame, _ t: Double, _ u: Double, _ l: SceneLayout) {
        let env = P.hold(u, rise: 0.05, fall: 0.85)
        f.subject.rotation = 6 * sin(2 * .pi * t / 0.22) * env
        f.subject.sy = 1 + 0.05 * CGFloat(sin(2 * .pi * t / 0.44) * env)
        f.subject.act = t < 2.2 ? cycle(t, 1.1) : 0
        let h = l.head(f.subject)
        f.front += rising(.joy, from: CGPoint(x: h.x, y: h.y + 0.08), t: t, start: 0.1, end: 2.4, count: 5,
                          life: 0.9, rise: 0.16, drift: 0.2, size: 0.05)
    }

    private static func hide(_ f: inout SceneFrame, _ t: Double, _ u: Double, _ l: SceneLayout) {
        // Un buisson pousse devant lui ; il se tasse derrière ; seuls ses yeux dépassent… puis coucou !
        let grow = P.easeOut(P.seg(t, 0, 0.5)) * (1 - P.easeInOut(P.seg(t, 2.2, 2.6)))
        let crouch = P.easeInOut(P.seg(t, 0.3, 0.8)) * (1 - P.easeInOut(P.seg(t, 1.7, 2.0)))
        f.subject.sy = 1 - 0.3 * CGFloat(crouch)
        f.subject.dy = 0
        f.front.append(Particle(kind: .bush, x: l.subjectBase.x, y: l.ground,
                                size: l.subjectSize * 1.0 * CGFloat(grow), opacity: min(1, grow * 2)))
        if t > 1.9 && t < 2.4 {
            f.front += burst(.spark, at: l.head(f.subject), t: t, start: 1.9, count: 5, spread: 0.12, life: 0.5, size: 0.03)
        }
    }

    // MARK: Avec complément

    /// L'approche : le sujet va jusqu'à l'objet (0 → 1 entre `a` et `b`), et revient (entre `c` et `d`).
    private static func approach(_ t: Double, _ a: Double, _ b: Double, _ c: Double, _ d: Double) -> Double {
        P.easeInOut(P.seg(t, a, b)) * (1 - P.easeInOut(P.seg(t, c, d)))
    }

    private static func eat(_ f: inout SceneFrame, _ t: Double, _ u: Double, _ l: SceneLayout) {
        let near = approach(t, 0, 0.6, 2.4, 3.0)
        f.subject.dx = l.reach * CGFloat(near)
        var left: CGFloat = 1
        for (k, bite) in [0.8, 1.4, 2.0].enumerated() {
            let chomp = P.pulse(P.seg(t, bite - 0.15, bite + 0.2))
            f.subject.rotation += 8 * chomp
            if t > bite { left = [0.66, 0.36, 0.0][k] }
            f.subject.act = max(f.subject.act, P.seg(t, bite - 0.2, bite + 0.4) > 0 && P.seg(t, bite - 0.2, bite + 0.4) < 1
                                ? P.seg(t, bite - 0.2, bite + 0.4) : 0)
            if let o = l.objectBase {
                f.front += burst(.crumb, at: CGPoint(x: o.x - l.objectSize * 0.2, y: o.y - l.objectSize * 0.45),
                                 t: t, start: bite, count: 6, spread: 0.13, life: 0.65, size: 0.018)
            }
        }
        f.object.scale = left
        f.object.opacity = left > 0 ? 1 : 0
        if t > 2.1 { f.front += rising(.heart, from: l.head(f.subject), t: t, start: 2.1, end: 3.3, count: 2, life: 0.9,
                                       rise: 0.14, drift: 0.06, size: 0.045) }
    }

    private static func drink(_ f: inout SceneFrame, _ t: Double, _ u: Double, _ l: SceneLayout) {
        let near = approach(t, 0, 0.6, 2.2, 2.8)
        f.subject.dx = l.reach * CGFloat(near)
        let sip = P.hold(P.seg(t, 0.7, 2.1), rise: 0.2, fall: 0.8)
        f.object.rotation = -24 * sip
        f.object.dx = -0.04 * CGFloat(sip)
        f.object.dy = -0.06 * CGFloat(sip)
        f.subject.act = sip > 0.5 ? cycle(t, 0.7) : 0
        if let o = l.objectBase {
            f.front += rising(.bubble, from: CGPoint(x: o.x - 0.05, y: o.y - l.objectSize * 0.8), t: t, start: 0.8,
                              end: 2.3, count: 4, life: 0.8, rise: 0.12, drift: 0.05, size: 0.03)
        }
    }

    private static func push(_ f: inout SceneFrame, _ t: Double, _ u: Double, _ l: SceneLayout) {
        let near = P.easeInOut(P.seg(t, 0, 0.6))
        let shove = P.easeInOut(P.seg(t, 0.7, 2.3))
        let room = max(0, min(0.24, l.width - (l.objectBase?.x ?? l.width) - l.objectSize * 0.45))
        f.subject.dx = l.reach * CGFloat(near) + room * CGFloat(shove)
        f.subject.rotation = 10 * P.hold(P.seg(t, 0.6, 2.4), rise: 0.1, fall: 0.9)
        f.object.dx = room * CGFloat(shove)
        f.object.rotation = 4 * sin(2 * .pi * t / 0.35) * P.bump(P.seg(t, 0.7, 2.3))
        if t > 0.7 && t < 2.3, let o = l.objectBase {
            f.behind.append(Particle(kind: .wind, x: o.x + f.object.dx - l.objectSize * 0.2,
                                     y: o.y - l.objectSize * 0.3, size: 0.1, x2: -1))
        }
    }

    private static func carry(_ f: inout SceneFrame, _ t: Double, _ u: Double, _ l: SceneLayout) {
        // L'objet saute sur le dos du sujet, qui l'emmène faire un tour.
        guard let o = l.objectBase else { return }
        let hopOn = P.easeInOut(P.seg(t, 0.2, 0.9))
        let walk = sin(2 * .pi * P.seg(t, 1.0, 2.8)) * 0.14
        let top = CGPoint(x: l.subjectBase.x, y: l.subjectBase.y - l.subjectSize * 0.72)
        f.subject.dx = CGFloat(walk)
        f.subject.dy = -0.02 * CGFloat(abs(sin(2 * .pi * t / 0.4)) * (t > 1.0 && t < 2.8 ? 1 : 0))
        f.object.dx = (top.x - o.x) * CGFloat(hopOn) + f.subject.dx
        f.object.dy = (top.y - o.y) * CGFloat(hopOn) - 0.12 * CGFloat(P.hop(P.seg(t, 0.2, 0.9))) + f.subject.dy
        f.object.scale = 1 - 0.2 * CGFloat(hopOn)
        f.object.rotation = 6 * sin(2 * .pi * t / 0.4) * (t > 1.0 && t < 2.8 ? 1 : 0)
    }

    private static func toss(_ f: inout SceneFrame, _ t: Double, _ u: Double, _ l: SceneLayout) {
        // L'objet vient dans les mains du sujet, s'envole très haut… et retombe à sa place.
        guard let o = l.objectBase else { return }
        let come = P.easeInOut(P.seg(t, 0.1, 0.6))
        let flight = P.seg(t, 0.9, 2.4)
        let hand = CGPoint(x: l.subjectBase.x + l.subjectSize * 0.3, y: l.subjectBase.y - l.subjectSize * 0.45)
        let fromHand = CGPoint(x: (hand.x - o.x) * CGFloat(come), y: (hand.y - o.y) * CGFloat(come))
        f.subject.act = P.seg(t, 0.7, 1.3) > 0 && P.seg(t, 0.7, 1.3) < 1 ? P.seg(t, 0.7, 1.3) : 0
        f.subject.rotation = -10 * P.pulse(P.seg(t, 0.7, 1.2))
        if flight > 0 {
            f.object.dx = fromHand.x * CGFloat(1 - flight)
            f.object.dy = fromHand.y * CGFloat(1 - flight) - 0.55 * CGFloat(P.hop(flight))
            f.object.rotation = 720 * flight          // deux tours : il retombe à l'endroit
            if flight < 0.9 {
                f.behind.append(Particle(kind: .wind, x: o.x + f.object.dx, y: o.y + f.object.dy - l.objectSize * 0.4,
                                         size: 0.08, opacity: 1 - flight, x2: -1))
            }
        } else {
            f.object.dx = fromHand.x
            f.object.dy = fromHand.y
        }
        f.front += burst(.puff, at: CGPoint(x: o.x, y: l.ground), t: t, start: 2.4, count: 4, spread: 0.1,
                         life: 0.4, size: 0.03)
    }

    private static func wash(_ f: inout SceneFrame, _ t: Double, _ u: Double, _ l: SceneLayout) {
        let near = approach(t, 0, 0.5, 2.5, 3.0)
        f.subject.dx = l.reach * CGFloat(near)
        f.subject.rotation = 6 * sin(2 * .pi * t / 0.4) * P.bump(P.seg(t, 0.5, 2.5))
        f.object.rotation = 3 * sin(2 * .pi * t / 0.3) * P.bump(P.seg(t, 0.5, 2.5))
        guard let o = l.objectBase else { return }
        let center = CGPoint(x: o.x, y: o.y - l.objectSize * 0.45)
        for k in 0..<7 {
            let born = 0.5 + 0.25 * Double(k)
            let age = (t - born) / 1.2
            guard age > 0, age < 1 else { continue }
            let a = Double(k) * 2.4
            f.front.append(Particle(kind: .bubble,
                                    x: center.x + l.objectSize * 0.5 * CGFloat(cos(a)) * CGFloat(0.6 + 0.4 * age),
                                    y: center.y + l.objectSize * 0.4 * CGFloat(sin(a)) - 0.08 * CGFloat(age),
                                    size: 0.025 + 0.015 * CGFloat(k % 3), opacity: P.bump(age)))
        }
        f.front += burst(.spark, at: CGPoint(x: center.x, y: center.y - l.objectSize * 0.3), t: t, start: 2.4, count: 6,
                         spread: 0.14, life: 0.6, size: 0.03)
    }

    private static func catchIt(_ f: inout SceneFrame, _ t: Double, _ u: Double, _ l: SceneLayout) {
        // L'objet décolle de sa place en cloche et atterrit dans les bras du sujet.
        guard let o = l.objectBase else { return }
        let flight = P.easeInOut(P.seg(t, 0.2, 1.3))
        let hands = CGPoint(x: l.subjectBase.x + l.subjectSize * 0.28, y: l.subjectBase.y - l.subjectSize * 0.4)
        f.object.dx = (hands.x - o.x) * CGFloat(flight)
        f.object.dy = (hands.y - o.y) * CGFloat(flight) - 0.3 * CGFloat(P.hop(P.seg(t, 0.2, 1.3)))
        f.object.rotation = 360 * flight
        f.object.scale = 1 - 0.15 * CGFloat(flight)
        f.subject.sy = 1 - 0.08 * CGFloat(P.pulse(P.seg(t, 1.2, 1.6)))
        f.subject.act = P.seg(t, 1.3, 2.3) > 0 && P.seg(t, 1.3, 2.3) < 1 ? P.seg(t, 1.3, 2.3) : 0
        f.front += burst(.spark, at: hands, t: t, start: 1.3, count: 6, spread: 0.12, life: 0.6, size: 0.03)
    }

    private static func lick(_ f: inout SceneFrame, _ t: Double, _ u: Double, _ l: SceneLayout) {
        let near = approach(t, 0, 0.6, 2.1, 2.6)
        f.subject.dx = l.reach * CGFloat(near)
        let licks = P.bump(P.seg(t, 0.6, 2.0))
        f.subject.rotation = 10 * sin(2 * .pi * t / 0.45) * licks
        f.subject.act = licks > 0.3 ? cycle(t, 0.9) : 0
        f.object.sy = 1 - 0.05 * CGFloat(abs(sin(2 * .pi * t / 0.45)) * licks)
        f.front += rising(.heart, from: l.head(f.subject), t: t, start: 0.8, end: 2.6, count: 3, life: 0.9,
                          rise: 0.16, drift: 0.08, size: 0.045)
    }

    private static func smell(_ f: inout SceneFrame, _ t: Double, _ u: Double, _ l: SceneLayout) {
        let near = approach(t, 0, 0.6, 2.1, 2.6)
        f.subject.dx = l.reach * CGFloat(near)
        f.subject.eyesClosed = t > 0.9 && t < 2.0
        f.subject.dy = -0.03 * CGFloat(P.pulse(P.seg(t, 0.9, 2.0)))
        guard let o = l.objectBase else { return }
        for k in 0..<3 {
            let age = cycle(t, 0.9, 0.3 * Double(k))
            guard t > 0.4, t < 2.2 else { break }
            f.front.append(Particle(kind: .scent,
                                    x: o.x - l.objectSize * 0.1 - 0.12 * CGFloat(age),
                                    y: o.y - l.objectSize * (0.6 + 0.25 * CGFloat(age)) - 0.03 * CGFloat(k),
                                    size: 0.07, opacity: P.bump(age)))
        }
        f.front += rising(.heart, from: l.head(f.subject), t: t, start: 1.8, end: 2.8, count: 2, life: 0.8,
                          rise: 0.12, drift: 0.05, size: 0.04)
    }

    private static func pull(_ f: inout SceneFrame, _ t: Double, _ u: Double, _ l: SceneLayout) {
        // Une corde relie le sujet à l'objet ; il tire en reculant, l'objet suit, puis tout revient.
        guard let o = l.objectBase else { return }
        let effort = P.hold(P.seg(t, 0.3, 2.7), rise: 0.2, fall: 0.8)
        let back = min(0.16, max(0, l.subjectBase.x - l.subjectSize * 0.45))
        f.subject.dx = -back * CGFloat(effort)
        f.subject.rotation = -12 * effort
        f.subject.turned = false
        f.object.dx = -back * CGFloat(P.hold(P.seg(t, 0.6, 2.7), rise: 0.25, fall: 0.8))
        f.object.rotation = 3 * sin(2 * .pi * t / 0.3) * P.bump(P.seg(t, 0.6, 2.7))
        let hand = CGPoint(x: l.subjectBase.x + f.subject.dx + l.subjectSize * 0.3, y: l.subjectBase.y - l.subjectSize * 0.4)
        let hook = CGPoint(x: o.x + f.object.dx - l.objectSize * 0.35, y: o.y - l.objectSize * 0.35)
        f.behind.append(Particle(kind: .rope, x: hand.x, y: hand.y, size: 0.012,
                                 opacity: P.easeInOut(P.seg(t, 0, 0.3)) * (1 - P.easeInOut(P.seg(t, 2.7, 3.0))),
                                 x2: hook.x, y2: hook.y))
    }
}
#endif
