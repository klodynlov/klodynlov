// PaperMode.swift — le mode papier : imprimer une page, la colorier aux vrais crayons, la
// photographier ; l'app redresse la photo et pose les vrais coups de crayon sur la page.
//
// Choix de l'utilisateur (28/09/2026) pour la suite de l'atelier : le mode « recommandé » du
// blueprint pour la motricité fine (docs/EVEIL.md § 6.2 : vrais crayons, vraie friction, vraie
// prise ; l'écran quelques secondes seulement). Algorithme de eveil/outils/papier (sa référence,
// testée sur des photos simulées : perspective, lumière chaude, grain, coin colorié en noir) :
//
// 1. La page imprimée (A4) : le dessin dans un carré, quatre repères — des carrés pleins noirs —
//    autour, dans la partie imprimable, le titre au-dessus (`PaperLayout`, `PaperPrint`).
// 2. La photo vient du scanner de documents d'iPadOS (feuille détectée, redressée, recadrée). On y
//    retrouve les repères : près de leur place attendue, la tache sombre la plus proche qui a
//    l'allure d'un carré plein (`PaperScan.markers`). Faute de repères, la photo est la page.
// 3. L'homographie repères → photo redresse le carré du dessin à la taille de la carte des zones.
// 4. Est-ce bien cette page ? La part des pixels de trait qui sont de l'encre (gris foncé presque
//    sans couleur) : ~0,9 pour la bonne page, ~0,2 pour une autre (sinon on cherche parmi toutes).
// 5. Les couleurs : balance des blancs d'après le papier ; un pixel est colorié s'il est coloré ou
//    sombre (crayon noir, marron) ; près d'un trait, seule une vraie couleur compte ; le reste est
//    transparent (les grains blancs du crayon se voient, comme sur la feuille). Les traits, l'app
//    les dessine par-dessus, nets. Puis le dessin prend vie (LivingDrawing.swift).
//
// Écarts assumés avec la référence : les centiles se lisent sur un histogramme (au niveau de gris
// près, sans trier un million de valeurs) ; les boucles par pixel passent par des pointeurs bruts
// (rapides même en Debug, comme ZoneMap).
//
// Rien n'est enregistré ni envoyé : la photo reste en mémoire le temps de la lire.

#if canImport(CoreGraphics) && canImport(CoreText)
import CoreGraphics
import CoreText
import Foundation

// MARK: - La page à imprimer

/// A4 portrait, en points (1 pt = 1/72 de pouce) ; mêmes nombres que eveil/outils/papier/mise_en_page.py.
enum PaperLayout {
    static let page = CGSize(width: 595.2756, height: 841.8898)
    /// Le carré du dessin.
    static let side: CGFloat = 480
    static let origin = CGPoint(x: (595.2756 - 480) / 2, y: 150)
    /// Un repère : un carré plein de ce côté, centré à `offset` du coin du dessin, vers l'extérieur.
    static let marker: CGFloat = 26
    static let offset: CGFloat = 26
    static let titleBaseline: CGFloat = 96
    static let titleSize: CGFloat = 34
    static let footerBaseline: CGFloat = 700
    /// Les imprimantes n'impriment pas tout au bord : rien d'utile à moins de 18 pt.
    static let printableMargin: CGFloat = 18

    /// Centres des repères en points : haut-gauche, haut-droit, bas-droit, bas-gauche.
    static var markers: [CGPoint] {
        let x0 = origin.x - offset, x1 = origin.x + side + offset
        let y0 = origin.y - offset, y1 = origin.y + side + offset
        return [CGPoint(x: x0, y: y0), CGPoint(x: x1, y: y0), CGPoint(x: x1, y: y1), CGPoint(x: x0, y: y1)]
    }

    /// Les mêmes centres dans le repère du dessin (0…1 sur le carré).
    static var unitMarkers: [CGPoint] {
        markers.map { CGPoint(x: ($0.x - origin.x) / side, y: ($0.y - origin.y) / side) }
    }
}

