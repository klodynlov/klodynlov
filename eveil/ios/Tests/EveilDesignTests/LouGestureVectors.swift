// LouGestureVectors.swift — FICHIER GÉNÉRÉ par eveil/outils/gestes/generer.py : ne pas modifier à la main.
//
// Vecteurs de parité Python → Swift des gestes animés de Lou (`animation.etat`, `animation.enchainer`) :
// à quelques instants d'un son ou d'une suite de sons, pour chaque bras, poignet, coude, direction de
// la main, bout de l'index, présence, côté du pouce ; et la bouche (avec son fondu), la gorge qui
// vibre, la tête levée, la table. Plus les durées (d'un son, d'une suite) et les débuts des sons.

import CoreGraphics

struct LouVectorArm {
    let wrist: CGPoint
    let elbow: CGPoint
    let direction: Double
    let indexTip: CGPoint
    let presence: Double
    let thumb: Double
}

struct LouVector {
    let keys: [String]
    let t: Double
    let mouth: String
    let previousMouth: String
    let mouthMix: Double
    let vibrate: Bool
    let vibration: Double
    let lift: Double
    let table: Double
    let arms: [LouVectorArm]
}

struct LouChainVector {
    let keys: [String]
    let duration: Double
    let starts: [Double]
}

enum LouGestureVectors {
    static var all: [LouVector] { v00() + v01() + v02() + v03() + v04() + v05() + v06() + v07() + v08() + v09() + v10() + v11() + v12() + v13() + v14() + v15() + v16() + v17() + v18() + v19() + v20() }
    static let durations: [String: Double] = [
        "a": 1.7,
        "o": 1.7,
        "ou": 2.2,
        "i": 1.7,
        "u": 1.7,
        "é": 1.7,
        "è": 1.7,
        "eu": 1.7,
        "eu ouvert": 1.7,
        "e": 1.7,
        "an": 1.7,
        "on": 1.7,
        "in": 1.7,
        "oi": 1.65,
        "oin": 1.9,
        "ch": 1.9,
        "s": 2.5,
        "z": 1.65,
        "j": 1.5,
        "f": 2,
        "v": 1.7,
        "p": 1.68,
        "b": 1.92,
        "t": 1.67,
        "d": 1.67,
        "k": 1.4,
        "g": 1.4,
        "m": 2,
        "n": 1.7,
        "gn": 2.05,
        "l": 1.55,
        "r": 1.7,
        "ill": 1.7,
        "ui": 1,
    ]
    static let chains: [LouChainVector] = [
        LouChainVector(keys: ["j", "u"], duration: 2.7, starts: [0, 1.25]),
        LouChainVector(keys: ["v", "oi"], duration: 2.85, starts: [0, 1.45]),
        LouChainVector(keys: ["ch", "ui", "ou"], duration: 4.5, starts: [0, 1.65, 2.55]),
        LouChainVector(keys: ["a", "é", "d", "s"], duration: 6.35, starts: [0, 1.52, 2.86, 4.1]),
        LouChainVector(keys: ["p", "xyz", "l"], duration: 3.6357, starts: [0, 1.4329, 2.3357]),
    ]

