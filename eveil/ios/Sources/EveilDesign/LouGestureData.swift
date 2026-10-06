// LouGestureData.swift — FICHIER GÉNÉRÉ par eveil/outils/gestes/generer.py : ne pas modifier à la main.
//
// Les chronologies des gestes animés de Lou (`eveil/outils/gestes/animation.py`) : une par son,
// du repos au repos. Clé : instant (s), bouche, gorge qui vibre, tête levée, table, segment adouci,
// puis un bras par `J(coude x, y, poignet x, y, direction de la main, forme, présence)` (direction en
// degrés, déroulée d'une clé à l'autre).

#if canImport(SwiftUI)
import SwiftUI

extension LouChronology {
    /// Les sons qui ont un geste, dans l'ordre de la planche.
    static let gestureKeys: [String] = ["a", "o", "ou", "i", "u", "é", "è", "eu", "eu ouvert", "e", "an", "on", "in", "oi", "oin", "ch", "s", "z", "j", "f", "v", "p", "b", "t", "d", "k", "g", "m", "n", "gn", "l", "r", "ill"]
    static let gestures: [String: LouChronology] = [
        "a": gesture00(),
        "o": gesture01(),
        "ou": gesture02(),
        "i": gesture03(),
        "u": gesture04(),
        "é": gesture05(),
        "è": gesture06(),
        "eu": gesture07(),
        "eu ouvert": gesture08(),
        "e": gesture09(),
        "an": gesture10(),
        "on": gesture11(),
        "in": gesture12(),
        "oi": gesture13(),
        "oin": gesture14(),
        "ch": gesture15(),
        "s": gesture16(),
        "z": gesture17(),
        "j": gesture18(),
        "f": gesture19(),
        "v": gesture20(),
        "p": gesture21(),
        "b": gesture22(),
        "t": gesture23(),
        "d": gesture24(),
        "k": gesture25(),
        "g": gesture26(),
        "m": gesture27(),
        "n": gesture28(),
        "gn": gesture29(),
        "l": gesture30(),
        "r": gesture31(),
        "ill": gesture32(),
    ]
    /// Les sons relevés sans geste : la bouche seule.
    static let mouthOnly: [String: LouChronology] = [
        "ui": mouthOnly00(),
    ]

    private static func gesture00() -> LouChronology {   // a
        var c = LouChronology(key: "a", duration: 1.6, posed: 0.8, gesture: true)
        c.arm(.right, thumb: -1, size: 40, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(250, 478, 224, 420, -86, "ouverte", 0))
        c.key(0.35, "grande", false, 0, 0, true, J(250, 240, 224, 182, -86, "ouverte", 1))
        c.key(1.25, "neutre", false, 0, 0, false, J(250, 240, 224, 182, -86, "ouverte", 1))
        c.key(1.6, "neutre", false, 0, 0, true, J(250, 478, 224, 420, -86, "ouverte", 0))
        return c
    }

    private static func gesture01() -> LouChronology {   // o
        var c = LouChronology(key: "o", duration: 1.6, posed: 0.8, gesture: true)
        c.arm(.right, thumb: -1, size: 44, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(236, 452, 202, 420, -100, "rond_o", 0))
        c.key(0.35, "ronde", false, 0, 0, true, J(236, 330, 202, 298, -100, "rond_o", 1))
        c.key(1.25, "neutre", false, 0, 0, false, J(236, 330, 202, 298, -100, "rond_o", 1))
        c.key(1.6, "neutre", false, 0, 0, true, J(236, 452, 202, 420, -100, "rond_o", 0))
        return c
    }

