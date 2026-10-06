// LouGestureArt.swift — FICHIER GÉNÉRÉ par eveil/outils/gestes/generer.py : ne pas modifier à la main.
//
// Lou en grand (`eveil/outils/gestes/lou_portrait.py`) : les parties fixes en commandes absolues
// M, L, C, Z dans le cadre 260 × 300 ; couleurs fixes 0xRRGGBB ou jetons de peau ; `lift` = déplacement
// vertical par unité de tête levée. Les formes de main (`FORMES`) pour la main calculée en Swift.

#if canImport(SwiftUI)
import SwiftUI

extension LouSkin {
    /// Les cinq peaux de `PEAUX` (la palette du coloriage, puis la peau de Lou), dans le même ordre.
    public static let allCases: [LouSkin] = [
        LouSkin(id: "claire", hex: "#FCDCC0", french: "peau claire", english: "light skin"),
        LouSkin(id: "doree", hex: "#E4AC7A", french: "peau dorée", english: "golden skin"),
        LouSkin(id: "lou", hex: "#B8784E", french: "peau de Lou", english: "Lou's skin"),
        LouSkin(id: "brune", hex: "#A66C44", french: "peau brune", english: "brown skin"),
        LouSkin(id: "foncee", hex: "#623C26", french: "peau foncée", english: "dark skin"),
    ]
}

extension LouArt {
    static let frame = CGSize(width: 260, height: 300)
    static let shoulderRight = CGPoint(x: 200, y: 224)
    static let shoulderLeft = CGPoint(x: 60, y: 224)
    static let shirt: UInt32 = 0xFFC83D
    static let shirtShade: UInt32 = 0xE8A91F
    /// Déplacement vertical de la bouche par unité de tête levée.
    static let mouthLift: CGFloat = -2.4348
    static let mouthKeys: [String] = ["neutre", "fermee", "dents_levre", "avancee", "petite_ronde", "ronde", "etiree", "grande", "mi_ouverte", "langue_haut", "fond"]
    static let bust: LouShape = bustShape()
    static let head: LouShape = headShape()
    static let table: LouShape = tableShape()
    static let vibration: LouShape = vibrationShape()
    static let mouths: [String: LouShape] = [
        "neutre": mouthNeutre(),
        "fermee": mouthFermee(),
        "dents_levre": mouthDentsLevre(),
        "avancee": mouthAvancee(),
        "petite_ronde": mouthPetiteRonde(),
        "ronde": mouthRonde(),
        "etiree": mouthEtiree(),
        "grande": mouthGrande(),
        "mi_ouverte": mouthMiOuverte(),
        "langue_haut": mouthLangueHaut(),
        "fond": mouthFond(),
    ]

    private static func bustShape() -> LouShape {
        var s = LouShape()
        s.fill(.fixed(0xFFC83D), 0xFF, "M 82 196 L 178 196 C 210 196 236 222 236 254 L 236 298 C 236 330 210 356 178 356 L 82 356 C 50 356 24 330 24 298 L 24 254 C 24 222 50 196 82 196 Z")
        s.fill(.skin, 0xFF, "M 121 160 L 139 160 C 144.5 160 149 164.5 149 170 L 149 198 C 149 203.5 144.5 208 139 208 L 121 208 C 115.5 208 111 203.5 111 198 L 111 170 C 111 164.5 115.5 160 121 160 Z")
        s.fill(.shade, 0x60, "M 149 182 C 149 185.9 140.5 189 130 189 C 119.5 189 111 185.9 111 182 C 111 178.1 119.5 175 130 175 C 140.5 175 149 178.1 149 182 Z")
        s.stroke(.fixed(0xE8A91F), 0xFF, 5, "M 159 200.1 C 155.5 207.1 143.6 212 130 212 C 116.4 212 104.5 207.1 101 200.1")
        return s
    }

    private static func tableShape() -> LouShape {
        var s = LouShape()
        s.fill(.fixed(0xB07A4A), 0xFF, "M -10 262 L 270 262 L 270 322 L -10 322 Z")
        s.fill(.fixed(0xC8A280), 0xFF, "M -10 262 L 270 262 L 270 268 L -10 268 Z")
        return s
    }

    private static func vibrationShape() -> LouShape {
        var s = LouShape()
        s.stroke(.fixed(0x1E88E5), 0xFF, 3, "M 153 177.8 C 157 185.4 157 194.6 153 202.2")
        s.stroke(.fixed(0x1E88E5), 0xFF, 3, "M 107 202.2 C 103 194.6 103 185.4 107 177.8")
        s.stroke(.fixed(0x1E88E5), 0xFF, 2.6, "M 159.1 174.5 C 164.3 184.2 164.3 195.8 159.1 205.5")
        s.stroke(.fixed(0x1E88E5), 0xFF, 2.6, "M 100.9 205.5 C 95.7 195.8 95.7 184.2 100.9 174.5")
        s.stroke(.fixed(0x1E88E5), 0xFF, 2.2, "M 165.3 171.2 C 171.6 183 171.6 197 165.3 208.8")
        s.stroke(.fixed(0x1E88E5), 0xFF, 2.2, "M 94.7 208.8 C 88.4 197 88.4 183 94.7 171.2")
        return s
    }

