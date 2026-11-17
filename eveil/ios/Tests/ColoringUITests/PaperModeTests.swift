// PaperModeTests.swift — le mode papier : la page imprimée, l'homographie, et des photos simulées.
//
// Même scénario que eveil/outils/papier/test_papier.py : la page imprimée (ici le VRAI PDF, rendu
// en pixels), coloriée « au crayon » (une grande zone sur deux, 15 % de grains blancs), puis
// photographiée de travers, sous une lumière chaude qui baisse vers les bords, avec du bruit.
// Tout est déterministe (grain et bruit viennent d'un hachage des coordonnées).
//
// `EVEIL_RENDER_DIR=/chemin swift test --filter PaperModeTests` écrit la page imprimée, la photo
// simulée, ce que l'atelier en lit (sous ses traits), et la carte « Colorier sur papier ».

#if canImport(SwiftUI) && canImport(AVFoundation) && canImport(CoreText)
@testable import ColoringUI
import CoreGraphics
import SwiftUI
import XCTest

/// Une page imprimée, coloriée puis photographiée — simulée.
struct PaperShot: @unchecked Sendable {
    let page: ColoringPage
    /// La page imprimée et coloriée (`res` pixels par point).
    let printed: RGBAImage
    let photo: RGBAImage
    /// Les vrais centres des repères sur la photo.
    let markers: [CGPoint]
    /// Les zones du carré imprimé (au côté du carré, en pixels) et le crayon de chaque zone coloriée.
    let zones: ZoneMap
    let colors: [Int: [UInt8]]

    static let crayons: [[UInt8]] = [[237, 51, 56], [56, 92, 217], [255, 214, 26], [102, 199, 64],
                                     [255, 140, 26], [148, 87, 219], [255, 140, 191], [140, 89, 51]]

    static func mix(_ x: Int, _ y: Int) -> Int {
        ((x &* 73_856_093) ^ (y &* 19_349_663) ^ 0x5BD1_E995) & 0xFFFF
    }

    static func image(_ rgba: RGBAImage) -> CGImage? {
        rgba.pixels.withUnsafeBytes { PaintLayer.image(from: Data($0), width: rgba.width, height: rgba.height) }
    }