    private static func gesture02() -> LouChronology {   // ou
        var c = LouChronology(key: "ou", duration: 2.1, posed: 1.65, gesture: true)
        c.arm(.right, thumb: -1, size: 44, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(236, 452, 202, 420, -100, "rond_o", 0))
        c.key(0.35, "petite_ronde", false, 0, 0, true, J(236, 330, 202, 298, -100, "rond_o", 1))
        c.key(0.3833, "petite_ronde", false, 0, 0, false, J(236.037, 329.933, 202.073, 297.867, -100, "rond_o", 1))
        c.key(0.4167, "petite_ronde", false, 0, 0, false, J(236.145, 329.737, 202.29, 297.474, -100, "rond_o", 1))
        c.key(0.45, "petite_ronde", false, 0, 0, false, J(236.324, 329.422, 202.649, 296.843, -100, "rond_o", 1))
        c.key(0.4833, "petite_ronde", false, 0, 0, false, J(236.576, 328.996, 203.152, 295.993, -100, "rond_o", 1))
        c.key(0.5167, "petite_ronde", false, 0, 0, false, J(236.898, 328.468, 203.796, 294.935, -100, "rond_o", 1))
        c.key(0.55, "petite_ronde", false, 0, 0, false, J(237.284, 327.845, 204.568, 293.69, -100, "rond_o", 1))
        c.key(0.5833, "petite_ronde", false, 0, 0, false, J(237.731, 327.133, 205.461, 292.267, -100, "rond_o", 1))
        c.key(0.6167, "petite_ronde", false, 0, 0, false, J(238.233, 326.336, 206.466, 290.671, -100, "rond_o", 1))
        c.key(0.65, "petite_ronde", false, 0, 0, false, J(238.78, 325.462, 207.561, 288.924, -100, "rond_o", 1))
        c.key(0.6833, "petite_ronde", false, 0, 0, false, J(239.368, 324.515, 208.736, 287.03, -100, "rond_o", 1))
        c.key(0.7167, "petite_ronde", false, 0, 0, false, J(239.991, 323.496, 209.981, 284.992, -100, "rond_o", 1))
        c.key(0.75, "petite_ronde", false, 0, 0, false, J(240.634, 322.415, 211.268, 282.83, -100, "rond_o", 1))
        c.key(0.9, "petite_ronde", false, 0, 0, false, J(243.57, 316.855, 217.14, 271.71, -100, "deux_serres", 1))
        c.key(0.9167, "petite_ronde", false, 0, 0, false, J(243.871, 316.175, 217.741, 270.349, -100, "deux_serres", 1))
        c.key(0.95, "petite_ronde", false, 0, 0, false, J(244.423, 314.784, 218.846, 267.568, -100, "deux_serres", 1))
        c.key(0.9833, "petite_ronde", false, 0, 0, false, J(244.896, 313.352, 219.793, 264.704, -100, "deux_serres", 1))
        c.key(0.9914, "petite_ronde", false, 0, 0, false, J(245, 312.999, 220.001, 263.998, -100, "deux_serres", 1))
        c.key(1.0167, "petite_ronde", false, 0, 0, false, J(245.263, 311.88, 220.526, 261.761, -100, "deux_serres", 1))
        c.key(1.05, "petite_ronde", false, 0, 0, false, J(245.53, 310.396, 221.061, 258.792, -100, "deux_serres", 1))
        c.key(1.0833, "petite_ronde", false, 0, 0, false, J(245.722, 308.912, 221.443, 255.823, -100, "deux_serres", 1))
        c.key(1.1167, "petite_ronde", false, 0, 0, false, J(245.859, 307.437, 221.717, 252.874, -100, "deux_serres", 1))
        c.key(1.15, "petite_ronde", false, 0, 0, false, J(245.953, 305.991, 221.906, 249.982, -100, "deux_serres", 1))
        c.key(1.1833, "petite_ronde", false, 0, 0, false, J(246.013, 304.579, 222.026, 247.158, -100, "deux_serres", 1))
        c.key(1.2, "petite_ronde", false, 0, 0, false, J(246.034, 303.887, 222.068, 245.773, -100, "deux_serres", 1))
        c.key(1.35, "petite_ronde", false, 0, 0, false, J(246.037, 298.322, 222.075, 234.644, -100, "deux_ecartes", 1))
        c.key(1.3833, "petite_ronde", false, 0, 0, false, J(246.019, 297.291, 222.039, 232.582, -100, "deux_ecartes", 1))
        c.key(1.4167, "petite_ronde", false, 0, 0, false, J(246.002, 296.349, 222.004, 230.698, -100, "deux_ecartes", 1))
        c.key(1.45, "petite_ronde", false, 0, 0, false, J(245.988, 295.509, 221.977, 229.018, -100, "deux_ecartes", 1))
        c.key(1.4833, "petite_ronde", false, 0, 0, false, J(245.98, 294.776, 221.959, 227.552, -100, "deux_ecartes", 1))
        c.key(1.5167, "petite_ronde", false, 0, 0, false, J(245.977, 294.157, 221.955, 226.314, -100, "deux_ecartes", 1))
        c.key(1.55, "petite_ronde", false, 0, 0, false, J(245.981, 293.663, 221.963, 225.326, -100, "deux_ecartes", 1))
        c.key(1.5833, "petite_ronde", false, 0, 0, false, J(245.989, 293.3, 221.979, 224.6, -100, "deux_ecartes", 1))
        c.key(1.6167, "petite_ronde", false, 0, 0, false, J(245.997, 293.076, 221.995, 224.152, -100, "deux_ecartes", 1))
        c.key(1.65, "petite_ronde", false, 0, 0, false, J(246, 293, 222, 224, -100, "deux_ecartes", 1))
        c.key(1.75, "neutre", false, 0, 0, false, J(246, 293, 222, 224, -100, "deux_ecartes", 1))
        c.key(2.1, "neutre", false, 0, 0, true, J(246, 489, 222, 420, -100, "deux_ecartes", 0))
        return c
    }

    private static func gesture03() -> LouChronology {   // i
        var c = LouChronology(key: "i", duration: 1.6, posed: 0.8, gesture: true)
        c.arm(.right, thumb: -1, size: 40, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(226, 500, 212, 420, -92, "index", 0))
        c.key(0.35, "etiree", false, 0, 0, true, J(226, 300, 212, 220, -92, "index", 1))
        c.key(1.25, "neutre", false, 0, 0, false, J(226, 300, 212, 220, -92, "index", 1))
        c.key(1.6, "neutre", false, 0, 0, true, J(226, 500, 212, 420, -92, "index", 0))
        return c
    }

    private static func gesture04() -> LouChronology {   // u
        var c = LouChronology(key: "u", duration: 1.6, posed: 0.8, gesture: true)
        c.arm(.right, thumb: -1, size: 40, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(226, 500, 212, 420, -92, "deux_ecartes", 0))
        c.key(0.35, "petite_ronde", false, 0, 0, true, J(226, 300, 212, 220, -92, "deux_ecartes", 1))
        c.key(1.25, "neutre", false, 0, 0, false, J(226, 300, 212, 220, -92, "deux_ecartes", 1))
        c.key(1.6, "neutre", false, 0, 0, true, J(226, 500, 212, 420, -92, "deux_ecartes", 0))
        return c
    }

    private static func gesture05() -> LouChronology {   // é
        var c = LouChronology(key: "é", duration: 1.6, posed: 0.8, gesture: true)
        c.arm(.left, thumb: 1, size: 36, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(22, 478, 80, 420, -54, "plate", 0))
        c.key(0.35, "etiree", false, 0, 0, true, J(22, 170, 80, 112, -54, "plate", 1))
        c.key(1.25, "neutre", false, 0, 0, false, J(22, 170, 80, 112, -54, "plate", 1))
        c.key(1.6, "neutre", false, 0, 0, true, J(22, 478, 80, 420, -54, "plate", 0))
        return c
    }

    private static func gesture06() -> LouChronology {   // è
        var c = LouChronology(key: "è", duration: 1.6, posed: 0.8, gesture: true)
        c.arm(.right, thumb: -1, size: 36, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(250, 484, 176, 420, -128, "plate", 0))
        c.key(0.35, "mi_ouverte", false, 1.2, 0, true, J(250, 130, 176, 66, -128, "plate", 1))
        c.key(1.25, "neutre", false, 1.2, 0, false, J(250, 130, 176, 66, -128, "plate", 1))
        c.key(1.6, "neutre", false, 0, 0, true, J(250, 484, 176, 420, -128, "plate", 0))
        return c
    }

    private static func gesture07() -> LouChronology {   // eu
        var c = LouChronology(key: "eu", duration: 1.6, posed: 0.8, gesture: true)
        c.arm(.right, thumb: -1, size: 44, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(236, 452, 202, 420, -100, "croise", 0))
        c.key(0.35, "ronde", false, 0, 0, true, J(236, 330, 202, 298, -100, "croise", 1))
        c.key(1.25, "neutre", false, 0, 0, false, J(236, 330, 202, 298, -100, "croise", 1))
        c.key(1.6, "neutre", false, 0, 0, true, J(236, 452, 202, 420, -100, "croise", 0))
        return c
    }