    private static func headShape() -> LouShape {
        var s = LouShape()
        s.fill(.fixed(0x2B1D16), 0xFF, "M 101.6 134.9 C 101.6 147 91.8 156.8 79.7 156.8 C 67.6 156.8 57.8 147 57.8 134.9 C 57.8 122.8 67.6 113 79.7 113 C 91.8 113 101.6 122.8 101.6 134.9 Z")
        s.fill(.fixed(0x2B1D16), 0xFF, "M 98.6 114 C 98.6 126.1 88.7 135.9 76.6 135.9 C 64.5 135.9 54.7 126.1 54.7 114 C 54.7 101.9 64.5 92.1 76.6 92.1 C 88.7 92.1 98.6 101.9 98.6 114 Z")
        s.fill(.fixed(0x2B1D16), 0xFF, "M 105.5 93.9 C 105.5 106 95.7 115.8 83.6 115.8 C 71.5 115.8 61.7 106 61.7 93.9 C 61.7 81.8 71.5 72 83.6 72 C 95.7 72 105.5 81.8 105.5 93.9 Z")
        s.fill(.fixed(0x2B1D16), 0xFF, "M 121.2 78.4 C 121.2 90.5 111.4 100.3 99.3 100.3 C 87.2 100.3 77.4 90.5 77.4 78.4 C 77.4 66.3 87.2 56.5 99.3 56.5 C 111.4 56.5 121.2 66.3 121.2 78.4 Z")
        s.fill(.fixed(0x2B1D16), 0xFF, "M 142.6 70.3 C 142.6 82.4 132.8 92.2 120.7 92.2 C 108.6 92.2 98.8 82.4 98.8 70.3 C 98.8 58.2 108.6 48.4 120.7 48.4 C 132.8 48.4 142.6 58.2 142.6 70.3 Z")
        s.fill(.fixed(0x2B1D16), 0xFF, "M 165.8 71.2 C 165.8 83.3 156 93.1 143.9 93.1 C 131.8 93.1 122 83.3 122 71.2 C 122 59.1 131.8 49.3 143.9 49.3 C 156 49.3 165.8 59.1 165.8 71.2 Z")
        s.fill(.fixed(0x2B1D16), 0xFF, "M 186.3 81 C 186.3 93.1 176.5 102.9 164.4 102.9 C 152.3 102.9 142.5 93.1 142.5 81 C 142.5 68.9 152.3 59 164.4 59 C 176.5 59 186.3 68.9 186.3 81 Z")
        s.fill(.fixed(0x2B1D16), 0xFF, "M 200.5 97.7 C 200.5 109.8 190.6 119.6 178.5 119.6 C 166.4 119.6 156.6 109.8 156.6 97.7 C 156.6 85.6 166.4 75.8 178.5 75.8 C 190.6 75.8 200.5 85.6 200.5 97.7 Z")
        s.fill(.fixed(0x2B1D16), 0xFF, "M 205.5 118.3 C 205.5 130.4 195.7 140.2 183.6 140.2 C 171.5 140.2 161.7 130.4 161.7 118.3 C 161.7 106.2 171.5 96.3 183.6 96.3 C 195.7 96.3 205.5 106.2 205.5 118.3 Z")
        s.fill(.skin, 0xFF, "M 88.4 132.9 C 88.4 140.3 82.4 146.3 75 146.3 C 67.6 146.3 61.6 140.3 61.6 132.9 C 61.6 125.5 67.6 119.5 75 119.5 C 82.4 119.5 88.4 125.5 88.4 132.9 Z")
        s.fill(.shade, 0x70, "M 79.3 132.9 C 79.3 136.4 76.5 139.2 73 139.2 C 69.5 139.2 66.7 136.4 66.7 132.9 C 66.7 129.4 69.5 126.5 73 126.5 C 76.5 126.5 79.3 129.4 79.3 132.9 Z")
        s.fill(.skin, 0xFF, "M 198.4 132.9 C 198.4 140.3 192.4 146.3 185 146.3 C 177.6 146.3 171.6 140.3 171.6 132.9 C 171.6 125.5 177.6 119.5 185 119.5 C 192.4 119.5 198.4 125.5 198.4 132.9 Z")
        s.fill(.shade, 0x70, "M 193.3 132.9 C 193.3 136.4 190.5 139.2 187 139.2 C 183.5 139.2 180.7 136.4 180.7 132.9 C 180.7 129.4 183.5 126.5 187 126.5 C 190.5 126.5 193.3 129.4 193.3 132.9 Z")
        s.fill(.skin, 0xFF, "M 186 128 C 186 158.9 160.9 184 130 184 C 99.1 184 74 158.9 74 128 C 74 97.1 99.1 72 130 72 C 160.9 72 186 97.1 186 128 Z")
        s.fill(.fixed(0x2B1D16), 0xFF, "M 111.7 93.2 C 111.7 103.3 103.6 111.4 93.5 111.4 C 83.4 111.4 75.2 103.3 75.2 93.2 C 75.2 83.1 83.4 74.9 93.5 74.9 C 103.6 74.9 111.7 83.1 111.7 93.2 Z")
        s.fill(.fixed(0x2B1D16), 0xFF, "M 136.1 88.8 C 136.1 98.9 127.9 107.1 117.8 107.1 C 107.7 107.1 99.6 98.9 99.6 88.8 C 99.6 78.7 107.7 70.5 117.8 70.5 C 127.9 70.5 136.1 78.7 136.1 88.8 Z")
        s.fill(.fixed(0x2B1D16), 0xFF, "M 160.4 88.8 C 160.4 98.9 152.3 107.1 142.2 107.1 C 132.1 107.1 123.9 98.9 123.9 88.8 C 123.9 78.7 132.1 70.5 142.2 70.5 C 152.3 70.5 160.4 78.7 160.4 88.8 Z")
        s.fill(.fixed(0x2B1D16), 0xFF, "M 184.8 93.2 C 184.8 103.3 176.6 111.4 166.5 111.4 C 156.4 111.4 148.3 103.3 148.3 93.2 C 148.3 83.1 156.4 74.9 166.5 74.9 C 176.6 74.9 184.8 83.1 184.8 93.2 Z")
        s.fill(.fixed(0x292B3D), 0xFF, "M 117 131.7 C 117 136.7 113.6 140.9 109.3 140.9 C 105 140.9 101.6 136.7 101.6 131.7 C 101.6 126.6 105 122.4 109.3 122.4 C 113.6 122.4 117 126.6 117 131.7 Z", lift: -2.4348)
        s.fill(.fixed(0xFFFFFF), 0xFF, "M 109.7 128.2 C 109.7 129.9 108.3 131.3 106.5 131.3 C 104.8 131.3 103.4 129.9 103.4 128.2 C 103.4 126.4 104.8 125 106.5 125 C 108.3 125 109.7 126.4 109.7 128.2 Z", lift: -4.5181)
        s.fill(.fixed(0xFA8599), 0x80, "M 105.7 148.7 C 105.7 154.1 101.3 158.4 95.9 158.4 C 90.5 158.4 86.2 154.1 86.2 148.7 C 86.2 143.3 90.5 139 95.9 139 C 101.3 139 105.7 143.3 105.7 148.7 Z", lift: -2.4348)
        s.fill(.fixed(0x292B3D), 0xFF, "M 158.4 131.7 C 158.4 136.7 155 140.9 150.7 140.9 C 146.4 140.9 143 136.7 143 131.7 C 143 126.6 146.4 122.4 150.7 122.4 C 155 122.4 158.4 126.6 158.4 131.7 Z", lift: -2.4348)
        s.fill(.fixed(0xFFFFFF), 0xFF, "M 151.1 128.2 C 151.1 129.9 149.7 131.3 147.9 131.3 C 146.2 131.3 144.8 129.9 144.8 128.2 C 144.8 126.4 146.2 125 147.9 125 C 149.7 125 151.1 126.4 151.1 128.2 Z", lift: -4.5181)
        s.fill(.fixed(0xFA8599), 0x80, "M 173.8 148.7 C 173.8 154.1 169.5 158.4 164.1 158.4 C 158.7 158.4 154.3 154.1 154.3 148.7 C 154.3 143.3 158.7 139 164.1 139 C 169.5 139 173.8 143.3 173.8 148.7 Z", lift: -2.4348)
        s.fill(.shade, 0xB0, "M 136 143.1 C 136 145.4 133.3 147.2 130 147.2 C 126.7 147.2 124 145.4 124 143.1 C 124 140.8 126.7 139 130 139 C 133.3 139 136 140.8 136 143.1 Z", lift: -2.4348)
        return s
    }

