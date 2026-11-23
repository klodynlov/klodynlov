// LouGestureMotion.swift — les gestes animés de Lou : chronologies, et l'image à un instant.
//
// Portage de `eveil/outils/gestes/animation.py` (la référence, testée) et de la main de
// `lou_portrait.py` (`Main.ecran`, `chemins`, `FORMES`). Les chronologies sont GÉNÉRÉES
// (`LouGestureData.swift`) ; ici on interpole entre leurs clés, exactement comme `animation.etat` :
//   - `x` = part du temps écoulé entre deux clés, adoucie x²(3 − 2x) si la clé d'arrivée est douce ;
//   - coude, poignet et direction de la main interpolés (le coude de chaque clé est donné : pas
//     d'IK image par image, qui faisait sauter le coude quand la main frôlait l'épaule) ;
//   - deux formes de main différentes : chemins des doigts rééchantillonnés puis interpolés ;
//   - la bouche et « la gorge vibre » changent d'un coup (valeur de la dernière clé passée).
// Vecteurs de parité : `Tests/EveilDesignTests/LouGestureVectors.swift`.

#if canImport(SwiftUI)
import SwiftUI

// MARK: - La main (repère de la main : u du poignet vers les doigts, 1 = longueur de la paume ; v vers le pouce)

enum LouFinger: Hashable, Sendable {
    case index, middle, ring, little, thumb

    /// Les quatre doigts (sans le pouce), dans l'ordre de peinture de `main()`.
    static let fingers: [LouFinger] = [.index, .middle, .ring, .little]
}

/// Un doigt : tendu (angle depuis l'axe, plis aux articulations), replié, ou le long d'un chemin.
enum LouFingerSpec: Sendable {
    case straight(Double, [Double])
    case folded
    case path([CGPoint])

    var isFolded: Bool {
        if case .folded = self { return true }
        return false
    }
}

/// Une forme de main (`FORMES`) ; `front` : les doigts peints par-dessus la paume, dans l'ordre.
struct LouHandForm: Sendable {
    let index: LouFingerSpec
    let middle: LouFingerSpec
    let ring: LouFingerSpec
    let little: LouFingerSpec
    let thumb: LouFingerSpec
    let front: [LouFinger]

    func spec(_ finger: LouFinger) -> LouFingerSpec {
        switch finger {
        case .index: return index
        case .middle: return middle
        case .ring: return ring
        case .little: return little
        case .thumb: return thumb
        }
    }
}

/// La géométrie de la main (les nombres sont générés : `LouGestureArt.swift`).
enum LouHandModel {
    static func form(_ name: String) -> LouHandForm {
        forms[name] ?? forms["ouverte"]!
    }

    /// Le chemin d'un doigt (repère de la main) ; replié : un moignon caché sous sa phalange repliée
    /// (le pouce replié : son chemin en travers des doigts).
    static func localPath(_ form: LouHandForm, _ finger: LouFinger) -> [CGPoint] {
        let b = base[finger]!
        switch form.spec(finger) {
        case .folded:
            return finger == .thumb ? foldedThumb : [b, CGPoint(x: 1.10, y: b.y)]
        case .path(let pts):
            return pts
        case .straight(let angle, let folds):
            // `_chemin_tendu` : les phalanges bout à bout, les plis s'ajoutent à l'angle.
            var pts = [b]
            var a = angle
            let parts: [CGFloat] = finger == .thumb ? [0.52, 0.48] : phalanges
            for (k, part) in parts.enumerated() {
                if k >= 1 && k - 1 < folds.count { a += folds[k - 1] }
                let p = pts[pts.count - 1]
                let lg = Double(length[finger]! * part)
                let r = a * .pi / 180
                pts.append(CGPoint(x: Double(p.x) + lg * cos(r), y: Double(p.y) + lg * sin(r)))
            }
            return pts
        }
    }