/// Le PDF d'une page à imprimer : titre, dessin au trait, repères, et une ligne pour l'adulte.
enum PaperPrint {
    static var ink: CGColor { CGColor(srgbRed: 0.18, green: 0.20, blue: 0.29, alpha: 1) }
    static var markerInk: CGColor { CGColor(srgbRed: 0.08, green: 0.08, blue: 0.09, alpha: 1) }

    static func pdf(for page: ColoringPage, locale: String) -> Data {
        let data = NSMutableData()
        var box = CGRect(origin: .zero, size: PaperLayout.page)
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let ctx = CGContext(consumer: consumer, mediaBox: &box, nil) else { return Data() }
        ctx.beginPDFPage(nil)
        // Repère de la page, y vers le bas ; le texte se redresse par sa propre matrice.
        ctx.translateBy(x: 0, y: PaperLayout.page.height)
        ctx.scaleBy(x: 1, y: -1)
        draw(page, locale: locale, in: ctx)
        ctx.endPDFPage()
        ctx.closePDF()
        return data as Data
    }

    /// La page dans un contexte au repère de la page (points, y vers le bas).
    static func draw(_ page: ColoringPage, locale: String, in ctx: CGContext) {
        ctx.saveGState()
        ctx.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
        text(page.title(locale: locale), size: PaperLayout.titleSize, baseline: PaperLayout.titleBaseline,
             bold: true, in: ctx)
        text(locale.hasPrefix("fr")
                ? "Colorie, puis photographie la page dans l'atelier : ton dessin prendra vie !"
                : "Color it, then take a photo of the page in the workshop: your picture will come alive!",
             size: 12, baseline: PaperLayout.footerBaseline, bold: false, in: ctx)
        // Le dessin, dans son carré.
        let art = page.lineArt
        ctx.saveGState()
        ctx.translateBy(x: PaperLayout.origin.x, y: PaperLayout.origin.y)
        ctx.scaleBy(x: PaperLayout.side, y: PaperLayout.side)
        ctx.setFillColor(ink)
        ctx.setStrokeColor(ink)
        if !art.ink.isEmpty {
            ctx.addPath(art.ink)
            ctx.fillPath()
        }
        ctx.setLineWidth(art.lineWidth)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.addPath(art.strokes)
        ctx.strokePath()
        ctx.restoreGState()
        // Les repères.
        ctx.setFillColor(markerInk)
        let s = PaperLayout.marker
        for c in PaperLayout.markers {
            ctx.fill(CGRect(x: c.x - s / 2, y: c.y - s / 2, width: s, height: s))
        }
        ctx.restoreGState()
    }

    /// Une ligne de texte centrée (repère y vers le bas, matrice de texte retournée).
    private static func text(_ string: String, size: CGFloat, baseline: CGFloat, bold: Bool, in ctx: CGContext) {
        let font = CTFontCreateUIFontForLanguage(bold ? .emphasizedSystem : .system, size, nil)
            ?? CTFontCreateWithName("Helvetica" as CFString, size, nil)
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): ink,
        ]
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: string, attributes: attributes)
                                                        as CFAttributedString)
        let width = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
        ctx.textPosition = CGPoint(x: max(PaperLayout.printableMargin, (PaperLayout.page.width - width) / 2),
                                   y: baseline)
        CTLineDraw(line, ctx)
    }
}

// MARK: - L'homographie

/// Transformation perspective du plan, par 4 correspondances (système 8 × 8, pivot de Gauss).
struct Homography {
    /// Ligne par ligne, h33 = 1.
    let m: [Double]

    init(_ m: [Double]) { self.m = m }

    init?(from src: [CGPoint], to dst: [CGPoint]) {
        guard src.count == 4, dst.count == 4 else { return nil }
        var a = [[Double]](repeating: [Double](repeating: 0, count: 9), count: 8)
        for k in 0..<4 {
            let x = Double(src[k].x), y = Double(src[k].y), u = Double(dst[k].x), v = Double(dst[k].y)
            a[2 * k] = [x, y, 1, 0, 0, 0, -x * u, -y * u, u]
            a[2 * k + 1] = [0, 0, 0, x, y, 1, -x * v, -y * v, v]
        }
        for c in 0..<8 {
            var p = c
            for r in c..<8 where abs(a[r][c]) > abs(a[p][c]) { p = r }
            guard abs(a[p][c]) > 1e-12 else { return nil }
            a.swapAt(c, p)
            for r in 0..<8 where r != c {
                let f = a[r][c] / a[c][c]
                if f == 0 { continue }
                for k in c..<9 { a[r][k] -= f * a[c][k] }
            }
        }
        m = (0..<8).map { a[$0][8] / a[$0][$0] } + [1]
    }

