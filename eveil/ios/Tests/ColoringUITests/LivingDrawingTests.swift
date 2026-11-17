// LivingDrawingTests.swift — « Le dessin prend vie » : le temps, les pièces, les attaches, le rendu.
//
// - Le temps (LivingMotion) : au repos avant et après la fête ; battre ne rapetisse jamais ; une
//   roue finit sur un nombre entier de tours (pas de saut au repos) ; deux ailes battent en miroir.
// - Les attaches : mêmes valeurs que la référence eveil/outils/coloriages/vivant.py
//   (`python3 -m coloriages.vivant --golden`), à 1,5 % de la page près (les deux cartes des zones
//   ne rastérisent pas au pixel près).
// - Toutes les pages : chacune bouge (sauf le cirque), attaches dans la page.
// - Le rendu : `EVEIL_RENDER_DIR=/chemin swift test --filter LivingDrawingTests` écrit, pour
//   quelques pages coloriées, quatre instants de la fête côte à côte (repos, puis 1,0 / 1,2 / 1,4 s).

#if canImport(SwiftUI) && canImport(AVFoundation)
@testable import ColoringUI
import CoreGraphics
import XCTest

final class LivingDrawingTests: XCTestCase {
    private let motions: [PartMotion] = [.roll, .spin, .pulse(0.12), .sway(14), .drift(0.02), .float(0.018)]

    private func instants(_ n: Int = 600) -> [Double] { (0...n).map { Double($0) * LivingMotion.duration / Double(n) } }

    // MARK: Le temps

    func testMotionRestsOutsideTheShow() {
        for m in motions {
            for t in [-1.0, 0, LivingMotion.duration, LivingMotion.duration + 1] {
                let r = LivingMotion.transform(m, at: t, phase: 0.7)
                XCTAssertEqual(r.angle, 0, "\(m)")
                XCTAssertEqual(r.scale, 1, "\(m)")
                XCTAssertEqual(r.dx, 0, "\(m)")
                XCTAssertEqual(r.dy, 0, "\(m)")
            }
        }
    }

    /// Battre ne fait que grandir : rien ne se découvre sous la pièce.
    func testPulseNeverShrinks() {
        for t in instants() {
            let s = LivingMotion.transform(.pulse(0.12), at: t, phase: 1.3).scale
            XCTAssertGreaterThanOrEqual(s, 1)
            XCTAssertLessThanOrEqual(s, 1.12 + 1e-9)
        }
    }

    /// Une roue démarre et s'arrête en douceur, sans reculer, et finit sur un nombre entier de tours.
    func testWheelsEndWhereTheyStarted() {
        for m in [PartMotion.roll, .spin] {
            var before = 0.0
            for t in instants().dropLast() {
                let a = LivingMotion.transform(m, at: t).angle
                XCTAssertGreaterThanOrEqual(a + 1e-12, before)
                XCTAssertLessThan(a - before, 0.05)
                before = a
            }
            let turns = LivingMotion.travel(LivingMotion.duration) / LivingMotion.period(m)
            XCTAssertEqual(turns, turns.rounded(), accuracy: 1e-9, "\(m)")
            XCTAssertGreaterThanOrEqual(turns.rounded(), 2)
        }
    }

    func testSwayIsBoundedAndMirrored() {
        for t in instants() {
            let a = LivingMotion.transform(.sway(14), at: t, phase: 0.4, sign: 1).angle
            let b = LivingMotion.transform(.sway(14), at: t, phase: 0.4, sign: -1).angle
            XCTAssertLessThanOrEqual(abs(a), 14 * .pi / 180 + 1e-9)
            XCTAssertEqual(a, -b, accuracy: 1e-12)
        }
    }

    func testFloatOnlyGoesUpAndDriftStaysLevel() {
        for t in instants() {
            let f = LivingMotion.transform(.float(0.018), at: t, phase: 2)
            XCTAssertEqual(f.dx, 0)
            XCTAssertLessThanOrEqual(f.dy, 0)
            XCTAssertGreaterThanOrEqual(f.dy, -0.018 - 1e-9)
            let d = LivingMotion.transform(.drift(0.02), at: t, phase: 2)
            XCTAssertEqual(d.dy, 0)
            XCTAssertLessThanOrEqual(abs(d.dx), 0.02 + 1e-9)
        }
    }

    // MARK: Les pièces et leurs attaches

    /// Les attaches (et le rayon des roues) de vivant.py, à 1024 px : (page, partie, x, y, rayon).
    static let reference: [(page: String, part: String, x: CGFloat, y: CGFloat, radius: CGFloat)] = [
        ("locomotive", "la roue", 0.2495, 0.7896, 0.0521),
        ("locomotive", "la roue", 0.7495, 0.7896, 0.0521),
        ("minouche", "la queue", 0.6857, 0.8638, 0),
        ("biche", "les feuilles", 0.1323, 0.4607, 0),
        ("biche", "les feuilles", 0.8755, 0.4854, 0),
        ("perruche", "la queue", 0.5926, 0.6997, 0),
        ("lapin", "les oreilles", 0.4312, 0.2733, 0),
        ("lapin", "les oreilles", 0.5688, 0.2733, 0),
        ("douche", "la serviette", 0.1133, 0.1250, 0),
    ]