    private static func gesture08() -> LouChronology {   // eu ouvert
        var c = LouChronology(key: "eu ouvert", duration: 1.6, posed: 0.8, gesture: true)
        c.arm(.right, thumb: -1, size: 44, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(236, 452, 202, 420, -100, "croise", 0))
        c.key(0.35, "ronde", false, 0, 0, true, J(236, 330, 202, 298, -100, "croise", 1))
        c.key(1.25, "neutre", false, 0, 0, false, J(236, 330, 202, 298, -100, "croise", 1))
        c.key(1.6, "neutre", false, 0, 0, true, J(236, 452, 202, 420, -100, "croise", 0))
        return c
    }

    private static func gesture09() -> LouChronology {   // e
        var c = LouChronology(key: "e", duration: 1.6, posed: 0.8, gesture: true)
        c.arm(.right, thumb: -1, size: 44, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(236, 452, 202, 420, -100, "croise", 0))
        c.key(0.35, "ronde", false, 0, 0, true, J(236, 330, 202, 298, -100, "croise", 1))
        c.key(1.25, "neutre", false, 0, 0, false, J(236, 330, 202, 298, -100, "croise", 1))
        c.key(1.6, "neutre", false, 0, 0, true, J(236, 452, 202, 420, -100, "croise", 0))
        return c
    }

    private static func gesture10() -> LouChronology {   // an
        var c = LouChronology(key: "an", duration: 1.6, posed: 0.8, gesture: true)
        c.arm(.right, thumb: 1, size: 36, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(250, 514.695, 196.727, 420, -158, "ouverte", 0))
        c.key(0.35, "grande", false, 0, 0, true, J(250, 240, 196.727, 145.305, -158, "ouverte", 1))
        c.key(1.25, "neutre", false, 0, 0, false, J(250, 240, 196.727, 145.305, -158, "ouverte", 1))
        c.key(1.6, "neutre", false, 0, 0, true, J(250, 514.695, 196.727, 420, -158, "ouverte", 0))
        return c
    }

    private static func gesture11() -> LouChronology {   // on
        var c = LouChronology(key: "on", duration: 1.6, posed: 0.8, gesture: true)
        c.arm(.right, thumb: -1, size: 30, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(240, 517.158, 189.007, 420, -132, "rond_o_tendu", 0))
        c.key(0.35, "ronde", false, 0, 0, true, J(240, 260, 189.007, 162.842, -132, "rond_o_tendu", 1))
        c.key(1.25, "neutre", false, 0, 0, false, J(240, 260, 189.007, 162.842, -132, "rond_o_tendu", 1))
        c.key(1.6, "neutre", false, 0, 0, true, J(240, 517.158, 189.007, 420, -132, "rond_o_tendu", 0))
        return c
    }

    private static func gesture12() -> LouChronology {   // in
        var c = LouChronology(key: "in", duration: 1.6, posed: 0.8, gesture: true)
        c.arm(.right, thumb: 1, size: 32, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(252, 502.477, 191.028, 420, -164, "index", 0))
        c.key(0.35, "mi_ouverte", false, 0, 0, true, J(252, 250, 191.028, 167.523, -164, "index", 1))
        c.key(1.25, "neutre", false, 0, 0, false, J(252, 250, 191.028, 167.523, -164, "index", 1))
        c.key(1.6, "neutre", false, 0, 0, true, J(252, 502.477, 191.028, 420, -164, "index", 0))
        return c
    }

    private static func gesture13() -> LouChronology {   // oi
        var c = LouChronology(key: "oi", duration: 1.55, posed: 0.75, gesture: true)
        c.arm(.right, thumb: -1, size: 44, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(236, 452, 202, 420, -100, "poing", 0))
        c.key(0.35, "ronde", false, 0, 0, true, J(236, 330, 202, 298, -100, "poing", 1))
        c.key(0.65, "ronde", false, 0, 0, false, J(236, 330, 202, 298, -100, "poing", 1))
        c.key(0.75, "ronde", false, 0, 0, true, J(236, 330, 202, 298, -100, "ouverte", 1))
        c.key(1.2, "neutre", false, 0, 0, false, J(236, 330, 202, 298, -100, "ouverte", 1))
        c.key(1.55, "neutre", false, 0, 0, true, J(236, 452, 202, 420, -100, "ouverte", 0))
        return c
    }

    private static func gesture14() -> LouChronology {   // oin
        var c = LouChronology(key: "oin", duration: 1.8, posed: 1.15, gesture: true)
        c.arm(.right, thumb: -1, size: 40, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(262, 480, 240, 420, -168, "bec_ferme", 0))
        c.key(0.35, "ronde", false, 0, 0, true, J(262, 330, 240, 270, -168, "bec_ferme", 1))
        c.key(0.6, "ronde", false, 0, 0, false, J(262, 330, 240, 270, -168, "bec_ferme", 1))
        c.key(0.75, "ronde", false, 0, 0, true, J(262, 330, 240, 270, -168, "bec_ouvert", 1))
        c.key(1, "ronde", false, 0, 0, false, J(262, 330, 240, 270, -168, "bec_ouvert", 1))
        c.key(1.15, "ronde", false, 0, 0, true, J(262, 330, 240, 270, -168, "bec_ferme", 1))
        c.key(1.45, "neutre", false, 0, 0, false, J(262, 330, 240, 270, -168, "bec_ferme", 1))
        c.key(1.8, "neutre", false, 0, 0, true, J(262, 480, 240, 420, -168, "bec_ferme", 0))
        return c
    }

    private static func gesture15() -> LouChronology {   // ch
        var c = LouChronology(key: "ch", duration: 1.8, posed: 0.9, gesture: true)
        c.arm(.right, thumb: -1, size: 40, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(200, 508, 130, 420, -90, "pince_ch", 0))
        c.key(0.35, "avancee", false, 0, 0, true, J(200, 320, 130, 232, -90, "pince_ch", 1))
        c.key(1.45, "neutre", false, 0, 0, false, J(200, 320, 130, 232, -90, "pince_ch", 1))
        c.key(1.8, "neutre", false, 0, 0, true, J(200, 508, 130, 420, -90, "pince_ch", 0))
        return c
    }