    /// `n` points également espacés le long de la ligne brisée (les deux bouts gardés).
    static func resample(_ pts: [CGPoint], _ n: Int = samples) -> [CGPoint] {
        guard pts.count >= 2 else { return Array(repeating: pts.first ?? .zero, count: n) }
        var cum: [Double] = [0]
        for i in 1..<pts.count {
            cum.append(cum[i - 1] + hypot(Double(pts[i].x - pts[i - 1].x), Double(pts[i].y - pts[i - 1].y)))
        }
        let total = cum[cum.count - 1]
        var out: [CGPoint] = []
        out.reserveCapacity(n)
        var j = 0
        for i in 0..<n {
            let s = total * Double(i) / Double(n - 1)
            while j < pts.count - 2 && cum[j + 1] < s { j += 1 }
            let seg = cum[j + 1] - cum[j]
            let u = seg <= 0 ? 0 : max(0, min(1, (s - cum[j]) / seg))
            out.append(louLerp(pts[j], pts[j + 1], u))
        }
        out[n - 1] = pts[pts.count - 1]
        return out
    }
}

@inline(__always) func louLerp(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }

@inline(__always) func louLerp(_ p: CGPoint, _ q: CGPoint, _ t: Double) -> CGPoint {
    CGPoint(x: Double(p.x) + Double(q.x - p.x) * t, y: Double(p.y) + Double(q.y - p.y) * t)
}

// MARK: - Les chronologies

/// Un bras de Lou (ce qui ne change pas pendant une suite de sons) : son épaule, et s'il est caché
/// derrière le dos (« d »).
struct LouArmSetup: Hashable, Sendable {
    enum Side: Hashable, Sendable { case left, right }
    let side: Side
    /// Bras caché derrière le buste (« d » : l'autre main dans le dos).
    let behind: Bool

    var shoulder: CGPoint { side == .right ? LouArt.shoulderRight : LouArt.shoulderLeft }
}

/// Un bras à une clé (direction en degrés, déroulée d'une clé à l'autre).
struct LouJoint: Sendable {
    var elbow: CGPoint
    var wrist: CGPoint
    var direction: Double
    let form: String
    var presence: Double    // 0 = au repos (invisible), 1 = là
    /// Côté du pouce (±1 ; interpolé d'un son à l'autre : la main tourne).
    let thumb: Double
    /// Longueur de la paume (taille de la main).
    let size: Double

    /// Le même bras descendu sous le cadre avec son coude, invisible (`animation.repos_de`).
    var atRest: LouJoint {
        var j = self
        let dy = LouChronology.restY - Double(wrist.y)
        j.wrist = CGPoint(x: Double(wrist.x), y: LouChronology.restY)
        j.elbow = CGPoint(x: Double(elbow.x), y: Double(elbow.y) + dy)
        j.presence = 0
        return j
    }
}

struct LouKey: Sendable {
    let t: Double
    let mouth: String
    let vibrate: Bool
    let lift: Double
    let table: Double
    /// Le segment qui ARRIVE à cette clé est adouci.
    let smooth: Bool
    let joints: [LouJoint]
}

/// Un son (du repos au repos), ou une suite de sons enchaînés (`chain`).
struct LouChronology: Sendable {
    let key: String
    let duration: Double
    /// L'instant « pose » (tenue quand les animations sont réduites).
    let posed: Double
    /// Faux : la bouche seule (son sans geste).
    let gesture: Bool
    fileprivate(set) var arms: [LouArmSetup] = []
    fileprivate(set) var keys: [LouKey] = []

    /// Au repos, la main est descendue sous le cadre (`REPOS_Y`).
    static let restY = 420.0
    /// Dans une suite : de la dernière pose d'un son à la première du suivant (`TRANSITION`), au moins…
    static let transition = 0.3
    /// … au plus (`TRANSITION_MAX`) ; entre les deux, la main la plus loin va à `VITESSE_TRANSITION` px/s.
    static let transitionMax = 0.5
    static let transitionSpeed = 700.0
    /// La bouche (et la gorge qui vibre) passe d'une clé à l'autre en fondu (`FONDU`).
    static let mouthFade = 0.12

    init(key: String, duration: Double, posed: Double, gesture: Bool) {
        self.key = key
        self.duration = duration
        self.posed = posed
        self.gesture = gesture
    }

    mutating func arm(_ side: LouArmSetup.Side, behind: Bool) {
        arms.append(LouArmSetup(side: side, behind: behind))
    }

