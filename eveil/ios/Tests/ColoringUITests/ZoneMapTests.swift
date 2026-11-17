// ZoneMapTests.swift — l'étiquetage des zones sur des masques de synthèse.
//
// Ce que les traits ferment devient une zone, et rien d'autre : un carré fermé
// donne 2 zones, deux cercles qui se chevauchent 4, un trait en diagonale d'un
// pixel est une vraie barrière (4-connexité), un trou dans le trait fait fuir,
// les miettes rejoignent une voisine, et le haut du masque est le haut de la page.

#if canImport(CoreGraphics)
@testable import ColoringUI
import CoreGraphics
import XCTest

final class ZoneMapTests: XCTestCase {
    /// Masque vide de côté `n`, et un tracé de rectangle creux (épaisseur `t`, avec un trou optionnel).
    private func squareMask(_ n: Int, from a: Int, to b: Int, thickness t: Int, gap: Range<Int>? = nil) -> [UInt8] {
        var m = [UInt8](repeating: 0, count: n * n)
        for y in a..<b {
            for x in a..<b {
                let onBorder = x < a + t || x >= b - t || y < a + t || y >= b - t
                let inGap = gap.map { $0.contains(x) && y < a + t } ?? false
                if onBorder && !inGap { m[y * n + x] = 255 }
            }
        }
        return m
    }

    private func art(_ path: CGPath, width: CGFloat) -> LineArt {
        LineArt(strokes: path, ink: CGMutablePath(), lineWidth: width)
    }

    func testClosedSquareGivesTwoZones() {
        let map = ZoneMap(mask: squareMask(100, from: 20, to: 80, thickness: 3), width: 100, height: 100)
        XCTAssertEqual(map.zoneCount, 2)
        let outside = map.zone(atPixel: 2, 2), inside = map.zone(atPixel: 50, 50)
        XCTAssertNotEqual(outside, 0)
        XCTAssertNotEqual(inside, 0)
        XCTAssertNotEqual(inside, outside, "l'intérieur d'une forme fermée ne rejoint jamais le dehors")
        XCTAssertEqual(map.zone(atPixel: 20, 50), 0, "un pixel de trait n'appartient à aucune zone")
        XCTAssertEqual(map.areas[inside], 54 * 54)
    }

    func testGapInTheLineLeaks() {
        let map = ZoneMap(mask: squareMask(100, from: 20, to: 80, thickness: 3, gap: 45..<50), width: 100, height: 100)
        XCTAssertEqual(map.zoneCount, 1, "un trou dans le trait fait communiquer dedans et dehors")
    }

    func testTwoOverlappingCirclesGiveFourZones() {
        let path = CGMutablePath()
        path.addEllipse(in: CGRect(x: 0.15, y: 0.25, width: 0.45, height: 0.45))
        path.addEllipse(in: CGRect(x: 0.40, y: 0.25, width: 0.45, height: 0.45))
        let map = ZoneMap(lineArt: art(path, width: 0.01), size: 256)
        XCTAssertEqual(map.zoneCount, 4, "dehors, gauche seule, lentille commune, droite seule")
        let zones = [map.zone(at: CGPoint(x: 0.03, y: 0.03)), map.zone(at: CGPoint(x: 0.25, y: 0.475)),
                     map.zone(at: CGPoint(x: 0.50, y: 0.475)), map.zone(at: CGPoint(x: 0.75, y: 0.475))]
        XCTAssertFalse(zones.contains(0))
        XCTAssertEqual(Set(zones).count, 4)
    }

    func testOnePixelDiagonalIsAWall() {
        // Un trait en diagonale d'un seul pixel : les deux côtés ne se touchent que par des coins.
        let n = 64
        var m = [UInt8](repeating: 0, count: n * n)
        for i in 0..<n { m[i * n + i] = 255 }
        let map = ZoneMap(mask: m, width: n, height: n, crumbFraction: 0)
        XCTAssertEqual(map.zoneCount, 2, "4-connexité : une diagonale fermée sépare les deux triangles")
        XCTAssertNotEqual(map.zone(atPixel: 50, 10), map.zone(atPixel: 10, 50))
    }