    private static func mouthNeutre() -> LouShape {
        var s = LouShape()
        s.stroke(.lips, 0xFF, 3.4, "M 119 157.7 C 120.8 158.4 126.3 162.2 130 162.2 C 133.7 162.2 139.2 158.4 141 157.7")
        return s
    }

    private static func mouthFermee() -> LouShape {
        var s = LouShape()
        s.fill(.lips, 0xFF, "M 143 158.7 C 143 162.1 137.2 164.9 130 164.9 C 122.8 164.9 117 162.1 117 158.7 C 117 155.3 122.8 152.5 130 152.5 C 137.2 152.5 143 155.3 143 158.7 Z")
        s.stroke(.fixed(0x4A1424), 0xFF, 2, "M 118 159.2 C 120 159 126 158.2 130 158.2 C 134 158.2 140 159 142 159.2")
        return s
    }

    private static func mouthDentsLevre() -> LouShape {
        var s = LouShape()
        s.fill(.lips, 0xFF, "M 144 160.7 C 144 164.8 137.7 168.2 130 168.2 C 122.3 168.2 116 164.8 116 160.7 C 116 156.5 122.3 153.2 130 153.2 C 137.7 153.2 144 156.5 144 160.7 Z")
        s.fill(.fixed(0x4A1424), 0xFF, "M 141 158.2 C 141 160.2 136.1 161.8 130 161.8 C 123.9 161.8 119 160.2 119 158.2 C 119 156.2 123.9 154.6 130 154.6 C 136.1 154.6 141 156.2 141 158.2 Z")
        s.fill(.fixed(0xFFFFFF), 0xFF, "M 123 155.5 L 137 155.5 C 138.1 155.5 139 156.4 139 157.5 L 139 159.7 C 139 160.8 138.1 161.7 137 161.7 L 123 161.7 C 121.9 161.7 121 160.8 121 159.7 L 121 157.5 C 121 156.4 121.9 155.5 123 155.5 Z")
        s.stroke(.fixed(0xB4B5BB), 0xFF, 0.8, "M 130 155.7 L 130 161.5")
        s.fill(.lips, 0xFF, "M 121.7 150.2 L 138.3 150.2 C 139.8 150.2 141 151.4 141 152.9 L 141 153 C 141 154.5 139.8 155.7 138.3 155.7 L 121.7 155.7 C 120.2 155.7 119 154.5 119 153 L 119 152.9 C 119 151.4 120.2 150.2 121.7 150.2 Z")
        return s
    }

