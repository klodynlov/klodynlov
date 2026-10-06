// ColoringRenderSupport.swift — rendre les pages et l'écran en PNG pour les RELIRE à l'œil.
//
// `EVEIL_RENDER_DIR=/chemin swift test --filter ColoringUITests` écrit, pour chaque
// page : ses traits seuls, la carte de ses zones (une teinte par zone, témoins en
// rouge, détails voulus en bleu) et un exemple colorié ; puis l'écran entier aux
// tailles d'iPad. Sans la variable, les tests vérifient seulement que le rendu se
// fait. (Même approche que EveilDesignTests/RenderSupport.swift, recopiée ici :
// une cible de test n'importe pas les fichiers d'une autre.)

#if canImport(SwiftUI) && canImport(ImageIO) && canImport(UniformTypeIdentifiers)
@testable import ColoringUI
import CoreGraphics
import Foundation
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

enum ColoringRender {
    /// Dossier de sortie, ou `nil` si l'on ne veut pas de fichiers.
    static var outputDirectory: URL? {
        guard let path = ProcessInfo.processInfo.environment["EVEIL_RENDER_DIR"], !path.isEmpty else { return nil }
        let url = URL(fileURLWithPath: path, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static func write(_ image: CGImage, name: String) {
        guard let dir = outputDirectory else { return }
        let url = dir.appendingPathComponent("\(name).png")
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            return
        }
        CGImageDestinationAddImage(dest, image, nil)
        CGImageDestinationFinalize(dest)
    }

    /// Une page composée comme à l'écran : papier blanc, couleurs, traits nets par-dessus.
    /// `colors` : image des couleurs (celle de la couche de peinture) ; `marks` : points à signaler.
    static func page(_ art: LineArt, size: Int = 1024, colors: CGImage? = nil,
                     marks: [(CGPoint, CGColor)] = []) -> CGImage? {
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        let s = CGFloat(size)
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: s, height: s))
        ctx.interpolationQuality = .medium
        if let colors { ctx.draw(colors, in: CGRect(x: 0, y: 0, width: s, height: s)) }
        // Repère unité, y vers le bas (comme l'écran).
        ctx.translateBy(x: 0, y: s)
        ctx.scaleBy(x: s, y: -s)
        let ink = CGColor(red: 0.18, green: 0.20, blue: 0.29, alpha: 1)
        ctx.setFillColor(ink)
        ctx.addPath(art.ink)
        ctx.fillPath()
        ctx.setStrokeColor(ink)
        ctx.setLineWidth(art.lineWidth)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.addPath(art.strokes)
        ctx.strokePath()
        for (p, color) in marks {
            ctx.setFillColor(color)
            ctx.fillEllipse(in: CGRect(x: p.x - 0.007, y: p.y - 0.007, width: 0.014, height: 0.014))
        }
        return ctx.makeImage()
    }

    /// Une teinte pastel distincte par zone (0 = trait : transparent).
    static func zoneColors(_ map: ZoneMap) -> CGImage? {
        var pixels = [UInt32](repeating: 0, count: map.width * map.height)
        var palette = [UInt32](repeating: 0, count: map.zoneCount + 1)
        for z in 1...max(map.zoneCount, 1) where z <= map.zoneCount {
            var h = UInt32(truncatingIfNeeded: z &* 2_654_435_761)
            h ^= h >> 13
            let r = 110 + (h & 0x7F), g = 110 + ((h >> 8) & 0x7F), b = 110 + ((h >> 16) & 0x7F)
            palette[z] = r | g << 8 | b << 16 | 0xFF00_0000
        }
        for i in pixels.indices { pixels[i] = palette[Int(map.labels[i])] }
        return pixels.withUnsafeBytes { PaintLayer.image(from: Data($0), width: map.width, height: map.height) }
    }

    /// Rend une vue SwiftUI à la taille donnée (points, échelle 2).
    @MainActor
    @discardableResult
    static func view<V: View>(_ view: V, size: CGSize, name: String) -> CGImage? {
        let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
        renderer.scale = 2
        guard let image = renderer.cgImage else { return nil }
        write(image, name: name)
        return image
    }
}
#endif