    func apply(_ p: CGPoint) -> CGPoint {
        let x = Double(p.x), y = Double(p.y)
        let w = m[6] * x + m[7] * y + m[8]
        return CGPoint(x: (m[0] * x + m[1] * y + m[2]) / w, y: (m[3] * x + m[4] * y + m[5]) / w)
    }

    var inverse: Homography? {
        let (a, b, c, d, e, f, g, h, i) = (m[0], m[1], m[2], m[3], m[4], m[5], m[6], m[7], m[8])
        let co = [e * i - f * h, c * h - b * i, b * f - c * e,
                  f * g - d * i, a * i - c * g, c * d - a * f,
                  d * h - e * g, b * g - a * h, a * e - b * d]
        let det = a * co[0] + b * co[3] + c * co[6]
        guard abs(det) > 1e-15, abs(co[8]) > 1e-15 else { return nil }
        return Homography(co.map { $0 / co[8] })
    }
}

// MARK: - La photo

/// Une photo à lire hors du fil principal : un CGImage est immuable (d'où le `@unchecked Sendable`).
struct PaperPhoto: @unchecked Sendable {
    let image: CGImage
}

/// Une image RGBA 8 bits en mémoire (octets R, G, B, A ; opaque).
struct RGBAImage {
    let width: Int
    let height: Int
    let pixels: [UInt32]

    init(width: Int, height: Int, pixels: [UInt32]) {
        self.width = width
        self.height = height
        self.pixels = pixels
    }

