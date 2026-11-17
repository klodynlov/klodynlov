// WorldsRenderTests.swift — les huit mondes du voyage, rendus en PNG pour les
// relire à l'œil, et le CONTRAT de mise en page vérifié sur les pixels :
//   - haut de l'écran (12 %) calme : peu de contraste (boutons posés dessus) ;
//   - bande du milieu (25–55 % h, 70 % central) claire et dégagée (carte, chat, bulle) ;
//   - sol (0,76 h → bas) : une bande où l'on peut poser le train et le gros bouton.
//
// `EVEIL_RENDER_DIR=/chemin swift test --filter EveilDesignTests` écrit :
//   monde-<nom>-portrait.png / -paysage.png   le décor seul (instant figé t = 0)
//   jeu-<nom>-portrait.png / -paysage.png     le décor sous une maquette de l'écran de jeu
//   mondes-planche.png                        les huit décors côte à côte
//   monde-<nom>-t7.png                        un autre instant (le mouvement a bien lieu)

#if canImport(SwiftUI) && canImport(ImageIO) && canImport(UniformTypeIdentifiers)
@testable import EveilDesign
import SwiftUI
import XCTest
#if canImport(AppKit)
import AppKit
#endif

@MainActor
final class WorldsRenderTests: XCTestCase {
    static let portrait = CGSize(width: 834, height: 1194)      // iPad Pro 11"
    static let landscape = CGSize(width: 1194, height: 834)

    private func scenery(_ world: World, at t: Double = 0) -> some View {
        WorldScenery(world: world).environment(\.sceneryFrozenTime, t)
    }

    func testEveryWorldRendersInBothOrientations() throws {
        for world in World.allCases {
            for (label, size) in [("portrait", Self.portrait), ("paysage", Self.landscape)] {
                let image = try XCTUnwrap(RenderSupport.render(scenery(world), size: size,
                                                               name: "monde-\(world)-\(label)", scale: 1),
                                          "\(world) \(label) : aucun rendu")
                XCTAssertEqual(image.width, Int(size.width))
                XCTAssertEqual(image.height, Int(size.height))
            }
        }
    }

    func testGameScreenMockupOverEachWorld() throws {
        for world in World.allCases {
            for (label, size) in [("portrait", Self.portrait), ("paysage", Self.landscape)] {
                let view = ZStack {
                    scenery(world)
                    GameScreenMockup(size: size, dark: world.isDark)
                }
                XCTAssertNotNil(RenderSupport.render(view, size: size, name: "jeu-\(world)-\(label)", scale: 1))
            }
        }
    }

