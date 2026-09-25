// ColoringRenderTests.swift — les planches à relire : chaque page, et l'écran aux tailles d'iPad.
//
// Avec EVEIL_RENDER_DIR, écrit pour chaque page `<id>-1-traits.png`, `<id>-2-zones.png`
// (une teinte par zone ; témoins en rouge, détails voulus en bleu) et
// `<id>-3-colorie.png` (chaque zone-témoin remplie, un coup de pinceau) ; puis
// l'écran entier : iPad 11" portrait/paysage, 13" portrait, et le choix des pages.

#if canImport(SwiftUI) && canImport(ImageIO) && canImport(UniformTypeIdentifiers)
@testable import ColoringUI
import CoreGraphics
import SwiftUI
import XCTest

final class ColoringRenderTests: XCTestCase {
    func testRenderEveryPage() throws {
        let red = CGColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
        let blue = CGColor(red: 0.1, green: 0.3, blue: 0.95, alpha: 1)
        for page in ColoringPages.all {
            let art = page.lineArt
            let sketch = page.sketch
            let map = ZoneMap(lineArt: art)
            let lines = try XCTUnwrap(ColoringRender.page(art), page.id)
            XCTAssertEqual(lines.width, 1024)
            ColoringRender.write(lines, name: "\(page.id)-1-traits")
            let marks = sketch.probes.map { ($0, red) } + sketch.details.map { ($0, blue) }
            if let zones = ColoringRender.page(art, colors: ColoringRender.zoneColors(map), marks: marks) {
                ColoringRender.write(zones, name: "\(page.id)-2-zones")
            }
            // Coloriage d'exemple : chaque zone-témoin, une couleur de la palette ; un coup de pinceau.
            let layer = PaintLayer()
            for (k, p) in (sketch.probes + sketch.details).enumerated() {
                let color = ColoringView.palette[k % 9].packed
                layer.fill(zone: map.zone(near: p), color: color, in: map)
            }
            if let first = sketch.probes.first {
                let start = CGPoint(x: first.x * 1024, y: first.y * 1024)
                layer.beginStroke(at: start, zone: map.zone(at: first), color: ColoringView.palette[9].packed,
                                  radius: ColoringStudio.brushRadius * 1024, in: map)
                layer.continueStroke(to: CGPoint(x: start.x + 160, y: start.y + 40), in: map)
                layer.continueStroke(to: CGPoint(x: start.x - 120, y: start.y + 90), in: map)
                layer.endStroke(in: map)
            }
            if let colored = ColoringRender.page(art, colors: layer.makeImage()) {
                ColoringRender.write(colored, name: "\(page.id)-3-colorie")
            }
        }
    }

    @MainActor
    func testRenderScreens() throws {
        for (name, size, picker, pageIndex) in [
            ("ecran-11-portrait", CGSize(width: 834, height: 1150), false, 0),
            ("ecran-13-portrait", CGSize(width: 1032, height: 1330), false, 3),
            ("ecran-11-paysage", CGSize(width: 1194, height: 790), false, 4),
            ("ecran-13-paysage", CGSize(width: 1376, height: 988), false, 6),
            ("choix-des-pages", CGSize(width: 834, height: 1150), true, 1),
        ] as [(String, CGSize, Bool, Int)] {
            let studio = ColoringStudio()
            studio.open(pageIndex)
            studio.loadSynchronously()
            // Un peu de couleur, comme un enfant l'aurait fait.
            let sketch = studio.page.sketch
            for (k, p) in sketch.probes.prefix(6).enumerated() {
                studio.fill(at: p, color: ColoringView.palette[(k * 3) % 9])
            }
            if picker {
                studio.open(0)
                studio.loadSynchronously()
                studio.fill(at: CGPoint(x: 0.5, y: 0.93), color: ColoringView.palette[3])
                studio.refreshThumbnail()
            }
            let view = ColoringView(locale: "fr-FR", onHome: {}, studio: studio, showPicker: picker)
            let image = try XCTUnwrap(ColoringRender.view(view, size: size, name: name), name)
            XCTAssertEqual(image.width, Int(size.width * 2))
        }
    }

