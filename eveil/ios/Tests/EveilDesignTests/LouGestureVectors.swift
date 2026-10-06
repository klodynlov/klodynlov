// LouGestureVectors.swift — FICHIER GÉNÉRÉ par eveil/outils/gestes/generer.py : ne pas modifier à la main.
//
// Vecteurs de parité Python → Swift des gestes animés de Lou (`animation.etat`) : à quelques
// instants, pour chaque bras, poignet, coude, direction de la main, bout de l'index, présence ;
// et la bouche, la gorge qui vibre, la tête levée, la table.

import CoreGraphics

struct LouVectorArm {
    let wrist: CGPoint
    let elbow: CGPoint
    let direction: Double
    let indexTip: CGPoint
    let presence: Double
}

struct LouVector {
    let key: String
    let t: Double
    let mouth: String
    let vibrate: Bool
    let lift: Double
    let table: Double
    let arms: [LouVectorArm]
}

enum LouGestureVectors {
    static var all: [LouVector] { v00() + v01() + v02() + v03() + v04() + v05() + v06() + v07() + v08() + v09() + v10() + v11() + v12() + v13() + v14() + v15() }
    static let durations: [String: Double] = [
        "a": 1.6,
        "o": 1.6,
        "ou": 2.1,
        "i": 1.6,
        "u": 1.6,
        "é": 1.6,
        "è": 1.6,
        "eu": 1.6,
        "eu ouvert": 1.6,
        "e": 1.6,
        "an": 1.6,
        "on": 1.6,
        "in": 1.6,
        "oi": 1.55,
        "oin": 1.8,
        "ch": 1.8,
        "s": 2.4,
        "z": 1.55,
        "j": 1.4,
        "f": 1.9,
        "v": 1.6,
        "p": 1.58,
        "b": 1.82,
        "t": 1.57,
        "d": 1.57,
        "k": 1.3,
        "g": 1.3,
        "m": 1.9,
        "n": 1.6,
        "gn": 1.95,
        "l": 1.45,
        "r": 1.6,
        "ill": 1.6,
        "ui": 1,
    ]

