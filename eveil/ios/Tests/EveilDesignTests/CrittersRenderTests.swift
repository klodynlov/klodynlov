// CrittersRenderTests.swift — les bestioles, rendues en planches PNG pour les
// relire à l'œil, et quelques garanties vérifiées sur les pixels :
//   - chaque bestiole est dessinée, centrée, sans déborder de son carré ;
//   - les ailes bougent vraiment quand `flapping` (deux instants ≠) ;
//   - `tint` change bien la couleur des dessins qui le prennent.
//
// Planches (`EVEIL_RENDER_DIR`) : bestioles-repos-clair / -repos-sombre (90 pt),
// bestioles-battement-haut / -battement-bas (deux poses du battement),
// bestioles-50pt (la plus petite taille), bestioles-teintes.

#if canImport(SwiftUI) && canImport(ImageIO) && canImport(UniformTypeIdentifiers)
@testable import EveilDesign
import SwiftUI
import XCTest

@MainActor
final class CrittersRenderTests: XCTestCase {
    /// Instants choisis pour montrer les deux poses (ailes hautes / basses).
    static let upTime = 0.075
    static let downTime = 0.24

    private func sheet(size: CGFloat, background: Color, time: Double?, label: Bool = true) -> some View {
        let columns = Array(repeating: GridItem(.fixed(size + 24), spacing: 8), count: 7)
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(CritterKind.allCases, id: \.self) { kind in
                VStack(spacing: 2) {
                    CritterView(kind: kind, size: size, flapping: time != nil)
                        .environment(\.sceneryFrozenTime, time)
                    if label {
                        Text(kind.rawValue).font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(background == .white || background == EveilPalette.skyLight
                                             ? EveilPalette.ink : Color.white.opacity(0.8))
                    }
                }
            }
        }
        .padding(16)
        .background(background)
    }

    private func sheetSize(_ size: CGFloat, label: Bool = true) -> CGSize {
        CGSize(width: 7 * (size + 24) + 6 * 8 + 32, height: 2 * (size + (label ? 20 : 0)) + 10 + 32)
    }

    func testCritterSheets() throws {
        let night = LinearGradient(colors: [EveilPalette.nightTop, EveilPalette.nightBottom], startPoint: .top, endPoint: .bottom)
        XCTAssertNotNil(RenderSupport.render(sheet(size: 90, background: EveilPalette.skyLight, time: nil),
                                             size: sheetSize(90), name: "bestioles-repos-clair"))
        XCTAssertNotNil(RenderSupport.render(sheet(size: 90, background: .clear, time: nil).background(night),
                                             size: sheetSize(90), name: "bestioles-repos-sombre"))
        XCTAssertNotNil(RenderSupport.render(sheet(size: 90, background: EveilPalette.skyLight, time: Self.upTime),
                                             size: sheetSize(90), name: "bestioles-battement-haut"))
        XCTAssertNotNil(RenderSupport.render(sheet(size: 90, background: EveilPalette.skyLight, time: Self.downTime),
                                             size: sheetSize(90), name: "bestioles-battement-bas"))
        XCTAssertNotNil(RenderSupport.render(sheet(size: 50, background: .white, time: nil, label: false),
                                             size: sheetSize(50, label: false), name: "bestioles-50pt"))
    }

    func testTintSheet() throws {
        let tints: [Color] = [.red, .orange, .green, .blue, .purple, .pink]
        let kinds = CritterKind.allCases.filter(\.usesTint)
        let grid = VStack(spacing: 8) {
            ForEach(kinds, id: \.self) { kind in
                HStack(spacing: 8) {
                    CritterView(kind: kind, size: 80, flapping: false)
                    ForEach(0..<tints.count, id: \.self) { i in
                        CritterView(kind: kind, size: 80, flapping: false, tint: tints[i])
                    }
                }
            }
        }
        .padding(12)
        .background(Color.white)
        XCTAssertNotNil(RenderSupport.render(grid, size: CGSize(width: 7 * 88 + 16, height: CGFloat(kinds.count) * 88 + 16),
                                             name: "bestioles-teintes"))
    }

    /// Dessinée, centrée, sans déborder : le bord du carré reste (presque) vide.
    func testEveryCritterIsDrawnInsideItsSquare() throws {
        for kind in CritterKind.allCases {
            for time in [nil, Self.upTime, Self.downTime] as [Double?] {
                let probe = try alphaProbe(kind: kind, time: time, size: 90)
                let inner = probe.coverage(CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8))
                XCTAssertGreaterThan(inner, 0.08, "\(kind) : presque rien n'est dessiné")
                let border = probe.border(width: 0.02)
                XCTAssertLessThan(border, 0.12, "\(kind) (t = \(String(describing: time))) déborde de son carré")
                let left = probe.coverage(CGRect(x: 0, y: 0, width: 0.5, height: 1))
                let right = probe.coverage(CGRect(x: 0.5, y: 0, width: 0.5, height: 1))
                XCTAssertLessThan(abs(left - right), 0.35, "\(kind) : dessin décentré")
            }
        }
    }

    /// `flapping` fait vraiment battre les ailes (écart visible sur fond blanc) ; au repos, rien ne bouge.
    func testWingsMoveOnlyWhenFlapping() throws {
        var report: [String] = []
        for kind in CritterKind.allCases where kind.hasWings {
            func onWhite(_ t: Double) throws -> PixelProbe {
                PixelProbe(try image(CritterView(kind: kind, size: 90).environment(\.sceneryFrozenTime, t)
                    .background(Color.white)))
            }
            let moved = try onWhite(Self.upTime).difference(from: try onWhite(Self.downTime))
            report.append("\(kind) \(String(format: "%.4f", moved))")
            XCTAssertGreaterThan(moved, 0.008, "\(kind) : les ailes ne bougent pas assez")
        }
        print("battement (écart moyen de luminance) : " + report.joined(separator: " · "))
        for kind in CritterKind.allCases {
            let a = try alphaProbe(kind: kind, time: nil, size: 60)
            let b = try alphaProbe(kind: kind, time: nil, size: 60)
            XCTAssertEqual(a.alphaDifference(from: b), 0, "\(kind) : la pose de repos n'est pas stable")
        }
    }

    func testTintChangesTheDrawing() throws {
        for kind in CritterKind.allCases where kind.usesTint {
            let plain = try image(CritterView(kind: kind, size: 60, flapping: false))
            let tinted = try image(CritterView(kind: kind, size: 60, flapping: false, tint: .green))
            XCTAssertGreaterThan(PixelProbe(plain).difference(from: PixelProbe(tinted)), 0.005, "\(kind) ignore sa teinte")
        }
    }

    // MARK: Outils

    private func image<V: View>(_ view: V) throws -> CGImage {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        return try XCTUnwrap(renderer.cgImage)
    }

    private func alphaProbe(kind: CritterKind, time: Double?, size: CGFloat) throws -> AlphaProbe {
        let view = CritterView(kind: kind, size: size, flapping: time != nil).environment(\.sceneryFrozenTime, time)
        return AlphaProbe(try image(view))
    }
}