    mutating func key(_ t: Double, _ mouth: String, _ vibrate: Bool, _ lift: Double, _ table: Double,
                      _ smooth: Bool, _ joints: LouJoint...) {
        keys.append(LouKey(t: t, mouth: mouth, vibrate: vibrate, lift: lift, table: table, smooth: smooth,
                           joints: joints))
    }

    static func J(_ ex: Double, _ ey: Double, _ wx: Double, _ wy: Double, _ direction: Double,
                  _ form: String, _ presence: Double, _ thumb: Double, _ size: Double) -> LouJoint {
        LouJoint(elbow: CGPoint(x: ex, y: ey), wrist: CGPoint(x: wx, y: wy), direction: direction, form: form,
                 presence: presence, thumb: thumb, size: size)
    }

    /// Un son inconnu : Lou au repos pendant une seconde (`animation.neutre`).
    static func neutral(_ key: String) -> LouChronology {
        var c = LouChronology(key: key, duration: 1, posed: 0.5, gesture: false)
        for t in [0, 0.2, 0.8, 1] { c.key(t, "neutre", false, 0, 0, false) }
        return c
    }

    /// La chronologie d'une étiquette : son geste, sinon sa bouche seule, sinon le repos.
    static func of(_ key: String) -> LouChronology {
        gestures[key] ?? mouthOnly[key] ?? neutral(key)
    }

    /// « smootherstep » 6x⁵ − 15x⁴ + 10x³ (`animation.adoucir`) : vitesse et accélération nulles aux bouts.
    @inline(__always) static func ease(_ x: Double) -> Double { x * x * x * (x * (6 * x - 15) + 10) }

    /// L'image à l'instant `t` (bornée à [0, durée]) — `animation.etat`.
    func frame(at time: Double) -> LouFrame {
        guard !keys.isEmpty else { return .rest }
        let t = max(0, min(duration, time))
        var i = 0
        while i + 1 < keys.count && keys[i + 1].t <= t { i += 1 }
        let k0 = keys[i]
        let k1 = i + 1 < keys.count ? keys[i + 1] : k0
        let span = k1.t - k0.t
        let x = span <= 0 ? 1 : (t - k0.t) / span
        let e = k1.smooth ? LouChronology.ease(x) : x
        var out: [LouArmFrame] = []
        for (n, setup) in arms.enumerated() {
            let p0 = k0.joints[n], p1 = k1.joints[n]
            let elbow = louLerp(p0.elbow, p1.elbow, e)
            let wrist = louLerp(p0.wrist, p1.wrist, e)
            let same = p0.form == p1.form
            out.append(LouArmFrame(setup: setup, shoulder: setup.shoulder, elbow: elbow, wrist: wrist,
                                   direction: louLerp(p0.direction, p1.direction, e), formA: p0.form,
                                   formB: same ? p0.form : p1.form, mix: same ? 0 : e,
                                   presence: louLerp(p0.presence, p1.presence, e),
                                   thumb: louLerp(p0.thumb, p1.thumb, e), size: louLerp(p0.size, p1.size, e)))
        }
        var frame = LouFrame(arms: out, mouth: k0.mouth, vibrate: k0.vibrate, lift: louLerp(k0.lift, k1.lift, e),
                             table: louLerp(k0.table, k1.table, e))
        // La bouche et la gorge qui vibre : en fondu depuis la clé où elles ont changé.
        var jb = i
        while jb > 0 && keys[jb].mouth == keys[jb - 1].mouth { jb -= 1 }
        if jb > 0 && t - keys[jb].t < LouChronology.mouthFade {
            frame.previousMouth = keys[jb - 1].mouth
            frame.mouthMix = (t - keys[jb].t) / LouChronology.mouthFade
        } else {
            frame.previousMouth = k0.mouth
        }
        var jv = i
        while jv > 0 && keys[jv].vibrate == keys[jv - 1].vibrate { jv -= 1 }
        frame.vibration = k0.vibrate ? 1 : 0
        if jv > 0 && t - keys[jv].t < LouChronology.mouthFade {
            let w = (t - keys[jv].t) / LouChronology.mouthFade
            frame.vibration = k0.vibrate ? w : 1 - w
        }
        return frame
    }
}