    private static func mouthAvancee() -> LouShape {
        var s = LouShape()
        s.fill(.lips, 0xFF, "M 143 158.7 C 143 165.3 137.2 170.7 130 170.7 C 122.8 170.7 117 165.3 117 158.7 C 117 152.1 122.8 146.7 130 146.7 C 137.2 146.7 143 152.1 143 158.7 Z")
        s.fill(.fixed(0x4A1424), 0xFF, "M 137.5 158.7 C 137.5 162.3 134.1 165.2 130 165.2 C 125.9 165.2 122.5 162.3 122.5 158.7 C 122.5 155.1 125.9 152.2 130 152.2 C 134.1 152.2 137.5 155.1 137.5 158.7 Z")
        s.fill(.fixed(0xFFFFFF), 0xFF, "M 125.4 154.5 L 134.6 154.5 C 135.4 154.5 136 155.1 136 155.9 L 136 156.7 C 136 157.5 135.4 158.1 134.6 158.1 L 125.4 158.1 C 124.6 158.1 124 157.5 124 156.7 L 124 155.9 C 124 155.1 124.6 154.5 125.4 154.5 Z")
        s.fill(.fixed(0xFFFFFF), 0xFF, "M 125.9 159.6 L 134.1 159.6 C 134.9 159.6 135.5 160.2 135.5 161 L 135.5 161.4 C 135.5 162.2 134.9 162.8 134.1 162.8 L 125.9 162.8 C 125.1 162.8 124.5 162.2 124.5 161.4 L 124.5 161 C 124.5 160.2 125.1 159.6 125.9 159.6 Z")
        s.stroke(.lipsInk, 0xFF, 1, "M 119.2 155.1 C 120.8 150.9 125.2 148.2 130 148.2 C 134.8 148.2 139.2 150.9 140.8 155.1")
        return s
    }

    private static func mouthPetiteRonde() -> LouShape {
        var s = LouShape()
        s.fill(.lips, 0xFF, "M 139.7 158.7 C 139.7 164.6 135.4 169.4 130 169.4 C 124.6 169.4 120.3 164.6 120.3 158.7 C 120.3 152.8 124.6 148 130 148 C 135.4 148 139.7 152.8 139.7 158.7 Z")
        s.fill(.fixed(0x4A1424), 0xFF, "M 134.2 158.7 C 134.2 161.6 132.3 163.9 130 163.9 C 127.7 163.9 125.8 161.6 125.8 158.7 C 125.8 155.8 127.7 153.5 130 153.5 C 132.3 153.5 134.2 155.8 134.2 158.7 Z")
        return s
    }

    private static func mouthRonde() -> LouShape {
        var s = LouShape()
        s.fill(.lips, 0xFF, "M 142.4 158.7 C 142.4 166.7 136.8 173.3 130 173.3 C 123.2 173.3 117.6 166.7 117.6 158.7 C 117.6 150.6 123.2 144.1 130 144.1 C 136.8 144.1 142.4 150.6 142.4 158.7 Z")
        s.fill(.fixed(0x4A1424), 0xFF, "M 137.8 158.7 C 137.8 164.2 134.3 168.7 130 168.7 C 125.7 168.7 122.2 164.2 122.2 158.7 C 122.2 153.2 125.7 148.7 130 148.7 C 134.3 148.7 137.8 153.2 137.8 158.7 Z")
        s.fill(.fixed(0xF58CA0), 0xFF, "M 135.6 165.9 C 135.6 167.8 133.1 169.3 130 169.3 C 126.9 169.3 124.4 167.8 124.4 165.9 C 124.4 164 126.9 162.5 130 162.5 C 133.1 162.5 135.6 164 135.6 165.9 Z")
        return s
    }