    /// Le PDF rendu en pixels, sur papier blanc.
    static func render(_ pdf: Data, res: CGFloat) -> RGBAImage? {
        guard let provider = CGDataProvider(data: pdf as CFData), let document = CGPDFDocument(provider),
              let page = document.page(at: 1) else { return nil }
        let w = Int((PaperLayout.page.width * res).rounded()), h = Int((PaperLayout.page.height * res).rounded())
        var px = [UInt32](repeating: 0xFFFF_FFFF, count: w * h)
        let ok = px.withUnsafeMutableBytes { raw -> Bool in
            guard let space = CGColorSpace(name: CGColorSpace.sRGB),
                  let ctx = CGContext(data: raw.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                      space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            ctx.scaleBy(x: res, y: res)
            ctx.drawPDFPage(page)
            return true
        }
        return ok ? RGBAImage(width: w, height: h, pixels: px) : nil
    }

    static func make(_ id: String, res: CGFloat = 1.6, blackCorner: Bool = false) -> PaperShot? {
        guard let page = ColoringPages.all.first(where: { $0.id == id }),
              let blank = render(PaperPrint.pdf(for: page, locale: "fr-FR"), res: res) else { return nil }
        let side = Int((PaperLayout.side * res).rounded())
        let zones = ZoneMap(lineArt: page.lineArt, size: side)
        let total = Double(side * side)
        let big = (0...zones.zoneCount).filter { $0 > 0 && Double(zones.areas[$0]) / total > 0.004 }
            .sorted { zones.areas[$0] > zones.areas[$1] }
        var colors: [Int: [UInt8]] = [:]
        for (k, z) in stride(from: 0, to: big.count, by: 2).map({ big[$0] }).prefix(8).enumerated() {
            colors[z] = crayons[k % crayons.count]
        }
        if blackCorner {
            // L'enfant a colorié en noir la zone la plus proche du coin haut-gauche du dessin.
            var sx = [Double](repeating: 0, count: zones.zoneCount + 1), sy = sx
            for y in 0..<side {
                for x in 0..<side {
                    let z = Int(zones.labels[y * side + x])
                    sx[z] += Double(x)
                    sy[z] += Double(y)
                }
            }
            let corner = (1...max(1, zones.zoneCount)).filter {
                $0 <= zones.zoneCount && Double(zones.areas[$0]) / total > 0.003
            }.min { (sx[$0] + sy[$0]) / Double(zones.areas[$0]) < (sx[$1] + sy[$1]) / Double(zones.areas[$1]) }
            if let corner { colors[corner] = [38, 38, 46] }
        }
        // Le crayon « multiplié » sur la page : les traits imprimés restent sombres.
        var tint = [UInt32](repeating: 0, count: zones.zoneCount + 1)
        for (z, c) in colors { tint[z] = UInt32(c[0]) | UInt32(c[1]) << 8 | UInt32(c[2]) << 16 | 0xFF00_0000 }
        var px = blank.pixels
        let ox = Int((PaperLayout.origin.x * res).rounded()), oy = Int((PaperLayout.origin.y * res).rounded())
        for y in 0..<side {
            for x in 0..<side {
                let t = tint[Int(zones.labels[y * side + x])]
                guard t != 0, mix(x, y) % 100 >= 15 else { continue }
                let i = (oy + y) * blank.width + ox + x
                let v = px[i]
                let r = (v & 0xFF) * (t & 0xFF) / 255
                let g = ((v >> 8) & 0xFF) * ((t >> 8) & 0xFF) / 255
                let b = ((v >> 16) & 0xFF) * ((t >> 16) & 0xFF) / 255
                px[i] = r | g << 8 | b << 16 | 0xFF00_0000
            }
        }
        let printed = RGBAImage(width: blank.width, height: blank.height, pixels: px)
        // La photo : la page de travers (le scanner l'a presque redressée), lumière chaude, bruit.
        let w = printed.width, h = printed.height
        let W = Double(w), H = Double(h)
        let corners = [CGPoint(x: 0, y: 0), CGPoint(x: W, y: 0), CGPoint(x: W, y: H), CGPoint(x: 0, y: H)]
        let seen = [CGPoint(x: 0.03 * W, y: 0.02 * H), CGPoint(x: 0.985 * W, y: 0.045 * H),
                    CGPoint(x: 0.96 * W, y: 0.99 * H), CGPoint(x: 0.01 * W, y: 0.965 * H)]
        guard let toPhoto = Homography(from: corners, to: seen), let toPage = toPhoto.inverse else { return nil }
        var out = [UInt32](repeating: 0, count: w * h)
        printed.pixels.withUnsafeBufferPointer { src in
            for y in 0..<h {
                for x in 0..<w {
                    let p = toPage.apply(CGPoint(x: Double(x) + 0.5, y: Double(y) + 0.5))
                    let inside = p.x >= 0 && p.y >= 0 && p.x < W && p.y < H
                    let v = inside ? RGBAImage.sample(src, w, h, Double(p.x), Double(p.y)) : 0
                    let r0 = inside ? Double(v & 0xFF) : 96
                    let g0 = inside ? Double((v >> 8) & 0xFF) : 84
                    let b0 = inside ? Double((v >> 16) & 0xFF) : 72
                    let dx = (Double(x) + 0.5) / W - 0.5, dy = (Double(y) + 0.5) / H - 0.5
                    let k = 1 - 0.15 * 2 * (dx * dx + dy * dy)
                    let noise = Double(mix(x, y) % 13 - 6)
                    let rg = channel(r0 * 0.97 * k + noise) | channel(g0 * 0.92 * k + noise) << 8
                    out[y * w + x] = rg | channel(b0 * 0.80 * k + noise) << 16 | 0xFF00_0000
                }
            }
        }
        return PaperShot(page: page, printed: printed, photo: RGBAImage(width: w, height: h, pixels: out),
                         markers: PaperLayout.markers.map { toPhoto.apply(CGPoint(x: $0.x * res, y: $0.y * res)) },
                         zones: zones, colors: colors)
    }

    private static func channel(_ v: Double) -> UInt32 { UInt32(max(0, min(255, v.rounded()))) }
}

extension RGBAImage {
    /// L'image tournée de `k` quarts de tour dans le sens des aiguilles d'une montre (comme
    /// `Image.tourner` de la référence) : une feuille photographiée de côté ou à l'envers.
    func turned(_ k: Int) -> RGBAImage {
        let q = (k % 4 + 4) % 4
        guard q != 0 else { return self }
        let w = q % 2 == 1 ? height : width, h = q % 2 == 1 ? width : height
        var out = [UInt32](repeating: 0, count: w * h)
        for y in 0..<h {
            for x in 0..<w {
                let sx: Int, sy: Int
                switch q {
                case 1: sx = y; sy = height - 1 - x
                case 2: sx = width - 1 - x; sy = height - 1 - y
                default: sx = width - 1 - y; sy = x
                }
                out[y * w + x] = pixels[sy * width + sx]
            }
        }
        return RGBAImage(width: w, height: h, pixels: out)
    }
}

final class PaperModeTests: XCTestCase {
    static let locomotive = PaperShot.make("locomotive")

