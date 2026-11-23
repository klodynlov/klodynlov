// LouGestureData.swift — FICHIER GÉNÉRÉ par eveil/outils/gestes/generer.py : ne pas modifier à la main.
//
// Les chronologies des gestes animés de Lou (`eveil/outils/gestes/animation.py`) : une par son,
// du repos au repos. Clé : instant (s), bouche, gorge qui vibre, tête levée, table, segment adouci,
// puis un bras par `J(coude x, y, poignet x, y, direction de la main, forme, présence, côté du pouce,
// taille de la main)` (direction en degrés, déroulée d'une clé à l'autre). Une suite de sons est
// enchaînée en Swift (`LouChronology.chain`, comme `animation.enchainer`).

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
        var c = LouChronology(key: "a", duration: 1.7, posed: 0.85, gesture: true)
        c.arm(.right, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(250, 478, 224, 420, -86, "ouverte", 0, -1, 40))
        c.key(0.4, "grande", false, 0, 0, true, J(250, 240, 224, 182, -86, "ouverte", 1, -1, 40))
        c.key(1.3, "neutre", false, 0, 0, false, J(250, 240, 224, 182, -86, "ouverte", 1, -1, 40))
        c.key(1.7, "neutre", false, 0, 0, true, J(250, 478, 224, 420, -86, "ouverte", 0, -1, 40))
        return c
    }

    private static func gesture01() -> LouChronology {   // o
        var c = LouChronology(key: "o", duration: 1.7, posed: 0.85, gesture: true)
        c.arm(.right, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(236, 452, 202, 420, -100, "rond_o", 0, -1, 44))
        c.key(0.4, "ronde", false, 0, 0, true, J(236, 330, 202, 298, -100, "rond_o", 1, -1, 44))
        c.key(1.3, "neutre", false, 0, 0, false, J(236, 330, 202, 298, -100, "rond_o", 1, -1, 44))
        c.key(1.7, "neutre", false, 0, 0, true, J(236, 452, 202, 420, -100, "rond_o", 0, -1, 44))
        return c
    }

    private static func gesture02() -> LouChronology {   // ou
        var c = LouChronology(key: "ou", duration: 2.2, posed: 1.7, gesture: true)
        c.arm(.right, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(236, 452, 202, 420, -100, "rond_o", 0, -1, 44))
        c.key(0.4, "petite_ronde", false, 0, 0, true, J(236, 330, 202, 298, -100, "rond_o", 1, -1, 44))
        c.key(0.4333, "petite_ronde", false, 0, 0, false, J(236.003, 329.994, 202.006, 297.989, -100, "rond_o", 1, -1, 44))
        c.key(0.4667, "petite_ronde", false, 0, 0, false, J(236.024, 329.957, 202.047, 297.914, -100, "rond_o", 1, -1, 44))
        c.key(0.5, "petite_ronde", false, 0, 0, false, J(236.077, 329.861, 202.154, 297.721, -100, "rond_o", 1, -1, 44))
        c.key(0.5333, "petite_ronde", false, 0, 0, false, J(236.174, 329.683, 202.349, 297.366, -100, "rond_o", 1, -1, 44))
        c.key(0.5667, "petite_ronde", false, 0, 0, false, J(236.332, 329.408, 202.665, 296.816, -100, "rond_o", 1, -1, 44))
        c.key(0.6, "petite_ronde", false, 0, 0, false, J(236.558, 329.025, 203.117, 296.051, -100, "rond_o", 1, -1, 44))
        c.key(0.6333, "petite_ronde", false, 0, 0, false, J(236.862, 328.526, 203.723, 295.053, -100, "rond_o", 1, -1, 44))
        c.key(0.6667, "petite_ronde", false, 0, 0, false, J(237.247, 327.904, 204.495, 293.808, -100, "rond_o", 1, -1, 44))
        c.key(0.7, "petite_ronde", false, 0, 0, false, J(237.714, 327.159, 205.429, 292.318, -100, "rond_o", 1, -1, 44))
        c.key(0.7333, "petite_ronde", false, 0, 0, false, J(238.261, 326.29, 206.523, 290.58, -100, "rond_o", 1, -1, 44))
        c.key(0.7667, "petite_ronde", false, 0, 0, false, J(238.885, 325.295, 207.77, 288.589, -100, "rond_o", 1, -1, 44))
        c.key(0.8, "petite_ronde", false, 0, 0, false, J(239.573, 324.182, 209.145, 286.365, -100, "rond_o", 1, -1, 44))
        c.key(0.95, "petite_ronde", false, 0, 0, false, J(243.113, 317.836, 216.225, 273.672, -100, "deux_serres", 1, -1, 44))
        c.key(0.9667, "petite_ronde", false, 0, 0, false, J(243.501, 317.012, 217.001, 272.024, -100, "deux_serres", 1, -1, 44))
        c.key(1, "petite_ronde", false, 0, 0, false, J(244.225, 315.309, 218.45, 268.618, -100, "deux_serres", 1, -1, 44))
        c.key(1.0333, "petite_ronde", false, 0, 0, false, J(244.843, 313.534, 219.686, 265.067, -100, "deux_serres", 1, -1, 44))
        c.key(1.0431, "petite_ronde", false, 0, 0, false, J(245, 313, 220, 264, -100, "deux_serres", 1, -1, 44))
        c.key(1.0667, "petite_ronde", false, 0, 0, false, J(245.301, 311.695, 220.602, 261.389, -100, "deux_serres", 1, -1, 44))
        c.key(1.1, "petite_ronde", false, 0, 0, false, J(245.609, 309.84, 221.217, 257.68, -100, "deux_serres", 1, -1, 44))
        c.key(1.1333, "petite_ronde", false, 0, 0, false, J(245.812, 308.001, 221.624, 254.001, -100, "deux_serres", 1, -1, 44))
        c.key(1.1667, "petite_ronde", false, 0, 0, false, J(245.941, 306.198, 221.882, 250.396, -100, "deux_serres", 1, -1, 44))
        c.key(1.2, "petite_ronde", false, 0, 0, false, J(246.016, 304.465, 222.033, 246.93, -100, "deux_serres", 1, -1, 44))
        c.key(1.2333, "petite_ronde", false, 0, 0, false, J(246.054, 302.816, 222.108, 243.631, -100, "deux_serres", 1, -1, 44))
        c.key(1.25, "petite_ronde", false, 0, 0, false, J(246.062, 302.025, 222.123, 242.05, -100, "deux_serres", 1, -1, 44))
        c.key(1.4, "petite_ronde", false, 0, 0, false, J(246.002, 296.318, 222.003, 230.636, -100, "deux_ecartes", 1, -1, 44))
        c.key(1.4333, "petite_ronde", false, 0, 0, false, J(245.987, 295.439, 221.974, 228.878, -100, "deux_ecartes", 1, -1, 44))
        c.key(1.4667, "petite_ronde", false, 0, 0, false, J(245.979, 294.707, 221.958, 227.414, -100, "deux_ecartes", 1, -1, 44))
        c.key(1.5, "petite_ronde", false, 0, 0, false, J(245.977, 294.123, 221.954, 226.246, -100, "deux_ecartes", 1, -1, 44))
        c.key(1.5333, "petite_ronde", false, 0, 0, false, J(245.981, 293.678, 221.962, 225.357, -100, "deux_ecartes", 1, -1, 44))
        c.key(1.5667, "petite_ronde", false, 0, 0, false, J(245.987, 293.362, 221.975, 224.723, -100, "deux_ecartes", 1, -1, 44))
        c.key(1.6, "petite_ronde", false, 0, 0, false, J(245.994, 293.159, 221.989, 224.318, -100, "deux_ecartes", 1, -1, 44))
        c.key(1.6333, "petite_ronde", false, 0, 0, false, J(245.998, 293.049, 221.997, 224.098, -100, "deux_ecartes", 1, -1, 44))
        c.key(1.6667, "petite_ronde", false, 0, 0, false, J(246, 293.006, 222, 224.013, -100, "deux_ecartes", 1, -1, 44))
        c.key(1.7, "petite_ronde", false, 0, 0, false, J(246, 293, 222, 224, -100, "deux_ecartes", 1, -1, 44))
        c.key(1.8, "neutre", false, 0, 0, false, J(246, 293, 222, 224, -100, "deux_ecartes", 1, -1, 44))
        c.key(2.2, "neutre", false, 0, 0, true, J(246, 489, 222, 420, -100, "deux_ecartes", 0, -1, 44))
        return c
    }

    private static func gesture03() -> LouChronology {   // i
        var c = LouChronology(key: "i", duration: 1.7, posed: 0.85, gesture: true)
        c.arm(.right, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(226, 500, 212, 420, -92, "index", 0, -1, 40))
        c.key(0.4, "etiree", false, 0, 0, true, J(226, 300, 212, 220, -92, "index", 1, -1, 40))
        c.key(1.3, "neutre", false, 0, 0, false, J(226, 300, 212, 220, -92, "index", 1, -1, 40))
        c.key(1.7, "neutre", false, 0, 0, true, J(226, 500, 212, 420, -92, "index", 0, -1, 40))
        return c
    }

    private static func gesture04() -> LouChronology {   // u
        var c = LouChronology(key: "u", duration: 1.7, posed: 0.85, gesture: true)
        c.arm(.right, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(226, 500, 212, 420, -92, "deux_ecartes", 0, -1, 40))
        c.key(0.4, "petite_ronde", false, 0, 0, true, J(226, 300, 212, 220, -92, "deux_ecartes", 1, -1, 40))
        c.key(1.3, "neutre", false, 0, 0, false, J(226, 300, 212, 220, -92, "deux_ecartes", 1, -1, 40))
        c.key(1.7, "neutre", false, 0, 0, true, J(226, 500, 212, 420, -92, "deux_ecartes", 0, -1, 40))
        return c
    }

    private static func gesture05() -> LouChronology {   // é
        var c = LouChronology(key: "é", duration: 1.7, posed: 0.85, gesture: true)
        c.arm(.left, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(22, 478, 80, 420, -54, "plate", 0, 1, 36))
        c.key(0.4, "etiree", false, 0, 0, true, J(22, 170, 80, 112, -54, "plate", 1, 1, 36))
        c.key(1.3, "neutre", false, 0, 0, false, J(22, 170, 80, 112, -54, "plate", 1, 1, 36))
        c.key(1.7, "neutre", false, 0, 0, true, J(22, 478, 80, 420, -54, "plate", 0, 1, 36))
        return c
    }

    private static func gesture06() -> LouChronology {   // è
        var c = LouChronology(key: "è", duration: 1.7, posed: 0.85, gesture: true)
        c.arm(.right, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(250, 484, 176, 420, -128, "plate", 0, -1, 36))
        c.key(0.4, "mi_ouverte", false, 1.2, 0, true, J(250, 130, 176, 66, -128, "plate", 1, -1, 36))
        c.key(1.3, "neutre", false, 1.2, 0, false, J(250, 130, 176, 66, -128, "plate", 1, -1, 36))
        c.key(1.7, "neutre", false, 0, 0, true, J(250, 484, 176, 420, -128, "plate", 0, -1, 36))
        return c
    }

    private static func gesture07() -> LouChronology {   // eu
        var c = LouChronology(key: "eu", duration: 1.7, posed: 0.85, gesture: true)
        c.arm(.right, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(236, 452, 202, 420, -100, "croise", 0, -1, 44))
        c.key(0.4, "ronde", false, 0, 0, true, J(236, 330, 202, 298, -100, "croise", 1, -1, 44))
        c.key(1.3, "neutre", false, 0, 0, false, J(236, 330, 202, 298, -100, "croise", 1, -1, 44))
        c.key(1.7, "neutre", false, 0, 0, true, J(236, 452, 202, 420, -100, "croise", 0, -1, 44))
        return c
    }

    private static func gesture08() -> LouChronology {   // eu ouvert
        var c = LouChronology(key: "eu ouvert", duration: 1.7, posed: 0.85, gesture: true)
        c.arm(.right, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(236, 452, 202, 420, -100, "croise", 0, -1, 44))
        c.key(0.4, "ronde", false, 0, 0, true, J(236, 330, 202, 298, -100, "croise", 1, -1, 44))
        c.key(1.3, "neutre", false, 0, 0, false, J(236, 330, 202, 298, -100, "croise", 1, -1, 44))
        c.key(1.7, "neutre", false, 0, 0, true, J(236, 452, 202, 420, -100, "croise", 0, -1, 44))
        return c
    }

    private static func gesture09() -> LouChronology {   // e
        var c = LouChronology(key: "e", duration: 1.7, posed: 0.85, gesture: true)
        c.arm(.right, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(236, 452, 202, 420, -100, "croise", 0, -1, 44))
        c.key(0.4, "ronde", false, 0, 0, true, J(236, 330, 202, 298, -100, "croise", 1, -1, 44))
        c.key(1.3, "neutre", false, 0, 0, false, J(236, 330, 202, 298, -100, "croise", 1, -1, 44))
        c.key(1.7, "neutre", false, 0, 0, true, J(236, 452, 202, 420, -100, "croise", 0, -1, 44))
        return c
    }

    private static func gesture10() -> LouChronology {   // an
        var c = LouChronology(key: "an", duration: 1.7, posed: 0.85, gesture: true)
        c.arm(.right, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(250, 514.695, 196.727, 420, -158, "ouverte", 0, 1, 36))
        c.key(0.4, "grande", false, 0, 0, true, J(250, 240, 196.727, 145.305, -158, "ouverte", 1, 1, 36))
        c.key(1.3, "neutre", false, 0, 0, false, J(250, 240, 196.727, 145.305, -158, "ouverte", 1, 1, 36))
        c.key(1.7, "neutre", false, 0, 0, true, J(250, 514.695, 196.727, 420, -158, "ouverte", 0, 1, 36))
        return c
    }

    private static func gesture11() -> LouChronology {   // on
        var c = LouChronology(key: "on", duration: 1.7, posed: 0.85, gesture: true)
        c.arm(.right, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(240, 517.158, 189.007, 420, -132, "rond_o_tendu", 0, -1, 30))
        c.key(0.4, "ronde", false, 0, 0, true, J(240, 260, 189.007, 162.842, -132, "rond_o_tendu", 1, -1, 30))
        c.key(1.3, "neutre", false, 0, 0, false, J(240, 260, 189.007, 162.842, -132, "rond_o_tendu", 1, -1, 30))
        c.key(1.7, "neutre", false, 0, 0, true, J(240, 517.158, 189.007, 420, -132, "rond_o_tendu", 0, -1, 30))
        return c
    }

    private static func gesture12() -> LouChronology {   // in
        var c = LouChronology(key: "in", duration: 1.7, posed: 0.85, gesture: true)
        c.arm(.right, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(252, 502.477, 191.028, 420, -164, "index", 0, 1, 32))
        c.key(0.4, "mi_ouverte", false, 0, 0, true, J(252, 250, 191.028, 167.523, -164, "index", 1, 1, 32))
        c.key(1.3, "neutre", false, 0, 0, false, J(252, 250, 191.028, 167.523, -164, "index", 1, 1, 32))
        c.key(1.7, "neutre", false, 0, 0, true, J(252, 502.477, 191.028, 420, -164, "index", 0, 1, 32))
        return c
    }

    private static func gesture13() -> LouChronology {   // oi
        var c = LouChronology(key: "oi", duration: 1.65, posed: 0.8, gesture: true)
        c.arm(.right, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(236, 452, 202, 420, -100, "poing", 0, -1, 44))
        c.key(0.4, "ronde", false, 0, 0, true, J(236, 330, 202, 298, -100, "poing", 1, -1, 44))
        c.key(0.7, "ronde", false, 0, 0, false, J(236, 330, 202, 298, -100, "poing", 1, -1, 44))
        c.key(0.8, "ronde", false, 0, 0, true, J(236, 330, 202, 298, -100, "ouverte", 1, -1, 44))
        c.key(1.25, "neutre", false, 0, 0, false, J(236, 330, 202, 298, -100, "ouverte", 1, -1, 44))
        c.key(1.65, "neutre", false, 0, 0, true, J(236, 452, 202, 420, -100, "ouverte", 0, -1, 44))
        return c
    }

    private static func gesture14() -> LouChronology {   // oin
        var c = LouChronology(key: "oin", duration: 1.9, posed: 1.2, gesture: true)
        c.arm(.right, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(262, 480, 240, 420, -168, "bec_ferme", 0, -1, 40))
        c.key(0.4, "ronde", false, 0, 0, true, J(262, 330, 240, 270, -168, "bec_ferme", 1, -1, 40))
        c.key(0.65, "ronde", false, 0, 0, false, J(262, 330, 240, 270, -168, "bec_ferme", 1, -1, 40))
        c.key(0.8, "ronde", false, 0, 0, true, J(262, 330, 240, 270, -168, "bec_ouvert", 1, -1, 40))
        c.key(1.05, "ronde", false, 0, 0, false, J(262, 330, 240, 270, -168, "bec_ouvert", 1, -1, 40))
        c.key(1.2, "ronde", false, 0, 0, true, J(262, 330, 240, 270, -168, "bec_ferme", 1, -1, 40))
        c.key(1.5, "neutre", false, 0, 0, false, J(262, 330, 240, 270, -168, "bec_ferme", 1, -1, 40))
        c.key(1.9, "neutre", false, 0, 0, true, J(262, 480, 240, 420, -168, "bec_ferme", 0, -1, 40))
        return c
    }

    private static func gesture15() -> LouChronology {   // ch
        var c = LouChronology(key: "ch", duration: 1.9, posed: 0.95, gesture: true)
        c.arm(.right, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(200, 508, 130, 420, -90, "pince_ch", 0, -1, 40))
        c.key(0.4, "avancee", false, 0, 0, true, J(200, 320, 130, 232, -90, "pince_ch", 1, -1, 40))
        c.key(1.5, "neutre", false, 0, 0, false, J(200, 320, 130, 232, -90, "pince_ch", 1, -1, 40))
        c.key(1.9, "neutre", false, 0, 0, true, J(200, 508, 130, 420, -90, "pince_ch", 0, -1, 40))
        return c
    }

    private static func gesture16() -> LouChronology {   // s
        var c = LouChronology(key: "s", duration: 2.5, posed: 2, gesture: true)
        c.arm(.right, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(232, 490, 218, 420, -96, "index", 0, -1, 40))
        c.key(0.4, "etiree", false, 0, 0, true, J(254, 236, 242.05, 134.444, -74, "index", 1, -1, 40))
        c.key(0.4333, "etiree", false, 0, 0, false, J(254, 236, 242.037, 134.437, -74, "index", 1, -1, 40))
        c.key(0.4667, "etiree", false, 0, 0, false, J(254, 236, 241.951, 134.39, -74, "index", 1, -1, 40))
        c.key(0.5, "etiree", false, 0, 0, false, J(254, 236, 241.728, 134.269, -74, "index", 1, -1, 40))
        c.key(0.5333, "etiree", false, 0, 0, false, J(254, 236, 241.316, 134.035, -74, "index", 1, -1, 40))
        c.key(0.5667, "etiree", false, 0, 0, false, J(254, 236, 240.677, 133.644, -74, "index", 1, -1, 40))
        c.key(0.6, "etiree", false, 0, 0, false, J(254, 236, 239.784, 133.066, -74, "index", 1, -1, 40))
        c.key(0.6333, "etiree", false, 0, 0, false, J(254, 236, 238.609, 132.276, -74, "index", 1, -1, 40))
        c.key(0.6667, "etiree", false, 0, 0, false, J(254, 236, 237.124, 131.26, -74, "index", 1, -1, 40))
        c.key(0.7, "etiree", false, 0, 0, false, J(254, 236, 235.313, 130.024, -74, "index", 1, -1, 40))
        c.key(0.7333, "etiree", false, 0, 0, false, J(254, 236, 233.149, 128.581, -74, "index", 1, -1, 40))
        c.key(0.7667, "etiree", false, 0, 0, false, J(254, 236, 230.594, 126.965, -74, "index", 1, -1, 40))
        c.key(0.8, "etiree", false, 0, 0, false, J(254, 236, 227.627, 125.254, -74, "index", 1, -1, 40))
        c.key(0.8333, "etiree", false, 0, 0, false, J(254, 236, 224.173, 123.609, -74, "index", 1, -1, 40))
        c.key(0.8667, "etiree", false, 0, 0, false, J(254, 236, 220.114, 122.463, -74, "index", 1, -1, 40))
        c.key(0.8821, "etiree", false, 0, 0, false, J(254, 236, 218.05, 122.444, -74, "index", 1, -1, 40))
        c.key(0.9, "etiree", false, 0, 0, false, J(254, 236, 215.626, 123.1, -74, "index", 1, -1, 40))
        c.key(0.9333, "etiree", false, 0, 0, false, J(254, 236, 211.267, 125.385, -74, "index", 1, -1, 40))
        c.key(0.9667, "etiree", false, 0, 0, false, J(254, 236, 207.139, 128.647, -74, "index", 1, -1, 40))
        c.key(1, "etiree", false, 0, 0, false, J(254, 236, 203.403, 132.724, -74, "index", 1, -1, 40))
        c.key(1.0333, "etiree", false, 0, 0, false, J(254, 236, 200.559, 137.739, -74, "index", 1, -1, 40))
        c.key(1.0488, "etiree", false, 0, 0, false, J(254, 236, 200.05, 140.444, -74, "index", 1, -1, 40))
        c.key(1.0667, "etiree", false, 0, 0, false, J(254, 236, 200.809, 143.587, -74, "index", 1, -1, 40))
        c.key(1.1, "etiree", false, 0, 0, false, J(254, 236, 204.251, 148.69, -74, "index", 1, -1, 40))
        c.key(1.1333, "etiree", false, 0, 0, false, J(254, 236, 208.614, 153.244, -74, "index", 1, -1, 40))
        c.key(1.1667, "etiree", false, 0, 0, false, J(254, 236, 213.272, 157.658, -74, "index", 1, -1, 40))
        c.key(1.2, "etiree", false, 0, 0, false, J(254, 236, 217.832, 162.209, -74, "index", 1, -1, 40))
        c.key(1.2017, "etiree", false, 0, 0, false, J(254, 236, 218.05, 162.444, -74, "index", 1, -1, 40))
        c.key(1.2333, "etiree", false, 0, 0, false, J(254, 236, 222.553, 166.582, -74, "index", 1, -1, 40))
        c.key(1.2667, "etiree", false, 0, 0, false, J(254, 236, 227.639, 170.496, -74, "index", 1, -1, 40))
        c.key(1.3, "etiree", false, 0, 0, false, J(254, 236, 232.573, 174.425, -74, "index", 1, -1, 40))
        c.key(1.3333, "etiree", false, 0, 0, false, J(254, 236, 236.737, 178.961, -74, "index", 1, -1, 40))
        c.key(1.354, "etiree", false, 0, 0, false, J(254, 236, 238.05, 182.444, -74, "index", 1, -1, 40))
        c.key(1.3667, "etiree", false, 0, 0, false, J(254, 236, 237.931, 184.699, -74, "index", 1, -1, 40))
        c.key(1.4, "etiree", false, 0, 0, false, J(254, 236, 235.966, 190.118, -74, "index", 1, -1, 40))
        c.key(1.4333, "etiree", false, 0, 0, false, J(254, 236, 233.004, 194.79, -74, "index", 1, -1, 40))
        c.key(1.4667, "etiree", false, 0, 0, false, J(254, 236, 229.601, 198.804, -74, "index", 1, -1, 40))
        c.key(1.5, "etiree", false, 0, 0, false, J(254, 236, 225.943, 202.105, -74, "index", 1, -1, 40))
        c.key(1.5331, "etiree", false, 0, 0, false, J(254, 236, 222.05, 204.444, -74, "index", 1, -1, 40))
        c.key(1.5333, "etiree", false, 0, 0, false, J(254, 236, 222.02, 204.453, -74, "index", 1, -1, 40))
        c.key(1.5667, "etiree", false, 0, 0, false, J(254, 236, 217.856, 204.968, -74, "index", 1, -1, 40))
        c.key(1.6, "etiree", false, 0, 0, false, J(254, 236, 214.081, 204.371, -74, "index", 1, -1, 40))
        c.key(1.6333, "etiree", false, 0, 0, false, J(254, 236, 210.79, 203.423, -74, "index", 1, -1, 40))
        c.key(1.6667, "etiree", false, 0, 0, false, J(254, 236, 207.945, 202.403, -74, "index", 1, -1, 40))
        c.key(1.7, "etiree", false, 0, 0, false, J(254, 236, 205.53, 201.437, -74, "index", 1, -1, 40))
        c.key(1.7333, "etiree", false, 0, 0, false, J(254, 236, 203.509, 200.587, -74, "index", 1, -1, 40))
        c.key(1.7667, "etiree", false, 0, 0, false, J(254, 236, 201.853, 199.882, -74, "index", 1, -1, 40))
        c.key(1.8, "etiree", false, 0, 0, false, J(254, 236, 200.547, 199.337, -74, "index", 1, -1, 40))
        c.key(1.8333, "etiree", false, 0, 0, false, J(254, 236, 199.557, 198.946, -74, "index", 1, -1, 40))
        c.key(1.8667, "etiree", false, 0, 0, false, J(254, 236, 198.853, 198.691, -74, "index", 1, -1, 40))
        c.key(1.9, "etiree", false, 0, 0, false, J(254, 236, 198.402, 198.546, -74, "index", 1, -1, 40))
        c.key(1.9333, "etiree", false, 0, 0, false, J(254, 236, 198.158, 198.475, -74, "index", 1, -1, 40))
        c.key(1.9667, "etiree", false, 0, 0, false, J(254, 236, 198.064, 198.448, -74, "index", 1, -1, 40))
        c.key(2, "etiree", false, 0, 0, false, J(254, 236, 198.05, 198.444, -74, "index", 1, -1, 40))
        c.key(2.1, "neutre", false, 0, 0, false, J(254, 236, 198.05, 198.444, -74, "index", 1, -1, 40))
        c.key(2.5, "neutre", false, 0, 0, true, J(254, 457.556, 198.05, 420, -74, "index", 0, -1, 40))
        return c
    }

    private static func gesture17() -> LouChronology {   // z
        var c = LouChronology(key: "z", duration: 1.65, posed: 1.1, gesture: true)
        c.arm(.right, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(232, 490, 218, 420, -96, "index", 0, -1, 40))
        c.key(0.4, "etiree", true, 0, 0, true, J(254, 236, 200.05, 130.444, -74, "index", 1, -1, 40))
        c.key(0.4333, "etiree", true, 0, 0, false, J(254, 236, 200.246, 130.465, -74, "index", 1, -1, 40))
        c.key(0.4667, "etiree", true, 0, 0, false, J(254, 236, 201.512, 130.58, -74, "index", 1, -1, 40))
        c.key(0.5, "etiree", true, 0, 0, false, J(254, 236, 204.621, 130.705, -74, "index", 1, -1, 40))
        c.key(0.5333, "etiree", true, 0, 0, false, J(254, 236, 210.047, 130.776, -74, "index", 1, -1, 40))
        c.key(0.5667, "etiree", true, 0, 0, false, J(254, 236, 218.035, 130.884, -74, "index", 1, -1, 40))
        c.key(0.6, "etiree", true, 0, 0, false, J(254, 236, 228.512, 131.398, -74, "index", 1, -1, 40))
        c.key(0.6333, "etiree", true, 0, 0, false, J(254, 236, 240.823, 134.431, -74, "index", 1, -1, 40))
        c.key(0.6391, "etiree", true, 0, 0, false, J(254, 236, 242.05, 136.444, -74, "index", 1, -1, 40))
        c.key(0.6667, "etiree", true, 0, 0, false, J(254, 236, 234.302, 145.815, -74, "index", 1, -1, 40))
        c.key(0.7, "etiree", true, 0, 0, false, J(254, 236, 221.492, 155.868, -74, "index", 1, -1, 40))
        c.key(0.7333, "etiree", true, 0, 0, false, J(254, 236, 208.035, 166.601, -74, "index", 1, -1, 40))
        c.key(0.7524, "etiree", true, 0, 0, false, J(254, 236, 202.05, 174.444, -74, "index", 1, -1, 40))
        c.key(0.7667, "etiree", true, 0, 0, false, J(254, 236, 208.389, 177.458, -74, "index", 1, -1, 40))
        c.key(0.8, "etiree", true, 0, 0, false, J(254, 236, 225.596, 177.495, -74, "index", 1, -1, 40))
        c.key(0.8333, "etiree", true, 0, 0, false, J(254, 236, 241.793, 178.395, -74, "index", 1, -1, 40))
        c.key(0.8402, "etiree", true, 0, 0, false, J(254, 236, 244.05, 180.444, -74, "index", 1, -1, 40))
        c.key(0.8667, "etiree", true, 0, 0, false, J(254, 236, 237.644, 189.864, -74, "index", 1, -1, 40))
        c.key(0.9, "etiree", true, 0, 0, false, J(254, 236, 228.123, 198.439, -74, "index", 1, -1, 40))
        c.key(0.9333, "etiree", true, 0, 0, false, J(254, 236, 220.005, 205.086, -74, "index", 1, -1, 40))
        c.key(0.9667, "etiree", true, 0, 0, false, J(254, 236, 213.758, 210.064, -74, "index", 1, -1, 40))
        c.key(1, "etiree", true, 0, 0, false, J(254, 236, 209.526, 213.463, -74, "index", 1, -1, 40))
        c.key(1.0333, "etiree", true, 0, 0, false, J(254, 236, 207.143, 215.462, -74, "index", 1, -1, 40))
        c.key(1.0667, "etiree", true, 0, 0, false, J(254, 236, 206.196, 216.311, -74, "index", 1, -1, 40))
        c.key(1.1, "etiree", true, 0, 0, false, J(254, 236, 206.05, 216.444, -74, "index", 1, -1, 40))
        c.key(1.25, "neutre", false, 0, 0, false, J(254, 236, 206.05, 216.444, -74, "index", 1, -1, 40))
        c.key(1.65, "neutre", false, 0, 0, true, J(254, 439.556, 206.05, 420, -74, "index", 0, -1, 40))
        return c
    }

    private static func gesture18() -> LouChronology {   // j
        var c = LouChronology(key: "j", duration: 1.5, posed: 0.75, gesture: true)
        c.arm(.right, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(250, 484.583, 231.993, 420, -150, "index", 0, 1, 40))
        c.key(0.4, "avancee", true, 0, 0, true, J(265, 263, 261.993, 191.417, -150, "index", 1, 1, 40))
        c.key(0.75, "avancee", true, 0, 0, true, J(250, 270, 231.993, 205.417, -150, "index", 1, 1, 40))
        c.key(1.1, "neutre", false, 0, 0, false, J(250, 270, 231.993, 205.417, -150, "index", 1, 1, 40))
        c.key(1.5, "neutre", false, 0, 0, true, J(250, 484.583, 231.993, 420, -150, "index", 0, 1, 40))
        return c
    }

    private static func gesture19() -> LouChronology {   // f
        var c = LouChronology(key: "f", duration: 2, posed: 0.55, gesture: true)
        c.arm(.right, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(232, 482, 184, 420, -178, "plate", 0, 1, 40))
        c.key(0.4, "dents_levre", false, 0, 0, true, J(232, 320, 184, 258, -178, "plate", 1, 1, 40))
        c.key(0.7, "dents_levre", false, 0, 0, false, J(232, 320, 184, 258, -178, "plate", 1, 1, 40))
        c.key(0.7333, "dents_levre", false, 0, 0, false, J(232.038, 320, 184.076, 258, -178, "plate", 1, 1, 40))
        c.key(0.7667, "dents_levre", false, 0, 0, false, J(232.285, 320, 184.571, 258, -178, "plate", 1, 1, 40))
        c.key(0.8, "dents_levre", false, 0, 0, false, J(232.899, 320, 185.798, 258, -178, "plate", 1, 1, 40))
        c.key(0.8333, "dents_levre", false, 0, 0, false, J(233.986, 320, 187.973, 258, -178, "plate", 1, 1, 40))
        c.key(0.8667, "dents_levre", false, 0, 0, false, J(235.615, 320, 191.23, 258, -178, "plate", 1, 1, 40))
        c.key(0.9, "dents_levre", false, 0, 0, false, J(237.797, 320, 195.594, 258, -178, "plate", 1, 1, 40))
        c.key(0.9333, "dents_levre", false, 0, 0, false, J(240.522, 320, 201.044, 258, -178, "plate", 1, 1, 40))
        c.key(0.9667, "dents_levre", false, 0, 0, false, J(243.757, 320, 207.513, 258, -178, "plate", 1, 1, 40))
        c.key(1, "dents_levre", false, 0, 0, false, J(247.412, 320, 214.823, 258, -178, "plate", 1, 1, 40))
        c.key(1.0333, "dents_levre", false, 0, 0, false, J(251.407, 320, 222.813, 258, -178, "plate", 1, 1, 40))
        c.key(1.0667, "dents_levre", false, 0, 0, false, J(255.65, 320, 231.299, 258, -178, "plate", 1, 1, 40))
        c.key(1.1, "dents_levre", false, 0, 0, false, J(260, 320, 240, 258, -178, "plate", 1, 1, 40))
        c.key(1.1333, "dents_levre", false, 0, 0, false, J(264.35, 320, 248.701, 258, -178, "plate", 1, 1, 40))
        c.key(1.1667, "dents_levre", false, 0, 0, false, J(268.593, 320, 257.187, 258, -178, "plate", 1, 1, 40))
        c.key(1.2, "dents_levre", false, 0, 0, false, J(272.588, 320, 265.177, 258, -178, "plate", 1, 1, 40))
        c.key(1.2333, "dents_levre", false, 0, 0, false, J(276.243, 320, 272.487, 258, -178, "plate", 1, 1, 40))
        c.key(1.2667, "dents_levre", false, 0, 0, false, J(279.478, 320, 278.956, 258, -178, "plate", 1, 1, 40))
        c.key(1.3, "dents_levre", false, 0, 0, false, J(282.203, 320, 284.406, 258, -178, "plate", 1, 1, 40))
        c.key(1.3333, "dents_levre", false, 0, 0, false, J(284.385, 320, 288.77, 258, -178, "plate", 1, 1, 40))
        c.key(1.3667, "dents_levre", false, 0, 0, false, J(286.014, 320, 292.027, 258, -178, "plate", 1, 1, 40))
        c.key(1.4, "dents_levre", false, 0, 0, false, J(287.101, 320, 294.202, 258, -178, "plate", 1, 1, 40))
        c.key(1.4333, "dents_levre", false, 0, 0, false, J(287.715, 320, 295.429, 258, -178, "plate", 1, 1, 40))
        c.key(1.4667, "dents_levre", false, 0, 0, false, J(287.962, 320, 295.924, 258, -178, "plate", 1, 1, 40))
        c.key(1.5, "dents_levre", false, 0, 0, false, J(288, 320, 296, 258, -178, "plate", 1, 1, 40))
        c.key(1.6, "neutre", false, 0, 0, false, J(288, 320, 296, 258, -178, "plate", 1, 1, 40))
        c.key(2, "neutre", false, 0, 0, true, J(288, 482, 296, 420, -178, "plate", 0, 1, 40))
        return c
    }

    private static func gesture20() -> LouChronology {   // v
        var c = LouChronology(key: "v", duration: 1.7, posed: 0.85, gesture: true)
        c.arm(.left, behind: false)
        c.arm(.right, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(70, 452, 126, 420, -122, "plate", 0, 1, 36), J(190, 452, 134, 420, -58, "plate", 0, -1, 36))
        c.key(0.4, "dents_levre", true, 0, 0, true, J(70, 330, 126, 298, -122, "plate", 1, 1, 36), J(190, 330, 134, 298, -58, "plate", 1, -1, 36))
        c.key(1.3, "neutre", false, 0, 0, false, J(70, 330, 126, 298, -122, "plate", 1, 1, 36), J(190, 330, 134, 298, -58, "plate", 1, -1, 36))
        c.key(1.7, "neutre", false, 0, 0, true, J(70, 452, 126, 420, -122, "plate", 0, 1, 36), J(190, 452, 134, 420, -58, "plate", 0, -1, 36))
        return c
    }

    private static func gesture21() -> LouChronology {   // p
        var c = LouChronology(key: "p", duration: 1.68, posed: 0.88, gesture: true)
        c.arm(.right, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(228, 504, 214, 420, -92, "poing", 0, -1, 40))
        c.key(0.4, "fermee", false, 0, 0, true, J(228, 290, 214, 206, -92, "poing", 1, -1, 40))
        c.key(0.8, "mi_ouverte", false, 0, 0, false, J(228, 290, 214, 206, -92, "poing", 1, -1, 40))
        c.key(0.88, "mi_ouverte", false, 0, 0, true, J(228, 290, 214, 206, -92, "ouverte", 1, -1, 40))
        c.key(1.28, "neutre", false, 0, 0, false, J(228, 290, 214, 206, -92, "ouverte", 1, -1, 40))
        c.key(1.68, "neutre", false, 0, 0, true, J(228, 504, 214, 420, -92, "ouverte", 0, -1, 40))
        return c
    }

    private static func gesture22() -> LouChronology {   // b
        var c = LouChronology(key: "b", duration: 1.92, posed: 1.12, gesture: true)
        c.arm(.right, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(262, 450, 222, 420, -152, "mi_fermee", 0, 1, 36))
        c.key(0.4, "fermee", true, 0, 0, true, J(307, 322, 312, 284, -152, "mi_fermee", 1, 1, 36))
        c.key(0.4333, "fermee", true, 0, 0, false, J(306.877, 322.005, 311.754, 284.009, -152, "mi_fermee", 1, 1, 36))
        c.key(0.4667, "fermee", true, 0, 0, false, J(306.114, 322.027, 310.228, 284.053, -152, "mi_fermee", 1, 1, 36))
        c.key(0.5, "fermee", true, 0, 0, false, J(304.332, 322.04, 306.665, 284.079, -152, "mi_fermee", 1, 1, 36))
        c.key(0.5333, "fermee", true, 0, 0, false, J(301.39, 322.037, 300.78, 284.075, -152, "mi_fermee", 1, 1, 36))
        c.key(0.5667, "fermee", true, 0, 0, false, J(297.328, 322.075, 292.656, 284.151, -152, "mi_fermee", 1, 1, 36))
        c.key(0.6, "fermee", true, 0, 0, false, J(292.382, 322.277, 282.765, 284.554, -152, "mi_fermee", 1, 1, 36))
        c.key(0.6333, "fermee", true, 0, 0, false, J(286.881, 322.854, 271.762, 285.708, -152, "mi_fermee", 1, 1, 36))
        c.key(0.6385, "fermee", true, 0, 0, false, J(286, 323, 270, 286, -152, "mi_fermee", 1, 1, 36))
        c.key(0.6667, "fermee", true, 0, 0, false, J(281.259, 324.064, 260.519, 288.129, -152, "mi_fermee", 1, 1, 36))
        c.key(0.7, "fermee", true, 0, 0, false, J(275.933, 325.563, 249.866, 291.126, -152, "mi_fermee", 1, 1, 36))
        c.key(0.7333, "fermee", true, 0, 0, false, J(271.206, 327.033, 240.413, 294.067, -152, "mi_fermee", 1, 1, 36))
        c.key(0.7667, "fermee", true, 0, 0, false, J(267.342, 328.287, 232.685, 296.574, -152, "mi_fermee", 1, 1, 36))
        c.key(0.8, "fermee", true, 0, 0, false, J(264.546, 329.201, 227.091, 298.403, -152, "mi_fermee", 1, 1, 36))
        c.key(0.8333, "fermee", true, 0, 0, false, J(262.848, 329.742, 223.696, 299.485, -152, "mi_fermee", 1, 1, 36))
        c.key(0.8667, "fermee", true, 0, 0, false, J(262.118, 329.965, 222.235, 299.93, -152, "mi_fermee", 1, 1, 36))
        c.key(0.9, "fermee", true, 0, 0, false, J(262, 330, 222, 300, -152, "mi_fermee", 1, 1, 36))
        c.key(1.02, "mi_ouverte", true, 0, 0, false, J(262, 330, 222, 300, -152, "mi_fermee", 1, 1, 36))
        c.key(1.12, "mi_ouverte", true, 0, 0, true, J(262, 330, 222, 300, -152, "ouverte", 1, 1, 36))
        c.key(1.52, "neutre", false, 0, 0, false, J(262, 330, 222, 300, -152, "ouverte", 1, 1, 36))
        c.key(1.92, "neutre", false, 0, 0, true, J(262, 450, 222, 420, -152, "ouverte", 0, 1, 36))
        return c
    }

    private static func gesture23() -> LouChronology {   // t
        var c = LouChronology(key: "t", duration: 1.67, posed: 0.87, gesture: true)
        c.arm(.right, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(244, 482, 228, 420, -96, "pince_fermee", 0, -1, 40))
        c.key(0.4, "langue_haut", false, 0, 0, true, J(244, 330, 228, 268, -96, "pince_fermee", 1, -1, 40))
        c.key(0.75, "langue_haut", false, 0, 0, false, J(244, 330, 228, 268, -96, "pince_fermee", 1, -1, 40))
        c.key(0.87, "langue_haut", false, 0, 0, true, J(244, 330, 228, 268, -96, "pince_ouverte", 1, -1, 40))
        c.key(1.27, "neutre", false, 0, 0, false, J(244, 330, 228, 268, -96, "pince_ouverte", 1, -1, 40))
        c.key(1.67, "neutre", false, 0, 0, true, J(244, 482, 228, 420, -96, "pince_ouverte", 0, -1, 40))
        return c
    }

    private static func gesture24() -> LouChronology {   // d
        var c = LouChronology(key: "d", duration: 1.67, posed: 0.87, gesture: true)
        c.arm(.right, behind: false)
        c.arm(.left, behind: true)
        c.key(0, "neutre", false, 0, 0, false, J(244, 482, 228, 420, -96, "pince_fermee", 0, -1, 40), J(18, 394, 86, 420, 10, "poing", 0, 1, 40))
        c.key(0.4, "langue_haut", true, 0, 0, true, J(244, 330, 228, 268, -96, "pince_fermee", 1, -1, 40), J(18, 274, 86, 300, 10, "poing", 1, 1, 40))
        c.key(0.75, "langue_haut", true, 0, 0, false, J(244, 330, 228, 268, -96, "pince_fermee", 1, -1, 40), J(18, 274, 86, 300, 10, "poing", 1, 1, 40))
        c.key(0.87, "langue_haut", true, 0, 0, true, J(244, 330, 228, 268, -96, "pince_ouverte", 1, -1, 40), J(18, 274, 86, 300, 10, "poing", 1, 1, 40))
        c.key(1.27, "neutre", false, 0, 0, false, J(244, 330, 228, 268, -96, "pince_ouverte", 1, -1, 40), J(18, 274, 86, 300, 10, "poing", 1, 1, 40))
        c.key(1.67, "neutre", false, 0, 0, true, J(244, 482, 228, 420, -96, "pince_ouverte", 0, -1, 40), J(18, 394, 86, 420, 10, "poing", 0, 1, 40))
        return c
    }

    private static func gesture25() -> LouChronology {   // k
        var c = LouChronology(key: "k", duration: 1.4, posed: 0.6, gesture: true)
        c.arm(.right, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(250, 485.157, 224.428, 420, -172, "index", 0, 1, 40))
        c.key(0.4, "neutre", false, 0, 0, true, J(268, 245, 260.428, 174.843, -172, "index", 1, 1, 40))
        c.key(0.6, "fond", false, 0, 0, true, J(250, 250, 224.428, 184.843, -172, "index", 1, 1, 40))
        c.key(1, "neutre", false, 0, 0, false, J(250, 250, 224.428, 184.843, -172, "index", 1, 1, 40))
        c.key(1.4, "neutre", false, 0, 0, true, J(250, 485.157, 224.428, 420, -172, "index", 0, 1, 40))
        return c
    }

    private static func gesture26() -> LouChronology {   // g
        var c = LouChronology(key: "g", duration: 1.4, posed: 0.6, gesture: true)
        c.arm(.right, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(250, 520.856, 228.798, 420, -172, "pouce_index", 0, -1, 40))
        c.key(0.4, "neutre", false, 0, 0, true, J(267, 246, 262.798, 141.144, -172, "pouce_index", 1, -1, 40))
        c.key(0.6, "fond", true, 0, 0, true, J(250, 250, 228.798, 149.144, -172, "pouce_index", 1, -1, 40))
        c.key(1, "neutre", false, 0, 0, false, J(250, 250, 228.798, 149.144, -172, "pouce_index", 1, -1, 40))
        c.key(1.4, "neutre", false, 0, 0, true, J(250, 520.856, 228.798, 420, -172, "pouce_index", 0, -1, 40))
        return c
    }

    private static func gesture27() -> LouChronology {   // m
        var c = LouChronology(key: "m", duration: 2, posed: 1, gesture: true)
        c.arm(.right, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(250, 452.4, 190.8, 420, 90, "trois_doigts", 0, 1, 40))
        c.key(0.4, "neutre", false, 0, 1, true, J(250, 202, 190.8, 141.6, 90, "trois_doigts", 1, 1, 40))
        c.key(0.65, "fermee", false, 0, 1, true, J(250, 230, 190.8, 197.6, 90, "trois_doigts", 1, 1, 40))
        c.key(1.35, "neutre", false, 0, 1, false, J(250, 230, 190.8, 197.6, 90, "trois_doigts", 1, 1, 40))
        c.key(1.6, "neutre", false, 0, 1, true, J(250, 202, 190.8, 141.6, 90, "trois_doigts", 1, 1, 40))
        c.key(2, "neutre", false, 0, 0, true, J(250, 480.4, 190.8, 420, 90, "trois_doigts", 0, 1, 40))
        return c
    }

    private static func gesture28() -> LouChronology {   // n
        var c = LouChronology(key: "n", duration: 1.7, posed: 0.85, gesture: true)
        c.arm(.right, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(254, 452.32, 157.186, 420, 112, "deux_ecartes", 0, 1, 36))
        c.key(0.4, "langue_haut", false, 0, 0, true, J(254, 120, 157.186, 87.68, 112, "deux_ecartes", 1, 1, 36))
        c.key(1.3, "neutre", false, 0, 0, false, J(254, 120, 157.186, 87.68, 112, "deux_ecartes", 1, 1, 36))
        c.key(1.7, "neutre", false, 0, 0, true, J(254, 452.32, 157.186, 420, 112, "deux_ecartes", 0, 1, 36))
        return c
    }

    private static func gesture29() -> LouChronology {   // gn
        var c = LouChronology(key: "gn", duration: 2.05, posed: 0.4, gesture: true)
        c.arm(.right, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(250, 505.63, 203.252, 420, -174, "index", 0, 1, 40))
        c.key(0.4, "fond", false, 0, 0, true, J(250, 250, 203.252, 164.37, -174, "index", 1, 1, 40))
        c.key(0.6, "fond", false, 0, 0, true, J(242, 250, 187.252, 164.37, -174, "index", 1, 1, 40))
        c.key(0.9, "fond", false, 0, 0, true, J(258, 250, 219.252, 164.37, -174, "index", 1, 1, 40))
        c.key(1.2, "fond", false, 0, 0, true, J(242, 250, 187.252, 164.37, -174, "index", 1, 1, 40))
        c.key(1.5, "fond", false, 0, 0, true, J(258, 250, 219.252, 164.37, -174, "index", 1, 1, 40))
        c.key(1.65, "neutre", false, 0, 0, true, J(250, 250, 203.252, 164.37, -174, "index", 1, 1, 40))
        c.key(2.05, "neutre", false, 0, 0, true, J(250, 505.63, 203.252, 420, -174, "index", 0, 1, 40))
        return c
    }

    private static func gesture30() -> LouChronology {   // l
        var c = LouChronology(key: "l", duration: 1.55, posed: 0.8, gesture: true)
        c.arm(.right, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(214, 539.361, 171.346, 420, -92, "index", 0, -1, 40))
        c.key(0.4, "langue_haut", false, 0, 0, true, J(214, 342, 171.346, 244.639, -92, "index", 1, -1, 40))
        c.key(0.8, "langue_haut", false, 0, 0, true, J(214, 320, 171.346, 200.639, -92, "index", 1, -1, 40))
        c.key(1.15, "neutre", false, 0, 0, false, J(214, 320, 171.346, 200.639, -92, "index", 1, -1, 40))
        c.key(1.55, "neutre", false, 0, 0, true, J(214, 539.361, 171.346, 420, -92, "index", 0, -1, 40))
        return c
    }

    private static func gesture31() -> LouChronology {   // r
        var c = LouChronology(key: "r", duration: 1.7, posed: 0.85, gesture: true)
        c.arm(.right, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(252, 472.784, 190.071, 420, -164, "crochet", 0, 1, 40))
        c.key(0.4, "fond", false, 0, 0, true, J(252, 280, 190.071, 227.216, -164, "crochet", 1, 1, 40))
        c.key(1.3, "neutre", false, 0, 0, false, J(252, 280, 190.071, 227.216, -164, "crochet", 1, 1, 40))
        c.key(1.7, "neutre", false, 0, 0, true, J(252, 472.784, 190.071, 420, -164, "crochet", 0, 1, 40))
        return c
    }

    private static func gesture32() -> LouChronology {   // ill
        var c = LouChronology(key: "ill", duration: 1.7, posed: 1.15, gesture: true)
        c.arm(.right, behind: false)
        c.key(0, "neutre", false, 0, 0, false, J(250, 495.2, 225.2, 420, 180, "index", 0, 1, 40))
        c.key(0.4, "etiree", false, 0, 0, true, J(250, 250, 225.2, 174.8, 180, "index", 1, 1, 40))
        c.key(0.55, "etiree", false, 0, 0, false, J(250, 250, 225.2, 174.8, 180, "index", 1, 1, 40))
        c.key(0.5833, "etiree", false, 0, 0, false, J(250.035, 250, 225.269, 174.8, 180, "index", 1, 1, 40))
        c.key(0.6167, "etiree", false, 0, 0, false, J(250.254, 250, 225.708, 174.8, 180, "index", 1, 1, 40))
        c.key(0.65, "etiree", false, 0, 0, false, J(250.781, 250, 226.762, 174.8, 180, "index", 1, 1, 40))
        c.key(0.6833, "etiree", false, 0, 0, false, J(251.68, 250, 228.56, 174.8, 180, "index", 1, 1, 40))
        c.key(0.7167, "etiree", false, 0, 0, false, J(252.97, 250, 231.141, 174.8, 180, "index", 1, 1, 40))
        c.key(0.75, "etiree", false, 0, 0, false, J(254.617, 250, 234.435, 174.8, 180, "index", 1, 1, 40))
        c.key(0.7833, "etiree", false, 0, 0, false, J(256.563, 250, 238.327, 174.8, 180, "index", 1, 1, 40))
        c.key(0.8167, "etiree", false, 0, 0, false, J(258.729, 250, 242.659, 174.8, 180, "index", 1, 1, 40))
        c.key(0.85, "etiree", false, 0, 0, false, J(261, 250, 247.2, 174.8, 180, "index", 1, 1, 40))
        c.key(0.8833, "etiree", false, 0, 0, false, J(263.271, 250, 251.741, 174.8, 180, "index", 1, 1, 40))
        c.key(0.9167, "etiree", false, 0, 0, false, J(265.437, 250, 256.073, 174.8, 180, "index", 1, 1, 40))
        c.key(0.95, "etiree", false, 0, 0, false, J(267.383, 250, 259.965, 174.8, 180, "index", 1, 1, 40))
        c.key(0.9833, "etiree", false, 0, 0, false, J(269.03, 250, 263.259, 174.8, 180, "index", 1, 1, 40))
        c.key(1.0167, "etiree", false, 0, 0, false, J(270.32, 250, 265.84, 174.8, 180, "index", 1, 1, 40))
        c.key(1.05, "etiree", false, 0, 0, false, J(271.219, 250, 267.638, 174.8, 180, "index", 1, 1, 40))
        c.key(1.0833, "etiree", false, 0, 0, false, J(271.746, 250, 268.692, 174.8, 180, "index", 1, 1, 40))
        c.key(1.1167, "etiree", false, 0, 0, false, J(271.965, 250, 269.131, 174.8, 180, "index", 1, 1, 40))
        c.key(1.15, "etiree", false, 0, 0, false, J(272, 250, 269.2, 174.8, 180, "index", 1, 1, 40))
        c.key(1.3, "neutre", false, 0, 0, false, J(272, 250, 269.2, 174.8, 180, "index", 1, 1, 40))
        c.key(1.7, "neutre", false, 0, 0, true, J(272, 495.2, 269.2, 420, 180, "index", 0, 1, 40))
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
