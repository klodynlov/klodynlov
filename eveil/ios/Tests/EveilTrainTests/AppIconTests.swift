// AppIconTests.swift — l'icône de l'app se dessine, et celle du projet Xcode est bien là.
//
// `EVEIL_APPICON_OUT=/chemin swift test --filter AppIconTests` écrit les variantes de l'icône
// (1024 × 1024, opaques) dans ce dossier ; `AppIcon.png` y est la variante retenue (`AppIconArt()`), à copier dans
// `App/Assets.xcassets/AppIcon.appiconset/`.

#if canImport(SwiftUI) && canImport(ImageIO) && canImport(UniformTypeIdentifiers)
import Foundation
import ImageIO
import SwiftUI
import TrainPracticeUI
import UniformTypeIdentifiers
import XCTest

@MainActor
final class AppIconTests: XCTestCase {
    func testEveryVariantRendersOpaqueAt1024() throws {
        for variant in AppIconArt.Variant.allCases {
            let image = try XCTUnwrap(render(AppIconArt(variant: variant)), "\(variant) : rien de rendu")
            XCTAssertEqual(image.width, 1024)
            XCTAssertEqual(image.height, 1024)
            write(image, name: "AppIcon-\(variant.rawValue)")
            if variant == AppIconArt().variant { write(image, name: "AppIcon") }
        }
    }

    /// L'icône du projet Xcode : présente, 1024 × 1024, sans canal alpha (refusé par l'App Store).
    func testXcodeProjectShipsTheIcon() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("App/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
        let source = try XCTUnwrap(CGImageSourceCreateWithURL(url as CFURL, nil), "icône absente : \(url.path)")
        let image = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
        XCTAssertEqual(image.width, 1024)
        XCTAssertEqual(image.height, 1024)
        XCTAssertTrue([.none, .noneSkipFirst, .noneSkipLast].contains(image.alphaInfo), "l'icône a un canal alpha")
    }

    private func render<V: View>(_ view: V) -> CGImage? {
        let renderer = ImageRenderer(content: view.frame(width: AppIconArt.side, height: AppIconArt.side))
        renderer.scale = 1
        renderer.isOpaque = true
        return renderer.cgImage
    }

    private func write(_ image: CGImage, name: String) {
        guard let dir = ProcessInfo.processInfo.environment["EVEIL_APPICON_OUT"], !dir.isEmpty else { return }
        let folder = URL(fileURLWithPath: dir, isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appendingPathComponent("\(name).png")
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
        else { return }
        CGImageDestinationAddImage(dest, image, nil)
        CGImageDestinationFinalize(dest)
    }
}
#endif