    /// Lit un CGImage, réduit si son grand côté dépasse `maxSide` (sur fond blanc).
    init?(_ image: CGImage, maxSide: Int = 2000) {
        guard image.width > 0, image.height > 0 else { return nil }
        let k = min(1, Double(maxSide) / Double(max(image.width, image.height)))
        let w = max(1, Int(Double(image.width) * k)), h = max(1, Int(Double(image.height) * k))
        var px = [UInt32](repeating: 0xFFFF_FFFF, count: w * h)
        let ok = px.withUnsafeMutableBytes { raw -> Bool in
            guard let space = CGColorSpace(name: CGColorSpace.sRGB),
                  let ctx = CGContext(data: raw.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                      space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            ctx.interpolationQuality = .high
            ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
            return true
        }
        guard ok else { return nil }
        self.init(width: w, height: h, pixels: px)
    }

    static func luma(_ v: UInt32) -> Double {
        0.299 * Double(v & 0xFF) + 0.587 * Double((v >> 8) & 0xFF) + 0.114 * Double((v >> 16) & 0xFF)
    }

    /// Couleur au point (x, y) en pixels (centre du pixel k en k + 0,5) ; blanc hors de l'image.
    func bilinear(_ x: Double, _ y: Double) -> UInt32 {
        pixels.withUnsafeBufferPointer { Self.sample($0, width, height, x, y) }
    }

    /// `bilinear` sur un tampon (la boucle du redressement).
    static func sample(_ p: UnsafeBufferPointer<UInt32>, _ width: Int, _ height: Int,
                       _ x: Double, _ y: Double) -> UInt32 {
        let sx = x - 0.5, sy = y - 0.5
        let fx0 = sx.rounded(.down), fy0 = sy.rounded(.down)
        guard fx0 >= -1, fy0 >= -1, fx0 < Double(width), fy0 < Double(height) else { return 0xFFFF_FFFF }
        let x0 = Int(fx0), y0 = Int(fy0)
        let ax = sx - fx0, ay = sy - fy0
        let xa = max(x0, 0), xb = min(x0 + 1, width - 1)
        let ya = max(y0, 0) * width, yb = min(y0 + 1, height - 1) * width
        let p00 = p[ya + xa], p10 = p[ya + xb], p01 = p[yb + xa], p11 = p[yb + xb]
        let w00 = (1 - ax) * (1 - ay), w10 = ax * (1 - ay), w01 = (1 - ax) * ay, w11 = ax * ay
        let r = w00 * Double(p00 & 0xFF) + w10 * Double(p10 & 0xFF)
            + w01 * Double(p01 & 0xFF) + w11 * Double(p11 & 0xFF)
        let g = w00 * Double((p00 >> 8) & 0xFF) + w10 * Double((p10 >> 8) & 0xFF)
            + w01 * Double((p01 >> 8) & 0xFF) + w11 * Double((p11 >> 8) & 0xFF)
        let b = w00 * Double((p00 >> 16) & 0xFF) + w10 * Double((p10 >> 16) & 0xFF)
            + w01 * Double((p01 >> 16) & 0xFF) + w11 * Double((p11 >> 16) & 0xFF)
        let rg = UInt32(min(255, r.rounded())) | UInt32(min(255, g.rounded())) << 8
        return rg | UInt32(min(255, b.rounded())) << 16 | 0xFF00_0000
    }

    /// Moyenne de blocs f × f.
    func reduced(_ f: Int) -> RGBAImage {
        guard f > 1 else { return self }
        let w = width / f, h = height / f
        var out = [UInt32](repeating: 0, count: w * h)
        let n = UInt32(f * f)
        let width = self.width
        pixels.withUnsafeBufferPointer { src in
            out.withUnsafeMutableBufferPointer { dst in
                for y in 0..<h {
                    for x in 0..<w {
                        var r: UInt32 = 0, g: UInt32 = 0, b: UInt32 = 0
                        for j in 0..<f {
                            let base = (y * f + j) * width + x * f
                            for k in 0..<f {
                                let v = src[base + k]
                                r += v & 0xFF
                                g += (v >> 8) & 0xFF
                                b += (v >> 16) & 0xFF
                            }
                        }
                        dst[y * w + x] = r / n | (g / n) << 8 | (b / n) << 16 | 0xFF00_0000
                    }
                }
            }
        }
        return RGBAImage(width: w, height: h, pixels: out)
    }
}

// MARK: - Lire une page coloriée

enum PaperScan {
    /// La photo est lue sur une version réduite à ~900 px de haut pour y chercher les repères.
    static let searchHeight = 900
    static let chroma = 45.0          // une couleur franche
    static let chromaNearLine = 70.0  // près d'un trait
    static let dark = 150.0           // crayon sombre (clarté après balance des blancs)
    static let nearLine = 0.006       // « près d'un trait » : 0,6 % du côté du dessin
    static let inkLightness = 0.4     // l'encre : moins de 40 % de la clarté du papier…
    static let inkChroma = 60.0       // … et presque sans couleur
    static let minimumMatch = 0.5     // sous ce seuil, ce n'est pas cette page
    /// Côté des cartes réduites qui servent à reconnaître une autre page.
    static let searchSide = 256