    private static func mouthEtiree() -> LouShape {
        var s = LouShape()
        s.fill(.lips, 0xFF, "M 149 158.7 C 149 162.3 140.5 165.2 130 165.2 C 119.5 165.2 111 162.3 111 158.7 C 111 155.1 119.5 152.2 130 152.2 C 140.5 152.2 149 155.1 149 158.7 Z")
        s.fill(.fixed(0x4A1424), 0xFF, "M 146 158.7 C 146 161 138.8 162.9 130 162.9 C 121.2 162.9 114 161 114 158.7 C 114 156.4 121.2 154.5 130 154.5 C 138.8 154.5 146 156.4 146 158.7 Z")
        s.fill(.fixed(0xFFFFFF), 0xFF, "M 114.2 158.1 L 114.2 157.9 L 114.5 157.6 L 115 157.2 L 115.5 156.9 L 116.1 156.6 L 116.9 156.3 L 117.7 156 L 118.7 155.7 L 119.7 155.5 L 120.8 155.2 L 122 155 L 123.2 154.9 L 124.5 154.7 L 125.9 154.6 L 127.2 154.5 L 128.6 154.5 L 130 154.5 L 131.4 154.5 L 132.8 154.5 L 134.1 154.6 L 135.5 154.7 L 136.8 154.9 L 138 155 L 139.2 155.2 L 140.3 155.5 L 141.3 155.7 L 142.3 156 L 143.1 156.3 L 143.9 156.6 L 144.5 156.9 L 145 157.2 L 145.5 157.6 L 145.8 157.9 L 145.8 158.1 Z")
        s.fill(.fixed(0xFFFFFF), 0xFF, "M 145.5 159.7 L 145.5 159.8 L 145 160.1 L 144.5 160.5 L 143.9 160.8 L 143.1 161.1 L 142.3 161.4 L 141.3 161.6 L 140.3 161.9 L 139.2 162.1 L 138 162.3 L 136.8 162.5 L 135.5 162.6 L 134.1 162.7 L 132.8 162.8 L 131.4 162.9 L 130 162.9 L 128.6 162.9 L 127.2 162.8 L 125.9 162.7 L 124.5 162.6 L 123.2 162.5 L 122 162.3 L 120.8 162.1 L 119.7 161.9 L 118.7 161.6 L 117.7 161.4 L 116.9 161.1 L 116.1 160.8 L 115.5 160.5 L 115 160.1 L 114.5 159.8 L 114.5 159.7 Z")
        return s
    }

    private static func mouthGrande() -> LouShape {
        var s = LouShape()
        s.fill(.lips, 0xFF, "M 145.6 162.7 C 145.6 173 138.6 181.3 130 181.3 C 121.4 181.3 114.4 173 114.4 162.7 C 114.4 152.4 121.4 144.1 130 144.1 C 138.6 144.1 145.6 152.4 145.6 162.7 Z")
        s.fill(.fixed(0x4A1424), 0xFF, "M 142 162.7 C 142 171 136.6 177.7 130 177.7 C 123.4 177.7 118 171 118 162.7 C 118 154.4 123.4 147.7 130 147.7 C 136.6 147.7 142 154.4 142 162.7 Z")
        s.fill(.fixed(0xF58CA0), 0xFF, "M 138.6 173.2 C 138.6 176.3 134.8 178.8 130 178.8 C 125.2 178.8 121.4 176.3 121.4 173.2 C 121.4 170.1 125.2 167.6 130 167.6 C 134.8 167.6 138.6 170.1 138.6 173.2 Z")
        s.fill(.fixed(0xFFFFFF), 0xFF, "M 122.4 151.1 L 123.1 150.4 L 124 149.7 L 124.9 149.1 L 125.9 148.6 L 126.9 148.2 L 127.9 147.9 L 129 147.7 L 130 147.7 L 131 147.7 L 132.1 147.9 L 133.1 148.2 L 134.1 148.6 L 135.1 149.1 L 136 149.7 L 136.9 150.4 L 137.6 151.1 Z")
        return s
    }

    private static func mouthMiOuverte() -> LouShape {
        var s = LouShape()
        s.fill(.lips, 0xFF, "M 144.9 159.7 C 144.9 165.7 138.2 170.6 130 170.6 C 121.8 170.6 115.1 165.7 115.1 159.7 C 115.1 153.7 121.8 148.8 130 148.8 C 138.2 148.8 144.9 153.7 144.9 159.7 Z")
        s.fill(.fixed(0x4A1424), 0xFF, "M 141.5 159.7 C 141.5 163.8 136.4 167.2 130 167.2 C 123.6 167.2 118.5 163.8 118.5 159.7 C 118.5 155.5 123.6 152.2 130 152.2 C 136.4 152.2 141.5 155.5 141.5 159.7 Z")
        s.fill(.fixed(0xF58CA0), 0xFF, "M 138.3 164.6 C 138.3 166.4 134.6 167.8 130 167.8 C 125.4 167.8 121.7 166.4 121.7 164.6 C 121.7 162.8 125.4 161.3 130 161.3 C 134.6 161.3 138.3 162.8 138.3 164.6 Z")
        s.fill(.fixed(0xFFFFFF), 0xFF, "M 121.3 154.8 L 121.9 154.4 L 122.6 153.9 L 123.4 153.5 L 124.2 153.2 L 125.1 152.9 L 126.1 152.6 L 127 152.4 L 128 152.3 L 129 152.2 L 130 152.2 L 131 152.2 L 132 152.3 L 133 152.4 L 133.9 152.6 L 134.9 152.9 L 135.8 153.2 L 136.6 153.5 L 137.4 153.9 L 138.1 154.4 L 138.7 154.8 Z")
        return s
    }

