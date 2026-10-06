// ColoringPagesTests.swift — chaque page tient ses promesses : des zones fermées, pas de fuite.
//
// Pour CHAQUE page, sur sa vraie carte 1024 × 1024 :
// - chaque point-témoin (le cœur d'une forme dessinée) tombe dans une zone, pas sur
//   un trait, pas dans le fond du coin de la page, et jamais dans la même zone
//   qu'un autre témoin : aucune forme ne fuit dans sa voisine ;
// - toute zone de moins de 0,3 % de la page est un détail VOULU (déclaré) ;
// - le nombre de zones reste raisonnable pour un enfant de 3-5 ans ;
// - l'étiquetage d'une page 1024² prend moins d'une demi-seconde en Debug sur Mac.

#if canImport(CoreGraphics)
@testable import ColoringUI
import CoreGraphics
import XCTest

final class ColoringPagesTests: XCTestCase {
    func testPagesHaveUniqueIdsAndTitles() {
        let pages = ColoringPages.all
        XCTAssertGreaterThanOrEqual(pages.count, 60)
        XCTAssertEqual(Set(pages.map(\.id)).count, pages.count)
        XCTAssertEqual(Set(pages.map(\.titleFR)).count, pages.count)
        for page in pages {
            XCTAssertFalse(page.title(locale: "fr-FR").isEmpty)
            XCTAssertFalse(page.title(locale: "en-US").isEmpty)
            XCTAssertNotEqual(page.title(locale: "fr-FR"), page.title(locale: "en-US"), page.id)
        }
    }

    func testEveryPageIsInExactlyOneAlbum() {
        var seen: [String: String] = [:]
        for album in ColoringPages.albums {
            XCTAssertFalse(album.pages.isEmpty, album.id)
            XCTAssertLessThanOrEqual(album.pages.count, ColoringPages.albumCapacity, "\(album.id) : trop de pages")
            XCTAssertNotEqual(album.title(locale: "fr-FR"), album.title(locale: "en-US"), album.id)
            for page in album.pages {
                if let other = seen[page.id] { XCTFail("\(page.id) est dans \(other) et \(album.id)") }
                seen[page.id] = album.id
            }
        }
        XCTAssertEqual(seen.count, ColoringPages.all.count)
        // Chaque album des pages générées existe (sinon ses pages seraient perdues).
        let ids = Set(ColoringPages.albums.map(\.id))
        for key in DrawnPages.byAlbum.keys { XCTAssertTrue(ids.contains(key), "album inconnu : \(key)") }
    }

    func testEveryDrawnShapeIsItsOwnZone() {
        for page in ColoringPages.all {
            let sketch = page.sketch
            let map = ZoneMap(lineArt: page.lineArt)
            let corner = map.zone(at: CGPoint(x: 0.004, y: 0.004))
            XCTAssertNotEqual(corner, 0, "\(page.id) : le coin de la page est sur un trait")
            var owner: [Int: String] = [:]
            let marks = sketch.probes.map { ($0, "témoin") } + sketch.details.map { ($0, "détail") }
            for (p, kind) in marks {
                let label = "\(page.id) : \(kind) (\(p.x), \(p.y))"
                let z = map.zone(at: p)
                XCTAssertNotEqual(z, 0, "\(label) est sur un trait")
                guard z != 0 else { continue }
                XCTAssertNotEqual(z, corner, "\(label) fuit dans le fond")
                if let other = owner[z] { XCTFail("\(label) partage sa zone avec \(other)") }
                owner[z] = label
                if kind == "témoin" {
                    XCTAssertGreaterThanOrEqual(map.fraction(of: z), 0.003,
                                                "\(label) : zone de \(percent(map.fraction(of: z))) — un détail ?")
                }
            }
        }
    }

    func testTinyZonesAreIntendedDetails() {
        for page in ColoringPages.all {
            let sketch = page.sketch
            let map = ZoneMap(lineArt: page.lineArt)
            let declared = Set(sketch.details.map { map.zone(at: $0) })
            for z in 1...map.zoneCount where map.fraction(of: z) < 0.003 && !declared.contains(z) {
                XCTFail("\(page.id) : zone \(z) de \(percent(map.fraction(of: z))) non voulue, vers \(where_(z, map))")
            }
        }
    }

    func testZoneCountsSuitYoungChildren() {
        for page in ColoringPages.all {
            let map = ZoneMap(lineArt: page.lineArt)
            XCTAssertTrue((6...80).contains(map.zoneCount), "\(page.id) : \(map.zoneCount) zones")
        }
    }

    func testLabelingIsFastEnough() {
        // Objectif produit : < 100 ms sur iPad M1 en Debug ; garde-fou ici : < 0,5 s sur Mac en Debug.
        var report: [String] = []
        for page in ColoringPages.all {
            let art = page.lineArt
            let t0 = Date()
            let raster = ZoneMap.rasterize(art, size: 1024)
            let t1 = Date()
            let map = ZoneMap(mask: raster.mask, width: 1024, height: 1024, rasterLineWidth: raster.lineWidth)
            let t2 = Date()
            let total = t2.timeIntervalSince(t0)
            report.append(String(format: "%@ %.0f+%.0f ms (%d zones)", page.id, t1.timeIntervalSince(t0) * 1000,
                                 t2.timeIntervalSince(t1) * 1000, map.zoneCount))
            XCTAssertLessThan(total, 0.5, "\(page.id) : \(total) s")
        }
        print("Carte des zones 1024² (rastérisation + étiquetage) : " + report.joined(separator: " · "))
    }

    func testLineArtIsQuickToBuild() {
        // Les traits visibles (élimination des parties cachées) se calculent une fois par page, en tâche
        // de fond ; la toute première page peut l'être sur le fil principal : il faut que ce soit bref.
        var report: [String] = []
        for page in ColoringPages.all {
            let t0 = Date()
            let art = page.sketch.lineArt(lineWidth: page.lineWidth)
            let dt = Date().timeIntervalSince(t0)
            XCTAssertFalse(art.strokes.isEmpty, page.id)
            report.append(String(format: "%@ %.0f ms", page.id, dt * 1000))
            XCTAssertLessThan(dt, 0.25, "\(page.id) : \(dt) s")
        }
        print("Traits visibles : " + report.joined(separator: " · "))
    }

    private func percent(_ f: Double) -> String { String(format: "%.3f %%", f * 100) }

    /// Centre approximatif d'une zone (pour dire où elle est).
    private func where_(_ z: Int, _ map: ZoneMap) -> String {
        var sx = 0, sy = 0, n = 0
        for i in stride(from: 0, to: map.labels.count, by: 1) where Int(map.labels[i]) == z {
            sx += i % map.width
            sy += i / map.width
            n += 1
        }
        guard n > 0 else { return "?" }
        return String(format: "(%.3f, %.3f)", Double(sx) / Double(n) / Double(map.width),
                      Double(sy) / Double(n) / Double(map.height))
    }
}
#endif