    func testPivotsMatchTheReference() throws {
        for id in Set(Self.reference.map(\.page)) {
            let page = try XCTUnwrap(ColoringPages.all.first { $0.id == id }, id)
            let map = ZoneMap(lineArt: page.lineArt)
            let n = CGFloat(map.width)
            let shapes = LivingDrawing.shapes(for: page.parts, map: map)
            for ref in Self.reference where ref.page == id {
                let found = shapes.contains { s in
                    s.part == ref.part && abs(s.pivot.x / n - ref.x) < 0.015 && abs(s.pivot.y / n - ref.y) < 0.015
                        && abs(s.radius / n - ref.radius) < 0.01
                }
                let seen = shapes.filter { $0.part == ref.part }.map { "(\($0.pivot.x / n), \($0.pivot.y / n), r \($0.radius / n))" }
                XCTAssertTrue(found, "\(id) : « \(ref.part) » attendue vers (\(ref.x), \(ref.y)) ; vue : \(seen)")
            }
        }
    }

    /// Chaque page bouge (sauf le cirque : le dessin entier danse quand même), attaches dans la page.
    func testEveryPageComesAlive() {
        var still: [String] = []
        for page in ColoringPages.all {
            let map = ZoneMap(lineArt: page.lineArt)
            let shapes = LivingDrawing.shapes(for: page.parts, map: map)
            if shapes.isEmpty { still.append(page.id) }
            for s in shapes {
                XCTAssertTrue((0...CGFloat(map.width)).contains(s.pivot.x) && (0...CGFloat(map.height)).contains(s.pivot.y),
                              "\(page.id) : « \(s.part) » tient hors de la page")
                XCTAssertTrue(s.silhouette.contains(1), "\(page.id) : « \(s.part) » sans silhouette")
            }
        }
        XCTAssertEqual(still, ["cirque"])
    }

    /// Les deux ailes de la mouche battent en miroir, chacune depuis le corps.
    func testTheFlysWingsFlapInAMirror() throws {
        let fly = try XCTUnwrap(ColoringPages.all.first { $0.id == "mouche" })
        let map = ZoneMap(lineArt: fly.lineArt)
        let wings = LivingDrawing.shapes(for: fly.parts, map: map).filter { $0.part == "les ailes" }
        XCTAssertEqual(wings.count, 2)
        XCTAssertEqual(Set(wings.map(\.sign)), [-1, 1])
        for w in wings {
            // L'attache est du côté du corps (le milieu de la page), pas au bout de l'aile.
            XCTAssertLessThan(abs(w.pivot.x / CGFloat(map.width) - 0.5), abs(w.center.x / CGFloat(map.width) - 0.5))
        }
    }

    // MARK: Le rendu

    /// Une page coloriée zone par zone (couleurs de la palette, dans l'ordre).
    private func painted(_ page: ColoringPage) -> (ZoneMap, [UInt32]) {
        let map = ZoneMap(lineArt: page.lineArt)
        let layer = PaintLayer()
        let palette = ColoringView.palette
        for z in 1...map.zoneCount where map.fraction(of: z) < 0.25 {
            _ = layer.fill(zone: z, color: palette[(z * 5) % (palette.count - 1)].packed, in: map)
        }
        return (map, layer.copyPixels())
    }

    func testLivingDrawingRendersEveryPiece() throws {
        for id in ["minouche", "chat", "papillon", "locomotive", "cloche", "niche", "mouche", "train", "fusee", "machine"] {
            let page = try XCTUnwrap(ColoringPages.all.first { $0.id == id }, id)
            let (map, paint) = painted(page)
            let shapes = LivingDrawing.shapes(for: page.parts, map: map)
            let drawing = try XCTUnwrap(LivingDrawing(page: page, map: map, paint: paint), id)
            XCTAssertEqual(drawing.pieces.count, shapes.count, id)
            XCTAssertEqual(drawing.base.width, map.width, id)
            for p in drawing.pieces {
                XCTAssertTrue(p.frame.minX >= 0 && p.frame.minY >= 0 && p.frame.maxX <= 1.0001 && p.frame.maxY <= 1.0001,
                              "\(id) : « \(p.part) » hors de la page")
            }
            // Quatre instants côte à côte : repos, puis la fête.
            let side = 320
            let frames = [0, 1.0, 1.2, 1.4].compactMap { drawing.frame(at: $0, size: side) }
            XCTAssertEqual(frames.count, 4, id)
            if let sheet = sideBySide(frames, side: side) { ColoringRender.write(sheet, name: "vivant-\(id)") }
        }
    }

    private func sideBySide(_ images: [CGImage], side: Int) -> CGImage? {
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let ctx = CGContext(data: nil, width: images.count * side, height: side, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        for (k, image) in images.enumerated() {
            ctx.draw(image, in: CGRect(x: k * side, y: 0, width: side, height: side))
        }
        return ctx.makeImage()
    }
}
#endif