    private static func gesture16() -> LouChronology {   // s
        var c = LouChronology(key: "s", duration: 2.4, posed: 1.95, gesture: true)
        c.arm(.right, thumb: -1, size: 40, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(232, 490, 218, 420, -96, "index", 0))
        c.key(0.35, "etiree", false, 0, 0, true, J(254, 236, 242.05, 134.444, -74, "index", 1))
        c.key(0.3833, "etiree", false, 0, 0, false, J(254, 236, 241.864, 134.343, -74, "index", 1))
        c.key(0.4167, "etiree", false, 0, 0, false, J(254, 236, 241.318, 134.037, -74, "index", 1))
        c.key(0.45, "etiree", false, 0, 0, false, J(254, 236, 240.452, 133.501, -74, "index", 1))
        c.key(0.4833, "etiree", false, 0, 0, false, J(254, 236, 239.287, 132.735, -74, "index", 1))
        c.key(0.5167, "etiree", false, 0, 0, false, J(254, 236, 237.833, 131.746, -74, "index", 1))
        c.key(0.55, "etiree", false, 0, 0, false, J(254, 236, 236.106, 130.563, -74, "index", 1))
        c.key(0.5833, "etiree", false, 0, 0, false, J(254, 236, 234.103, 129.211, -74, "index", 1))
        c.key(0.6167, "etiree", false, 0, 0, false, J(254, 236, 231.816, 127.724, -74, "index", 1))
        c.key(0.65, "etiree", false, 0, 0, false, J(254, 236, 229.246, 126.162, -74, "index", 1))
        c.key(0.6833, "etiree", false, 0, 0, false, J(254, 236, 226.365, 124.604, -74, "index", 1))
        c.key(0.7167, "etiree", false, 0, 0, false, J(254, 236, 223.117, 123.209, -74, "index", 1))
        c.key(0.75, "etiree", false, 0, 0, false, J(254, 236, 219.457, 122.407, -74, "index", 1))
        c.key(0.762, "etiree", false, 0, 0, false, J(254, 236, 218.05, 122.444, -74, "index", 1))
        c.key(0.7833, "etiree", false, 0, 0, false, J(254, 236, 215.581, 123.116, -74, "index", 1))
        c.key(0.8167, "etiree", false, 0, 0, false, J(254, 236, 211.858, 125.01, -74, "index", 1))
        c.key(0.85, "etiree", false, 0, 0, false, J(254, 236, 208.349, 127.576, -74, "index", 1))
        c.key(0.8833, "etiree", false, 0, 0, false, J(254, 236, 205.097, 130.7, -74, "index", 1))
        c.key(0.9167, "etiree", false, 0, 0, false, J(254, 236, 202.24, 134.386, -74, "index", 1))
        c.key(0.95, "etiree", false, 0, 0, false, J(254, 236, 200.269, 138.718, -74, "index", 1))
        c.key(0.962, "etiree", false, 0, 0, false, J(254, 236, 200.05, 140.444, -74, "index", 1))
        c.key(0.9833, "etiree", false, 0, 0, false, J(254, 236, 200.765, 143.485, -74, "index", 1))
        c.key(1.0167, "etiree", false, 0, 0, false, J(254, 236, 203.423, 147.693, -74, "index", 1))
        c.key(1.05, "etiree", false, 0, 0, false, J(254, 236, 206.8, 151.444, -74, "index", 1))
        c.key(1.0833, "etiree", false, 0, 0, false, J(254, 236, 210.457, 155.004, -74, "index", 1))
        c.key(1.1167, "etiree", false, 0, 0, false, J(254, 236, 214.203, 158.545, -74, "index", 1))
        c.key(1.15, "etiree", false, 0, 0, false, J(254, 236, 217.832, 162.209, -74, "index", 1))
        c.key(1.1521, "etiree", false, 0, 0, false, J(254, 236, 218.05, 162.444, -74, "index", 1))
        c.key(1.1833, "etiree", false, 0, 0, false, J(254, 236, 221.561, 165.764, -74, "index", 1))
        c.key(1.2167, "etiree", false, 0, 0, false, J(254, 236, 225.606, 168.96, -74, "index", 1))
        c.key(1.25, "etiree", false, 0, 0, false, J(254, 236, 229.668, 172.049, -74, "index", 1))
        c.key(1.2833, "etiree", false, 0, 0, false, J(254, 236, 233.536, 175.293, -74, "index", 1))
        c.key(1.3167, "etiree", false, 0, 0, false, J(254, 236, 236.798, 179.055, -74, "index", 1))
        c.key(1.3415, "etiree", false, 0, 0, false, J(254, 236, 238.05, 182.444, -74, "index", 1))
        c.key(1.35, "etiree", false, 0, 0, false, J(254, 236, 238.051, 183.686, -74, "index", 1))
        c.key(1.3833, "etiree", false, 0, 0, false, J(254, 236, 236.838, 188.287, -74, "index", 1))
        c.key(1.4167, "etiree", false, 0, 0, false, J(254, 236, 234.645, 192.403, -74, "index", 1))
        c.key(1.45, "etiree", false, 0, 0, false, J(254, 236, 232.017, 196.068, -74, "index", 1))
        c.key(1.4833, "etiree", false, 0, 0, false, J(254, 236, 229.112, 199.304, -74, "index", 1))
        c.key(1.5167, "etiree", false, 0, 0, false, J(254, 236, 225.981, 202.076, -74, "index", 1))
        c.key(1.55, "etiree", false, 0, 0, false, J(254, 236, 222.623, 204.186, -74, "index", 1))
        c.key(1.5554, "etiree", false, 0, 0, false, J(254, 236, 222.05, 204.444, -74, "index", 1))
        c.key(1.5833, "etiree", false, 0, 0, false, J(254, 236, 218.984, 204.993, -74, "index", 1))
        c.key(1.6167, "etiree", false, 0, 0, false, J(254, 236, 215.469, 204.665, -74, "index", 1))
        c.key(1.65, "etiree", false, 0, 0, false, J(254, 236, 212.287, 203.892, -74, "index", 1))
        c.key(1.6833, "etiree", false, 0, 0, false, J(254, 236, 209.431, 202.954, -74, "index", 1))
        c.key(1.7167, "etiree", false, 0, 0, false, J(254, 236, 206.88, 201.986, -74, "index", 1))
        c.key(1.75, "etiree", false, 0, 0, false, J(254, 236, 204.645, 201.068, -74, "index", 1))
        c.key(1.7833, "etiree", false, 0, 0, false, J(254, 236, 202.718, 200.25, -74, "index", 1))
        c.key(1.8167, "etiree", false, 0, 0, false, J(254, 236, 201.099, 199.565, -74, "index", 1))
        c.key(1.85, "etiree", false, 0, 0, false, J(254, 236, 199.807, 199.041, -74, "index", 1))
        c.key(1.8833, "etiree", false, 0, 0, false, J(254, 236, 198.851, 198.69, -74, "index", 1))
        c.key(1.9167, "etiree", false, 0, 0, false, J(254, 236, 198.253, 198.503, -74, "index", 1))
        c.key(1.95, "etiree", false, 0, 0, false, J(254, 236, 198.05, 198.444, -74, "index", 1))
        c.key(2.05, "neutre", false, 0, 0, false, J(254, 236, 198.05, 198.444, -74, "index", 1))
        c.key(2.4, "neutre", false, 0, 0, true, J(254, 457.556, 198.05, 420, -74, "index", 0))
        return c
    }

