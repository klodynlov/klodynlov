// SmokeRenderTests.swift — le rendu PNG fonctionne (base des planches à relire).

#if canImport(SwiftUI) && canImport(ImageIO) && canImport(UniformTypeIdentifiers)
import EveilDesign
import SwiftUI
import XCTest

@MainActor
final class SmokeRenderTests: XCTestCase {
    func testMascotRendersToAnImage() throws {
        let image = RenderSupport.render(CatStationMaster(mood: .hello, size: 200),
                                         size: CGSize(width: 220, height: 260), name: "mascotte")
        let cg = try XCTUnwrap(image, "ImageRenderer n'a rien produit")
        XCTAssertEqual(cg.width, 440)
    }
}
#endif