    /// Les centres des repères (haut-gauche, haut-droit, bas-droit, bas-gauche) en pixels, ou nil.
    ///
    /// Près de sa place attendue, la tache sombre la plus proche qui a l'allure d'un carré plein :
    /// sombre (moins de 45 % du papier, le 90e centile de la photo), boîte presque carrée remplie à
    /// plus de 80 % (une lettre, un œil rond, un trait ne le sont pas), de 0,4 à 2,5 fois le côté
    /// attendu. Un coin de dessin colorié tout noir pourrait passer ces tests : c'est pourquoi la
    /// plus PROCHE gagne (les repères sont hors du dessin).
    static func markers(in photo: RGBAImage) -> [CGPoint]? {
        let f = max(1, Int((Double(photo.height) / Double(searchHeight)).rounded(.toNearestOrEven)))
        let small = photo.reduced(f)
        let W = small.width, H = small.height
        guard W > 8, H > 8 else { return nil }
        let luma = small.pixels.map(RGBAImage.luma)
        let threshold = 0.45 * percentile(luma, 0.90)
        let darkMask = luma.map { $0 < threshold }
        let kx = Double(W) / Double(PaperLayout.page.width), ky = Double(H) / Double(PaperLayout.page.height)
        let side = Double(PaperLayout.marker) * (kx + ky) / 2
        let radius = 0.10 * Double(W)
        var seen = [Bool](repeating: false, count: W * H)
        var queue: [Int] = []
        var out: [CGPoint] = []
        for c in PaperLayout.markers {
            let ex = Double(c.x) * kx, ey = Double(c.y) * ky
            let x0 = max(0, Int(ex - radius)), x1 = min(W, Int(ex + radius) + 1)
            let y0 = max(0, Int(ey - radius)), y1 = min(H, Int(ey + radius) + 1)
            var best: (d: Double, x: Double, y: Double)?
            for y in y0..<max(y0, y1) {
                for x in x0..<max(x0, x1) {
                    let start = y * W + x
                    guard darkMask[start], !seen[start] else { continue }
                    // Une tache sombre : sa taille, sa boîte, son centre.
                    seen[start] = true
                    queue.removeAll(keepingCapacity: true)
                    queue.append(start)
                    var head = 0
                    var n = 0, sx = 0, sy = 0
                    var bx0 = x, by0 = y, bx1 = x, by1 = y
                    while head < queue.count {
                        let k = queue[head]
                        head += 1
                        let qx = k % W, qy = k / W
                        n += 1
                        sx += qx
                        sy += qy
                        bx0 = min(bx0, qx); bx1 = max(bx1, qx)
                        by0 = min(by0, qy); by1 = max(by1, qy)
                        if qx + 1 < W, darkMask[k + 1], !seen[k + 1] { seen[k + 1] = true; queue.append(k + 1) }
                        if qx > 0, darkMask[k - 1], !seen[k - 1] { seen[k - 1] = true; queue.append(k - 1) }
                        if qy + 1 < H, darkMask[k + W], !seen[k + W] { seen[k + W] = true; queue.append(k + W) }
                        if qy > 0, darkMask[k - W], !seen[k - W] { seen[k - W] = true; queue.append(k - W) }
                    }
                    let w = Double(bx1 - bx0 + 1), h = Double(by1 - by0 + 1)
                    guard (0.4 * side...2.5 * side).contains(w), (0.4 * side...2.5 * side).contains(h),
                          (0.6...(1 / 0.6)).contains(w / h), Double(n) >= 0.8 * w * h else { continue }
                    let mx = Double(sx) / Double(n) + 0.5, my = Double(sy) / Double(n) + 0.5
                    let d = (mx - ex) * (mx - ex) + (my - ey) * (my - ey)
                    if d <= radius * radius, d < (best?.d ?? .infinity) { best = (d, mx, my) }
                }
            }
            guard let best else { return nil }
            out.append(CGPoint(x: best.x * Double(f), y: best.y * Double(f)))
        }
        return out
    }

    /// Faute de repères (coin coupé, photo floue) : la photo est prise pour la page entière.
    static func pageMarkers(width: Int, height: Int) -> [CGPoint] {
        let kx = CGFloat(width) / PaperLayout.page.width, ky = CGFloat(height) / PaperLayout.page.height
        return PaperLayout.markers.map { CGPoint(x: $0.x * kx, y: $0.y * ky) }
    }

    /// Le carré du dessin (size × size, RGBA opaque) lu sur la photo.
    static func rectify(_ photo: RGBAImage, markers: [CGPoint], size: Int) -> [UInt32]? {
        guard size > 0, let h = Homography(from: PaperLayout.unitMarkers, to: markers) else { return nil }
        let (m0, m1, m2, m3, m4, m5, m6, m7, m8) = (h.m[0], h.m[1], h.m[2], h.m[3], h.m[4], h.m[5],
                                                    h.m[6], h.m[7], h.m[8])
        let n = Double(size), width = photo.width, height = photo.height
        var out = [UInt32](repeating: 0, count: size * size)
        photo.pixels.withUnsafeBufferPointer { src in
            out.withUnsafeMutableBufferPointer { dst in
                for y in 0..<size {
                    let v = (Double(y) + 0.5) / n
                    for x in 0..<size {
                        let u = (Double(x) + 0.5) / n
                        let w = m6 * u + m7 * v + m8
                        dst[y * size + x] = RGBAImage.sample(src, width, height,
                                                             (m0 * u + m1 * v + m2) / w, (m3 * u + m4 * v + m5) / w)
                    }
                }
            }
        }
        return out
    }