// MARK: - Une suite de sons, enchaînés (17/11/2026)

/// Une suite de sons enchaînés sans repasser par le repos (`animation.enchainer`) : la dernière pose
/// d'un son glisse (0,3 à 0,5 s, adouci) vers la première du suivant ; repos seulement au début et à la fin.
/// Un bras qui ne sert pas à un son y descend sous le cadre en fondu ; la bouche du son suivant
/// arrive avec la transition.
struct LouChain: Sendable {
    let chronology: LouChronology
    /// Où commence chaque son (le premier à 0 ; ensuite au milieu de sa transition).
    let starts: [Double]

    var duration: Double { chronology.duration }

    /// Le rang du son en cours (nil avant le début ou à la fin).
    func index(at t: Double) -> Int? {
        guard t >= 0, t < duration - 1e-9, !starts.isEmpty else { return nil }
        return starts.lastIndex { $0 <= t }
    }

    init(_ keys: [String]) {
        let chs = keys.map(LouChronology.of)
        guard let first = chs.first else {
            chronology = LouChronology(key: "", duration: 0, posed: 0, gesture: false)
            starts = []
            return
        }
        if chs.count == 1 {
            chronology = first
            starts = [0]
            return
        }
        var places: [LouArmSetup] = []
        for ch in chs {
            for a in ch.arms where !places.contains(a) { places.append(a) }
        }
        var rows: [(sound: Int, key: Int)] = [(0, 0)]
        for (i, ch) in chs.enumerated() {
            for k in 1..<(ch.keys.count - 1) { rows.append((i, k)) }
        }
        let last = chs.count - 1
        rows.append((last, chs[last].keys.count - 1))

        func joint(_ i: Int, _ arm: LouArmSetup, _ k: Int) -> LouJoint? {
            guard let n = chs[i].arms.firstIndex(of: arm) else { return nil }
            return chs[i].keys[k].joints[n]
        }
        func before(_ i: Int, _ arm: LouArmSetup) -> LouJoint? {
            for p in stride(from: i - 1, through: 0, by: -1) where chs[p].arms.contains(arm) {
                return joint(p, arm, chs[p].keys.count - 2)
            }
            return nil
        }
        func after(_ i: Int, _ arm: LouArmSetup) -> LouJoint? {
            for n in (i + 1)..<chs.count where chs[n].arms.contains(arm) { return joint(n, arm, 1) }
            return nil
        }

        var lastDirection: [LouArmSetup: Double] = [:]
        var lines: [[LouJoint]] = []
        for row in rows {
            let lastOfSound = row.key == chs[row.sound].keys.count - 2
            var joints: [LouJoint] = []
            for arm in places {
                var j: LouJoint
                if let own = joint(row.sound, arm, row.key) {
                    j = own
                } else {   // ce bras ne sert pas à ce son : sous le cadre
                    let previous = before(row.sound, arm), next = after(row.sound, arm)
                    if previous == nil || (lastOfSound && next != nil) {
                        j = next!.atRest
                    } else {
                        j = previous!.atRest
                    }
                }
                if let d = lastDirection[arm] {
                    while j.direction - d > 180 { j.direction -= 360 }
                    while j.direction - d < -180 { j.direction += 360 }
                }
                lastDirection[arm] = j.direction
                joints.append(j)
            }
            lines.append(joints)
        }
        // Chaque son est décalé : sa première pose arrive une transition après la dernière du précédent ;
        // la transition dure 0,3 s, plus si une main va loin (un bras qui arrive du repos).
        var transitions: [Double] = []
        for r in 1..<rows.count where rows[r].sound > rows[r - 1].sound {
            var far = 0.0
            for (a, b) in zip(lines[r - 1], lines[r]) {
                far = max(far, hypot(Double(a.wrist.x - b.wrist.x), Double(a.wrist.y - b.wrist.y)))
            }
            transitions.append(min(LouChronology.transitionMax,
                                   max(LouChronology.transition, far / LouChronology.transitionSpeed)))
        }
        var shift = [0.0]
        for i in 1..<chs.count {
            shift.append(shift[i - 1] + chs[i - 1].keys[chs[i - 1].keys.count - 2].t + transitions[i - 1]
                         - chs[i].keys[1].t)
        }
        var out = LouChronology(key: keys.joined(separator: "+"), duration: shift[last] + chs[last].duration,
                                posed: first.posed, gesture: chs.contains { $0.gesture })
        for arm in places { out.arm(arm.side, behind: arm.behind) }
        for (r, row) in rows.enumerated() {
            let key = chs[row.sound].keys[row.key]
            let lastOfSound = row.key == chs[row.sound].keys.count - 2
            let joints = lines[r]
            let t = r == 0 ? 0 : shift[row.sound] + key.t
            var mouth = key.mouth, vibrate = key.vibrate, smooth = key.smooth
            if lastOfSound && row.sound + 1 < chs.count {
                mouth = chs[row.sound + 1].keys[1].mouth
                vibrate = chs[row.sound + 1].keys[1].vibrate
            }
            if row.key == 1 && row.sound > 0 { smooth = true }
            out.keys.append(LouKey(t: t, mouth: mouth, vibrate: vibrate, lift: key.lift, table: key.table,
                                   smooth: smooth, joints: joints))
        }
        chronology = out
        var s = [0.0]
        for i in 1..<chs.count {
            s.append(shift[i - 1] + chs[i - 1].keys[chs[i - 1].keys.count - 2].t + transitions[i - 1] / 2)
        }
        starts = s
    }
}