/// Couverture (alpha) d'une image à fond transparent.
struct AlphaProbe {
    let width: Int
    let height: Int
    private let alpha: [UInt8]

    init(_ image: CGImage) {
        let wd = image.width, ht = image.height
        width = wd
        height = ht
        var rgba = [UInt8](repeating: 0, count: wd * ht * 4)
        let space = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        rgba.withUnsafeMutableBytes { buf in
            if let ctx = CGContext(data: buf.baseAddress, width: wd, height: ht, bitsPerComponent: 8, bytesPerRow: wd * 4,
                                   space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
                ctx.draw(image, in: CGRect(x: 0, y: 0, width: wd, height: ht))
            }
        }
        alpha = stride(from: 3, to: rgba.count, by: 4).map { rgba[$0] }
    }

    /// Part des pixels visibles (alpha > 10 %) dans `rect` (fractions, origine en haut à gauche).
    func coverage(_ rect: CGRect) -> Double {
        let x0 = Int(rect.minX * CGFloat(width)), x1 = Int(rect.maxX * CGFloat(width))
        let y0 = Int(rect.minY * CGFloat(height)), y1 = Int(rect.maxY * CGFloat(height))
        var on = 0, n = 0
        for y in y0..<y1 {
            for x in x0..<x1 {
                n += 1
                if alpha[y * width + x] > 25 { on += 1 }
            }
        }
        return n == 0 ? 0 : Double(on) / Double(n)
    }

    /// Couverture de la bordure (épaisseur relative `width`).
    func border(width w: CGFloat) -> Double {
        let bands = [CGRect(x: 0, y: 0, width: 1, height: w), CGRect(x: 0, y: 1 - w, width: 1, height: w),
                     CGRect(x: 0, y: 0, width: w, height: 1), CGRect(x: 1 - w, y: 0, width: w, height: 1)]
        return bands.map(coverage).max() ?? 0
    }

    /// Écart moyen de couverture avec une autre image de même taille.
    func alphaDifference(from other: AlphaProbe) -> Double {
        guard other.width == width, other.height == height else { return 1 }
        var d = 0
        for i in 0..<alpha.count { d += abs(Int(alpha[i]) - Int(other.alpha[i])) }
        return Double(d) / Double(alpha.count) / 255
    }
}
#endif