    func testCrumbsJoinTheirNeighbour() {
        // Un minuscule carré fermé (intérieur 3 × 3 = 9 px < 0,02 % de 300²) dans un grand : c'est une miette.
        let n = 300
        var m = squareMask(n, from: 20, to: 280, thickness: 3)
        for y in 148..<155 { for x in 148..<155 where x < 150 || x > 152 || y < 150 || y > 152 { m[y * n + x] = 255 } }
        let raw = ZoneMap(mask: m, width: n, height: n, crumbFraction: 0)
        XCTAssertEqual(raw.zoneCount, 3)
        let merged = ZoneMap(mask: m, width: n, height: n)
        XCTAssertEqual(merged.zoneCount, 2, "la miette rejoint la zone qui l'entoure")
        XCTAssertEqual(merged.zone(atPixel: 151, 151), merged.zone(atPixel: 60, 60))
    }

    func testMaskTopIsPageTop() {
        // Un trait horizontal en y = 0,25 (unité) : ligne ≈ 256 du masque, pas 768.
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -0.1, y: 0.25))
        path.addLine(to: CGPoint(x: 1.1, y: 0.25))
        let raster = ZoneMap.rasterize(art(path, width: 0.01), size: 1024)
        XCTAssertEqual(raster.mask[256 * 1024 + 512], 255)
        XCTAssertEqual(raster.mask[768 * 1024 + 512], 0)
        let map = ZoneMap(lineArt: art(path, width: 0.01), size: 1024)
        XCTAssertEqual(map.zoneCount, 2)
        XCTAssertGreaterThan(map.fraction(of: map.zone(at: CGPoint(x: 0.5, y: 0.9))), 0.7)
    }

    func testRasterLineIsThinnerThanTheShownLine() {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0.5, y: -0.1))
        path.addLine(to: CGPoint(x: 0.5, y: 1.1))
        let raster = ZoneMap.rasterize(art(path, width: 0.012), size: 1024)
        let shown = 0.012 * 1024
        XCTAssertLessThanOrEqual(raster.lineWidth, shown * 0.8 + 0.001)
        XCTAssertLessThanOrEqual(raster.lineWidth, shown - 3 + 0.001, "au moins 1,5 px de marge de chaque côté")
        let row = raster.mask[(512 * 1024)..<(513 * 1024)]
        let lit = row.filter { $0 != 0 }.count
        XCTAssertTrue((Int(raster.lineWidth) - 1...Int(raster.lineWidth) + 2).contains(lit), "trait de \(lit) px")
    }

    func testRunsCoverEachZoneExactly() {
        let path = CGMutablePath()
        path.addEllipse(in: CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6))
        path.addRect(CGRect(x: 0.35, y: 0.35, width: 0.3, height: 0.3))
        let map = ZoneMap(lineArt: art(path, width: 0.012), size: 256)
        for z in 1...map.zoneCount {
            var covered = 0
            for r in map.runRange(of: z) {
                let start = Int(map.runStarts[r])
                for i in start..<(start + Int(map.runLengths[r])) {
                    XCTAssertEqual(Int(map.labels[i]), z)
                    covered += 1
                }
            }
            XCTAssertEqual(covered, map.areas[z])
        }
        XCTAssertEqual(map.areas.reduce(0, +), 256 * 256)
    }

    func testTouchOnALineFindsTheNearestZone() {
        let map = ZoneMap(mask: squareMask(100, from: 20, to: 80, thickness: 3), width: 100, height: 100,
                          rasterLineWidth: 3)
        XCTAssertEqual(map.zone(atPixel: 21, 50), 0)
        let near = map.zone(near: CGPoint(x: 0.225, y: 0.5))    // pixel (22, 50), sur le trait, côté intérieur
        XCTAssertEqual(near, map.zone(atPixel: 50, 50))
    }
}
#endif