    private static func mouthLangueHaut() -> LouShape {
        var s = LouShape()
        s.fill(.lips, 0xFF, "M 144.4 159.7 C 144.4 166 138 171.1 130 171.1 C 122 171.1 115.6 166 115.6 159.7 C 115.6 153.4 122 148.3 130 148.3 C 138 148.3 144.4 153.4 144.4 159.7 Z")
        s.fill(.fixed(0x4A1424), 0xFF, "M 141 159.7 C 141 164.1 136.1 167.7 130 167.7 C 123.9 167.7 119 164.1 119 159.7 C 119 155.3 123.9 151.7 130 151.7 C 136.1 151.7 141 155.3 141 159.7 Z")
        s.fill(.fixed(0xF58CA0), 0xFF, "M 121.8 164.1 C 121.2 162.7 125.3 160.4 126.7 158.9 C 128.1 157.3 128.9 154.7 130 154.7 C 131.1 154.7 131.9 157.3 133.3 158.9 C 134.7 160.4 138.8 162.7 138.2 164.1 C 137.7 165.4 132.8 167 130 167 C 127.2 167 122.3 165.4 121.8 164.1 Z")
        s.stroke(.fixed(0xB96275), 0xFF, 1.2, "M 130 157.3 L 130 163.7")
        s.fill(.fixed(0xFFFFFF), 0xFF, "M 122.1 154.1 L 122.2 154 L 122.9 153.5 L 123.7 153.1 L 124.5 152.8 L 125.4 152.4 L 126.2 152.2 L 127.2 152 L 128.1 151.8 L 129 151.7 L 130 151.7 L 131 151.7 L 131.9 151.8 L 132.8 152 L 133.8 152.2 L 134.6 152.4 L 135.5 152.8 L 136.3 153.1 L 137.1 153.5 L 137.8 154 L 137.9 154.1 Z")
        return s
    }

    private static func mouthFond() -> LouShape {
        var s = LouShape()
        s.fill(.lips, 0xFF, "M 143.4 159.7 C 143.4 165.4 137.4 170.1 130 170.1 C 122.6 170.1 116.6 165.4 116.6 159.7 C 116.6 153.9 122.6 149.3 130 149.3 C 137.4 149.3 143.4 153.9 143.4 159.7 Z")
        s.fill(.fixed(0x4A1424), 0xFF, "M 140 159.7 C 140 163.5 135.5 166.7 130 166.7 C 124.5 166.7 120 163.5 120 159.7 C 120 155.8 124.5 152.7 130 152.7 C 135.5 152.7 140 155.8 140 159.7 Z")
        s.fill(.fixed(0xFFFFFF), 0xFF, "M 122.5 155.1 L 122.9 154.7 L 123.6 154.3 L 124.3 153.9 L 125 153.6 L 125.8 153.3 L 126.6 153.1 L 127.4 152.9 L 128.3 152.8 L 129.1 152.7 L 130 152.7 L 130.9 152.7 L 131.7 152.8 L 132.6 152.9 L 133.4 153.1 L 134.2 153.3 L 135 153.6 L 135.7 153.9 L 136.4 154.3 L 137.1 154.7 L 137.5 155.1 Z")
        s.fill(.fixed(0x974A5C), 0xFF, "M 136 164.1 C 136 165.2 133.3 166.1 130 166.1 C 126.7 166.1 124 165.2 124 164.1 C 124 163 126.7 162.1 130 162.1 C 133.3 162.1 136 163 136 164.1 Z")
        return s
    }
}