// MARK: - L'image à un instant

struct LouArmFrame: Sendable {
    let setup: LouArmSetup
    let shoulder: CGPoint
    let elbow: CGPoint
    let wrist: CGPoint
    /// Direction des doigts (degrés, 0 = droite, −90 = haut).
    let direction: Double
    let formA: String
    let formB: String
    /// 0 = `formA`, 1 = `formB`.
    let mix: Double
    let presence: Double
    /// Côté du pouce (±1 ; entre les deux pendant une transition : la main tourne).
    let thumb: Double
    let size: Double

    /// `Main.ecran` : un point du repère de la main, à l'écran.
    func screen(_ q: CGPoint) -> CGPoint {
        let d = direction * .pi / 180
        let ux = cos(d), uy = sin(d)
        let px = -uy * thumb, py = ux * thumb
        return CGPoint(x: Double(wrist.x) + size * (Double(q.x) * ux + Double(q.y) * px),
                       y: Double(wrist.y) + size * (Double(q.x) * uy + Double(q.y) * py))
    }

    /// Le bout d'un doigt à l'écran (formes mêlées : les bouts sont interpolés).
    func tip(_ finger: LouFinger) -> CGPoint {
        let a = LouHandModel.localPath(LouHandModel.form(formA), finger)
        let b = LouHandModel.localPath(LouHandModel.form(formB), finger)
        return screen(louLerp(a[a.count - 1], b[b.count - 1], mix))
    }
}

struct LouFrame: Sendable {
    var arms: [LouArmFrame]
    var mouth: String
    var vibrate: Bool
    var lift: Double
    var table: Double
    /// La bouche d'avant, pendant le fondu ; `mouthMix` = part de `mouth` (1 : fondu fini).
    var previousMouth: String
    var mouthMix: Double = 1
    /// « La gorge vibre », en fondu (0 … 1).
    var vibration: Double
    /// Temps depuis le début de la suite (fait battre les signes de vibration) ; nil : immobiles.
    var pulse: Double?

    init(arms: [LouArmFrame], mouth: String, vibrate: Bool, lift: Double, table: Double, pulse: Double? = nil) {
        self.arms = arms
        self.mouth = mouth
        self.vibrate = vibrate
        self.lift = lift
        self.table = table
        self.previousMouth = mouth
        self.vibration = vibrate ? 1 : 0
        self.pulse = pulse
    }

    /// Lou au repos : bouche fermée, souriante, les bras sous le cadre.
    static let rest = LouFrame(arms: [], mouth: "neutre", vibrate: false, lift: 0, table: 0)
}
#endif
