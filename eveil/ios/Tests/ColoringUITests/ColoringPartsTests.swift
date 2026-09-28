// ColoringPartsTests.swift — les consignes du mode interactif visent de vraies zones.
//
// « Colorie le soleil en jaune » : pour CHAQUE page, sur sa vraie carte 1024 × 1024, chaque
// partie nommée a ses points dans des zones (jamais sur un trait), assez grandes pour un doigt
// (pas un détail) ; deux parties ne visent jamais la même zone ; la couleur proposée est une
// couleur de la palette (ou « au choix ») ; le nom a son article (la voix le dit tel quel).

#if canImport(SwiftUI) && canImport(AVFoundation)
@testable import ColoringUI
import CoreGraphics
import XCTest

final class ColoringPartsTests: XCTestCase {
    func testEveryPartAimsAtItsOwnZones() {
        let colors = Set(ColoringView.palette.map(\.nameFR))
        var named = 0
        for page in ColoringPages.all {
            let map = ZoneMap(lineArt: page.lineArt)
            let parts = page.parts
            XCTAssertEqual(Set(parts.map(\.fr)).count, parts.count, "\(page.id) : deux parties du même nom")
            var owner: [Int: String] = [:]
            for part in parts {
                if let c = part.color {
                    XCTAssertTrue(colors.contains(c) || c == ColoringInstructions.anyColor, "\(page.id) : couleur « \(c) »")
                }
                XCTAssertFalse(part.points.isEmpty, "\(page.id) : « \(part.fr) » sans point")
                XCTAssertTrue(part.fr.contains(" ") || part.fr.hasPrefix("l'"), "\(page.id) : « \(part.fr) » sans article")
                XCTAssertTrue(part.en.hasPrefix("the "), "\(page.id) : « \(part.en) » sans article")
                for p in part.points {
                    let z = map.zone(at: p)
                    XCTAssertNotEqual(z, 0, "\(page.id) : « \(part.fr) » (\(p.x), \(p.y)) est sur un trait")
                    guard z != 0 else { continue }
                    XCTAssertGreaterThanOrEqual(map.fraction(of: z), 0.003, "\(page.id) : « \(part.fr) » vise un détail")
                    if let other = owner[z], other != part.fr {
                        XCTFail("\(page.id) : « \(part.fr) » et « \(other) » visent la même zone")
                    }
                    owner[z] = part.fr
                }
                named += 1
            }
        }
        XCTAssertGreaterThan(named, 80)
    }

    /// Le sujet d'abord, puis le décor ; le même nom deux fois = une seule partie.
    func testPartsOrderAndMerge() {
        var s = Sketch()
        s.part("le soleil", "the sun", color: "jaune", rank: 1, at: [(0.8, 0.1)])
        s.part("le toit", "the roof", color: "rouge", at: [(0.5, 0.3)])
        s.part("la roue", "the wheel", color: "noir", rank: 1, at: [(0.2, 0.8)])
        s.part("la roue", "the wheel", color: "noir", rank: 1, at: [(0.7, 0.8)])
        XCTAssertEqual(s.parts.map(\.fr), ["le toit", "le soleil", "la roue"])
        XCTAssertEqual(s.parts.last?.points.count, 2)
    }
}
#endif