    /// Part des pixels de trait (loin du bord) qui sont de l'ENCRE sur le carré redressé : un gris
    /// foncé presque sans couleur (un ciel colorié en rouge, sombre lui aussi, n'en est pas).
    static func match(_ square: [UInt32], labels: [UInt16], size n: Int) -> Double {
        guard n > 4, square.count == n * n, labels.count == n * n else { return 0 }
        var ink = 0, total = 0
        square.withUnsafeBufferPointer { sq in
            labels.withUnsafeBufferPointer { lab in
                var zoneLuma: [Double] = []
                zoneLuma.reserveCapacity(n * n)
                for i in 0..<(n * n) where lab[i] != 0 { zoneLuma.append(RGBAImage.luma(sq[i])) }
                let paper = zoneLuma.isEmpty ? 255 : percentile(zoneLuma, 0.95)
                let m = max(2, n / 50)
                guard n > 2 * m else { return }
                for y in m..<(n - m) {
                    for x in m..<(n - m) {
                        let i = y * n + x
                        guard lab[i] == 0 else { continue }
                        total += 1
                        let v = sq[i]
                        let r = Double(v & 0xFF), g = Double((v >> 8) & 0xFF), b = Double((v >> 16) & 0xFF)
                        if 0.299 * r + 0.587 * g + 0.114 * b < inkLightness * paper,
                           max(r, g, b) - min(r, g, b) < inkChroma { ink += 1 }
                    }
                }
            }
        }
        return total > 0 ? Double(ink) / Double(total) : 0
    }

    /// Les coups de crayon (RGBA opaque ; 0 = papier ou trait), à la taille de la carte des zones.
    static func paint(_ square: [UInt32], map: ZoneMap) -> [UInt32] {
        let n = map.width
        guard map.width == map.height, square.count == n * n else { return [] }
        let near = nearLines(map.labels, size: n,
                             reach: max(1, Int((nearLine * Double(n)).rounded(.toNearestOrEven))))
        var out = [UInt32](repeating: 0, count: n * n)
        square.withUnsafeBufferPointer { sq in
            map.labels.withUnsafeBufferPointer { lab in
                // Le papier : la couleur moyenne des pixels de zone les plus clairs.
                var zoneLuma: [Double] = []
                zoneLuma.reserveCapacity(n * n)
                for i in 0..<(n * n) where lab[i] != 0 { zoneLuma.append(RGBAImage.luma(sq[i])) }
                guard !zoneLuma.isEmpty else { return }
                let top = percentile(zoneLuma, 0.95)
                var sr = 0.0, sg = 0.0, sb = 0.0, count = 0.0
                for i in 0..<(n * n) where lab[i] != 0 && RGBAImage.luma(sq[i]) >= top - 6 {
                    let v = sq[i]
                    sr += Double(v & 0xFF)
                    sg += Double((v >> 8) & 0xFF)
                    sb += Double((v >> 16) & 0xFF)
                    count += 1
                }
                func gain(_ sum: Double) -> Double { min(3, max(0.8, 255 / max(1, sum / max(1, count)))) }
                let gr = gain(sr), gg = gain(sg), gb = gain(sb)
                near.withUnsafeBufferPointer { nl in
                    out.withUnsafeMutableBufferPointer { o in
                        for i in 0..<(n * n) where lab[i] != 0 {
                            let v = sq[i]
                            let r = min(255, (Double(v & 0xFF) * gr).rounded())
                            let g = min(255, (Double((v >> 8) & 0xFF) * gg).rounded())
                            let b = min(255, (Double((v >> 16) & 0xFF) * gb).rounded())
                            let c = max(r, g, b) - min(r, g, b)
                            let painted = nl[i] ? c >= chromaNearLine
                                                : (c >= chroma || 0.299 * r + 0.587 * g + 0.114 * b <= dark)
                            if painted { o[i] = UInt32(r) | UInt32(g) << 8 | UInt32(b) << 16 | 0xFF00_0000 }
                        }
                    }
                }
            }
        }
        return out
    }