    private static func v00() -> [LouVector] {   // a
        [
            LouVector(key: "a", t: 0.175, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 224, y: 301), elbow: CGPoint(x: 250, y: 359), direction: -86, indexTip: CGPoint(x: 205.9691, y: 227.3847), presence: 0.5)]),
            LouVector(key: "a", t: 0.35, mouth: "grande", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 224, y: 182), elbow: CGPoint(x: 250, y: 240), direction: -86, indexTip: CGPoint(x: 205.9691, y: 108.3847), presence: 1)]),
            LouVector(key: "a", t: 0.8, mouth: "grande", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 224, y: 182), elbow: CGPoint(x: 250, y: 240), direction: -86, indexTip: CGPoint(x: 205.9691, y: 108.3847), presence: 1)]),
            LouVector(key: "a", t: 1.2, mouth: "grande", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 224, y: 182), elbow: CGPoint(x: 250, y: 240), direction: -86, indexTip: CGPoint(x: 205.9691, y: 108.3847), presence: 1)]),
            LouVector(key: "a", t: 1.263, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 224, y: 182.9606), elbow: CGPoint(x: 250, y: 240.9606), direction: -86, indexTip: CGPoint(x: 205.9691, y: 109.3454), presence: 0.996)]),
            LouVector(key: "a", t: 1.5, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 224, y: 372.8163), elbow: CGPoint(x: 250, y: 430.8163), direction: -86, indexTip: CGPoint(x: 205.9691, y: 299.2011), presence: 0.1983)]),
        ]
    }

    private static func v01() -> [LouVector] {   // ou
        [
            LouVector(key: "ou", t: 0.175, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 202, y: 359), elbow: CGPoint(x: 236, y: 391), direction: -100, indexTip: CGPoint(x: 151.0873, y: 317.3726), presence: 0.5)]),
            LouVector(key: "ou", t: 0.35, mouth: "petite_ronde", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 202, y: 298), elbow: CGPoint(x: 236, y: 330), direction: -100, indexTip: CGPoint(x: 151.0873, y: 256.3726), presence: 1)]),
            LouVector(key: "ou", t: 1.0297, mouth: "petite_ronde", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 220.7349, y: 260.6019), elbow: CGPoint(x: 245.3672, y: 311.3007), direction: -100, indexTip: CGPoint(x: 188.1366, y: 184.6813), presence: 1)]),
            LouVector(key: "ou", t: 1.65, mouth: "petite_ronde", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 222, y: 224), elbow: CGPoint(x: 246, y: 293), direction: -100, indexTip: CGPoint(x: 181.377, y: 151.0797), presence: 1)]),
            LouVector(key: "ou", t: 1.875, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 222, y: 281.1429), elbow: CGPoint(x: 246, y: 350.1429), direction: -100, indexTip: CGPoint(x: 181.377, y: 208.2226), presence: 0.7085)]),
            LouVector(key: "ou", t: 2, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 222, y: 381.1429), elbow: CGPoint(x: 246, y: 450.1429), direction: -100, indexTip: CGPoint(x: 181.377, y: 308.2226), presence: 0.1983)]),
        ]
    }

    private static func v02() -> [LouVector] {   // é
        [
            LouVector(key: "é", t: 0.175, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 80, y: 266), elbow: CGPoint(x: 22, y: 324), direction: -54, indexTip: CGPoint(x: 130.3624, y: 221.1816), presence: 0.5)]),
            LouVector(key: "é", t: 0.35, mouth: "etiree", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 80, y: 112), elbow: CGPoint(x: 22, y: 170), direction: -54, indexTip: CGPoint(x: 130.3624, y: 67.1816), presence: 1)]),
            LouVector(key: "é", t: 0.8, mouth: "etiree", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 80, y: 112), elbow: CGPoint(x: 22, y: 170), direction: -54, indexTip: CGPoint(x: 130.3624, y: 67.1816), presence: 1)]),
            LouVector(key: "é", t: 1.2, mouth: "etiree", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 80, y: 112), elbow: CGPoint(x: 22, y: 170), direction: -54, indexTip: CGPoint(x: 130.3624, y: 67.1816), presence: 1)]),
            LouVector(key: "é", t: 1.263, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 80, y: 113.2432), elbow: CGPoint(x: 22, y: 171.2432), direction: -54, indexTip: CGPoint(x: 130.3624, y: 68.4248), presence: 0.996)]),
            LouVector(key: "é", t: 1.5, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 80, y: 358.9388), elbow: CGPoint(x: 22, y: 416.9388), direction: -54, indexTip: CGPoint(x: 130.3624, y: 314.1204), presence: 0.1983)]),
        ]
    }

    private static func v03() -> [LouVector] {   // s
        [
            LouVector(key: "s", t: 0.175, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 230.025, y: 277.222), elbow: CGPoint(x: 243, y: 363), direction: -85, indexTip: CGPoint(x: 221.6611, y: 203.0106), presence: 0.5)]),
            LouVector(key: "s", t: 0.35, mouth: "etiree", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 242.05, y: 134.444), elbow: CGPoint(x: 254, y: 236), direction: -74, indexTip: CGPoint(x: 248, y: 60.0002), presence: 1)]),
            LouVector(key: "s", t: 1.1651, mouth: "etiree", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 219.5129, y: 163.8273), elbow: CGPoint(x: 254, y: 236), direction: -74, indexTip: CGPoint(x: 225.4629, y: 89.3835), presence: 1)]),
            LouVector(key: "s", t: 1.95, mouth: "etiree", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 198.05, y: 198.444), elbow: CGPoint(x: 254, y: 236), direction: -74, indexTip: CGPoint(x: 204, y: 124.0002), presence: 1)]),
            LouVector(key: "s", t: 2.175, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 198.05, y: 263.0376), elbow: CGPoint(x: 254, y: 300.5936), direction: -74, indexTip: CGPoint(x: 204, y: 188.5938), presence: 0.7085)]),
            LouVector(key: "s", t: 2.3, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 198.05, y: 376.0764), elbow: CGPoint(x: 254, y: 413.6324), direction: -74, indexTip: CGPoint(x: 204, y: 301.6326), presence: 0.1983)]),
        ]
    }

    private static func v04() -> [LouVector] {   // z
        [
            LouVector(key: "z", t: 0.175, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 209.025, y: 275.222), elbow: CGPoint(x: 243, y: 363), direction: -85, indexTip: CGPoint(x: 200.6611, y: 201.0106), presence: 0.5)]),
            LouVector(key: "z", t: 0.35, mouth: "etiree", vibrate: true, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 200.05, y: 130.444), elbow: CGPoint(x: 254, y: 236), direction: -74, indexTip: CGPoint(x: 206, y: 56.0002), presence: 1)]),
            LouVector(key: "z", t: 0.7297, mouth: "etiree", vibrate: true, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 212.072, y: 177.3892), elbow: CGPoint(x: 254, y: 236), direction: -74, indexTip: CGPoint(x: 218.0219, y: 102.9454), presence: 1)]),
            LouVector(key: "z", t: 1.05, mouth: "etiree", vibrate: true, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 206.05, y: 216.444), elbow: CGPoint(x: 254, y: 236), direction: -74, indexTip: CGPoint(x: 212, y: 142.0002), presence: 1)]),
            LouVector(key: "z", t: 1.3, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 206.05, y: 256.7991), elbow: CGPoint(x: 254, y: 276.3551), direction: -74, indexTip: CGPoint(x: 212, y: 182.3553), presence: 0.8017)]),
            LouVector(key: "z", t: 1.45, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 206.05, y: 379.6449), elbow: CGPoint(x: 254, y: 399.2009), direction: -74, indexTip: CGPoint(x: 212, y: 305.2011), presence: 0.1983)]),
        ]
    }

    private static func v05() -> [LouVector] {   // oi
        [
            LouVector(key: "oi", t: 0.175, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 202, y: 359), elbow: CGPoint(x: 236, y: 391), direction: -100, indexTip: CGPoint(x: 177.5628, y: 314.1623), presence: 0.5)]),
            LouVector(key: "oi", t: 0.35, mouth: "ronde", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 202, y: 298), elbow: CGPoint(x: 236, y: 330), direction: -100, indexTip: CGPoint(x: 177.5628, y: 253.1623), presence: 1)]),
            LouVector(key: "oi", t: 0.75, mouth: "ronde", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 202, y: 298), elbow: CGPoint(x: 236, y: 330), direction: -100, indexTip: CGPoint(x: 163.1651, y: 224.2268), presence: 1)]),
            LouVector(key: "oi", t: 0.763, mouth: "ronde", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 202, y: 298), elbow: CGPoint(x: 236, y: 330), direction: -100, indexTip: CGPoint(x: 163.1651, y: 224.2268), presence: 1)]),
            LouVector(key: "oi", t: 1.15, mouth: "ronde", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 202, y: 298), elbow: CGPoint(x: 236, y: 330), direction: -100, indexTip: CGPoint(x: 163.1651, y: 224.2268), presence: 1)]),
            LouVector(key: "oi", t: 1.45, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 202, y: 395.8134), elbow: CGPoint(x: 236, y: 427.8134), direction: -100, indexTip: CGPoint(x: 163.1651, y: 322.0402), presence: 0.1983)]),
        ]
    }

    private static func v06() -> [LouVector] {   // oin
        [
            LouVector(key: "oin", t: 0.175, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 240, y: 345), elbow: CGPoint(x: 262, y: 405), direction: -168, indexTip: CGPoint(x: 165.5926, y: 343.0875), presence: 0.5)]),
            LouVector(key: "oin", t: 0.35, mouth: "ronde", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 240, y: 270), elbow: CGPoint(x: 262, y: 330), direction: -168, indexTip: CGPoint(x: 165.5926, y: 268.0875), presence: 1)]),
            LouVector(key: "oin", t: 1.013, mouth: "ronde", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 240, y: 270), elbow: CGPoint(x: 262, y: 330), direction: -168, indexTip: CGPoint(x: 168, y: 261.4731), presence: 1)]),
            LouVector(key: "oin", t: 1.15, mouth: "ronde", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 240, y: 270), elbow: CGPoint(x: 262, y: 330), direction: -168, indexTip: CGPoint(x: 165.5926, y: 268.0875), presence: 1)]),
            LouVector(key: "oin", t: 1.475, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 240, y: 272.1866), elbow: CGPoint(x: 262, y: 332.1866), direction: -168, indexTip: CGPoint(x: 165.5926, y: 270.2741), presence: 0.9854)]),
            LouVector(key: "oin", t: 1.7, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 240, y: 390.2624), elbow: CGPoint(x: 262, y: 450.2624), direction: -168, indexTip: CGPoint(x: 165.5926, y: 388.3499), presence: 0.1983)]),
        ]
    }

    private static func v07() -> [LouVector] {   // f
        [
            LouVector(key: "f", t: 0.175, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 184, y: 339), elbow: CGPoint(x: 232, y: 401), direction: -178, indexTip: CGPoint(x: 111.4239, y: 320.4553), presence: 0.5)]),
            LouVector(key: "f", t: 0.35, mouth: "dents_levre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 184, y: 258), elbow: CGPoint(x: 232, y: 320), direction: -178, indexTip: CGPoint(x: 111.4239, y: 239.4553), presence: 1)]),
            LouVector(key: "f", t: 0.5, mouth: "dents_levre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 184, y: 258), elbow: CGPoint(x: 232, y: 320), direction: -178, indexTip: CGPoint(x: 111.4239, y: 239.4553), presence: 1)]),
            LouVector(key: "f", t: 1.063, mouth: "dents_levre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 242.7238, y: 258), elbow: CGPoint(x: 261.3617, y: 320), direction: -178, indexTip: CGPoint(x: 170.1477, y: 239.4553), presence: 1)]),
            LouVector(key: "f", t: 1.2, mouth: "dents_levre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 269.9685, y: 258), elbow: CGPoint(x: 274.984, y: 320), direction: -178, indexTip: CGPoint(x: 197.3924, y: 239.4553), presence: 1)]),
            LouVector(key: "f", t: 1.8, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 296, y: 387.8834), elbow: CGPoint(x: 288, y: 449.8834), direction: -178, indexTip: CGPoint(x: 223.4239, y: 369.3387), presence: 0.1983)]),
        ]
    }

    private static func v08() -> [LouVector] {   // v
        [
            LouVector(key: "v", t: 0.175, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 126, y: 359), elbow: CGPoint(x: 70, y: 391), direction: -122, indexTip: CGPoint(x: 103.3112, y: 295.5155), presence: 0.5), LouVectorArm(wrist: CGPoint(x: 134, y: 359), elbow: CGPoint(x: 190, y: 391), direction: -58, indexTip: CGPoint(x: 156.6888, y: 295.5155), presence: 0.5)]),
            LouVector(key: "v", t: 0.35, mouth: "dents_levre", vibrate: true, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 126, y: 298), elbow: CGPoint(x: 70, y: 330), direction: -122, indexTip: CGPoint(x: 103.3112, y: 234.5155), presence: 1), LouVectorArm(wrist: CGPoint(x: 134, y: 298), elbow: CGPoint(x: 190, y: 330), direction: -58, indexTip: CGPoint(x: 156.6888, y: 234.5155), presence: 1)]),
            LouVector(key: "v", t: 0.8, mouth: "dents_levre", vibrate: true, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 126, y: 298), elbow: CGPoint(x: 70, y: 330), direction: -122, indexTip: CGPoint(x: 103.3112, y: 234.5155), presence: 1), LouVectorArm(wrist: CGPoint(x: 134, y: 298), elbow: CGPoint(x: 190, y: 330), direction: -58, indexTip: CGPoint(x: 156.6888, y: 234.5155), presence: 1)]),
            LouVector(key: "v", t: 1.2, mouth: "dents_levre", vibrate: true, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 126, y: 298), elbow: CGPoint(x: 70, y: 330), direction: -122, indexTip: CGPoint(x: 103.3112, y: 234.5155), presence: 1), LouVectorArm(wrist: CGPoint(x: 134, y: 298), elbow: CGPoint(x: 190, y: 330), direction: -58, indexTip: CGPoint(x: 156.6888, y: 234.5155), presence: 1)]),
            LouVector(key: "v", t: 1.263, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 126, y: 298.4924), elbow: CGPoint(x: 70, y: 330.4924), direction: -122, indexTip: CGPoint(x: 103.3112, y: 235.0079), presence: 0.996), LouVectorArm(wrist: CGPoint(x: 134, y: 298.4924), elbow: CGPoint(x: 190, y: 330.4924), direction: -58, indexTip: CGPoint(x: 156.6888, y: 235.0079), presence: 0.996)]),
            LouVector(key: "v", t: 1.5, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 126, y: 395.8134), elbow: CGPoint(x: 70, y: 427.8134), direction: -122, indexTip: CGPoint(x: 103.3112, y: 332.3289), presence: 0.1983), LouVectorArm(wrist: CGPoint(x: 134, y: 395.8134), elbow: CGPoint(x: 190, y: 427.8134), direction: -58, indexTip: CGPoint(x: 156.6888, y: 332.3289), presence: 0.1983)]),
        ]
    }

    private static func v09() -> [LouVector] {   // p
        [
            LouVector(key: "p", t: 0.175, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 214, y: 313), elbow: CGPoint(x: 228, y: 397), direction: -92, indexTip: CGPoint(x: 197.6734, y: 269.5433), presence: 0.5)]),
            LouVector(key: "p", t: 0.35, mouth: "fermee", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 214, y: 206), elbow: CGPoint(x: 228, y: 290), direction: -92, indexTip: CGPoint(x: 197.6734, y: 162.5433), presence: 1)]),
            LouVector(key: "p", t: 0.83, mouth: "mi_ouverte", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 214, y: 206), elbow: CGPoint(x: 228, y: 290), direction: -92, indexTip: CGPoint(x: 188.373, y: 134.6727), presence: 1)]),
            LouVector(key: "p", t: 0.843, mouth: "mi_ouverte", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 214, y: 206), elbow: CGPoint(x: 228, y: 290), direction: -92, indexTip: CGPoint(x: 188.373, y: 134.6727), presence: 1)]),
            LouVector(key: "p", t: 1.205, mouth: "mi_ouverte", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 214, y: 206), elbow: CGPoint(x: 228, y: 290), direction: -92, indexTip: CGPoint(x: 188.373, y: 134.6727), presence: 1)]),
            LouVector(key: "p", t: 1.48, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 214, y: 377.5743), elbow: CGPoint(x: 228, y: 461.5743), direction: -92, indexTip: CGPoint(x: 188.373, y: 306.2471), presence: 0.1983)]),
        ]
    }

    private static func v10() -> [LouVector] {   // b
        [
            LouVector(key: "b", t: 0.175, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 267, y: 352), elbow: CGPoint(x: 284.5, y: 386), direction: -152, indexTip: CGPoint(x: 234.8212, y: 298.4532), presence: 0.5)]),
            LouVector(key: "b", t: 0.35, mouth: "fermee", vibrate: true, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 312, y: 284), elbow: CGPoint(x: 307, y: 322), direction: -152, indexTip: CGPoint(x: 279.8212, y: 230.4532), presence: 1)]),
            LouVector(key: "b", t: 0.663, mouth: "fermee", vibrate: true, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 249.7301, y: 291.188), elbow: CGPoint(x: 275.8653, y: 325.5945), direction: -152, indexTip: CGPoint(x: 217.5513, y: 237.6412), presence: 1)]),
            LouVector(key: "b", t: 1.07, mouth: "mi_ouverte", vibrate: true, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 222, y: 300), elbow: CGPoint(x: 262, y: 330), direction: -152, indexTip: CGPoint(x: 174.4131, y: 251.1289), presence: 1)]),
            LouVector(key: "b", t: 1.445, mouth: "mi_ouverte", vibrate: true, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 222, y: 300), elbow: CGPoint(x: 262, y: 330), direction: -152, indexTip: CGPoint(x: 174.4131, y: 251.1289), presence: 1)]),
            LouVector(key: "b", t: 1.72, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 222, y: 396.2099), elbow: CGPoint(x: 262, y: 426.2099), direction: -152, indexTip: CGPoint(x: 174.4131, y: 347.3388), presence: 0.1983)]),
        ]
    }

    private static func v11() -> [LouVector] {   // d
        [
            LouVector(key: "d", t: 0.175, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 228, y: 344), elbow: CGPoint(x: 244, y: 406), direction: -96, indexTip: CGPoint(x: 194.2162, y: 290.438), presence: 0.5), LouVectorArm(wrist: CGPoint(x: 86, y: 360), elbow: CGPoint(x: 18, y: 334), direction: 10, indexTip: CGPoint(x: 126.7615, y: 382.2157), presence: 0.5)]),
            LouVector(key: "d", t: 0.35, mouth: "langue_haut", vibrate: true, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 228, y: 268), elbow: CGPoint(x: 244, y: 330), direction: -96, indexTip: CGPoint(x: 194.2162, y: 214.438), presence: 1), LouVectorArm(wrist: CGPoint(x: 86, y: 300), elbow: CGPoint(x: 18, y: 274), direction: 10, indexTip: CGPoint(x: 126.7615, y: 322.2157), presence: 1)]),
            LouVector(key: "d", t: 0.82, mouth: "langue_haut", vibrate: true, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 228, y: 268), elbow: CGPoint(x: 244, y: 330), direction: -96, indexTip: CGPoint(x: 198.6984, y: 203.5096), presence: 1), LouVectorArm(wrist: CGPoint(x: 86, y: 300), elbow: CGPoint(x: 18, y: 274), direction: 10, indexTip: CGPoint(x: 126.7615, y: 322.2157), presence: 1)]),
            LouVector(key: "d", t: 0.833, mouth: "langue_haut", vibrate: true, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 228, y: 268), elbow: CGPoint(x: 244, y: 330), direction: -96, indexTip: CGPoint(x: 198.6984, y: 203.5096), presence: 1), LouVectorArm(wrist: CGPoint(x: 86, y: 300), elbow: CGPoint(x: 18, y: 274), direction: 10, indexTip: CGPoint(x: 126.7615, y: 322.2157), presence: 1)]),
            LouVector(key: "d", t: 1.195, mouth: "langue_haut", vibrate: true, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 228, y: 268), elbow: CGPoint(x: 244, y: 330), direction: -96, indexTip: CGPoint(x: 198.6984, y: 203.5096), presence: 1), LouVectorArm(wrist: CGPoint(x: 86, y: 300), elbow: CGPoint(x: 18, y: 274), direction: 10, indexTip: CGPoint(x: 126.7615, y: 322.2157), presence: 1)]),
            LouVector(key: "d", t: 1.47, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 228, y: 389.8659), elbow: CGPoint(x: 244, y: 451.8659), direction: -96, indexTip: CGPoint(x: 198.6984, y: 325.3755), presence: 0.1983), LouVectorArm(wrist: CGPoint(x: 86, y: 396.2099), elbow: CGPoint(x: 18, y: 370.2099), direction: 10, indexTip: CGPoint(x: 126.7615, y: 418.4256), presence: 0.1983)]),
        ]
    }

    private static func v12() -> [LouVector] {   // m
        [
            LouVector(key: "m", t: 0.175, mouth: "neutre", vibrate: false, lift: 0, table: 0.5, arms: [LouVectorArm(wrist: CGPoint(x: 190.8, y: 280.8), elbow: CGPoint(x: 250, y: 327.2), direction: 90, indexTip: CGPoint(x: 178.8, y: 346.4), presence: 0.5)]),
            LouVector(key: "m", t: 0.35, mouth: "neutre", vibrate: false, lift: 0, table: 1, arms: [LouVectorArm(wrist: CGPoint(x: 190.8, y: 141.6), elbow: CGPoint(x: 250, y: 202), direction: 90, indexTip: CGPoint(x: 178.8, y: 207.2), presence: 1)]),
            LouVector(key: "m", t: 0.95, mouth: "fermee", vibrate: false, lift: 0, table: 1, arms: [LouVectorArm(wrist: CGPoint(x: 190.8, y: 197.6), elbow: CGPoint(x: 250, y: 230), direction: 90, indexTip: CGPoint(x: 178.8, y: 263.2), presence: 1)]),
            LouVector(key: "m", t: 1.313, mouth: "neutre", vibrate: false, lift: 0, table: 1, arms: [LouVectorArm(wrist: CGPoint(x: 190.8, y: 197.1615), elbow: CGPoint(x: 250, y: 229.7807), direction: 90, indexTip: CGPoint(x: 178.8, y: 262.7615), presence: 1)]),
            LouVector(key: "m", t: 1.425, mouth: "neutre", vibrate: false, lift: 0, table: 1, arms: [LouVectorArm(wrist: CGPoint(x: 190.8, y: 169.6), elbow: CGPoint(x: 250, y: 216), direction: 90, indexTip: CGPoint(x: 178.8, y: 235.2), presence: 1)]),
            LouVector(key: "m", t: 1.8, mouth: "neutre", vibrate: false, lift: 0, table: 0.1983, arms: [LouVectorArm(wrist: CGPoint(x: 190.8, y: 364.807), elbow: CGPoint(x: 250, y: 425.207), direction: 90, indexTip: CGPoint(x: 178.8, y: 430.407), presence: 0.1983)]),
        ]
    }

    private static func v13() -> [LouVector] {   // gn
        [
            LouVector(key: "gn", t: 0.175, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 203.252, y: 292.185), elbow: CGPoint(x: 250, y: 377.815), direction: -174, indexTip: CGPoint(x: 132, y: 269.8146), presence: 0.5)]),
            LouVector(key: "gn", t: 0.35, mouth: "fond", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 203.252, y: 164.37), elbow: CGPoint(x: 250, y: 250), direction: -174, indexTip: CGPoint(x: 132, y: 141.9996), presence: 1)]),
            LouVector(key: "gn", t: 1.15, mouth: "fond", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 187.252, y: 164.37), elbow: CGPoint(x: 242, y: 250), direction: -174, indexTip: CGPoint(x: 116, y: 141.9996), presence: 1)]),
            LouVector(key: "gn", t: 1.163, mouth: "fond", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 187.4271, y: 164.37), elbow: CGPoint(x: 242.0875, y: 250), direction: -174, indexTip: CGPoint(x: 116.1751, y: 141.9996), presence: 1)]),
            LouVector(key: "gn", t: 1.85, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 203.252, y: 369.3212), elbow: CGPoint(x: 250, y: 454.9512), direction: -174, indexTip: CGPoint(x: 132, y: 346.9508), presence: 0.1983)]),
        ]
    }

    private static func v14() -> [LouVector] {   // ill
        [
            LouVector(key: "ill", t: 0.175, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 225.2, y: 297.4), elbow: CGPoint(x: 250, y: 372.6), direction: 180, indexTip: CGPoint(x: 152, y: 282.6), presence: 0.5)]),
            LouVector(key: "ill", t: 0.35, mouth: "etiree", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 225.2, y: 174.8), elbow: CGPoint(x: 250, y: 250), direction: 180, indexTip: CGPoint(x: 152, y: 160), presence: 1)]),
            LouVector(key: "ill", t: 0.813, mouth: "etiree", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 248.6241, y: 174.8), elbow: CGPoint(x: 261.7121, y: 250), direction: 180, indexTip: CGPoint(x: 175.4241, y: 160), presence: 1)]),
            LouVector(key: "ill", t: 1.1, mouth: "etiree", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 269.2, y: 174.8), elbow: CGPoint(x: 272, y: 250), direction: 180, indexTip: CGPoint(x: 196, y: 160), presence: 1)]),
            LouVector(key: "ill", t: 1.35, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 269.2, y: 223.4111), elbow: CGPoint(x: 272, y: 298.6111), direction: 180, indexTip: CGPoint(x: 196, y: 208.6111), presence: 0.8017)]),
            LouVector(key: "ill", t: 1.5, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 269.2, y: 371.3889), elbow: CGPoint(x: 272, y: 446.5889), direction: 180, indexTip: CGPoint(x: 196, y: 356.5889), presence: 0.1983)]),
        ]
    }

    private static func v15() -> [LouVector] {   // ui
        [
            LouVector(key: "ui", t: 0.175, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: []),
            LouVector(key: "ui", t: 0.35, mouth: "mi_ouverte", vibrate: false, lift: 0, table: 0, arms: []),
            LouVector(key: "ui", t: 0.5, mouth: "mi_ouverte", vibrate: false, lift: 0, table: 0, arms: []),
            LouVector(key: "ui", t: 0.75, mouth: "mi_ouverte", vibrate: false, lift: 0, table: 0, arms: []),
            LouVector(key: "ui", t: 0.813, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: []),
            LouVector(key: "ui", t: 0.9, mouth: "neutre", vibrate: false, lift: 0, table: 0, arms: []),
        ]
    }
}
