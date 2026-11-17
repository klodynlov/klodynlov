// RenderSupport.swift — rendre une vue SwiftUI en PNG pour la RELIRE à l'œil.
//
// `EVEIL_RENDER_DIR=/chemin swift test --filter EveilDesignTests` écrit les
// planches (mondes, bestioles, dessins des mots) dans ce dossier. Sans la
// variable, les tests vérifient seulement que le rendu produit une image.

#if canImport(SwiftUI) && canImport(ImageIO) && canImport(UniformTypeIdentifiers)
import Foundation
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

enum RenderSupport {
    /// Dossier de sortie, ou `nil` si l'on ne veut pas de fichiers.
    static var outputDirectory: URL? {
        guard let path = ProcessInfo.processInfo.environment["EVEIL_RENDER_DIR"], !path.isEmpty else { return nil }
        let url = URL(fileURLWithPath: path, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Rend `view` à la taille donnée (points) ; écrit `name`.png si un dossier est fixé.
    @MainActor
    @discardableResult
    static func render<V: View>(_ view: V, size: CGSize, name: String, scale: CGFloat = 2) -> CGImage? {
        let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
        renderer.scale = scale
        guard let image = renderer.cgImage else { return nil }
        if let dir = outputDirectory {
            let url = dir.appendingPathComponent("\(name).png")
            if let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) {
                CGImageDestinationAddImage(dest, image, nil)
                CGImageDestinationFinalize(dest)
            }
        }
        return image
    }
}
#endif