    private static func gesture17() -> LouChronology {   // z
        var c = LouChronology(key: "z", duration: 1.55, posed: 1.05, gesture: true)
        c.arm(.right, thumb: -1, size: 40, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(232, 490, 218, 420, -96, "index", 0))
        c.key(0.35, "etiree", true, 0, 0, true, J(254, 236, 200.05, 130.444, -74, "index", 1))
        c.key(0.3833, "etiree", true, 0, 0, false, J(254, 236, 201.338, 130.569, -74, "index", 1))
        c.key(0.4167, "etiree", true, 0, 0, false, J(254, 236, 205.062, 130.715, -74, "index", 1))
        c.key(0.45, "etiree", true, 0, 0, false, J(254, 236, 210.945, 130.784, -74, "index", 1))
        c.key(0.4833, "etiree", true, 0, 0, false, J(254, 236, 218.737, 130.898, -74, "index", 1))
        c.key(0.5167, "etiree", true, 0, 0, false, J(254, 236, 228.203, 131.369, -74, "index", 1))
        c.key(0.55, "etiree", true, 0, 0, false, J(254, 236, 238.839, 133.345, -74, "index", 1))
        c.key(0.5634, "etiree", true, 0, 0, false, J(254, 236, 242.05, 136.444, -74, "index", 1))
        c.key(0.5833, "etiree", true, 0, 0, false, J(254, 236, 238.092, 142.388, -74, "index", 1))
        c.key(0.6167, "etiree", true, 0, 0, false, J(254, 236, 228.214, 150.719, -74, "index", 1))
        c.key(0.65, "etiree", true, 0, 0, false, J(254, 236, 217.471, 158.94, -74, "index", 1))
        c.key(0.6833, "etiree", true, 0, 0, false, J(254, 236, 206.744, 167.787, -74, "index", 1))
        c.key(0.703, "etiree", true, 0, 0, false, J(254, 236, 202.05, 174.444, -74, "index", 1))
        c.key(0.7167, "etiree", true, 0, 0, false, J(254, 236, 206.651, 177.233, -74, "index", 1))
        c.key(0.75, "etiree", true, 0, 0, false, J(254, 236, 220.537, 177.633, -74, "index", 1))
        c.key(0.7833, "etiree", true, 0, 0, false, J(254, 236, 234.062, 177.435, -74, "index", 1))
        c.key(0.8117, "etiree", true, 0, 0, false, J(254, 236, 244.05, 180.444, -74, "index", 1))
        c.key(0.8167, "etiree", true, 0, 0, false, J(254, 236, 243.647, 182.279, -74, "index", 1))
        c.key(0.85, "etiree", true, 0, 0, false, J(254, 236, 236.012, 191.448, -74, "index", 1))
        c.key(0.8833, "etiree", true, 0, 0, false, J(254, 236, 227.886, 198.64, -74, "index", 1))
        c.key(0.9167, "etiree", true, 0, 0, false, J(254, 236, 220.553, 204.646, -74, "index", 1))
        c.key(0.95, "etiree", true, 0, 0, false, J(254, 236, 214.46, 209.505, -74, "index", 1))
        c.key(0.9833, "etiree", true, 0, 0, false, J(254, 236, 209.87, 213.185, -74, "index", 1))
        c.key(1.0167, "etiree", true, 0, 0, false, J(254, 236, 207.01, 215.576, -74, "index", 1))
        c.key(1.05, "etiree", true, 0, 0, false, J(254, 236, 206.05, 216.444, -74, "index", 1))
        c.key(1.2, "neutre", false, 0, 0, false, J(254, 236, 206.05, 216.444, -74, "index", 1))
        c.key(1.55, "neutre", false, 0, 0, true, J(254, 439.556, 206.05, 420, -74, "index", 0))
        return c
    }

    private static func gesture18() -> LouChronology {   // j
        var c = LouChronology(key: "j", duration: 1.4, posed: 0.7, gesture: true)
        c.arm(.right, thumb: 1, size: 40, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(250, 484.583, 231.993, 420, -150, "index", 0))
        c.key(0.35, "avancee", true, 0, 0, true, J(265, 263, 261.993, 191.417, -150, "index", 1))
        c.key(0.7, "avancee", true, 0, 0, true, J(250, 270, 231.993, 205.417, -150, "index", 1))
        c.key(1.05, "neutre", false, 0, 0, false, J(250, 270, 231.993, 205.417, -150, "index", 1))
        c.key(1.4, "neutre", false, 0, 0, true, J(250, 484.583, 231.993, 420, -150, "index", 0))
        return c
    }