extension LouHandModel {
    static let palmLength: CGFloat = 40
    static let samples = 10
    static let base: [LouFinger: CGPoint] = [
        .index: CGPoint(x: 0.97, y: 0.37),
        .middle: CGPoint(x: 1, y: 0.12),
        .ring: CGPoint(x: 0.97, y: -0.13),
        .little: CGPoint(x: 0.89, y: -0.36),
        .thumb: CGPoint(x: 0.32, y: 0.44),
    ]
    static let length: [LouFinger: CGFloat] = [
        .index: 0.86,
        .middle: 0.95,
        .ring: 0.88,
        .little: 0.7,
        .thumb: 0.8,
    ]
    static let width: [LouFinger: CGFloat] = [
        .index: 0.29,
        .middle: 0.3,
        .ring: 0.285,
        .little: 0.25,
        .thumb: 0.32,
    ]
    static let phalanges: [CGFloat] = [0.46, 0.3, 0.24]
    static let palm: [CGPoint] = [CGPoint(x: -0.02, y: 0.3), CGPoint(x: 0.3, y: 0.5), CGPoint(x: 0.8, y: 0.5), CGPoint(x: 1.02, y: 0.3), CGPoint(x: 1.03, y: -0.2), CGPoint(x: 0.92, y: -0.47), CGPoint(x: 0.45, y: -0.46), CGPoint(x: -0.02, y: -0.3)]
    static let foldedThumb: [CGPoint] = [CGPoint(x: 0.32, y: 0.44), CGPoint(x: 0.55, y: 0.4), CGPoint(x: 0.74, y: 0.18), CGPoint(x: 0.78, y: -0.06)]
    static let forms: [String: LouHandForm] = [
        "ouverte": form00(),
        "plate": form01(),
        "poing": form02(),
        "index": form03(),
        "deux_serres": form04(),
        "deux_ecartes": form05(),
        "rond_o": form06(),
        "rond_o_tendu": form07(),
        "croise": form08(),
        "pince_fermee": form09(),
        "pince_ouverte": form10(),
        "bec_ferme": form11(),
        "bec_ouvert": form12(),
        "trois_doigts": form13(),
        "crochet": form14(),
        "mi_fermee": form15(),
        "pouce_index": form16(),
        "pince_ch": form17(),
    ]

    private static func form00() -> LouHandForm {   // ouverte
        LouHandForm(index: .straight(14, []),
                    middle: .straight(3, []),
                    ring: .straight(-8, []),
                    little: .straight(-19, []),
                    thumb: .straight(52, [-10]),
                    front: [])
    }

    private static func form01() -> LouHandForm {   // plate
        LouHandForm(index: .straight(2, []),
                    middle: .straight(0, []),
                    ring: .straight(-2, []),
                    little: .straight(-4, []),
                    thumb: .straight(20, [-6]),
                    front: [])
    }

    private static func form02() -> LouHandForm {   // poing
        LouHandForm(index: .folded,
                    middle: .folded,
                    ring: .folded,
                    little: .folded,
                    thumb: .folded,
                    front: [])
    }

    private static func form03() -> LouHandForm {   // index
        LouHandForm(index: .straight(0, []),
                    middle: .folded,
                    ring: .folded,
                    little: .folded,
                    thumb: .folded,
                    front: [])
    }

    private static func form04() -> LouHandForm {   // deux_serres
        LouHandForm(index: .straight(4, []),
                    middle: .straight(-2, []),
                    ring: .folded,
                    little: .folded,
                    thumb: .folded,
                    front: [])
    }

    private static func form05() -> LouHandForm {   // deux_ecartes
        LouHandForm(index: .straight(17, []),
                    middle: .straight(-10, []),
                    ring: .folded,
                    little: .folded,
                    thumb: .folded,
                    front: [])
    }

    private static func form06() -> LouHandForm {   // rond_o
        LouHandForm(index: .path([CGPoint(x: 0.97, y: 0.37), CGPoint(x: 1.0325, y: 0.4073), CGPoint(x: 1.1922, y: 0.3268), CGPoint(x: 1.3707, y: 0.3385), CGPoint(x: 1.5185, y: 0.4392), CGPoint(x: 1.5948, y: 0.601), CGPoint(x: 1.5785, y: 0.7791), CGPoint(x: 1.474, y: 0.9242), CGPoint(x: 1.3103, y: 0.9963), CGPoint(x: 1.1326, y: 0.9752)]),
                    middle: .folded,
                    ring: .folded,
                    little: .folded,
                    thumb: .path([CGPoint(x: 0.32, y: 0.44), CGPoint(x: 0.62, y: 0.72), CGPoint(x: 0.9, y: 0.92), CGPoint(x: 1.06, y: 0.98), CGPoint(x: 1.16, y: 0.98)]),
                    front: [])
    }

    private static func form07() -> LouHandForm {   // rond_o_tendu
        LouHandForm(index: .path([CGPoint(x: 0.97, y: 0.37), CGPoint(x: 1.0325, y: 0.4073), CGPoint(x: 1.1922, y: 0.3268), CGPoint(x: 1.3707, y: 0.3385), CGPoint(x: 1.5185, y: 0.4392), CGPoint(x: 1.5948, y: 0.601), CGPoint(x: 1.5785, y: 0.7791), CGPoint(x: 1.474, y: 0.9242), CGPoint(x: 1.3103, y: 0.9963), CGPoint(x: 1.1326, y: 0.9752)]),
                    middle: .straight(-2, []),
                    ring: .straight(-9, []),
                    little: .straight(-17, []),
                    thumb: .path([CGPoint(x: 0.32, y: 0.44), CGPoint(x: 0.62, y: 0.72), CGPoint(x: 0.9, y: 0.92), CGPoint(x: 1.06, y: 0.98), CGPoint(x: 1.16, y: 0.98)]),
                    front: [])
    }