    func testContactSheet() throws {
        let cell = CGSize(width: 278, height: 398)
        let sheet = VStack(spacing: 10) {
            ForEach(0..<2, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(0..<4, id: \.self) { col in
                        let world = World.allCases[row * 4 + col]
                        VStack(spacing: 4) {
                            self.scenery(world).frame(width: cell.width, height: cell.height)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            Label(world.name(locale: "fr-FR"), systemImage: world.symbol)
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(EveilPalette.ink)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color.white)
        XCTAssertNotNil(RenderSupport.render(sheet, size: CGSize(width: cell.width * 4 + 54, height: cell.height * 2 + 86),
                                             name: "mondes-planche", scale: 1))
    }

    /// Le décor bouge vraiment : deux instants différents ne donnent pas la même image.
    func testAmbientMotionChangesTheFrame() throws {
        for world in World.allCases {
            let a = try XCTUnwrap(RenderSupport.render(scenery(world, at: 0), size: Self.landscape,
                                                       name: "monde-\(world)-t0", scale: 1))
            let b = try XCTUnwrap(RenderSupport.render(scenery(world, at: 7.3), size: Self.landscape,
                                                       name: "monde-\(world)-t7", scale: 1))
            XCTAssertGreaterThan(PixelProbe(a).difference(from: PixelProbe(b)), 0.0005,
                                 "\(world) : rien ne bouge entre t = 0 et t = 7,3 s")
        }
    }

    /// Le contrat de mise en page, mesuré sur les pixels du décor seul.
    func testLayoutContractOnPixels() throws {
        var report: [String] = ["monde        orient.   haut σ   milieu µ  milieu σ   sol σ"]
        for world in World.allCases {
            for (label, size) in [("portrait", Self.portrait), ("paysage", Self.landscape)] {
                let renderer = ImageRenderer(content: scenery(world).frame(width: size.width, height: size.height))
                let probe = PixelProbe(try XCTUnwrap(renderer.cgImage))
                let top = probe.luminance(CGRect(x: 0, y: 0, width: 1, height: 0.12))
                let middle = probe.luminance(CGRect(x: 0.15, y: 0.25, width: 0.70, height: 0.30))
                let ground = probe.luminance(CGRect(x: 0.25, y: 0.78, width: 0.5, height: 0.10))
                report.append(String(format: "%-12@ %-9@ %6.3f   %7.3f   %7.3f   %6.3f", "\(world)" as NSString,
                                     label as NSString, top.std, middle.mean, middle.std, ground.std))
                XCTAssertLessThan(top.std, 0.08, "\(world) \(label) : le haut de l'écran n'est pas calme")
                XCTAssertLessThan(middle.std, 0.10, "\(world) \(label) : la bande du milieu est chargée")
                if !world.isDark {
                    XCTAssertGreaterThan(middle.mean, 0.62, "\(world) \(label) : la bande du milieu est trop sombre")
                }
                XCTAssertLessThan(ground.std, 0.10, "\(world) \(label) : le sol sous le bouton est chargé")
            }
        }
        print(report.joined(separator: "\n"))
    }

    func testJourneyVisitsEveryWorldThenLoops() {
        var seen: [World] = []
        var w = World.countryside
        for _ in World.allCases {
            seen.append(w)
            w = w.next
        }
        XCTAssertEqual(seen, World.allCases)
        XCTAssertEqual(w, .countryside)
        for world in World.allCases {
            XCTAssertFalse(world.name(locale: "fr-FR").isEmpty)
            XCTAssertFalse(world.name(locale: "en-US").isEmpty)
        }
        XCTAssertEqual(Set(World.allCases.map(\.symbol)).count, World.allCases.count, "pictogrammes en double")
    }

    #if canImport(AppKit)
    func testJourneySymbolsExist() {
        for world in World.allCases {
            XCTAssertNotNil(NSImage(systemSymbolName: world.symbol, accessibilityDescription: nil),
                            "\(world) : symbole système « \(world.symbol) » introuvable")
        }
    }
    #endif
}

// MARK: - Maquette de l'écran de jeu (approximative) pour juger la composition

/// Reprend la disposition de `PracticeView` : boutons en haut, carte + chat +
/// bulle au milieu, train dont les rails sont vers 0,745 h, gros bouton sur le sol.
struct GameScreenMockup: View {
    let size: CGSize
    let dark: Bool

    var body: some View {
        let w = size.width, h = size.height, wide = w > h
        let card = min(wide ? 300 : 250, h * 0.26)
        let cat = min(wide ? 250 : 210, h * 0.24)
        ZStack {
            HStack {
                Image(systemName: "house.fill").font(.system(size: 30, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 64, height: 64).background(Circle().fill(EveilPalette.ink.opacity(0.35)))
                Spacer()
                Image(systemName: "gearshape.fill").font(.system(size: 26))
                    .foregroundStyle(dark ? Color.white.opacity(0.7) : EveilPalette.ink.opacity(0.55))
                    .frame(width: 56, height: 56)
            }
            .padding(.horizontal, 28)
            .position(x: w / 2, y: 20 + 32)
            HStack(alignment: .center, spacing: wide ? 44 : 22) {
                VStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: card * 0.14, style: .continuous).fill(.white)
                        .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
                        .overlay(Image(systemName: "shower.fill").font(.system(size: card * 0.45))
                            .foregroundStyle(.green))
                        .frame(width: card, height: card)
                    Text("douche").font(.system(size: 26, weight: .semibold, design: .rounded))
                        .foregroundStyle(dark ? Color.white.opacity(0.85) : EveilPalette.ink.opacity(0.7))
                }
                HStack(spacing: 6) {
                    CatStationMaster(mood: .cheering, size: cat)
                    SpeechBubble("Bravo ! Tout le train est parti !").frame(maxWidth: wide ? 380 : 300)
                }
            }
            .position(x: w / 2, y: h * (wide ? 0.34 : 0.31))
            MockTrain().frame(width: 560, height: 150).position(x: w / 2, y: h * 0.745 - 75)
            Label("À toi !", systemImage: "ear.fill")
                .font(.system(size: 36, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                .padding(.horizontal, 48).padding(.vertical, 22)
                .background(Capsule().fill(EveilPalette.go).shadow(color: .black.opacity(0.18), radius: 8, y: 6))
                .position(x: w / 2, y: h * 0.745 + 70)
        }
        .frame(width: w, height: h)
    }
}

/// Silhouette du petit train (le vrai vit dans TrainPracticeUI).
private struct MockTrain: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            HStack(spacing: 22) {
                ForEach(0..<14, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 2).fill(EveilPalette.rail.opacity(0.75)).frame(width: 18, height: 12)
                }
            }
            .frame(width: 560, alignment: .leading).clipped()
            Rectangle().fill(EveilPalette.rail).frame(width: 560, height: 5).offset(y: -8)
            HStack(alignment: .bottom, spacing: 8) {
                RoundedRectangle(cornerRadius: 20).fill(EveilPalette.loco).frame(width: 190, height: 110)
                RoundedRectangle(cornerRadius: 16).fill(EveilPalette.wagonLit).frame(width: 130, height: 84)
                RoundedRectangle(cornerRadius: 14).fill(EveilPalette.caboose).frame(width: 120, height: 76)
            }
            .padding(.leading, 30).padding(.bottom, 26)
            HStack(spacing: 38) {
                ForEach(0..<7, id: \.self) { _ in Circle().fill(Color(white: 0.22)).frame(width: 36, height: 36) }
            }
            .padding(.leading, 40).padding(.bottom, 8)
        }
        .frame(width: 560, height: 150, alignment: .bottomLeading)
    }
}