    private static func gesture19() -> LouChronology {   // f
        var c = LouChronology(key: "f", duration: 1.9, posed: 0.5, gesture: true)
        c.arm(.right, thumb: 1, size: 40, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(232, 482, 184, 420, -178, "plate", 0))
        c.key(0.35, "dents_levre", false, 0, 0, true, J(232, 320, 184, 258, -178, "plate", 1))
        c.key(0.65, "dents_levre", false, 0, 0, false, J(232, 320, 184, 258, -178, "plate", 1))
        c.key(0.6833, "dents_levre", false, 0, 0, false, J(232.283, 320, 184.566, 258, -178, "plate", 1))
        c.key(0.7167, "dents_levre", false, 0, 0, false, J(233.103, 320, 186.206, 258, -178, "plate", 1))
        c.key(0.75, "dents_levre", false, 0, 0, false, J(234.406, 320, 188.812, 258, -178, "plate", 1))
        c.key(0.7833, "dents_levre", false, 0, 0, false, J(236.146, 320, 192.292, 258, -178, "plate", 1))
        c.key(0.8167, "dents_levre", false, 0, 0, false, J(238.281, 320, 196.562, 258, -178, "plate", 1))
        c.key(0.85, "dents_levre", false, 0, 0, false, J(240.75, 320, 201.5, 258, -178, "plate", 1))
        c.key(0.8833, "dents_levre", false, 0, 0, false, J(243.51, 320, 207.02, 258, -178, "plate", 1))
        c.key(0.9167, "dents_levre", false, 0, 0, false, J(246.522, 320, 213.043, 258, -178, "plate", 1))
        c.key(0.95, "dents_levre", false, 0, 0, false, J(249.719, 320, 219.438, 258, -178, "plate", 1))
        c.key(0.9833, "dents_levre", false, 0, 0, false, J(253.061, 320, 226.123, 258, -178, "plate", 1))
        c.key(1.0167, "dents_levre", false, 0, 0, false, J(256.512, 320, 233.023, 258, -178, "plate", 1))
        c.key(1.05, "dents_levre", false, 0, 0, false, J(260, 320, 240, 258, -178, "plate", 1))
        c.key(1.0833, "dents_levre", false, 0, 0, false, J(263.488, 320, 246.977, 258, -178, "plate", 1))
        c.key(1.1167, "dents_levre", false, 0, 0, false, J(266.939, 320, 253.877, 258, -178, "plate", 1))
        c.key(1.15, "dents_levre", false, 0, 0, false, J(270.281, 320, 260.562, 258, -178, "plate", 1))
        c.key(1.1833, "dents_levre", false, 0, 0, false, J(273.478, 320, 266.957, 258, -178, "plate", 1))
        c.key(1.2167, "dents_levre", false, 0, 0, false, J(276.49, 320, 272.98, 258, -178, "plate", 1))
        c.key(1.25, "dents_levre", false, 0, 0, false, J(279.25, 320, 278.5, 258, -178, "plate", 1))
        c.key(1.2833, "dents_levre", false, 0, 0, false, J(281.719, 320, 283.438, 258, -178, "plate", 1))
        c.key(1.3167, "dents_levre", false, 0, 0, false, J(283.854, 320, 287.708, 258, -178, "plate", 1))
        c.key(1.35, "dents_levre", false, 0, 0, false, J(285.594, 320, 291.188, 258, -178, "plate", 1))
        c.key(1.3833, "dents_levre", false, 0, 0, false, J(286.897, 320, 293.794, 258, -178, "plate", 1))
        c.key(1.4167, "dents_levre", false, 0, 0, false, J(287.717, 320, 295.434, 258, -178, "plate", 1))
        c.key(1.45, "dents_levre", false, 0, 0, false, J(288, 320, 296, 258, -178, "plate", 1))
        c.key(1.55, "neutre", false, 0, 0, false, J(288, 320, 296, 258, -178, "plate", 1))
        c.key(1.9, "neutre", false, 0, 0, true, J(288, 482, 296, 420, -178, "plate", 0))
        return c
    }

    private static func gesture20() -> LouChronology {   // v
        var c = LouChronology(key: "v", duration: 1.6, posed: 0.8, gesture: true)
        c.arm(.left, thumb: 1, size: 36, behind: false)
        c.arm(.right, thumb: -1, size: 36, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(70, 452, 126, 420, -122, "plate", 0), J(190, 452, 134, 420, -58, "plate", 0))
        c.key(0.35, "dents_levre", true, 0, 0, true, J(70, 330, 126, 298, -122, "plate", 1), J(190, 330, 134, 298, -58, "plate", 1))
        c.key(1.25, "neutre", false, 0, 0, false, J(70, 330, 126, 298, -122, "plate", 1), J(190, 330, 134, 298, -58, "plate", 1))
        c.key(1.6, "neutre", false, 0, 0, true, J(70, 452, 126, 420, -122, "plate", 0), J(190, 452, 134, 420, -58, "plate", 0))
        return c
    }

    private static func gesture21() -> LouChronology {   // p
        var c = LouChronology(key: "p", duration: 1.58, posed: 0.83, gesture: true)
        c.arm(.right, thumb: -1, size: 40, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(228, 504, 214, 420, -92, "poing", 0))
        c.key(0.35, "fermee", false, 0, 0, true, J(228, 290, 214, 206, -92, "poing", 1))
        c.key(0.75, "mi_ouverte", false, 0, 0, false, J(228, 290, 214, 206, -92, "poing", 1))
        c.key(0.83, "mi_ouverte", false, 0, 0, true, J(228, 290, 214, 206, -92, "ouverte", 1))
        c.key(1.23, "neutre", false, 0, 0, false, J(228, 290, 214, 206, -92, "ouverte", 1))
        c.key(1.58, "neutre", false, 0, 0, true, J(228, 504, 214, 420, -92, "ouverte", 0))
        return c
    }

    private static func gesture22() -> LouChronology {   // b
        var c = LouChronology(key: "b", duration: 1.82, posed: 1.07, gesture: true)
        c.arm(.right, thumb: 1, size: 36, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(262, 450, 222, 420, -152, "mi_fermee", 0))
        c.key(0.35, "fermee", true, 0, 0, true, J(307, 322, 312, 284, -152, "mi_fermee", 1))
        c.key(0.3833, "fermee", true, 0, 0, false, J(306.415, 322.02, 310.829, 284.04, -152, "mi_fermee", 1))
        c.key(0.4167, "fermee", true, 0, 0, false, J(304.76, 322.039, 307.52, 284.079, -152, "mi_fermee", 1))
        c.key(0.45, "fermee", true, 0, 0, false, J(302.21, 322.037, 302.419, 284.075, -152, "mi_fermee", 1))
        c.key(0.4833, "fermee", true, 0, 0, false, J(298.924, 322.05, 295.848, 284.1, -152, "mi_fermee", 1))
        c.key(0.5167, "fermee", true, 0, 0, false, J(295.055, 322.14, 288.109, 284.281, -152, "mi_fermee", 1))
        c.key(0.55, "fermee", true, 0, 0, false, J(290.795, 322.395, 279.589, 284.79, -152, "mi_fermee", 1))
        c.key(0.5833, "fermee", true, 0, 0, false, J(286.317, 322.948, 270.633, 285.895, -152, "mi_fermee", 1))
        c.key(0.5856, "fermee", true, 0, 0, false, J(286, 323, 270, 286, -152, "mi_fermee", 1))
        c.key(0.6167, "fermee", true, 0, 0, false, J(281.813, 323.922, 261.626, 287.843, -152, "mi_fermee", 1))
        c.key(0.65, "fermee", true, 0, 0, false, J(277.46, 325.112, 252.92, 290.223, -152, "mi_fermee", 1))
        c.key(0.6833, "fermee", true, 0, 0, false, J(273.375, 326.348, 244.749, 292.695, -152, "mi_fermee", 1))
        c.key(0.7167, "fermee", true, 0, 0, false, J(269.687, 327.523, 237.374, 295.045, -152, "mi_fermee", 1))
        c.key(0.75, "fermee", true, 0, 0, false, J(266.564, 328.542, 231.127, 297.085, -152, "mi_fermee", 1))
        c.key(0.7833, "fermee", true, 0, 0, false, J(264.139, 329.333, 226.278, 298.666, -152, "mi_fermee", 1))
        c.key(0.8167, "fermee", true, 0, 0, false, J(262.561, 329.832, 223.122, 299.663, -152, "mi_fermee", 1))
        c.key(0.85, "fermee", true, 0, 0, false, J(262, 330, 222, 300, -152, "mi_fermee", 1))
        c.key(0.97, "mi_ouverte", true, 0, 0, false, J(262, 330, 222, 300, -152, "mi_fermee", 1))
        c.key(1.07, "mi_ouverte", true, 0, 0, true, J(262, 330, 222, 300, -152, "ouverte", 1))
        c.key(1.47, "neutre", false, 0, 0, false, J(262, 330, 222, 300, -152, "ouverte", 1))
        c.key(1.82, "neutre", false, 0, 0, true, J(262, 450, 222, 420, -152, "ouverte", 0))
        return c
    }

