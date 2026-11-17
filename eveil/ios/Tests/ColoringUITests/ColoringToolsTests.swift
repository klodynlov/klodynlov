// ColoringToolsTests.swift — la palette de 24 couleurs, la gomme, le mode interactif.
//
// Demandes de l'utilisateur (28/09/2026) : « rajouter des couleurs dans la palette, la
// gomme comme outil, plus un mode interactif que l'on peut activer au choix ».

#if canImport(SwiftUI) && canImport(AVFoundation)
@testable import ColoringUI
import CoreGraphics
import EveilDesign
import XCTest

final class ColoringToolsTests: XCTestCase {
    // MARK: Palette

    func testPaletteHasTwentyFourDistinctNamedColors() {
        let palette = ColoringView.palette
        XCTAssertEqual(palette.count, 24)
        XCTAssertEqual(Set(palette.map(\.packed)).count, palette.count, "deux pastilles identiques")
        XCTAssertEqual(Set(palette.map(\.nameFR)).count, palette.count)
        XCTAssertEqual(Set(palette.map(\.nameEN)).count, palette.count)
        // Des couleurs de peau pour tous les enfants.
        XCTAssertEqual(palette.filter { $0.nameFR.hasPrefix("peau") }.count, 4)
        for name in ["rouge", "jaune", "vert", "bleu", "noir", "blanc", "marron", "gris"] {
            XCTAssertTrue(palette.contains { $0.nameFR == name }, name)
        }
    }

    func testPaletteRowsAreFull() {
        // Rangées complètes dans les deux mises en page : aucune pastille orpheline.
        XCTAssertEqual(ColoringView.palette.count % WorkshopLayout.rowPaletteColumns, 0)
        XCTAssertEqual(ColoringView.palette.count % WorkshopLayout.gridPaletteColumns, 0)
    }

    /// Chaque couleur chante une note de la gamme pentatonique, du plus grave au plus aigu.
    func testEachColorHasItsNote() {
        let notes = ColoringView.palette.indices.map { ColoringView.note(ofColor: $0) }
        XCTAssertEqual(notes.first, 0)
        XCTAssertEqual(notes.last, 14)
        XCTAssertEqual(notes, notes.sorted(), "la palette monte la gamme")
        XCTAssertTrue(notes.allSatisfy { (0...14).contains($0) })
    }

    // MARK: Gomme

    /// Trois bandes verticales séparées par deux traits : zones gauche, milieu, droite.
    private func stripes(_ n: Int = 256) -> ZoneMap {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0.33, y: -0.1))
        path.addLine(to: CGPoint(x: 0.33, y: 1.1))
        path.move(to: CGPoint(x: 0.66, y: -0.1))
        path.addLine(to: CGPoint(x: 0.66, y: 1.1))
        return ZoneMap(lineArt: LineArt(strokes: path, ink: CGMutablePath(), lineWidth: 0.02), size: n)
    }

    func testEraserWhitensOnlyItsZoneAndIsUndoable() {
        let map = stripes()
        let layer = PaintLayer(width: map.width, height: map.height)
        let red = ColoringView.palette[0].packed
        for x in [0.1, 0.5, 0.9] {
            layer.fill(zone: map.zone(at: CGPoint(x: x, y: 0.5)), color: red, in: map)
        }
        let before = layer.copyPixels()
        let middle = map.zone(at: CGPoint(x: 0.5, y: 0.5))
        // La gomme part du milieu et file à travers les deux traits.
        layer.beginStroke(at: CGPoint(x: 128, y: 128), zone: middle, color: PaintLayer.transparent, radius: 30, in: map)
        for p in [CGPoint(x: 5, y: 60), CGPoint(x: 250, y: 120), CGPoint(x: 128, y: 250)] {
            layer.continueStroke(to: p, in: map)
        }
        XCTAssertTrue(layer.endStroke(in: map))
        var erased = 0
        for i in 0..<(map.width * map.height) where layer.pixel(i) != before[i] {
            XCTAssertEqual(Int(map.labels[i]), middle, "la gomme a débordé au pixel \(i)")
            erased += 1
        }
        XCTAssertGreaterThan(erased, 2000)
        XCTAssertEqual(layer.pixel(128 * map.width + 128), PaintLayer.transparent, "le papier est redevenu blanc")
        XCTAssertTrue(layer.undo(in: map))
        XCTAssertEqual(layer.copyPixels(), before, "annuler rend le coloriage d'avant la gomme")
    }

    func testEraserIsWiderThanTheBrush() {
        XCTAssertGreaterThan(ColoringStudio.eraserRadius, ColoringStudio.brushRadius)
    }

    // MARK: Mode interactif

    func testInteractiveModeIsOffByDefault() {
        XCTAssertFalse(SuiteSettings.coloringInteractiveDefault)
        XCTAssertEqual(SuiteSettings.coloringInteractiveKey, "eveil.coloring.interactive")
    }

    /// Le dessin danse puis se pose exactement ; « Réduire les animations » : il ne bouge pas.
    func testTheDrawingDancesThenRests() {
        let start = Date(timeIntervalSinceReferenceDate: 1000)
        let rest = ColoringView.dance(since: nil, at: start, reduceMotion: false)
        XCTAssertEqual(rest.stretch, 0)
        XCTAssertEqual(rest.tilt, 0)
        let moving = ColoringView.dance(since: start, at: start.addingTimeInterval(0.1), reduceMotion: false)
        XCTAssertNotEqual(moving.tilt, 0)
        XCTAssertLessThan(abs(moving.stretch), 0.05)
        let after = ColoringView.dance(since: start, at: start.addingTimeInterval(5), reduceMotion: false)
        XCTAssertEqual(after.stretch, 0)
        XCTAssertEqual(after.tilt, 0)
        let still = ColoringView.dance(since: start, at: start.addingTimeInterval(0.1), reduceMotion: true)
        XCTAssertEqual(still.tilt, 0)
    }

    /// Les confettis : même fête à chaque fois (rien d'aléatoire), dans l'écran, puis plus rien.
    func testConfettiAreDeterministicAndEnd() {
        let size = CGSize(width: 834, height: 1150)
        var seen = 0
        for k in 0..<ConfettiLayer.count {
            let a = ConfettiLayer.piece(k, at: 1.0, in: size)
            let b = ConfettiLayer.piece(k, at: 1.0, in: size)
            XCTAssertEqual(a?.x, b?.x)
            XCTAssertEqual(a?.y, b?.y)
            if let a {
                seen += 1
                XCTAssertTrue((-40...size.width + 40).contains(a.x), "confetti \(k) hors de l'écran")
                XCTAssertTrue((0...1).contains(a.opacity))
            }
            XCTAssertNil(ConfettiLayer.piece(k, at: ConfettiLayer.duration + 0.1, in: size), "la fête s'arrête")
        }
        XCTAssertGreaterThan(seen, ConfettiLayer.count / 2, "à mi-fête, la plupart des confettis tombent")
    }
}
#endif