    private func index(_ id: String) -> Int? { ColoringPages.all.firstIndex { $0.id == id } }

    /// Ce qu'a dit la lecture, en quelques mots (pas le million de pixels).
    private func said(_ outcome: PaperScan.Outcome) -> String {
        switch outcome {
        case let .painted(_, match): return "cette page (accord \(match))"
        case let .otherPage(k, _, _, match): return "la page \(ColoringPages.all[k].id) (accord \(match))"
        case .unreadable: return "illisible"
        }
    }

    private func assertNear(_ found: [CGPoint], _ truth: [CGPoint], width: Int,
                            file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(found.count, 4, file: file, line: line)
        for (a, b) in zip(found, truth) {
            XCTAssertLessThan(hypot(a.x - b.x, a.y - b.y), 0.005 * CGFloat(width), "\(a) ≠ \(b)", file: file, line: line)
        }
    }

    // MARK: La page imprimée

    /// Mêmes nombres que eveil/outils/papier/mise_en_page.py ; repères imprimables, hors du dessin.
    func testLayoutMatchesTheReference() {
        let expected: [(Double, Double)] = [(31.6378, 124), (563.6378, 124), (563.6378, 656), (31.6378, 656)]
        for (p, e) in zip(PaperLayout.markers, expected) {
            XCTAssertEqual(Double(p.x), e.0, accuracy: 1e-3)
            XCTAssertEqual(Double(p.y), e.1, accuracy: 1e-3)
        }
        let s = PaperLayout.marker / 2
        for c in PaperLayout.markers {
            XCTAssertGreaterThanOrEqual(min(c.x - s, c.y - s, PaperLayout.page.width - c.x - s,
                                            PaperLayout.page.height - c.y - s), PaperLayout.printableMargin)
        }
        for u in PaperLayout.unitMarkers { XCTAssertTrue(u.x < 0 || u.x > 1 || u.y < 0 || u.y > 1, "\(u)") }
        // Le titre au-dessus des repères du haut, la ligne pour l'adulte sous ceux du bas.
        XCTAssertLessThan(PaperLayout.titleBaseline + 10, PaperLayout.origin.y - PaperLayout.offset - s)
        XCTAssertGreaterThan(PaperLayout.footerBaseline - 12,
                             PaperLayout.origin.y + PaperLayout.side + PaperLayout.offset + s)
    }

    func testThePrintedPageIsOneA4Page() throws {
        let data = PaperPrint.pdf(for: ColoringPages.all[0], locale: "fr-FR")
        let provider = try XCTUnwrap(CGDataProvider(data: data as CFData))
        let document = try XCTUnwrap(CGPDFDocument(provider))
        XCTAssertEqual(document.numberOfPages, 1)
        let box = try XCTUnwrap(document.page(at: 1)).getBoxRect(.mediaBox)
        XCTAssertEqual(box.width, PaperLayout.page.width, accuracy: 0.01)
        XCTAssertEqual(box.height, PaperLayout.page.height, accuracy: 0.01)
    }

    /// Sur la page telle qu'elle sort du PDF, les repères sont là où la mise en page les attend.
    func testTheMarkersArePrintedWhereExpected() throws {
        let page = try XCTUnwrap(ColoringPages.all.first { $0.id == "locomotive" })
        let printed = try XCTUnwrap(PaperShot.render(PaperPrint.pdf(for: page, locale: "fr-FR"), res: 1.6))
        let found = try XCTUnwrap(PaperScan.markers(in: printed))
        assertNear(found, PaperLayout.markers.map { CGPoint(x: $0.x * 1.6, y: $0.y * 1.6) }, width: printed.width)
    }