    private static func gesture23() -> LouChronology {   // t
        var c = LouChronology(key: "t", duration: 1.57, posed: 0.82, gesture: true)
        c.arm(.right, thumb: -1, size: 40, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(244, 482, 228, 420, -96, "pince_fermee", 0))
        c.key(0.35, "langue_haut", false, 0, 0, true, J(244, 330, 228, 268, -96, "pince_fermee", 1))
        c.key(0.7, "langue_haut", false, 0, 0, false, J(244, 330, 228, 268, -96, "pince_fermee", 1))
        c.key(0.82, "langue_haut", false, 0, 0, true, J(244, 330, 228, 268, -96, "pince_ouverte", 1))
        c.key(1.22, "neutre", false, 0, 0, false, J(244, 330, 228, 268, -96, "pince_ouverte", 1))
        c.key(1.57, "neutre", false, 0, 0, true, J(244, 482, 228, 420, -96, "pince_ouverte", 0))
        return c
    }

    private static func gesture24() -> LouChronology {   // d
        var c = LouChronology(key: "d", duration: 1.57, posed: 0.82, gesture: true)
        c.arm(.right, thumb: -1, size: 40, behind: false)
        c.arm(.left, thumb: 1, size: 40, behind: true)
        c.key(0, "neutre", false, 0, 0, false, J(244, 482, 228, 420, -96, "pince_fermee", 0), J(18, 394, 86, 420, 10, "poing", 0))
        c.key(0.35, "langue_haut", true, 0, 0, true, J(244, 330, 228, 268, -96, "pince_fermee", 1), J(18, 274, 86, 300, 10, "poing", 1))
        c.key(0.7, "langue_haut", true, 0, 0, false, J(244, 330, 228, 268, -96, "pince_fermee", 1), J(18, 274, 86, 300, 10, "poing", 1))
        c.key(0.82, "langue_haut", true, 0, 0, true, J(244, 330, 228, 268, -96, "pince_ouverte", 1), J(18, 274, 86, 300, 10, "poing", 1))
        c.key(1.22, "neutre", false, 0, 0, false, J(244, 330, 228, 268, -96, "pince_ouverte", 1), J(18, 274, 86, 300, 10, "poing", 1))
        c.key(1.57, "neutre", false, 0, 0, true, J(244, 482, 228, 420, -96, "pince_ouverte", 0), J(18, 394, 86, 420, 10, "poing", 0))
        return c
    }

    private static func gesture25() -> LouChronology {   // k
        var c = LouChronology(key: "k", duration: 1.3, posed: 0.55, gesture: true)
        c.arm(.right, thumb: 1, size: 40, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(250, 485.157, 224.428, 420, -172, "index", 0))
        c.key(0.35, "neutre", false, 0, 0, true, J(268, 245, 260.428, 174.843, -172, "index", 1))
        c.key(0.55, "fond", false, 0, 0, true, J(250, 250, 224.428, 184.843, -172, "index", 1))
        c.key(0.95, "neutre", false, 0, 0, false, J(250, 250, 224.428, 184.843, -172, "index", 1))
        c.key(1.3, "neutre", false, 0, 0, true, J(250, 485.157, 224.428, 420, -172, "index", 0))
        return c
    }

    private static func gesture26() -> LouChronology {   // g
        var c = LouChronology(key: "g", duration: 1.3, posed: 0.55, gesture: true)
        c.arm(.right, thumb: -1, size: 40, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(250, 520.856, 228.798, 420, -172, "pouce_index", 0))
        c.key(0.35, "neutre", false, 0, 0, true, J(267, 246, 262.798, 141.144, -172, "pouce_index", 1))
        c.key(0.55, "fond", true, 0, 0, true, J(250, 250, 228.798, 149.144, -172, "pouce_index", 1))
        c.key(0.95, "neutre", false, 0, 0, false, J(250, 250, 228.798, 149.144, -172, "pouce_index", 1))
        c.key(1.3, "neutre", false, 0, 0, true, J(250, 520.856, 228.798, 420, -172, "pouce_index", 0))
        return c
    }

    private static func gesture27() -> LouChronology {   // m
        var c = LouChronology(key: "m", duration: 1.9, posed: 0.95, gesture: true)
        c.arm(.right, thumb: 1, size: 40, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(250, 452.4, 190.8, 420, 90, "trois_doigts", 0))
        c.key(0.35, "neutre", false, 0, 1, true, J(250, 202, 190.8, 141.6, 90, "trois_doigts", 1))
        c.key(0.6, "fermee", false, 0, 1, true, J(250, 230, 190.8, 197.6, 90, "trois_doigts", 1))
        c.key(1.3, "neutre", false, 0, 1, false, J(250, 230, 190.8, 197.6, 90, "trois_doigts", 1))
        c.key(1.55, "neutre", false, 0, 1, true, J(250, 202, 190.8, 141.6, 90, "trois_doigts", 1))
        c.key(1.9, "neutre", false, 0, 0, true, J(250, 480.4, 190.8, 420, 90, "trois_doigts", 0))
        return c
    }

    private static func gesture28() -> LouChronology {   // n
        var c = LouChronology(key: "n", duration: 1.6, posed: 0.8, gesture: true)
        c.arm(.right, thumb: 1, size: 36, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(254, 452.32, 157.186, 420, 112, "deux_ecartes", 0))
        c.key(0.35, "langue_haut", false, 0, 0, true, J(254, 120, 157.186, 87.68, 112, "deux_ecartes", 1))
        c.key(1.25, "neutre", false, 0, 0, false, J(254, 120, 157.186, 87.68, 112, "deux_ecartes", 1))
        c.key(1.6, "neutre", false, 0, 0, true, J(254, 452.32, 157.186, 420, 112, "deux_ecartes", 0))
        return c
    }

