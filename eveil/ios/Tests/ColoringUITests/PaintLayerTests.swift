// PaintLayerTests.swift — remplir, peindre au pochoir, annuler : la couche de couleurs.
//
// Remplir colore toute la zone et rien d'autre ; annuler rend exactement l'image
// d'avant ; le pinceau ne peint QUE la zone où il a commencé, même quand le doigt
// file à travers les traits ; tout effacer s'annule ; l'historique reste borné.

#if canImport(CoreGraphics)
@testable import ColoringUI
import CoreGraphics
import XCTest

final class PaintLayerTests: XCTestCase {
    private let red = PaintColor(237, 51, 56, fr: "rouge", en: "red").packed
    private let blue = PaintColor(56, 92, 217, fr: "bleu", en: "blue").packed

    /// Trois bandes verticales séparées par deux traits : zones gauche, milieu, droite.
    private func stripes(_ n: Int = 256) -> ZoneMap {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0.33, y: -0.1))
        path.addLine(to: CGPoint(x: 0.33, y: 1.1))
        path.move(to: CGPoint(x: 0.66, y: -0.1))
        path.addLine(to: CGPoint(x: 0.66, y: 1.1))
        return ZoneMap(lineArt: LineArt(strokes: path, ink: CGMutablePath(), lineWidth: 0.02), size: n)
    }

    func testFillPaintsTheWholeZoneAndOnlyIt() {
        let map = stripes()
        let layer = PaintLayer(width: map.width, height: map.height)
        let middle = map.zone(at: CGPoint(x: 0.5, y: 0.5))
        XCTAssertTrue(layer.fill(zone: middle, color: red, in: map))
        for i in 0..<(map.width * map.height) {
            XCTAssertEqual(layer.pixel(i) == red, Int(map.labels[i]) == middle, "pixel \(i)")
        }
        XCTAssertFalse(layer.fill(zone: middle, color: red, in: map), "même couleur : rien ne change, pas de pas")
        XCTAssertEqual(layer.stepCount, 1)
    }

    func testFillThenUndoRestoresExactly() {
        let map = stripes()
        let layer = PaintLayer(width: map.width, height: map.height)
        let left = map.zone(at: CGPoint(x: 0.1, y: 0.5)), middle = map.zone(at: CGPoint(x: 0.5, y: 0.5))
        layer.fill(zone: left, color: blue, in: map)
        paintStroke(layer, map, from: CGPoint(x: 120, y: 30), to: CGPoint(x: 140, y: 200), color: blue)
        let before = layer.copyPixels()
        XCTAssertTrue(layer.fill(zone: middle, color: red, in: map))
        XCTAssertNotEqual(layer.copyPixels(), before)
        XCTAssertTrue(layer.undo(in: map))
        XCTAssertEqual(layer.copyPixels(), before, "annuler rend l'image d'avant au pixel près (trait compris)")
    }

    func testBrushNeverPaintsOutsideItsZone() {
        let map = stripes()
        let layer = PaintLayer(width: map.width, height: map.height)
        let middle = map.zone(at: CGPoint(x: 0.5, y: 0.5))
        // Le doigt part du milieu et file à travers les deux traits, aller et retour, très vite.
        layer.beginStroke(at: CGPoint(x: 128, y: 128), zone: middle, color: red, radius: 20, in: map)
        for p in [CGPoint(x: 10, y: 60), CGPoint(x: 250, y: 90), CGPoint(x: 5, y: 200), CGPoint(x: 245, y: 250)] {
            layer.continueStroke(to: p, in: map)
        }
        XCTAssertTrue(layer.endStroke(in: map))
        var painted = 0
        for i in 0..<(map.width * map.height) where layer.pixel(i) != 0 {
            XCTAssertEqual(Int(map.labels[i]), middle, "le pinceau a débordé au pixel \(i)")
            painted += 1
        }
        XCTAssertGreaterThan(painted, 2000)
    }

    func testFastStrokeStaysContinuous() {
        let map = stripes()
        let layer = PaintLayer(width: map.width, height: map.height)
        let middle = map.zone(at: CGPoint(x: 0.5, y: 0.5))
        // Deux points très éloignés (geste rapide) : tout le chemin entre eux est peint.
        layer.beginStroke(at: CGPoint(x: 128, y: 10), zone: middle, color: red, radius: 6, in: map)
        layer.continueStroke(to: CGPoint(x: 128, y: 240), in: map)
        layer.endStroke(in: map)
        for y in 10...240 { XCTAssertEqual(layer.pixel(y * map.width + 128), red, "trou dans le trait en y = \(y)") }
    }

    func testBrushUndoRemovesTheWholeStroke() {
        let map = stripes()
        let layer = PaintLayer(width: map.width, height: map.height)
        let middle = map.zone(at: CGPoint(x: 0.5, y: 0.5))
        layer.fill(zone: middle, color: blue, in: map)
        let before = layer.copyPixels()
        paintStroke(layer, map, from: CGPoint(x: 100, y: 20), to: CGPoint(x: 150, y: 230), color: red)
        paintStroke(layer, map, from: CGPoint(x: 150, y: 20), to: CGPoint(x: 100, y: 230), color: red)
        XCTAssertEqual(layer.stepCount, 3)
        layer.undo(in: map)
        layer.undo(in: map)
        XCTAssertEqual(layer.copyPixels(), before)
    }

    func testBrushEdgeIsSoftButNeverDoublePainted() {
        let map = stripes()
        let middle = map.zone(at: CGPoint(x: 0.5, y: 0.5))
        // Un aller simple, puis un trait qui repasse trois fois au même endroit : le bord
        // garde le même dégradé (couverture maximale, jamais de couches qui s'accumulent).
        func edgeAlpha(passes: Int) -> UInt32 {
            let layer = PaintLayer(width: map.width, height: map.height)
            layer.beginStroke(at: CGPoint(x: 128.3, y: 60), zone: middle, color: red, radius: 10, in: map)
            for k in 0..<passes {
                layer.continueStroke(to: CGPoint(x: 128.3, y: k.isMultiple(of: 2) ? 190 : 60), in: map)
            }
            layer.endStroke(in: map)
            XCTAssertEqual(layer.pixel(128 * map.width + 128), red)
            return layer.pixel(128 * map.width + 138) >> 24     // à ≈ 10,2 px de l'axe : bord adouci
        }
        let once = edgeAlpha(passes: 1)
        XCTAssertGreaterThan(once, 0)
        XCTAssertLessThan(once, 255)
        XCTAssertEqual(edgeAlpha(passes: 3), once)
    }

    func testClearIsUndoable() {
        let map = stripes()
        let layer = PaintLayer(width: map.width, height: map.height)
        layer.fill(zone: map.zone(at: CGPoint(x: 0.1, y: 0.5)), color: red, in: map)
        paintStroke(layer, map, from: CGPoint(x: 120, y: 30), to: CGPoint(x: 130, y: 220), color: blue)
        let before = layer.copyPixels()
        XCTAssertTrue(layer.clear(in: map))
        XCTAssertTrue(layer.copyPixels().allSatisfy { $0 == 0 })
        XCTAssertFalse(layer.clear(in: map), "déjà blanche : rien à effacer")
        XCTAssertTrue(layer.undo(in: map))
        XCTAssertEqual(layer.copyPixels(), before)
    }

    func testSnapshotRoundTrip() {
        let map = stripes()
        let layer = PaintLayer(width: map.width, height: map.height)
        layer.fill(zone: map.zone(at: CGPoint(x: 0.8, y: 0.5)), color: red, in: map)
        paintStroke(layer, map, from: CGPoint(x: 100, y: 30), to: CGPoint(x: 150, y: 220), color: blue)
        let colored = layer.copyPixels()
        let snapshot = layer.snapshot()
        XCTAssertFalse(snapshot.isBlank)
        layer.restore(nil)
        XCTAssertTrue(layer.copyPixels().allSatisfy { $0 == 0 })
        XCTAssertFalse(layer.canUndo)
        layer.restore(snapshot)
        XCTAssertEqual(layer.copyPixels(), colored)
        XCTAssertNotNil(layer.thumbnail(side: 64))
        XCTAssertNotNil(layer.makeImage())
    }

    func testHistoryIsBounded() {
        let map = stripes()
        let layer = PaintLayer(width: map.width, height: map.height, maxHistoryBytes: 40_000, maxSteps: 10)
        let zones = [0.1, 0.5, 0.9].map { map.zone(at: CGPoint(x: $0, y: 0.5)) }
        for k in 0..<30 {
            layer.fill(zone: zones[k % 3], color: k.isMultiple(of: 2) ? red : blue, in: map)
            paintStroke(layer, map, from: CGPoint(x: 20 + k, y: 10), to: CGPoint(x: 60, y: 240), color: red)
            XCTAssertLessThanOrEqual(layer.stepCount, 10)
            XCTAssertTrue(layer.historyBytes <= 40_000 || layer.stepCount == 1)
        }
    }

    private func paintStroke(_ layer: PaintLayer, _ map: ZoneMap, from a: CGPoint, to b: CGPoint, color: UInt32) {
        let zone = map.zone(atPixel: Int(a.x), Int(a.y))
        layer.beginStroke(at: a, zone: zone, color: color, radius: 12, in: map)
        for k in 1...8 {
            let t = CGFloat(k) / 8
            layer.continueStroke(to: CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t), in: map)
        }
        layer.endStroke(in: map)
    }
}
#endif