    // MARK: L'homographie

    func testHomographyRoundTrip() throws {
        let h = Homography([1.02, 0.05, 12, -0.03, 0.98, 20, 0.0001, 0.00005, 1])
        let src = [CGPoint(x: 0, y: 0), CGPoint(x: 595, y: 0), CGPoint(x: 595, y: 842), CGPoint(x: 0, y: 842)]
        let h2 = try XCTUnwrap(Homography(from: src, to: src.map(h.apply)))
        let back = try XCTUnwrap(h2.inverse)
        for p in [CGPoint(x: 100, y: 100), CGPoint(x: 300, y: 500), CGPoint(x: 590, y: 20)] {
            let a = h.apply(p), b = h2.apply(p), c = back.apply(b)
            XCTAssertEqual(a.x, b.x, accuracy: 1e-6)
            XCTAssertEqual(a.y, b.y, accuracy: 1e-6)
            XCTAssertEqual(c.x, p.x, accuracy: 1e-6)
            XCTAssertEqual(c.y, p.y, accuracy: 1e-6)
        }
        let aligned = [CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 1), CGPoint(x: 2, y: 2), CGPoint(x: 3, y: 3)]
        XCTAssertNil(Homography(from: aligned, to: [CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 0),
                                                    CGPoint(x: 1, y: 1), CGPoint(x: 0, y: 1)]))
    }

    // MARK: Une photo

    func testMarkersAreFoundOnThePhoto() throws {
        let shot = try XCTUnwrap(Self.locomotive)
        assertNear(try XCTUnwrap(PaperScan.markers(in: shot.photo)), shot.markers, width: shot.photo.width)
    }

    func testTheRightPageAndNotAnother() throws {
        let shot = try XCTUnwrap(Self.locomotive)
        let marks = try XCTUnwrap(PaperScan.markers(in: shot.photo))
        let n = PaperScan.searchSide
        let square = try XCTUnwrap(PaperScan.rectify(shot.photo, markers: marks, size: n))
        let other = try XCTUnwrap(ColoringPages.all.first { $0.id == "minouche" })
        XCTAssertGreaterThan(PaperScan.match(square, labels: ZoneMap(lineArt: shot.page.lineArt, size: n).labels, size: n), 0.8)
        XCTAssertLessThan(PaperScan.match(square, labels: ZoneMap(lineArt: other.lineArt, size: n).labels, size: n), 0.35)
    }

    /// Chaque zone coloriée ressort de sa couleur (balance des blancs faite) ; une zone blanche reste
    /// transparente ; aucun trait n'est peint.
    func testTheCrayonStrokesComeBack() throws {
        let shot = try XCTUnwrap(Self.locomotive)
        let photo = try XCTUnwrap(PaperShot.image(shot.photo))
        let map = ZoneMap(lineArt: shot.page.lineArt)
        let at = try XCTUnwrap(index("locomotive"))
        let outcome = PaperScan.read(photo, pages: ColoringPages.all, index: at, map: map)
        guard case let .painted(paint, match) = outcome else { return XCTFail("lu : \(said(outcome))") }
        XCTAssertGreaterThan(match, 0.8)
        XCTAssertEqual(paint.count, map.width * map.height)
        let n = map.width, sim = shot.zones, k = Double(sim.width) / Double(n)
        var total: [Int: Int] = [:], painted: [Int: [UInt32]] = [:]
        var paintedLines = 0
        for y in 0..<n {
            for x in 0..<n {
                let i = y * n + x
                guard map.labels[i] != 0 else {
                    if paint[i] != 0 { paintedLines += 1 }
                    continue
                }
                let z = Int(sim.labels[Int((Double(y) + 0.5) * k) * sim.width + Int((Double(x) + 0.5) * k)])
                total[z, default: 0] += 1
                if paint[i] != 0 { painted[z, default: []].append(paint[i]) }
            }
        }
        XCTAssertEqual(paintedLines, 0)
        XCTAssertFalse(shot.colors.isEmpty)
        for (z, rgb) in shot.colors {
            guard let count = total[z], count >= 30 else { continue }
            let got = painted[z] ?? []
            XCTAssertGreaterThan(Double(got.count) / Double(count), 0.6, "zone \(z)")
            guard !got.isEmpty else { continue }
            for c in 0..<3 {
                let values = got.map { Int(($0 >> UInt32(8 * c)) & 0xFF) }.sorted()
                XCTAssertLessThan(abs(values[values.count / 2] - Int(rgb[c])), 60, "zone \(z), canal \(c)")
            }
        }
        let area = Double(sim.width * sim.height)
        for z in 1...max(1, sim.zoneCount) where z <= sim.zoneCount {
            guard shot.colors[z] == nil, Double(sim.areas[z]) / area > 0.01,
                  let count = total[z], count > 0 else { continue }
            XCTAssertLessThan(Double(painted[z]?.count ?? 0) / Double(count), 0.08, "zone blanche \(z)")
        }
        if ColoringRender.outputDirectory != nil {
            if let printed = PaperShot.image(shot.printed) { ColoringRender.write(printed, name: "papier-imprime") }
            ColoringRender.write(photo, name: "papier-photo")
            let colors = paint.withUnsafeBytes { PaintLayer.image(from: Data($0), width: n, height: n) }
            if let read = ColoringRender.page(shot.page.lineArt, colors: colors) {
                ColoringRender.write(read, name: "papier-lu")
            }
        }
    }

    /// La photo d'une AUTRE page de l'atelier : c'est elle que l'atelier reconnaît (et ouvrira).
    func testAPhotoOfAnotherPageIsRecognized() throws {
        let shot = try XCTUnwrap(Self.locomotive)
        let photo = try XCTUnwrap(PaperShot.image(shot.photo))
        let pages = ColoringPages.all
        let here = try XCTUnwrap(index("minouche")), there = try XCTUnwrap(index("locomotive"))
        let outcome = PaperScan.read(photo, pages: pages, index: here, map: ZoneMap(lineArt: pages[here].lineArt))
        guard case let .otherPage(k, paint, map, match) = outcome else { return XCTFail("lu : \(said(outcome))") }
        XCTAssertEqual(k, there)
        XCTAssertEqual(map.width, ZoneMap.defaultSize)
        XCTAssertGreaterThan(match, 0.8)
        XCTAssertEqual(paint.count, map.width * map.height)
        XCTAssertGreaterThan(paint.lazy.filter { $0 != 0 }.count, map.width * map.height / 20)
    }

    // MARK: De côté, à l'envers

    /// Un point de la page droite ramené sur la photo telle qu'elle est : le même pixel.
    func testTurnsAreConsistent() {
        let image = RGBAImage(width: 3, height: 2, pixels: (0..<6).map { UInt32($0) | 0xFF00_0000 })
        for k in 0..<4 {
            let t = image.turned(k)
            for y in 0..<t.height {
                for x in 0..<t.width {
                    let p = PaperScan.fromUpright(CGPoint(x: Double(x) + 0.5, y: Double(y) + 0.5), turns: k,
                                                  width: image.width, height: image.height)
                    XCTAssertEqual(t.pixels[y * t.width + x], image.pixels[Int(p.y) * image.width + Int(p.x)],
                                   "\(k) quart(s) de tour, (\(x), \(y))")
                }
            }
        }
        XCTAssertEqual(PaperScan.turns(for: image), [1, 3])
        XCTAssertEqual(PaperScan.turns(for: image.turned(1)), [0, 2])
    }

    /// La feuille photographiée de côté ou à l'envers (l'enfant assis en face de l'adulte) : lue dans
    /// le bon sens, avec les mêmes coups de crayon (à quelques pixels près).
    func testASheetTurnedAroundIsReadTheRightWay() throws {
        let shot = try XCTUnwrap(Self.locomotive)
        let at = try XCTUnwrap(index("locomotive"))
        let map = ZoneMap(lineArt: shot.page.lineArt)
        var painted: [Int] = []
        for k in 0..<4 {
            let photo = try XCTUnwrap(PaperShot.image(shot.photo.turned(k)))
            let outcome = PaperScan.read(photo, pages: ColoringPages.all, index: at, map: map)
            guard case let .painted(paint, match) = outcome else {
                XCTFail("photo tournée de \(k) quart(s) : lu \(said(outcome))")
                continue
            }
            XCTAssertGreaterThan(match, 0.8, "photo tournée de \(k) quart(s)")
            painted.append(paint.lazy.filter { $0 != 0 }.count)
        }
        if let first = painted.first {
            for n in painted { XCTAssertEqual(Double(n), Double(first), accuracy: 0.03 * Double(first)) }
        }
    }

    // MARK: Les pièges

    /// Un coin du dessin colorié tout noir ressemble à un repère : la tache la plus proche gagne.
    func testABlackCornerDoesNotFoolTheMarkers() throws {
        let shot = try XCTUnwrap(PaperShot.make("minouche", blackCorner: true))
        assertNear(try XCTUnwrap(PaperScan.markers(in: shot.photo)), shot.markers, width: shot.photo.width)
    }

    /// Une photo sans page (une feuille blanche) : illisible, jamais une page au hasard.
    func testABlankSheetIsUnreadable() throws {
        let blank = RGBAImage(width: 600, height: 848, pixels: [UInt32](repeating: 0xFFF0_F0F0, count: 600 * 848))
        XCTAssertNil(PaperScan.markers(in: blank))
        let pages = Array(ColoringPages.all.prefix(8))
        let outcome = PaperScan.read(try XCTUnwrap(PaperShot.image(blank)), pages: pages, index: 0,
                                     map: ZoneMap(lineArt: pages[0].lineArt, size: 256))
        guard case .unreadable = outcome else { return XCTFail("lu : \(said(outcome))") }
    }

    // MARK: Dans l'atelier

    func testLoadingIsUndoable() {
        let layer = PaintLayer(width: 8, height: 8)
        var values = [UInt32](repeating: 0, count: 64)
        values[9] = 0xFF00_00FF
        XCTAssertTrue(layer.load(values, in: nil))
        XCTAssertEqual(layer.pixel(9), 0xFF00_00FF)
        XCTAssertTrue(layer.canUndo)
        XCTAssertTrue(layer.undo(in: nil))
        XCTAssertEqual(layer.pixel(9), 0)
        XCTAssertFalse(layer.load([0, 0], in: nil))
    }

    /// La photo d'une autre page : l'atelier ouvre cette page (avec sa carte, sans la recalculer)
    /// et y pose les coups de crayon.
    @MainActor
    func testLoadingAnotherPageOpensIt() throws {
        let pages = Array(ColoringPages.all.prefix(3))
        let studio = ColoringStudio(pages: pages)
        studio.loadSynchronously()
        let map = ZoneMap(lineArt: pages[2].lineArt)
        var paint = [UInt32](repeating: 0, count: map.width * map.height)
        let first = try XCTUnwrap(map.labels.firstIndex(of: 1))
        for i in paint.indices where map.labels[i] == 1 { paint[i] = 0xFF30_A0F0 }
        studio.loadPaper(paint, page: 2, map: map)
        XCTAssertEqual(studio.pageIndex, 2)
        XCTAssertTrue(studio.isReady)
        XCTAssertTrue(studio.canUndo)
        let point = CGPoint(x: (Double(first % map.width) + 0.5) / Double(map.width),
                            y: (Double(first / map.width) + 0.5) / Double(map.width))
        XCTAssertEqual(studio.coverage(of: nil, at: [point]).first?.painted, map.areas[1])
        studio.undo()
        XCTAssertEqual(studio.coverage(of: nil, at: [point]).first?.painted, 0)
    }

    // MARK: La carte « Colorier sur papier »

    @MainActor
    func testTheSheetRenders() throws {
        let page = try XCTUnwrap(ColoringPages.all.first { $0.id == "locomotive" })
        let sizes = [("paysage", CGSize(width: 1194, height: 834)), ("portrait", CGSize(width: 834, height: 1194))]
        for (name, size) in sizes {
            let states: [(PaperSheet.ReadState, String)] = [(.ready, ""), (.reading, "-lecture"), (.unreadable, "-reessaie")]
            for (state, suffix) in states {
                let sheet = PaperSheet(page: page, locale: "fr-FR", state: state, read: { _ in false }, say: { _ in },
                                       onClose: {})
                XCTAssertNotNil(ColoringRender.view(sheet, size: size, name: "papier-carte-\(name)\(suffix)"))
            }
        }
    }
}
#endif