    /// Vrai à moins de `reach` pixels (4-connexité) d'un pixel de trait.
    static func nearLines(_ labels: [UInt16], size n: Int, reach: Int) -> [Bool] {
        var near = [Bool](repeating: false, count: n * n)
        var depth = [UInt16](repeating: 0, count: n * n)
        var queue: [Int32] = []
        queue.reserveCapacity(n * n)
        labels.withUnsafeBufferPointer { lab in
            near.withUnsafeMutableBufferPointer { nl in
                depth.withUnsafeMutableBufferPointer { dp in
                    for i in 0..<(n * n) where lab[i] == 0 {
                        nl[i] = true
                        queue.append(Int32(i))
                    }
                    var head = 0
                    while head < queue.count {
                        let i = Int(queue[head])
                        head += 1
                        let d = dp[i]
                        guard Int(d) < reach else { continue }
                        let x = i % n
                        if x + 1 < n, !nl[i + 1] { nl[i + 1] = true; dp[i + 1] = d + 1; queue.append(Int32(i + 1)) }
                        if x > 0, !nl[i - 1] { nl[i - 1] = true; dp[i - 1] = d + 1; queue.append(Int32(i - 1)) }
                        if i + n < n * n, !nl[i + n] { nl[i + n] = true; dp[i + n] = d + 1; queue.append(Int32(i + n)) }
                        if i >= n, !nl[i - n] { nl[i - n] = true; dp[i - n] = d + 1; queue.append(Int32(i - n)) }
                    }
                }
            }
        }
        return near
    }

    /// Le centile `q` (0…1) de valeurs 0…255, lu sur leur histogramme (au niveau de gris près).
    static func percentile(_ values: [Double], _ q: Double) -> Double {
        var histogram = [Int](repeating: 0, count: 256)
        for v in values { histogram[min(255, max(0, Int(v)))] += 1 }
        let target = q * Double(values.count)
        var s = 0
        for (k, n) in histogram.enumerated() {
            s += n
            if Double(s) >= target { return Double(k) }
        }
        return 255
    }

    // MARK: Tout

    /// Ce que dit une photo.
    enum Outcome {
        /// Les coups de crayon de cette page (à la taille de sa carte des zones).
        case painted([UInt32], match: Double)
        /// C'est une autre page de l'atelier (son indice dans `pages`) : sa carte, ses coups de crayon.
        case otherPage(Int, [UInt32], map: ZoneMap, match: Double)
        /// Ni cette page ni une autre : pas de page lisible.
        case unreadable
    }

    /// Lit une photo pour la page `index` de `pages` (sa carte `map`) ; si ce n'est pas elle, cherche
    /// la page photographiée parmi toutes (cartes réduites à `searchSide` px, puis la vraie carte).
    static func read(_ photo: CGImage, pages: [ColoringPage], index: Int, map: ZoneMap) -> Outcome {
        guard let image = RGBAImage(photo) else { return .unreadable }
        let marks = markers(in: image) ?? pageMarkers(width: image.width, height: image.height)
        guard let square = rectify(image, markers: marks, size: map.width) else { return .unreadable }
        let here = match(square, labels: map.labels, size: map.width)
        if here >= minimumMatch { return .painted(paint(square, map: map), match: here) }
        // Une autre page ? On compare en petit, puis on lit la meilleure en grand.
        guard let squareSmall = rectify(image, markers: marks, size: searchSide) else { return .unreadable }
        var best: (k: Int, score: Double)?
        for (k, page) in pages.enumerated() where k != index {
            let m = ZoneMap(lineArt: page.lineArt, size: searchSide)
            let s = match(squareSmall, labels: m.labels, size: searchSide)
            if s >= minimumMatch, s > (best?.score ?? 0) { best = (k, s) }
        }
        guard let best else { return .unreadable }
        let full = ZoneMap(lineArt: pages[best.k].lineArt, size: map.width)
        let score = match(square, labels: full.labels, size: full.width)
        guard score >= minimumMatch else { return .unreadable }
        return .otherPage(best.k, paint(square, map: full), map: full, match: score)
    }
}
#endif
