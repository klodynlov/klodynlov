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

/// Ce qui ne change pas pendant un geste, pour un bras.
struct LouArmSetup: Sendable {
    enum Side: Sendable { case left, right }
    let side: Side
    let thumb: CGFloat
    let size: CGFloat
    /// Bras caché derrière le buste (« d » : l'autre main dans le dos).
    let behind: Bool

    var shoulder: CGPoint { side == .right ? LouArt.shoulderRight : LouArt.shoulderLeft }
}

/// Un bras à une clé (direction en degrés, déroulée d'une clé à l'autre).
struct LouJoint: Sendable {
    let elbow: CGPoint
    let wrist: CGPoint
    let direction: Double
    let form: String
    let presence: Double    // 0 = au repos (invisible), 1 = là
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

/// Un son : du repos au repos.
struct LouChronology: Sendable {
    let key: String
    let duration: Double
    /// L'instant « pose » (tenue quand les animations sont réduites).
    let posed: Double
    /// Faux : la bouche seule (son sans geste).
    let gesture: Bool
    private(set) var arms: [LouArmSetup] = []
    private(set) var keys: [LouKey] = []

    init(key: String, duration: Double, posed: Double, gesture: Bool) {
        self.key = key
        self.duration = duration
        self.posed = posed
        self.gesture = gesture
    }

    mutating func arm(_ side: LouArmSetup.Side, thumb: CGFloat, size: CGFloat, behind: Bool) {
        arms.append(LouArmSetup(side: side, thumb: thumb, size: size, behind: behind))
    }

    mutating func key(_ t: Double, _ mouth: String, _ vibrate: Bool, _ lift: Double, _ table: Double,
                      _ smooth: Bool, _ joints: LouJoint...) {
        keys.append(LouKey(t: t, mouth: mouth, vibrate: vibrate, lift: lift, table: table, smooth: smooth,
                           joints: joints))
    }

    static func J(_ ex: Double, _ ey: Double, _ wx: Double, _ wy: Double, _ direction: Double,
                  _ form: String, _ presence: Double) -> LouJoint {
        LouJoint(elbow: CGPoint(x: ex, y: ey), wrist: CGPoint(x: wx, y: wy), direction: direction, form: form,
                 presence: presence)
    }

    /// Un son inconnu : Lou au repos pendant une seconde.
    static func neutral(_ key: String) -> LouChronology {
        var c = LouChronology(key: key, duration: 1, posed: 0.5, gesture: false)
        c.key(0, "neutre", false, 0, 0, false)
        c.key(1, "neutre", false, 0, 0, false)
        return c
    }

    /// La chronologie d'une étiquette : son geste, sinon sa bouche seule, sinon le repos.
    static func of(_ key: String) -> LouChronology {
        gestures[key] ?? mouthOnly[key] ?? neutral(key)
    }

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
        let e = k1.smooth ? x * x * (3 - 2 * x) : x
        var out: [LouArmFrame] = []
        for (n, setup) in arms.enumerated() {
            let p0 = k0.joints[n], p1 = k1.joints[n]
            let elbow = louLerp(p0.elbow, p1.elbow, e)
            let wrist = louLerp(p0.wrist, p1.wrist, e)
            let same = p0.form == p1.form
            out.append(LouArmFrame(setup: setup, shoulder: setup.shoulder, elbow: elbow, wrist: wrist,
                                   direction: louLerp(p0.direction, p1.direction, e), formA: p0.form,
                                   formB: same ? p0.form : p1.form, mix: same ? 0 : e,
                                   presence: louLerp(p0.presence, p1.presence, e)))
        }
        return LouFrame(arms: out, mouth: k0.mouth, vibrate: k0.vibrate, lift: louLerp(k0.lift, k1.lift, e),
                        table: louLerp(k0.table, k1.table, e))
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

    /// `Main.ecran` : un point du repère de la main, à l'écran.
    func screen(_ q: CGPoint) -> CGPoint {
        let d = direction * .pi / 180
        let ux = cos(d), uy = sin(d)
        let pouce = Double(setup.thumb)
        let px = -uy * pouce, py = ux * pouce
        let s = Double(setup.size)
        return CGPoint(x: Double(wrist.x) + s * (Double(q.x) * ux + Double(q.y) * px),
                       y: Double(wrist.y) + s * (Double(q.x) * uy + Double(q.y) * py))
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
    /// Temps depuis le début de la suite (fait battre les signes de vibration) ; nil : immobiles.
    var pulse: Double?

    init(arms: [LouArmFrame], mouth: String, vibrate: Bool, lift: Double, table: Double, pulse: Double? = nil) {
        self.arms = arms
        self.mouth = mouth
        self.vibrate = vibrate
        self.lift = lift
        self.table = table
        self.pulse = pulse
    }

    /// Lou au repos : bouche fermée, souriante, les bras sous le cadre.
    static let rest = LouFrame(arms: [], mouth: "neutre", vibrate: false, lift: 0, table: 0)
}
#endif