    private static func v00() -> [LouVector] {   // a
        [
            LouVector(keys: ["a"], t: 0.2, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 224, y: 301), elbow: CGPoint(x: 250, y: 359), direction: -86, indexTip: CGPoint(x: 205.9691, y: 227.3847), presence: 0.5, thumb: -1)]),
            LouVector(keys: ["a"], t: 0.4, mouth: "grande", previousMouth: "neutre", mouthMix: 0, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 224, y: 182), elbow: CGPoint(x: 250, y: 240), direction: -86, indexTip: CGPoint(x: 205.9691, y: 108.3847), presence: 1, thumb: -1)]),
            LouVector(keys: ["a"], t: 0.85, mouth: "grande", previousMouth: "grande", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 224, y: 182), elbow: CGPoint(x: 250, y: 240), direction: -86, indexTip: CGPoint(x: 205.9691, y: 108.3847), presence: 1, thumb: -1)]),
            LouVector(keys: ["a"], t: 1.275, mouth: "grande", previousMouth: "grande", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 224, y: 182), elbow: CGPoint(x: 250, y: 240), direction: -86, indexTip: CGPoint(x: 205.9691, y: 108.3847), presence: 1, thumb: -1)]),
            LouVector(keys: ["a"], t: 1.313, mouth: "neutre", previousMouth: "grande", mouthMix: 0.1083, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 224, y: 182.0778), elbow: CGPoint(x: 250, y: 240.0778), direction: -86, indexTip: CGPoint(x: 205.9691, y: 108.4625), presence: 0.9997, thumb: -1)]),
            LouVector(keys: ["a"], t: 1.6, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 224, y: 395.3633), elbow: CGPoint(x: 250, y: 453.3633), direction: -86, indexTip: CGPoint(x: 205.9691, y: 321.748), presence: 0.1035, thumb: -1)]),
        ]
    }

    private static func v01() -> [LouVector] {   // ou
        [
            LouVector(keys: ["ou"], t: 0.2, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 202, y: 359), elbow: CGPoint(x: 236, y: 391), direction: -100, indexTip: CGPoint(x: 151.0873, y: 317.3726), presence: 0.5, thumb: -1)]),
            LouVector(keys: ["ou"], t: 0.4, mouth: "petite_ronde", previousMouth: "neutre", mouthMix: 0, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 202, y: 298), elbow: CGPoint(x: 236, y: 330), direction: -100, indexTip: CGPoint(x: 151.0873, y: 256.3726), presence: 1, thumb: -1)]),
            LouVector(keys: ["ou"], t: 1.0797, mouth: "petite_ronde", previousMouth: "petite_ronde", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 220.8421, y: 259.941), elbow: CGPoint(x: 245.4212, y: 310.9708), direction: -100, indexTip: CGPoint(x: 188.2438, y: 184.0204), presence: 1, thumb: -1)]),
            LouVector(keys: ["ou"], t: 1.7, mouth: "petite_ronde", previousMouth: "petite_ronde", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 222, y: 224), elbow: CGPoint(x: 246, y: 293), direction: -100, indexTip: CGPoint(x: 181.377, y: 151.0797), presence: 1, thumb: -1)]),
            LouVector(keys: ["ou"], t: 1.95, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 222, y: 277.9407), elbow: CGPoint(x: 246, y: 346.9407), direction: -100, indexTip: CGPoint(x: 181.377, y: 205.0204), presence: 0.7248, thumb: -1)]),
            LouVector(keys: ["ou"], t: 2.1, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 222, y: 399.7109), elbow: CGPoint(x: 246, y: 468.7109), direction: -100, indexTip: CGPoint(x: 181.377, y: 326.7906), presence: 0.1035, thumb: -1)]),
        ]
    }

    private static func v02() -> [LouVector] {   // é
        [
            LouVector(keys: ["é"], t: 0.2, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 80, y: 266), elbow: CGPoint(x: 22, y: 324), direction: -54, indexTip: CGPoint(x: 130.3624, y: 221.1816), presence: 0.5, thumb: 1)]),
            LouVector(keys: ["é"], t: 0.4, mouth: "etiree", previousMouth: "neutre", mouthMix: 0, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 80, y: 112), elbow: CGPoint(x: 22, y: 170), direction: -54, indexTip: CGPoint(x: 130.3624, y: 67.1816), presence: 1, thumb: 1)]),
            LouVector(keys: ["é"], t: 0.85, mouth: "etiree", previousMouth: "etiree", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 80, y: 112), elbow: CGPoint(x: 22, y: 170), direction: -54, indexTip: CGPoint(x: 130.3624, y: 67.1816), presence: 1, thumb: 1)]),
            LouVector(keys: ["é"], t: 1.275, mouth: "etiree", previousMouth: "etiree", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 80, y: 112), elbow: CGPoint(x: 22, y: 170), direction: -54, indexTip: CGPoint(x: 130.3624, y: 67.1816), presence: 1, thumb: 1)]),
            LouVector(keys: ["é"], t: 1.313, mouth: "neutre", previousMouth: "etiree", mouthMix: 0.1083, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 80, y: 112.1006), elbow: CGPoint(x: 22, y: 170.1006), direction: -54, indexTip: CGPoint(x: 130.3624, y: 67.2823), presence: 0.9997, thumb: 1)]),
            LouVector(keys: ["é"], t: 1.6, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 80, y: 388.1172), elbow: CGPoint(x: 22, y: 446.1172), direction: -54, indexTip: CGPoint(x: 130.3624, y: 343.2988), presence: 0.1035, thumb: 1)]),
        ]
    }

    private static func v03() -> [LouVector] {   // s
        [
            LouVector(keys: ["s"], t: 0.2, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 230.025, y: 277.222), elbow: CGPoint(x: 243, y: 363), direction: -85, indexTip: CGPoint(x: 221.6611, y: 203.0106), presence: 0.5, thumb: -1)]),
            LouVector(keys: ["s"], t: 0.4, mouth: "etiree", previousMouth: "neutre", mouthMix: 0, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 242.05, y: 134.444), elbow: CGPoint(x: 254, y: 236), direction: -74, indexTip: CGPoint(x: 248, y: 60.0002), presence: 1, thumb: -1)]),
            LouVector(keys: ["s"], t: 1.2147, mouth: "etiree", previousMouth: "etiree", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 219.9025, y: 164.1463), elbow: CGPoint(x: 254, y: 236), direction: -74, indexTip: CGPoint(x: 225.8525, y: 89.7026), presence: 1, thumb: -1)]),
            LouVector(keys: ["s"], t: 2, mouth: "etiree", previousMouth: "etiree", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 198.05, y: 198.444), elbow: CGPoint(x: 254, y: 236), direction: -74, indexTip: CGPoint(x: 204, y: 124.0002), presence: 1, thumb: -1)]),
            LouVector(keys: ["s"], t: 2.25, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 198.05, y: 259.4179), elbow: CGPoint(x: 254, y: 296.9739), direction: -74, indexTip: CGPoint(x: 204, y: 184.9741), presence: 0.7248, thumb: -1)]),
            LouVector(keys: ["s"], t: 2.4, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 198.05, y: 397.0655), elbow: CGPoint(x: 254, y: 434.6215), direction: -74, indexTip: CGPoint(x: 204, y: 322.6217), presence: 0.1035, thumb: -1)]),
        ]
    }

    private static func v04() -> [LouVector] {   // z
        [
            LouVector(keys: ["z"], t: 0.2, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 209.025, y: 275.222), elbow: CGPoint(x: 243, y: 363), direction: -85, indexTip: CGPoint(x: 200.6611, y: 201.0106), presence: 0.5, thumb: -1)]),
            LouVector(keys: ["z"], t: 0.4, mouth: "etiree", previousMouth: "neutre", mouthMix: 0, vibrate: true, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 200.05, y: 130.444), elbow: CGPoint(x: 254, y: 236), direction: -74, indexTip: CGPoint(x: 206, y: 56.0002), presence: 1, thumb: -1)]),
            LouVector(keys: ["z"], t: 0.7797, mouth: "etiree", previousMouth: "etiree", mouthMix: 1, vibrate: true, vibration: 1, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 215.1064, y: 177.4724), elbow: CGPoint(x: 254, y: 236), direction: -74, indexTip: CGPoint(x: 221.0564, y: 103.0287), presence: 1, thumb: -1)]),
            LouVector(keys: ["z"], t: 1.1, mouth: "etiree", previousMouth: "etiree", mouthMix: 1, vibrate: true, vibration: 1, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 206.05, y: 216.444), elbow: CGPoint(x: 254, y: 236), direction: -74, indexTip: CGPoint(x: 212, y: 142.0002), presence: 1, thumb: -1)]),
            LouVector(keys: ["z"], t: 1.375, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 206.05, y: 253.0853), elbow: CGPoint(x: 254, y: 272.6413), direction: -74, indexTip: CGPoint(x: 212, y: 178.6415), presence: 0.82, thumb: -1)]),
            LouVector(keys: ["z"], t: 1.55, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 206.05, y: 398.9288), elbow: CGPoint(x: 254, y: 418.4848), direction: -74, indexTip: CGPoint(x: 212, y: 324.485), presence: 0.1035, thumb: -1)]),
        ]
    }

    private static func v05() -> [LouVector] {   // oi
        [
            LouVector(keys: ["oi"], t: 0.2, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 202, y: 359), elbow: CGPoint(x: 236, y: 391), direction: -100, indexTip: CGPoint(x: 177.5628, y: 314.1623), presence: 0.5, thumb: -1)]),
            LouVector(keys: ["oi"], t: 0.4, mouth: "ronde", previousMouth: "neutre", mouthMix: 0, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 202, y: 298), elbow: CGPoint(x: 236, y: 330), direction: -100, indexTip: CGPoint(x: 177.5628, y: 253.1623), presence: 1, thumb: -1)]),
            LouVector(keys: ["oi"], t: 0.8, mouth: "ronde", previousMouth: "ronde", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 202, y: 298), elbow: CGPoint(x: 236, y: 330), direction: -100, indexTip: CGPoint(x: 163.1651, y: 224.2268), presence: 1, thumb: -1)]),
            LouVector(keys: ["oi"], t: 0.813, mouth: "ronde", previousMouth: "ronde", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 202, y: 298), elbow: CGPoint(x: 236, y: 330), direction: -100, indexTip: CGPoint(x: 163.1651, y: 224.2268), presence: 1, thumb: -1)]),
            LouVector(keys: ["oi"], t: 1.225, mouth: "ronde", previousMouth: "ronde", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 202, y: 298), elbow: CGPoint(x: 236, y: 330), direction: -100, indexTip: CGPoint(x: 163.1651, y: 224.2268), presence: 1, thumb: -1)]),
            LouVector(keys: ["oi"], t: 1.55, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 202, y: 407.3711), elbow: CGPoint(x: 236, y: 439.3711), direction: -100, indexTip: CGPoint(x: 163.1651, y: 333.5979), presence: 0.1035, thumb: -1)]),
        ]
    }

    private static func v06() -> [LouVector] {   // oin
        [
            LouVector(keys: ["oin"], t: 0.2, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 240, y: 345), elbow: CGPoint(x: 262, y: 405), direction: -168, indexTip: CGPoint(x: 165.5926, y: 343.0875), presence: 0.5, thumb: -1)]),
            LouVector(keys: ["oin"], t: 0.4, mouth: "ronde", previousMouth: "neutre", mouthMix: 0, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 240, y: 270), elbow: CGPoint(x: 262, y: 330), direction: -168, indexTip: CGPoint(x: 165.5926, y: 268.0875), presence: 1, thumb: -1)]),
            LouVector(keys: ["oin"], t: 1.063, mouth: "ronde", previousMouth: "ronde", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 240, y: 270), elbow: CGPoint(x: 262, y: 330), direction: -168, indexTip: CGPoint(x: 168.0383, y: 261.3681), presence: 1, thumb: -1)]),
            LouVector(keys: ["oin"], t: 1.2, mouth: "ronde", previousMouth: "ronde", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 240, y: 270), elbow: CGPoint(x: 262, y: 330), direction: -168, indexTip: CGPoint(x: 165.5926, y: 268.0875), presence: 1, thumb: -1)]),
            LouVector(keys: ["oin"], t: 1.55, mouth: "neutre", previousMouth: "ronde", mouthMix: 0.4167, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 240, y: 272.4078), elbow: CGPoint(x: 262, y: 332.4078), direction: -168, indexTip: CGPoint(x: 165.5926, y: 270.4953), presence: 0.9839, thumb: -1)]),
            LouVector(keys: ["oin"], t: 1.8, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 240, y: 404.4727), elbow: CGPoint(x: 262, y: 464.4727), direction: -168, indexTip: CGPoint(x: 165.5926, y: 402.5602), presence: 0.1035, thumb: -1)]),
        ]
    }

    private static func v07() -> [LouVector] {   // f
        [
            LouVector(keys: ["f"], t: 0.2, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 184, y: 339), elbow: CGPoint(x: 232, y: 401), direction: -178, indexTip: CGPoint(x: 111.4239, y: 320.4553), presence: 0.5, thumb: 1)]),
            LouVector(keys: ["f"], t: 0.4, mouth: "dents_levre", previousMouth: "neutre", mouthMix: 0, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 184, y: 258), elbow: CGPoint(x: 232, y: 320), direction: -178, indexTip: CGPoint(x: 111.4239, y: 239.4553), presence: 1, thumb: 1)]),
            LouVector(keys: ["f"], t: 0.55, mouth: "dents_levre", previousMouth: "dents_levre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 184, y: 258), elbow: CGPoint(x: 232, y: 320), direction: -178, indexTip: CGPoint(x: 111.4239, y: 239.4553), presence: 1, thumb: 1)]),
            LouVector(keys: ["f"], t: 1.113, mouth: "dents_levre", previousMouth: "dents_levre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 243.3968, y: 258), elbow: CGPoint(x: 261.6982, y: 320), direction: -178, indexTip: CGPoint(x: 170.8207, y: 239.4553), presence: 1, thumb: 1)]),
            LouVector(keys: ["f"], t: 1.275, mouth: "dents_levre", previousMouth: "dents_levre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 280.3144, y: 258), elbow: CGPoint(x: 280.1572, y: 320), direction: -178, indexTip: CGPoint(x: 207.7384, y: 239.4553), presence: 1, thumb: 1)]),
            LouVector(keys: ["f"], t: 1.9, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 296, y: 403.2305), elbow: CGPoint(x: 288, y: 465.2305), direction: -178, indexTip: CGPoint(x: 223.4239, y: 384.6858), presence: 0.1035, thumb: 1)]),
        ]
    }

    private static func v08() -> [LouVector] {   // v
        [
            LouVector(keys: ["v"], t: 0.2, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 126, y: 359), elbow: CGPoint(x: 70, y: 391), direction: -122, indexTip: CGPoint(x: 103.3112, y: 295.5155), presence: 0.5, thumb: 1), LouVectorArm(wrist: CGPoint(x: 134, y: 359), elbow: CGPoint(x: 190, y: 391), direction: -58, indexTip: CGPoint(x: 156.6888, y: 295.5155), presence: 0.5, thumb: -1)]),
            LouVector(keys: ["v"], t: 0.4, mouth: "dents_levre", previousMouth: "neutre", mouthMix: 0, vibrate: true, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 126, y: 298), elbow: CGPoint(x: 70, y: 330), direction: -122, indexTip: CGPoint(x: 103.3112, y: 234.5155), presence: 1, thumb: 1), LouVectorArm(wrist: CGPoint(x: 134, y: 298), elbow: CGPoint(x: 190, y: 330), direction: -58, indexTip: CGPoint(x: 156.6888, y: 234.5155), presence: 1, thumb: -1)]),
            LouVector(keys: ["v"], t: 0.85, mouth: "dents_levre", previousMouth: "dents_levre", mouthMix: 1, vibrate: true, vibration: 1, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 126, y: 298), elbow: CGPoint(x: 70, y: 330), direction: -122, indexTip: CGPoint(x: 103.3112, y: 234.5155), presence: 1, thumb: 1), LouVectorArm(wrist: CGPoint(x: 134, y: 298), elbow: CGPoint(x: 190, y: 330), direction: -58, indexTip: CGPoint(x: 156.6888, y: 234.5155), presence: 1, thumb: -1)]),
            LouVector(keys: ["v"], t: 1.275, mouth: "dents_levre", previousMouth: "dents_levre", mouthMix: 1, vibrate: true, vibration: 1, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 126, y: 298), elbow: CGPoint(x: 70, y: 330), direction: -122, indexTip: CGPoint(x: 103.3112, y: 234.5155), presence: 1, thumb: 1), LouVectorArm(wrist: CGPoint(x: 134, y: 298), elbow: CGPoint(x: 190, y: 330), direction: -58, indexTip: CGPoint(x: 156.6888, y: 234.5155), presence: 1, thumb: -1)]),
            LouVector(keys: ["v"], t: 1.313, mouth: "neutre", previousMouth: "dents_levre", mouthMix: 0.1083, vibrate: false, vibration: 0.8917, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 126, y: 298.0399), elbow: CGPoint(x: 70, y: 330.0399), direction: -122, indexTip: CGPoint(x: 103.3112, y: 234.5554), presence: 0.9997, thumb: 1), LouVectorArm(wrist: CGPoint(x: 134, y: 298.0399), elbow: CGPoint(x: 190, y: 330.0399), direction: -58, indexTip: CGPoint(x: 156.6888, y: 234.5554), presence: 0.9997, thumb: -1)]),
            LouVector(keys: ["v"], t: 1.6, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 126, y: 407.3711), elbow: CGPoint(x: 70, y: 439.3711), direction: -122, indexTip: CGPoint(x: 103.3112, y: 343.8866), presence: 0.1035, thumb: 1), LouVectorArm(wrist: CGPoint(x: 134, y: 407.3711), elbow: CGPoint(x: 190, y: 439.3711), direction: -58, indexTip: CGPoint(x: 156.6888, y: 343.8866), presence: 0.1035, thumb: -1)]),
        ]
    }

    private static func v09() -> [LouVector] {   // p
        [
            LouVector(keys: ["p"], t: 0.2, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 214, y: 313), elbow: CGPoint(x: 228, y: 397), direction: -92, indexTip: CGPoint(x: 197.6734, y: 269.5433), presence: 0.5, thumb: -1)]),
            LouVector(keys: ["p"], t: 0.4, mouth: "fermee", previousMouth: "neutre", mouthMix: 0, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 214, y: 206), elbow: CGPoint(x: 228, y: 290), direction: -92, indexTip: CGPoint(x: 197.6734, y: 162.5433), presence: 1, thumb: -1)]),
            LouVector(keys: ["p"], t: 0.88, mouth: "mi_ouverte", previousMouth: "fermee", mouthMix: 0.6667, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 214, y: 206), elbow: CGPoint(x: 228, y: 290), direction: -92, indexTip: CGPoint(x: 188.373, y: 134.6727), presence: 1, thumb: -1)]),
            LouVector(keys: ["p"], t: 0.893, mouth: "mi_ouverte", previousMouth: "fermee", mouthMix: 0.775, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 214, y: 206), elbow: CGPoint(x: 228, y: 290), direction: -92, indexTip: CGPoint(x: 188.373, y: 134.6727), presence: 1, thumb: -1)]),
            LouVector(keys: ["p"], t: 1.28, mouth: "neutre", previousMouth: "mi_ouverte", mouthMix: 0, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 214, y: 206), elbow: CGPoint(x: 228, y: 290), direction: -92, indexTip: CGPoint(x: 188.373, y: 134.6727), presence: 1, thumb: -1)]),
            LouVector(keys: ["p"], t: 1.58, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 214, y: 397.8477), elbow: CGPoint(x: 228, y: 481.8477), direction: -92, indexTip: CGPoint(x: 188.373, y: 326.5204), presence: 0.1035, thumb: -1)]),
        ]
    }

    private static func v10() -> [LouVector] {   // b
        [
            LouVector(keys: ["b"], t: 0.2, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 267, y: 352), elbow: CGPoint(x: 284.5, y: 386), direction: -152, indexTip: CGPoint(x: 234.8212, y: 298.4532), presence: 0.5, thumb: 1)]),
            LouVector(keys: ["b"], t: 0.4, mouth: "fermee", previousMouth: "neutre", mouthMix: 0, vibrate: true, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 312, y: 284), elbow: CGPoint(x: 307, y: 322), direction: -152, indexTip: CGPoint(x: 279.8212, y: 230.4532), presence: 1, thumb: 1)]),
            LouVector(keys: ["b"], t: 0.713, mouth: "fermee", previousMouth: "fermee", mouthMix: 1, vibrate: true, vibration: 1, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 246.1756, y: 292.2741), elbow: CGPoint(x: 274.0876, y: 326.1369), direction: -152, indexTip: CGPoint(x: 213.9968, y: 238.7273), presence: 1, thumb: 1)]),
            LouVector(keys: ["b"], t: 1.12, mouth: "mi_ouverte", previousMouth: "fermee", mouthMix: 0.8333, vibrate: true, vibration: 1, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 222, y: 300), elbow: CGPoint(x: 262, y: 330), direction: -152, indexTip: CGPoint(x: 174.4131, y: 251.1289), presence: 1, thumb: 1)]),
            LouVector(keys: ["b"], t: 1.52, mouth: "neutre", previousMouth: "mi_ouverte", mouthMix: 0, vibrate: false, vibration: 1, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 222, y: 300), elbow: CGPoint(x: 262, y: 330), direction: -152, indexTip: CGPoint(x: 174.4131, y: 251.1289), presence: 1, thumb: 1)]),
            LouVector(keys: ["b"], t: 1.82, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 222, y: 407.5781), elbow: CGPoint(x: 262, y: 437.5781), direction: -152, indexTip: CGPoint(x: 174.4131, y: 358.707), presence: 0.1035, thumb: 1)]),
        ]
    }

    private static func v11() -> [LouVector] {   // d
        [
            LouVector(keys: ["d"], t: 0.2, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 228, y: 344), elbow: CGPoint(x: 244, y: 406), direction: -96, indexTip: CGPoint(x: 194.2162, y: 290.438), presence: 0.5, thumb: -1), LouVectorArm(wrist: CGPoint(x: 86, y: 360), elbow: CGPoint(x: 18, y: 334), direction: 10, indexTip: CGPoint(x: 126.7615, y: 382.2157), presence: 0.5, thumb: 1)]),
            LouVector(keys: ["d"], t: 0.4, mouth: "langue_haut", previousMouth: "neutre", mouthMix: 0, vibrate: true, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 228, y: 268), elbow: CGPoint(x: 244, y: 330), direction: -96, indexTip: CGPoint(x: 194.2162, y: 214.438), presence: 1, thumb: -1), LouVectorArm(wrist: CGPoint(x: 86, y: 300), elbow: CGPoint(x: 18, y: 274), direction: 10, indexTip: CGPoint(x: 126.7615, y: 322.2157), presence: 1, thumb: 1)]),
            LouVector(keys: ["d"], t: 0.87, mouth: "langue_haut", previousMouth: "langue_haut", mouthMix: 1, vibrate: true, vibration: 1, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 228, y: 268), elbow: CGPoint(x: 244, y: 330), direction: -96, indexTip: CGPoint(x: 198.6984, y: 203.5096), presence: 1, thumb: -1), LouVectorArm(wrist: CGPoint(x: 86, y: 300), elbow: CGPoint(x: 18, y: 274), direction: 10, indexTip: CGPoint(x: 126.7615, y: 322.2157), presence: 1, thumb: 1)]),
            LouVector(keys: ["d"], t: 0.883, mouth: "langue_haut", previousMouth: "langue_haut", mouthMix: 1, vibrate: true, vibration: 1, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 228, y: 268), elbow: CGPoint(x: 244, y: 330), direction: -96, indexTip: CGPoint(x: 198.6984, y: 203.5096), presence: 1, thumb: -1), LouVectorArm(wrist: CGPoint(x: 86, y: 300), elbow: CGPoint(x: 18, y: 274), direction: 10, indexTip: CGPoint(x: 126.7615, y: 322.2157), presence: 1, thumb: 1)]),
            LouVector(keys: ["d"], t: 1.27, mouth: "neutre", previousMouth: "langue_haut", mouthMix: 0, vibrate: false, vibration: 1, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 228, y: 268), elbow: CGPoint(x: 244, y: 330), direction: -96, indexTip: CGPoint(x: 198.6984, y: 203.5096), presence: 1, thumb: -1), LouVectorArm(wrist: CGPoint(x: 86, y: 300), elbow: CGPoint(x: 18, y: 274), direction: 10, indexTip: CGPoint(x: 126.7615, y: 322.2157), presence: 1, thumb: 1)]),
            LouVector(keys: ["d"], t: 1.57, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 228, y: 404.2656), elbow: CGPoint(x: 244, y: 466.2656), direction: -96, indexTip: CGPoint(x: 198.6984, y: 339.7752), presence: 0.1035, thumb: -1), LouVectorArm(wrist: CGPoint(x: 86, y: 407.5781), elbow: CGPoint(x: 18, y: 381.5781), direction: 10, indexTip: CGPoint(x: 126.7615, y: 429.7938), presence: 0.1035, thumb: 1)]),
        ]
    }

    private static func v12() -> [LouVector] {   // m
        [
            LouVector(keys: ["m"], t: 0.2, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0.5, arms: [LouVectorArm(wrist: CGPoint(x: 190.8, y: 280.8), elbow: CGPoint(x: 250, y: 327.2), direction: 90, indexTip: CGPoint(x: 178.8, y: 346.4), presence: 0.5, thumb: 1)]),
            LouVector(keys: ["m"], t: 0.4, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 1, arms: [LouVectorArm(wrist: CGPoint(x: 190.8, y: 141.6), elbow: CGPoint(x: 250, y: 202), direction: 90, indexTip: CGPoint(x: 178.8, y: 207.2), presence: 1, thumb: 1)]),
            LouVector(keys: ["m"], t: 1, mouth: "fermee", previousMouth: "fermee", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 1, arms: [LouVectorArm(wrist: CGPoint(x: 190.8, y: 197.6), elbow: CGPoint(x: 250, y: 230), direction: 90, indexTip: CGPoint(x: 178.8, y: 263.2), presence: 1, thumb: 1)]),
            LouVector(keys: ["m"], t: 1.363, mouth: "neutre", previousMouth: "fermee", mouthMix: 0.1083, vibrate: false, vibration: 0, lift: 0, table: 1, arms: [LouVectorArm(wrist: CGPoint(x: 190.8, y: 197.5273), elbow: CGPoint(x: 250, y: 229.9636), direction: 90, indexTip: CGPoint(x: 178.8, y: 263.1273), presence: 1, thumb: 1)]),
            LouVector(keys: ["m"], t: 1.5, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 1, arms: [LouVectorArm(wrist: CGPoint(x: 190.8, y: 159.3766), elbow: CGPoint(x: 250, y: 210.8883), direction: 90, indexTip: CGPoint(x: 178.8, y: 224.9766), presence: 1, thumb: 1)]),
            LouVector(keys: ["m"], t: 1.9, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0.1035, arms: [LouVectorArm(wrist: CGPoint(x: 190.8, y: 391.1812), elbow: CGPoint(x: 250, y: 451.5812), direction: 90, indexTip: CGPoint(x: 178.8, y: 456.7812), presence: 0.1035, thumb: 1)]),
        ]
    }

    private static func v13() -> [LouVector] {   // gn
        [
            LouVector(keys: ["gn"], t: 0.2, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 203.252, y: 292.185), elbow: CGPoint(x: 250, y: 377.815), direction: -174, indexTip: CGPoint(x: 132, y: 269.8146), presence: 0.5, thumb: 1)]),
            LouVector(keys: ["gn"], t: 0.4, mouth: "fond", previousMouth: "neutre", mouthMix: 0, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 203.252, y: 164.37), elbow: CGPoint(x: 250, y: 250), direction: -174, indexTip: CGPoint(x: 132, y: 141.9996), presence: 1, thumb: 1)]),
            LouVector(keys: ["gn"], t: 1.213, mouth: "fond", previousMouth: "fond", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 187.2764, y: 164.37), elbow: CGPoint(x: 242.0122, y: 250), direction: -174, indexTip: CGPoint(x: 116.0244, y: 141.9996), presence: 1, thumb: 1)]),
            LouVector(keys: ["gn"], t: 1.225, mouth: "fond", previousMouth: "fond", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 187.4148, y: 164.37), elbow: CGPoint(x: 242.0814, y: 250), direction: -174, indexTip: CGPoint(x: 116.1628, y: 141.9996), presence: 1, thumb: 1)]),
            LouVector(keys: ["gn"], t: 1.95, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 203.252, y: 393.5383), elbow: CGPoint(x: 250, y: 479.1683), direction: -174, indexTip: CGPoint(x: 132, y: 371.1679), presence: 0.1035, thumb: 1)]),
        ]
    }

    private static func v14() -> [LouVector] {   // ill
        [
            LouVector(keys: ["ill"], t: 0.2, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 225.2, y: 297.4), elbow: CGPoint(x: 250, y: 372.6), direction: 180, indexTip: CGPoint(x: 152, y: 282.6), presence: 0.5, thumb: 1)]),
            LouVector(keys: ["ill"], t: 0.4, mouth: "etiree", previousMouth: "neutre", mouthMix: 0, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 225.2, y: 174.8), elbow: CGPoint(x: 250, y: 250), direction: 180, indexTip: CGPoint(x: 152, y: 160), presence: 1, thumb: 1)]),
            LouVector(keys: ["ill"], t: 0.863, mouth: "etiree", previousMouth: "etiree", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 248.9728, y: 174.8), elbow: CGPoint(x: 261.8866, y: 250), direction: 180, indexTip: CGPoint(x: 175.7728, y: 160), presence: 1, thumb: 1)]),
            LouVector(keys: ["ill"], t: 1.15, mouth: "etiree", previousMouth: "etiree", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 269.2, y: 174.8), elbow: CGPoint(x: 272, y: 250), direction: 180, indexTip: CGPoint(x: 196, y: 160), presence: 1, thumb: 1)]),
            LouVector(keys: ["ill"], t: 1.425, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 269.2, y: 218.9375), elbow: CGPoint(x: 272, y: 294.1375), direction: 180, indexTip: CGPoint(x: 196, y: 204.1375), presence: 0.82, thumb: 1)]),
            LouVector(keys: ["ill"], t: 1.6, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 269.2, y: 394.618), elbow: CGPoint(x: 272, y: 469.818), direction: 180, indexTip: CGPoint(x: 196, y: 379.818), presence: 0.1035, thumb: 1)]),
        ]
    }

    private static func v15() -> [LouVector] {   // ui
        [
            LouVector(keys: ["ui"], t: 0.2, mouth: "mi_ouverte", previousMouth: "neutre", mouthMix: 0, vibrate: false, vibration: 0, lift: 0, table: 0, arms: []),
            LouVector(keys: ["ui"], t: 0.4, mouth: "mi_ouverte", previousMouth: "mi_ouverte", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: []),
            LouVector(keys: ["ui"], t: 0.5, mouth: "mi_ouverte", previousMouth: "mi_ouverte", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: []),
            LouVector(keys: ["ui"], t: 0.75, mouth: "mi_ouverte", previousMouth: "mi_ouverte", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: []),
            LouVector(keys: ["ui"], t: 0.813, mouth: "neutre", previousMouth: "mi_ouverte", mouthMix: 0.1083, vibrate: false, vibration: 0, lift: 0, table: 0, arms: []),
            LouVector(keys: ["ui"], t: 0.9, mouth: "neutre", previousMouth: "mi_ouverte", mouthMix: 0.8333, vibrate: false, vibration: 0, lift: 0, table: 0, arms: []),
        ]
    }

    private static func v16() -> [LouVector] {   // j + u
        [
            LouVector(keys: ["j", "u"], t: 0.2, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 246.993, y: 305.7085), elbow: CGPoint(x: 257.5, y: 373.7915), direction: -150, indexTip: CGPoint(x: 190.9999, y: 256.2913), presence: 0.5, thumb: 1)]),
            LouVector(keys: ["j", "u"], t: 0.4, mouth: "avancee", previousMouth: "neutre", mouthMix: 0, vibrate: true, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 261.993, y: 191.417), elbow: CGPoint(x: 265, y: 263), direction: -150, indexTip: CGPoint(x: 205.9999, y: 141.9998), presence: 1, thumb: 1)]),
            LouVector(keys: ["j", "u"], t: 0.75, mouth: "avancee", previousMouth: "avancee", mouthMix: 1, vibrate: true, vibration: 1, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 231.993, y: 205.417), elbow: CGPoint(x: 250, y: 270), direction: -150, indexTip: CGPoint(x: 175.9999, y: 155.9998), presence: 1, thumb: 1)]),
            LouVector(keys: ["j", "u"], t: 1.113, mouth: "petite_ronde", previousMouth: "avancee", mouthMix: 0.1083, vibrate: false, vibration: 0.8917, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 231.9778, y: 205.4281), elbow: CGPoint(x: 249.9817, y: 270.0229), direction: -149.9558, indexTip: CGPoint(x: 176.0164, y: 155.9812), presence: 1, thumb: 0.9985)]),
            LouVector(keys: ["j", "u"], t: 1.14, mouth: "petite_ronde", previousMouth: "avancee", mouthMix: 0.3333, vibrate: false, vibration: 0.6667, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 231.6088, y: 205.6972), elbow: CGPoint(x: 249.5388, y: 270.5765), direction: -148.8855, indexTip: CGPoint(x: 176.4144, y: 155.5431), presence: 1, thumb: 0.9616)]),
            LouVector(keys: ["j", "u"], t: 1.25, mouth: "petite_ronde", previousMouth: "petite_ronde", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 221.9965, y: 212.7085), elbow: CGPoint(x: 238, y: 285), direction: -121, indexTip: CGPoint(x: 184.6828, y: 150.6081), presence: 1, thumb: 0)]),
            LouVector(keys: ["j", "u"], t: 1.45, mouth: "petite_ronde", previousMouth: "petite_ronde", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 212, y: 220), elbow: CGPoint(x: 226, y: 300), direction: -92, indexTip: CGPoint(x: 184.6554, y: 149.2143), presence: 1, thumb: -1)]),
            LouVector(keys: ["j", "u"], t: 1.725, mouth: "petite_ronde", previousMouth: "petite_ronde", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 212, y: 220), elbow: CGPoint(x: 226, y: 300), direction: -92, indexTip: CGPoint(x: 184.6554, y: 149.2143), presence: 1, thumb: -1)]),
            LouVector(keys: ["j", "u"], t: 2.6, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 212, y: 399.2969), elbow: CGPoint(x: 226, y: 479.2969), direction: -92, indexTip: CGPoint(x: 184.6554, y: 328.5112), presence: 0.1035, thumb: -1)]),
        ]
    }

    private static func v17() -> [LouVector] {   // v + oi
        [
            LouVector(keys: ["v", "oi"], t: 0.2, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 126, y: 359), elbow: CGPoint(x: 70, y: 391), direction: -122, indexTip: CGPoint(x: 103.3112, y: 295.5155), presence: 0.5, thumb: 1), LouVectorArm(wrist: CGPoint(x: 134, y: 359), elbow: CGPoint(x: 190, y: 391), direction: -58, indexTip: CGPoint(x: 156.6888, y: 295.5155), presence: 0.5, thumb: -1)]),
            LouVector(keys: ["v", "oi"], t: 0.4, mouth: "dents_levre", previousMouth: "neutre", mouthMix: 0, vibrate: true, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 126, y: 298), elbow: CGPoint(x: 70, y: 330), direction: -122, indexTip: CGPoint(x: 103.3112, y: 234.5155), presence: 1, thumb: 1), LouVectorArm(wrist: CGPoint(x: 134, y: 298), elbow: CGPoint(x: 190, y: 330), direction: -58, indexTip: CGPoint(x: 156.6888, y: 234.5155), presence: 1, thumb: -1)]),
            LouVector(keys: ["v", "oi"], t: 0.85, mouth: "dents_levre", previousMouth: "dents_levre", mouthMix: 1, vibrate: true, vibration: 1, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 126, y: 298), elbow: CGPoint(x: 70, y: 330), direction: -122, indexTip: CGPoint(x: 103.3112, y: 234.5155), presence: 1, thumb: 1), LouVectorArm(wrist: CGPoint(x: 134, y: 298), elbow: CGPoint(x: 190, y: 330), direction: -58, indexTip: CGPoint(x: 156.6888, y: 234.5155), presence: 1, thumb: -1)]),
            LouVector(keys: ["v", "oi"], t: 1.34, mouth: "ronde", previousMouth: "dents_levre", mouthMix: 0.3333, vibrate: false, vibration: 0.6667, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 126, y: 300.3443), elbow: CGPoint(x: 70, y: 332.3443), direction: -122, indexTip: CGPoint(x: 103.3112, y: 236.8598), presence: 0.9808, thumb: 1), LouVectorArm(wrist: CGPoint(x: 135.3067, y: 298), elbow: CGPoint(x: 190.8839, y: 330), direction: -58.8071, indexTip: CGPoint(x: 156.9474, y: 234.3741), presence: 1, thumb: -1)]),
            LouVector(keys: ["v", "oi"], t: 1.45, mouth: "ronde", previousMouth: "ronde", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 126, y: 359), elbow: CGPoint(x: 70, y: 391), direction: -122, indexTip: CGPoint(x: 103.3112, y: 295.5155), presence: 0.5, thumb: 1), LouVectorArm(wrist: CGPoint(x: 168, y: 298), elbow: CGPoint(x: 213, y: 330), direction: -79, indexTip: CGPoint(x: 164.0621, y: 237.5484), presence: 1, thumb: -1)]),
            LouVector(keys: ["v", "oi"], t: 1.65, mouth: "ronde", previousMouth: "ronde", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 126, y: 420), elbow: CGPoint(x: 70, y: 452), direction: -122, indexTip: CGPoint(x: 103.3112, y: 356.5155), presence: 0, thumb: 1), LouVectorArm(wrist: CGPoint(x: 202, y: 298), elbow: CGPoint(x: 236, y: 330), direction: -100, indexTip: CGPoint(x: 177.5628, y: 253.1623), presence: 1, thumb: -1)]),
            LouVector(keys: ["v", "oi"], t: 1.85, mouth: "ronde", previousMouth: "ronde", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 126, y: 420), elbow: CGPoint(x: 70, y: 452), direction: -122, indexTip: CGPoint(x: 103.3112, y: 356.5155), presence: 0, thumb: 1), LouVectorArm(wrist: CGPoint(x: 202, y: 298), elbow: CGPoint(x: 236, y: 330), direction: -100, indexTip: CGPoint(x: 177.5628, y: 253.1623), presence: 1, thumb: -1)]),
            LouVector(keys: ["v", "oi"], t: 1.913, mouth: "ronde", previousMouth: "ronde", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 126, y: 420), elbow: CGPoint(x: 70, y: 452), direction: -122, indexTip: CGPoint(x: 103.3112, y: 356.5155), presence: 0, thumb: 1), LouVectorArm(wrist: CGPoint(x: 202, y: 298), elbow: CGPoint(x: 236, y: 330), direction: -100, indexTip: CGPoint(x: 177.3049, y: 252.6441), presence: 1, thumb: -1)]),
            LouVector(keys: ["v", "oi"], t: 2.75, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 126, y: 420), elbow: CGPoint(x: 70, y: 452), direction: -122, indexTip: CGPoint(x: 103.3112, y: 356.5155), presence: 0, thumb: 1), LouVectorArm(wrist: CGPoint(x: 202, y: 407.3711), elbow: CGPoint(x: 236, y: 439.3711), direction: -100, indexTip: CGPoint(x: 163.1651, y: 333.5979), presence: 0.1035, thumb: -1)]),
        ]
    }

    private static func v18() -> [LouVector] {   // ch + ui + ou
        [
            LouVector(keys: ["ch", "ui", "ou"], t: 0.2, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 130, y: 326), elbow: CGPoint(x: 200, y: 414), direction: -90, indexTip: CGPoint(x: 158.8, y: 256.4), presence: 0.5, thumb: -1)]),
            LouVector(keys: ["ch", "ui", "ou"], t: 0.4, mouth: "avancee", previousMouth: "neutre", mouthMix: 0, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 130, y: 232), elbow: CGPoint(x: 200, y: 320), direction: -90, indexTip: CGPoint(x: 158.8, y: 162.4), presence: 1, thumb: -1)]),
            LouVector(keys: ["ch", "ui", "ou"], t: 0.95, mouth: "avancee", previousMouth: "avancee", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 130, y: 232), elbow: CGPoint(x: 200, y: 320), direction: -90, indexTip: CGPoint(x: 158.8, y: 162.4), presence: 1, thumb: -1)]),
            LouVector(keys: ["ch", "ui", "ou"], t: 1.54, mouth: "mi_ouverte", previousMouth: "avancee", mouthMix: 0.3333, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 130, y: 235.6126), elbow: CGPoint(x: 200, y: 323.6126), direction: -90, indexTip: CGPoint(x: 158.8, y: 166.0126), presence: 0.9808, thumb: -1)]),
            LouVector(keys: ["ch", "ui", "ou"], t: 1.65, mouth: "mi_ouverte", previousMouth: "mi_ouverte", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 130, y: 326), elbow: CGPoint(x: 200, y: 414), direction: -90, indexTip: CGPoint(x: 158.8, y: 256.4), presence: 0.5, thumb: -1)]),
            LouVector(keys: ["ch", "ui", "ou"], t: 1.85, mouth: "mi_ouverte", previousMouth: "mi_ouverte", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 130.3663, y: 420), elbow: CGPoint(x: 200.1832, y: 507.7151), direction: -90.0509, indexTip: CGPoint(x: 158.7741, y: 350.463), presence: 0, thumb: -1)]),
            LouVector(keys: ["ch", "ui", "ou"], t: 2.44, mouth: "petite_ronde", previousMouth: "mi_ouverte", mouthMix: 0.3333, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 202, y: 417.6557), elbow: CGPoint(x: 236, y: 449.6557), direction: -100, indexTip: CGPoint(x: 151.0873, y: 376.0283), presence: 0.0192, thumb: -1)]),
            LouVector(keys: ["ch", "ui", "ou"], t: 2.55, mouth: "petite_ronde", previousMouth: "petite_ronde", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 202, y: 359), elbow: CGPoint(x: 236, y: 391), direction: -100, indexTip: CGPoint(x: 151.0873, y: 317.3726), presence: 0.5, thumb: -1)]),
            LouVector(keys: ["ch", "ui", "ou"], t: 2.725, mouth: "petite_ronde", previousMouth: "petite_ronde", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 202.0045, y: 297.9917), elbow: CGPoint(x: 236.0023, y: 329.9955), direction: -100, indexTip: CGPoint(x: 151.0918, y: 256.3643), presence: 1, thumb: -1)]),
            LouVector(keys: ["ch", "ui", "ou"], t: 2.75, mouth: "petite_ronde", previousMouth: "petite_ronde", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 202.0265, y: 297.9515), elbow: CGPoint(x: 236.0135, y: 329.9755), direction: -100, indexTip: CGPoint(x: 151.1138, y: 256.3241), presence: 1, thumb: -1)]),
            LouVector(keys: ["ch", "ui", "ou"], t: 3.3463, mouth: "petite_ronde", previousMouth: "petite_ronde", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 220.0816, y: 263.646), elbow: CGPoint(x: 245.0408, y: 312.8231), direction: -100, indexTip: CGPoint(x: 187.4833, y: 187.7254), presence: 1, thumb: -1)]),
            LouVector(keys: ["ch", "ui", "ou"], t: 4.4, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 222, y: 399.7109), elbow: CGPoint(x: 246, y: 468.7109), direction: -100, indexTip: CGPoint(x: 181.377, y: 326.7906), presence: 0.1035, thumb: -1)]),
        ]
    }

    private static func v19() -> [LouVector] {   // a + é + d + s
        [
            LouVector(keys: ["a", "é", "d", "s"], t: 0.2, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 224, y: 301), elbow: CGPoint(x: 250, y: 359), direction: -86, indexTip: CGPoint(x: 205.9691, y: 227.3847), presence: 0.5, thumb: -1), LouVectorArm(wrist: CGPoint(x: 80, y: 420), elbow: CGPoint(x: 22, y: 478), direction: -54, indexTip: CGPoint(x: 130.3624, y: 375.1816), presence: 0, thumb: 1), LouVectorArm(wrist: CGPoint(x: 86, y: 420), elbow: CGPoint(x: 18, y: 394), direction: 10, indexTip: CGPoint(x: 126.7615, y: 442.2157), presence: 0, thumb: 1)]),
            LouVector(keys: ["a", "é", "d", "s"], t: 0.4, mouth: "grande", previousMouth: "neutre", mouthMix: 0, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 224, y: 182), elbow: CGPoint(x: 250, y: 240), direction: -86, indexTip: CGPoint(x: 205.9691, y: 108.3847), presence: 1, thumb: -1), LouVectorArm(wrist: CGPoint(x: 80, y: 420), elbow: CGPoint(x: 22, y: 478), direction: -54, indexTip: CGPoint(x: 130.3624, y: 375.1816), presence: 0, thumb: 1), LouVectorArm(wrist: CGPoint(x: 86, y: 420), elbow: CGPoint(x: 18, y: 394), direction: 10, indexTip: CGPoint(x: 126.7615, y: 442.2157), presence: 0, thumb: 1)]),
            LouVector(keys: ["a", "é", "d", "s"], t: 0.85, mouth: "grande", previousMouth: "grande", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 224, y: 182), elbow: CGPoint(x: 250, y: 240), direction: -86, indexTip: CGPoint(x: 205.9691, y: 108.3847), presence: 1, thumb: -1), LouVectorArm(wrist: CGPoint(x: 80, y: 420), elbow: CGPoint(x: 22, y: 478), direction: -54, indexTip: CGPoint(x: 130.3624, y: 375.1816), presence: 0, thumb: 1), LouVectorArm(wrist: CGPoint(x: 86, y: 420), elbow: CGPoint(x: 18, y: 394), direction: 10, indexTip: CGPoint(x: 126.7615, y: 442.2157), presence: 0, thumb: 1)]),
            LouVector(keys: ["a", "é", "d", "s"], t: 1.41, mouth: "etiree", previousMouth: "grande", mouthMix: 0.9167, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 224, y: 206.6367), elbow: CGPoint(x: 250, y: 264.6367), direction: -86, indexTip: CGPoint(x: 205.9691, y: 133.0215), presence: 0.8965, thumb: -1), LouVectorArm(wrist: CGPoint(x: 80, y: 388.1172), elbow: CGPoint(x: 22, y: 446.1172), direction: -54, indexTip: CGPoint(x: 130.3624, y: 343.2988), presence: 0.1035, thumb: 1), LouVectorArm(wrist: CGPoint(x: 86, y: 420), elbow: CGPoint(x: 18, y: 394), direction: 10, indexTip: CGPoint(x: 126.7615, y: 442.2157), presence: 0, thumb: 1)]),
            LouVector(keys: ["a", "é", "d", "s"], t: 1.52, mouth: "etiree", previousMouth: "etiree", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 224, y: 301), elbow: CGPoint(x: 250, y: 359), direction: -86, indexTip: CGPoint(x: 205.9691, y: 227.3847), presence: 0.5, thumb: -1), LouVectorArm(wrist: CGPoint(x: 80, y: 266), elbow: CGPoint(x: 22, y: 324), direction: -54, indexTip: CGPoint(x: 130.3624, y: 221.1816), presence: 0.5, thumb: 1), LouVectorArm(wrist: CGPoint(x: 86, y: 420), elbow: CGPoint(x: 18, y: 394), direction: 10, indexTip: CGPoint(x: 126.7615, y: 442.2157), presence: 0, thumb: 1)]),
            LouVector(keys: ["a", "é", "d", "s"], t: 1.72, mouth: "etiree", previousMouth: "etiree", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 224, y: 419.7914), elbow: CGPoint(x: 250, y: 477.7914), direction: -86, indexTip: CGPoint(x: 205.9691, y: 346.1762), presence: 0.0009, thumb: -1), LouVectorArm(wrist: CGPoint(x: 80, y: 112.2699), elbow: CGPoint(x: 22, y: 170.2699), direction: -54, indexTip: CGPoint(x: 130.3624, y: 67.4515), presence: 0.9991, thumb: 1), LouVectorArm(wrist: CGPoint(x: 86, y: 420), elbow: CGPoint(x: 18, y: 394), direction: 10, indexTip: CGPoint(x: 126.7615, y: 442.2157), presence: 0, thumb: 1)]),
            LouVector(keys: ["a", "é", "d", "s"], t: 2.75, mouth: "langue_haut", previousMouth: "etiree", mouthMix: 0.9167, vibrate: true, vibration: 0.9167, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 228, y: 404.2656), elbow: CGPoint(x: 244, y: 466.2656), direction: -96, indexTip: CGPoint(x: 194.2162, y: 350.7036), presence: 0.1035, thumb: -1), LouVectorArm(wrist: CGPoint(x: 80, y: 143.8828), elbow: CGPoint(x: 22, y: 201.8828), direction: -54, indexTip: CGPoint(x: 130.3624, y: 99.0644), presence: 0.8965, thumb: 1), LouVectorArm(wrist: CGPoint(x: 86, y: 407.5781), elbow: CGPoint(x: 18, y: 381.5781), direction: 10, indexTip: CGPoint(x: 126.7615, y: 429.7938), presence: 0.1035, thumb: 1)]),
            LouVector(keys: ["a", "é", "d", "s"], t: 2.86, mouth: "langue_haut", previousMouth: "langue_haut", mouthMix: 1, vibrate: true, vibration: 1, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 228, y: 344), elbow: CGPoint(x: 244, y: 406), direction: -96, indexTip: CGPoint(x: 194.2162, y: 290.438), presence: 0.5, thumb: -1), LouVectorArm(wrist: CGPoint(x: 80, y: 266), elbow: CGPoint(x: 22, y: 324), direction: -54, indexTip: CGPoint(x: 130.3624, y: 221.1816), presence: 0.5, thumb: 1), LouVectorArm(wrist: CGPoint(x: 86, y: 360), elbow: CGPoint(x: 18, y: 334), direction: 10, indexTip: CGPoint(x: 126.7615, y: 382.2157), presence: 0.5, thumb: 1)]),
            LouVector(keys: ["a", "é", "d", "s"], t: 3.06, mouth: "langue_haut", previousMouth: "langue_haut", mouthMix: 1, vibrate: true, vibration: 1, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 228, y: 268.1332), elbow: CGPoint(x: 244, y: 330.1332), direction: -96, indexTip: CGPoint(x: 194.2162, y: 214.5711), presence: 0.9991, thumb: -1), LouVectorArm(wrist: CGPoint(x: 80, y: 419.7301), elbow: CGPoint(x: 22, y: 477.7301), direction: -54, indexTip: CGPoint(x: 130.3624, y: 374.9117), presence: 0.0009, thumb: 1), LouVectorArm(wrist: CGPoint(x: 86, y: 300.1052), elbow: CGPoint(x: 18, y: 274.1052), direction: 10, indexTip: CGPoint(x: 126.7615, y: 322.3208), presence: 0.9991, thumb: 1)]),
            LouVector(keys: ["a", "é", "d", "s"], t: 3.6, mouth: "langue_haut", previousMouth: "langue_haut", mouthMix: 1, vibrate: true, vibration: 1, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 228, y: 268), elbow: CGPoint(x: 244, y: 330), direction: -96, indexTip: CGPoint(x: 198.6984, y: 203.5096), presence: 1, thumb: -1), LouVectorArm(wrist: CGPoint(x: 80, y: 420), elbow: CGPoint(x: 22, y: 478), direction: -54, indexTip: CGPoint(x: 130.3624, y: 375.1816), presence: 0, thumb: 1), LouVectorArm(wrist: CGPoint(x: 86, y: 300), elbow: CGPoint(x: 18, y: 274), direction: 10, indexTip: CGPoint(x: 126.7615, y: 322.2157), presence: 1, thumb: 1)]),
            LouVector(keys: ["a", "é", "d", "s"], t: 3.99, mouth: "etiree", previousMouth: "langue_haut", mouthMix: 0.3333, vibrate: false, vibration: 0.6667, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 228.27, y: 265.4336), elbow: CGPoint(x: 244.1922, y: 328.1937), direction: -95.5773, indexTip: CGPoint(x: 199.5791, y: 200.5998), presence: 1, thumb: -1), LouVectorArm(wrist: CGPoint(x: 80, y: 420), elbow: CGPoint(x: 22, y: 478), direction: -54, indexTip: CGPoint(x: 130.3624, y: 375.1816), presence: 0, thumb: 1), LouVectorArm(wrist: CGPoint(x: 86, y: 302.3059), elbow: CGPoint(x: 18, y: 276.3059), direction: 10, indexTip: CGPoint(x: 126.7615, y: 324.5216), presence: 0.9808, thumb: 1)]),
            LouVector(keys: ["a", "é", "d", "s"], t: 4.1, mouth: "etiree", previousMouth: "etiree", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 235.025, y: 201.222), elbow: CGPoint(x: 249, y: 283), direction: -85, indexTip: CGPoint(x: 222.6141, y: 129.668), presence: 1, thumb: -1), LouVectorArm(wrist: CGPoint(x: 80, y: 420), elbow: CGPoint(x: 22, y: 478), direction: -54, indexTip: CGPoint(x: 130.3624, y: 375.1816), presence: 0, thumb: 1), LouVectorArm(wrist: CGPoint(x: 86, y: 360), elbow: CGPoint(x: 18, y: 334), direction: 10, indexTip: CGPoint(x: 126.7615, y: 382.2157), presence: 0.5, thumb: 1)]),
            LouVector(keys: ["a", "é", "d", "s"], t: 4.3, mouth: "etiree", previousMouth: "etiree", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 241.994, y: 134.4135), elbow: CGPoint(x: 254, y: 236), direction: -74, indexTip: CGPoint(x: 247.944, y: 59.9697), presence: 1, thumb: -1), LouVectorArm(wrist: CGPoint(x: 80, y: 420), elbow: CGPoint(x: 22, y: 478), direction: -54, indexTip: CGPoint(x: 130.3624, y: 375.1816), presence: 0, thumb: 1), LouVectorArm(wrist: CGPoint(x: 86, y: 420), elbow: CGPoint(x: 18, y: 394), direction: 10, indexTip: CGPoint(x: 126.7615, y: 442.2157), presence: 0, thumb: 1)]),
            LouVector(keys: ["a", "é", "d", "s"], t: 4.963, mouth: "etiree", previousMouth: "etiree", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 205.9543, y: 150.4678), elbow: CGPoint(x: 254, y: 236), direction: -74, indexTip: CGPoint(x: 211.9043, y: 76.024), presence: 1, thumb: -1), LouVectorArm(wrist: CGPoint(x: 80, y: 420), elbow: CGPoint(x: 22, y: 478), direction: -54, indexTip: CGPoint(x: 130.3624, y: 375.1816), presence: 0, thumb: 1), LouVectorArm(wrist: CGPoint(x: 86, y: 420), elbow: CGPoint(x: 18, y: 394), direction: 10, indexTip: CGPoint(x: 126.7615, y: 442.2157), presence: 0, thumb: 1)]),
            LouVector(keys: ["a", "é", "d", "s"], t: 6.25, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 198.05, y: 397.0655), elbow: CGPoint(x: 254, y: 434.6215), direction: -74, indexTip: CGPoint(x: 204, y: 322.6217), presence: 0.1035, thumb: -1), LouVectorArm(wrist: CGPoint(x: 80, y: 420), elbow: CGPoint(x: 22, y: 478), direction: -54, indexTip: CGPoint(x: 130.3624, y: 375.1816), presence: 0, thumb: 1), LouVectorArm(wrist: CGPoint(x: 86, y: 420), elbow: CGPoint(x: 18, y: 394), direction: 10, indexTip: CGPoint(x: 126.7615, y: 442.2157), presence: 0, thumb: 1)]),
        ]
    }

    private static func v20() -> [LouVector] {   // p + xyz + l
        [
            LouVector(keys: ["p", "xyz", "l"], t: 0.2, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 214, y: 313), elbow: CGPoint(x: 228, y: 397), direction: -92, indexTip: CGPoint(x: 197.6734, y: 269.5433), presence: 0.5, thumb: -1)]),
            LouVector(keys: ["p", "xyz", "l"], t: 0.4, mouth: "fermee", previousMouth: "neutre", mouthMix: 0, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 214, y: 206), elbow: CGPoint(x: 228, y: 290), direction: -92, indexTip: CGPoint(x: 197.6734, y: 162.5433), presence: 1, thumb: -1)]),
            LouVector(keys: ["p", "xyz", "l"], t: 0.88, mouth: "mi_ouverte", previousMouth: "fermee", mouthMix: 0.6667, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 214, y: 206), elbow: CGPoint(x: 228, y: 290), direction: -92, indexTip: CGPoint(x: 188.373, y: 134.6727), presence: 1, thumb: -1)]),
            LouVector(keys: ["p", "xyz", "l"], t: 1.3229, mouth: "neutre", previousMouth: "mi_ouverte", mouthMix: 0.3575, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 214, y: 210.7386), elbow: CGPoint(x: 228, y: 294.7386), direction: -92, indexTip: CGPoint(x: 188.373, y: 139.4113), presence: 0.9779, thumb: -1)]),
            LouVector(keys: ["p", "xyz", "l"], t: 1.4329, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 214, y: 313.0562), elbow: CGPoint(x: 228, y: 397.0562), direction: -92, indexTip: CGPoint(x: 188.373, y: 241.729), presence: 0.4997, thumb: -1)]),
            LouVector(keys: ["p", "xyz", "l"], t: 1.5987, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 213.0768, y: 420), elbow: CGPoint(x: 227.697, y: 504.2892), direction: -92, indexTip: CGPoint(x: 187.6291, y: 348.6444), presence: 0, thumb: -1)]),
            LouVector(keys: ["p", "xyz", "l"], t: 1.6329, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 210.6456, y: 420), elbow: CGPoint(x: 226.899, y: 505.0507), direction: -92, indexTip: CGPoint(x: 185.6698, y: 348.5696), presence: 0, thumb: -1)]),
            LouVector(keys: ["p", "xyz", "l"], t: 2.2257, mouth: "langue_haut", previousMouth: "neutre", mouthMix: 0.3332, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 171.346, y: 416.6336), elbow: CGPoint(x: 214, y: 513.9946), direction: -92, indexTip: CGPoint(x: 154.0004, y: 343.9947), presence: 0.0192, thumb: -1)]),
            LouVector(keys: ["p", "xyz", "l"], t: 2.2579, mouth: "langue_haut", previousMouth: "neutre", mouthMix: 0.6015, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 171.346, y: 403.5388), elbow: CGPoint(x: 214, y: 500.8998), direction: -92, indexTip: CGPoint(x: 154.0004, y: 330.8999), presence: 0.0939, thumb: -1)]),
            LouVector(keys: ["p", "xyz", "l"], t: 2.3357, mouth: "langue_haut", previousMouth: "langue_haut", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 171.346, y: 332.3352), elbow: CGPoint(x: 214, y: 429.6962), direction: -92, indexTip: CGPoint(x: 154.0004, y: 259.6963), presence: 0.4999, thumb: -1)]),
            LouVector(keys: ["p", "xyz", "l"], t: 2.5357, mouth: "langue_haut", previousMouth: "langue_haut", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 171.346, y: 243.9333), elbow: CGPoint(x: 214, y: 341.6471), direction: -92, indexTip: CGPoint(x: 154.0004, y: 171.2944), presence: 1, thumb: -1)]),
            LouVector(keys: ["p", "xyz", "l"], t: 3.5357, mouth: "neutre", previousMouth: "neutre", mouthMix: 1, vibrate: false, vibration: 0, lift: 0, table: 0, arms: [LouVectorArm(wrist: CGPoint(x: 171.346, y: 397.2844), elbow: CGPoint(x: 214, y: 516.6454), direction: -92, indexTip: CGPoint(x: 154.0004, y: 324.6455), presence: 0.1036, thumb: -1)]),
        ]
    }
}