    /// Tailles utiles (hors barre d'état et indicateur d'accueil) : iPad 11" et 13", portrait et paysage,
    /// et iPad mini en portrait.
    static let iPadSizes = [CGSize(width: 834, height: 1150), CGSize(width: 1032, height: 1330),
                            CGSize(width: 1194, height: 790), CGSize(width: 1376, height: 988),
                            CGSize(width: 744, height: 1090)]

    @MainActor
    func testLayoutFitsIPads() {
        // La palette tient avec de bonnes marges ; la page est grande ; les boutons restent gros.
        for size in Self.iPadSizes {
            let l = WorkshopLayout(size: size)
            let toolColumn = 7.26 * l.tool + 6
            if l.portrait {
                XCTAssertLessThanOrEqual(l.swatch * WorkshopLayout.rowPaletteSwatches, size.width - 70, "palette trop large : \(size)")
                XCTAssertLessThanOrEqual(2 * l.margin + l.tool + l.gap + l.side, size.width + 0.5, "\(size)")
                XCTAssertLessThanOrEqual(2 * l.margin + WorkshopLayout.headerHeight + max(l.side, toolColumn) + l.swatch * 1.4
                                         + 3 * l.gap, size.height + 0.5, "\(size)")
            } else {
                XCTAssertLessThanOrEqual(2 * l.margin + l.tool + l.side + l.swatch * WorkshopLayout.gridPaletteWidth + 2 * l.gap,
                                         size.width + 0.5, "\(size)")
                XCTAssertLessThanOrEqual(2 * l.margin + WorkshopLayout.headerHeight + 2 * l.gap
                                         + max(l.side, toolColumn, l.swatch * WorkshopLayout.gridPaletteHeight),
                                         size.height + 0.5, "\(size)")
            }
            XCTAssertGreaterThanOrEqual(l.swatch, 52, "pastilles trop petites pour \(size)")
            XCTAssertGreaterThanOrEqual(l.tool, 60, "\(size)")
            XCTAssertGreaterThanOrEqual(l.side, 560, "page trop petite pour \(size)")
        }
    }

    func testPagePickerShowsEveryAlbumAtOnce() {
        // Toutes les pages d'un album visibles d'un coup, sans défiler, sur chaque iPad ; la rangée
        // des albums tient en largeur, avec des boutons assez grands pour un doigt.
        for size in Self.iPadSizes {
            let width = min(size.width - 40, 1100) - 2 * GridPlan.padding
            let height = GridPlan.gridHeight(panel: size.height - 40, albums: true)
            for album in ColoringPages.albums {
                let plan = GridPlan(count: album.pages.count, width: width, height: height)
                XCTAssertTrue(plan.fits, "\(size) \(album.id) : il faudrait défiler")
                XCTAssertGreaterThanOrEqual(plan.thumb, 140, "\(size) \(album.id) : vignettes de \(plan.thumb) pt")
                XCTAssertGreaterThanOrEqual(plan.columns * plan.rows, album.pages.count)
            }
            XCTAssertGreaterThanOrEqual(AlbumBar.buttonWidth(count: ColoringPages.albums.count, width: width), 76,
                                        "\(size) : boutons d'album trop étroits")
        }
    }

    func testPagePickerGroupsFollowTheAlbums() {
        let groups = PageGroup.groups(for: ColoringPages.all)
        XCTAssertEqual(groups.count, ColoringPages.albums.count, "aucune page hors album")
        XCTAssertEqual(groups.flatMap(\.pages).sorted(), Array(ColoringPages.all.indices))
        for (k, album) in ColoringPages.albums.enumerated() {
            XCTAssertEqual(groups[k].pages.map { ColoringPages.all[$0].id }, album.pages.map(\.id))
        }
    }
}
#endif