    private static func form08() -> LouHandForm {   // croise
        LouHandForm(index: .path([CGPoint(x: 0.97, y: 0.37), CGPoint(x: 1.18, y: 0.52), CGPoint(x: 1.42, y: 0.8), CGPoint(x: 1.62, y: 1.02)]),
                    middle: .folded,
                    ring: .folded,
                    little: .folded,
                    thumb: .path([CGPoint(x: 0.32, y: 0.44), CGPoint(x: 0.78, y: 0.62), CGPoint(x: 1.18, y: 0.52), CGPoint(x: 1.56, y: 0.3)]),
                    front: [.thumb, .index])
    }

    private static func form09() -> LouHandForm {   // pince_fermee
        LouHandForm(index: .path([CGPoint(x: 0.97, y: 0.37), CGPoint(x: 1.22, y: 0.4), CGPoint(x: 1.4, y: 0.56), CGPoint(x: 1.42, y: 0.7)]),
                    middle: .folded,
                    ring: .folded,
                    little: .folded,
                    thumb: .path([CGPoint(x: 0.32, y: 0.44), CGPoint(x: 0.62, y: 0.68), CGPoint(x: 1.02, y: 0.8), CGPoint(x: 1.36, y: 0.74)]),
                    front: [])
    }

    private static func form10() -> LouHandForm {   // pince_ouverte
        LouHandForm(index: .path([CGPoint(x: 0.97, y: 0.37), CGPoint(x: 1.26, y: 0.36), CGPoint(x: 1.52, y: 0.44), CGPoint(x: 1.68, y: 0.56)]),
                    middle: .folded,
                    ring: .folded,
                    little: .folded,
                    thumb: .path([CGPoint(x: 0.32, y: 0.44), CGPoint(x: 0.6, y: 0.78), CGPoint(x: 0.92, y: 1.02), CGPoint(x: 1.1, y: 1.14)]),
                    front: [])
    }

    private static func form11() -> LouHandForm {   // bec_ferme
        LouHandForm(index: .straight(-2, []),
                    middle: .straight(-5, []),
                    ring: .folded,
                    little: .folded,
                    thumb: .path([CGPoint(x: 0.32, y: 0.44), CGPoint(x: 0.78, y: 0.66), CGPoint(x: 1.34, y: 0.62), CGPoint(x: 1.78, y: 0.4)]),
                    front: [.index, .middle, .thumb])
    }

    private static func form12() -> LouHandForm {   // bec_ouvert
        LouHandForm(index: .straight(-14, []),
                    middle: .straight(-17, []),
                    ring: .folded,
                    little: .folded,
                    thumb: .path([CGPoint(x: 0.32, y: 0.44), CGPoint(x: 0.74, y: 0.74), CGPoint(x: 1.22, y: 0.92), CGPoint(x: 1.58, y: 1.02)]),
                    front: [])
    }

    private static func form13() -> LouHandForm {   // trois_doigts
        LouHandForm(index: .path([CGPoint(x: 0.97, y: 0.37), CGPoint(x: 1.3, y: 0.36), CGPoint(x: 1.64, y: 0.3)]),
                    middle: .path([CGPoint(x: 1, y: 0.12), CGPoint(x: 1.34, y: 0.08), CGPoint(x: 1.66, y: 0.02)]),
                    ring: .folded,
                    little: .folded,
                    thumb: .path([CGPoint(x: 0.32, y: 0.44), CGPoint(x: 0.82, y: 0.7), CGPoint(x: 1.3, y: 0.66), CGPoint(x: 1.62, y: 0.52)]),
                    front: [])
    }

    private static func form14() -> LouHandForm {   // crochet
        LouHandForm(index: .straight(4, [80, 75]),
                    middle: .folded,
                    ring: .folded,
                    little: .folded,
                    thumb: .folded,
                    front: [])
    }

    private static func form15() -> LouHandForm {   // mi_fermee
        LouHandForm(index: .straight(16, [38, 40]),
                    middle: .straight(9, [38, 40]),
                    ring: .straight(1, [38, 40]),
                    little: .straight(-7, [38, 40]),
                    thumb: .straight(78, [-40, -30]),
                    front: [])
    }

    private static func form16() -> LouHandForm {   // pouce_index
        LouHandForm(index: .straight(4, []),
                    middle: .folded,
                    ring: .folded,
                    little: .folded,
                    thumb: .straight(78, [-4]),
                    front: [])
    }

    private static func form17() -> LouHandForm {   // pince_ch
        LouHandForm(index: .path([CGPoint(x: 0.97, y: 0.37), CGPoint(x: 1.16, y: 0.06), CGPoint(x: 1.44, y: -0.44), CGPoint(x: 1.74, y: -0.72)]),
                    middle: .folded,
                    ring: .folded,
                    little: .folded,
                    thumb: .path([CGPoint(x: 0.32, y: 0.44), CGPoint(x: 0.8, y: 0.78), CGPoint(x: 1.3, y: 0.9), CGPoint(x: 1.74, y: 0.8)]),
                    front: [.thumb, .index])
    }
}
#endif