    private static func gesture29() -> LouChronology {   // gn
        var c = LouChronology(key: "gn", duration: 1.95, posed: 0.35, gesture: true)
        c.arm(.right, thumb: 1, size: 40, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(250, 505.63, 203.252, 420, -174, "index", 0))
        c.key(0.35, "fond", false, 0, 0, true, J(250, 250, 203.252, 164.37, -174, "index", 1))
        c.key(0.55, "fond", false, 0, 0, true, J(242, 250, 187.252, 164.37, -174, "index", 1))
        c.key(0.85, "fond", false, 0, 0, true, J(258, 250, 219.252, 164.37, -174, "index", 1))
        c.key(1.15, "fond", false, 0, 0, true, J(242, 250, 187.252, 164.37, -174, "index", 1))
        c.key(1.45, "fond", false, 0, 0, true, J(258, 250, 219.252, 164.37, -174, "index", 1))
        c.key(1.6, "neutre", false, 0, 0, true, J(250, 250, 203.252, 164.37, -174, "index", 1))
        c.key(1.95, "neutre", false, 0, 0, true, J(250, 505.63, 203.252, 420, -174, "index", 0))
        return c
    }

    private static func gesture30() -> LouChronology {   // l
        var c = LouChronology(key: "l", duration: 1.45, posed: 0.75, gesture: true)
        c.arm(.right, thumb: -1, size: 40, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(214, 539.361, 171.346, 420, -92, "index", 0))
        c.key(0.35, "langue_haut", false, 0, 0, true, J(214, 342, 171.346, 244.639, -92, "index", 1))
        c.key(0.75, "langue_haut", false, 0, 0, true, J(214, 320, 171.346, 200.639, -92, "index", 1))
        c.key(1.1, "neutre", false, 0, 0, false, J(214, 320, 171.346, 200.639, -92, "index", 1))
        c.key(1.45, "neutre", false, 0, 0, true, J(214, 539.361, 171.346, 420, -92, "index", 0))
        return c
    }

    private static func gesture31() -> LouChronology {   // r
        var c = LouChronology(key: "r", duration: 1.6, posed: 0.8, gesture: true)
        c.arm(.right, thumb: 1, size: 40, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(252, 472.784, 190.071, 420, -164, "crochet", 0))
        c.key(0.35, "fond", false, 0, 0, true, J(252, 280, 190.071, 227.216, -164, "crochet", 1))
        c.key(1.25, "neutre", false, 0, 0, false, J(252, 280, 190.071, 227.216, -164, "crochet", 1))
        c.key(1.6, "neutre", false, 0, 0, true, J(252, 472.784, 190.071, 420, -164, "crochet", 0))
        return c
    }

    private static func gesture32() -> LouChronology {   // ill
        var c = LouChronology(key: "ill", duration: 1.6, posed: 1.1, gesture: true)
        c.arm(.right, thumb: 1, size: 40, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(250, 495.2, 225.2, 420, 180, "index", 0))
        c.key(0.35, "etiree", false, 0, 0, true, J(250, 250, 225.2, 174.8, 180, "index", 1))
        c.key(0.5, "etiree", false, 0, 0, false, J(250, 250, 225.2, 174.8, 180, "index", 1))
        c.key(0.5333, "etiree", false, 0, 0, false, J(250.196, 250, 225.592, 174.8, 180, "index", 1))
        c.key(0.5667, "etiree", false, 0, 0, false, J(250.755, 250, 226.71, 174.8, 180, "index", 1))
        c.key(0.6, "etiree", false, 0, 0, false, J(251.63, 250, 228.459, 174.8, 180, "index", 1))
        c.key(0.6333, "etiree", false, 0, 0, false, J(252.775, 250, 230.75, 174.8, 180, "index", 1))
        c.key(0.6667, "etiree", false, 0, 0, false, J(254.151, 250, 233.502, 174.8, 180, "index", 1))
        c.key(0.7, "etiree", false, 0, 0, false, J(255.704, 250, 236.607, 174.8, 180, "index", 1))
        c.key(0.7333, "etiree", false, 0, 0, false, J(257.392, 250, 239.984, 174.8, 180, "index", 1))
        c.key(0.7667, "etiree", false, 0, 0, false, J(259.176, 250, 243.552, 174.8, 180, "index", 1))
        c.key(0.8, "etiree", false, 0, 0, false, J(261, 250, 247.2, 174.8, 180, "index", 1))
        c.key(0.8333, "etiree", false, 0, 0, false, J(262.824, 250, 250.848, 174.8, 180, "index", 1))
        c.key(0.8667, "etiree", false, 0, 0, false, J(264.608, 250, 254.416, 174.8, 180, "index", 1))
        c.key(0.9, "etiree", false, 0, 0, false, J(266.296, 250, 257.793, 174.8, 180, "index", 1))
        c.key(0.9333, "etiree", false, 0, 0, false, J(267.849, 250, 260.898, 174.8, 180, "index", 1))
        c.key(0.9667, "etiree", false, 0, 0, false, J(269.225, 250, 263.65, 174.8, 180, "index", 1))
        c.key(1, "etiree", false, 0, 0, false, J(270.37, 250, 265.941, 174.8, 180, "index", 1))
        c.key(1.0333, "etiree", false, 0, 0, false, J(271.245, 250, 267.69, 174.8, 180, "index", 1))
        c.key(1.0667, "etiree", false, 0, 0, false, J(271.804, 250, 268.808, 174.8, 180, "index", 1))
        c.key(1.1, "etiree", false, 0, 0, false, J(272, 250, 269.2, 174.8, 180, "index", 1))
        c.key(1.25, "neutre", false, 0, 0, false, J(272, 250, 269.2, 174.8, 180, "index", 1))
        c.key(1.6, "neutre", false, 0, 0, true, J(272, 495.2, 269.2, 420, 180, "index", 0))
        return c
    }

    private static func mouthOnly00() -> LouChronology {   // ui
        var c = LouChronology(key: "ui", duration: 1, posed: 0.5, gesture: false)
        c.key(0, "neutre", false, 0, 0, false)
        c.key(0.2, "mi_ouverte", false, 0, 0, true)
        c.key(0.8, "neutre", false, 0, 0, true)
        c.key(1, "neutre", false, 0, 0, true)
        return c
    }
}
#endif