// MARK: - Lecture des pixels

/// Luminance des pixels d'une image (sRGB 8 bits), par région relative.
struct PixelProbe {
    let width: Int
    let height: Int
    private let lum: [Float]

    init(_ image: CGImage) {
        let wd = image.width, ht = image.height
        width = wd
        height = ht
        var rgba = [UInt8](repeating: 0, count: wd * ht * 4)
        let space = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        rgba.withUnsafeMutableBytes { buf in
            if let ctx = CGContext(data: buf.baseAddress, width: wd, height: ht, bitsPerComponent: 8,
                                   bytesPerRow: wd * 4, space: space,
                                   bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
                ctx.draw(image, in: CGRect(x: 0, y: 0, width: wd, height: ht))
            }
        }
        var l = [Float](repeating: 0, count: wd * ht)
        for i in 0..<(wd * ht) {
            let r = Float(rgba[i * 4]), g = Float(rgba[i * 4 + 1]), b = Float(rgba[i * 4 + 2])
            l[i] = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255
        }
        lum = l
    }

    /// Moyenne et écart-type de la luminance dans `rect` (fractions de l'image, origine en haut).
    func luminance(_ rect: CGRect) -> (mean: Double, std: Double) {
        let x0 = Int(rect.minX * CGFloat(width)), x1 = Int(rect.maxX * CGFloat(width))
        let y0 = Int(rect.minY * CGFloat(height)), y1 = Int(rect.maxY * CGFloat(height))
        var sum = 0.0, sq = 0.0, n = 0.0
        // En mémoire, la première rangée du bitmap est le HAUT de l'image.
        for y in stride(from: y0, to: y1, by: 2) {
            let row = y * width
            for x in stride(from: x0, to: x1, by: 2) {
                let v = Double(lum[row + x])
                sum += v; sq += v * v; n += 1
            }
        }
        guard n > 0 else { return (0, 0) }
        let mean = sum / n
        return (mean, max(0, sq / n - mean * mean).squareRoot())
    }

    /// Écart moyen de luminance avec une autre image de même taille.
    func difference(from other: PixelProbe) -> Double {
        guard other.width == width, other.height == height else { return 1 }
        var d = 0.0
        for i in stride(from: 0, to: lum.count, by: 3) { d += Double(abs(lum[i] - other.lum[i])) }
        return d / Double(lum.count / 3)
    }
}
#endif
