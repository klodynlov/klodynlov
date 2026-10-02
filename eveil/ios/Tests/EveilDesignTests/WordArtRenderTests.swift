// WordArtRenderTests.swift — les dessins des mots : tous là, dans leur carré, et relisibles à l'œil.
//
// Vérifie sans regarder : chaque mot des lexiques fr-FR / en-US a son dessin ; aucun
// dessin n'est vide ni ne déborde (au repos, marge ≥ 4 % ; pendant l'action, rien
// n'est coupé par le bord) ; chaque action revient à la pose de repos (pas de saut
// à la fin de l'animation) ; le calendrier du clignement avance toujours.
//
// Avec `EVEIL_RENDER_DIR=/chemin swift test --filter WordArtRenderTests`, écrit aussi
// de quoi RELIRE les dessins :
//   wordart-planche-fr.png, wordart-planche-en.png   planches de contact (cartes comme en jeu)
//   wordart-actions-N.png                            l'action image par image + le clignement
//   wordart-<id>.png                                 chaque dessin seul, 250 pt, sur sa carte

#if canImport(SwiftUI) && canImport(ImageIO) && canImport(UniformTypeIdentifiers)
@testable import EveilDesign
import SwiftUI
import XCTest
#if canImport(AppKit)
import AppKit
#endif

@MainActor
final class WordArtRenderTests: XCTestCase {

    // MARK: Couverture des lexiques

    /// Les identifiants des deux lexiques, lus dans le dépôt (eveil/lexique/*.json).
    private func lexiconIds() throws -> [String] {
        let lexique = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()      // EveilDesignTests
            .deletingLastPathComponent()      // Tests
            .deletingLastPathComponent()      // ios
            .deletingLastPathComponent()      // eveil
            .appendingPathComponent("lexique")
        var ids: [String] = []
        for file in ["fr-FR.json", "en-US.json"] {
            let data = try Data(contentsOf: lexique.appendingPathComponent(file))
            let root = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
            let words = try XCTUnwrap(root["words"] as? [[String: Any]], "pas de « words » dans \(file)")
            ids += words.compactMap { $0["id"] as? String }
        }
        return ids
    }

    func testEveryLexiconWordHasADrawing() throws {
        let ids = try lexiconIds()
        XCTAssertFalse(ids.isEmpty)
        for id in ids {
            XCTAssertTrue(WordArt.isIllustrated(id), "\(id) n'a pas de dessin")
        }
        XCTAssertEqual(Set(WordArtSubject.allCases.map(\.rawValue)), Set(ids),
                       "un dessin sans mot, ou un mot sans dessin")
    }

    func testUnknownWordKeepsTheSystemPictogram() {
        XCTAssertFalse(WordArt.isIllustrated("fr.inconnu"))
        XCTAssertNotNil(RenderSupport.render(WordArt(wordId: "fr.inconnu", size: 120),
                                             size: CGSize(width: 120, height: 120), name: "wordart-repli"))
    }

    // MARK: Vérifications au pixel

    /// Les images d'une action, de t = 0 (repos) à la fin.
    private static let actionTimes: [Double] = [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]

    /// Seule exception VOULUE : la manche du bras qui pousse (en.push) entre par le bord gauche.
    private static let entersFromTheLeft: Set<WordArtSubject> = [.push]

    func testEachDrawingIsInsideItsSquareAndNotEmpty() throws {
        let clock = Date()
        for subject in WordArtSubject.allCases {
            for t in Self.actionTimes {
                let pixels = try XCTUnwrap(Pixels(WordArtCanvas(subject: subject, pose: WordArtPose(t: t), size: 200)))
                XCTAssertGreaterThan(pixels.inkCount(), 2_000, "\(subject.rawValue) t=\(t) : dessin (presque) vide")
                // Au repos : la marge de 8 % est respectée à ±4 % près. Pendant l'action : rien n'est coupé.
                let border = t == 0 ? 8 : 1
                let touching = pixels.inkCount(border: border, ignoringLeft: Self.entersFromTheLeft.contains(subject))
                XCTAssertEqual(touching, 0, "\(subject.rawValue) t=\(t) : le dessin touche le bord (cadre \(pixels.inkBox()))")
            }
            // Le mouvement de repos (vapeur, bulles, gouttes, fumée, drapeau) ne sort pas non plus du cadre.
            guard subject.idle == .flow else { continue }
            for idle in [1.0, 1.45, 1.9, 2.35, 2.8, 3.25, 3.7] {
                for t in [0.0, 0.5] {
                    let pose = WordArtPose(t: t, idle: idle)
                    let pixels = try XCTUnwrap(Pixels(WordArtCanvas(subject: subject, pose: pose, size: 200)))
                    XCTAssertEqual(pixels.inkCount(border: 1), 0,
                                   "\(subject.rawValue) repos=\(idle) t=\(t) : touche le bord (cadre \(pixels.inkBox()))")
                }
            }
        }
        // 45 dessins × 10 poses : le rendu reste bon marché (ordre de grandeur, pas une mesure fine).
        print("WordArt : \(WordArtSubject.allCases.count * Self.actionTimes.count) rendus en \(String(format: "%.2f", Date().timeIntervalSince(clock))) s")
    }

    /// Dernière image d'une action (à 120 Hz, ≤ 1/120 s avant la fin) contre le repos :
    /// au plus un liseré d'un pixel peut bouger (1 % de l'image), jamais un saut visible.
    func testEveryActionComesBackToRest() throws {
        for subject in WordArtSubject.allCases {
            let rest = try XCTUnwrap(Pixels(WordArtCanvas(subject: subject, pose: WordArtPose(t: 0), size: 200)))
            let end = try XCTUnwrap(Pixels(WordArtCanvas(subject: subject, pose: WordArtPose(t: 0.995), size: 200)))
            let changed = rest.differingPixels(end)
            XCTAssertLessThan(changed, 400, "\(subject.rawValue) : l'action ne revient pas au repos (\(changed) px)")
        }
    }

    func testBlinkScheduleOnlyWakesUpAtTheEdgesOfABlink() {
        let start = Date(timeIntervalSinceReferenceDate: 1_000_003.3)
        let dates = Array(WordArtBlinkSchedule().entries(from: start, mode: .normal).prefix(7))
        XCTAssertEqual(dates.first, start)
        for (a, b) in zip(dates, dates.dropFirst()) {
            XCTAssertGreaterThan(b, a)
            XCTAssertLessThanOrEqual(b.timeIntervalSince(a), WordArtBlinkSchedule.period)
        }
        // Évalué PILE aux dates du calendrier (c'est ce que fait TimelineView) : fermé, ouvert, fermé…
        let states = dates.dropFirst().map { WordArtBlinkSchedule.isClosed(at: $0.timeIntervalSinceReferenceDate) }
        XCTAssertEqual(states, [true, false, true, false, true, false])
    }

    // MARK: La vraie vue, en direct : toucher → action → retour au repos

    #if canImport(AppKit)
    /// `WordArt` dans une vraie fenêtre : on incrémente `pulse` (comme l'écran de jeu au toucher),
    /// l'horloge tourne, le dessin bouge, puis revient à sa pose de repos une fois l'action finie.
    func testPulseStartsTheActionThenComesBackToRestInALiveView() throws {
        let live = try liveTap { pulse in WordArt(wordId: "fr.cloche", size: 200, pulse: pulse) }
        XCTAssertGreaterThan(live.during, 500, "la cloche ne se balance pas après le toucher")
        XCTAssertLessThan(live.after, 200, "la cloche n'est pas revenue au repos")
    }

    /// « Réduire les animations » : le toucher ne fait rien bouger (le son suffit).
    func testReduceMotionKeepsTheDrawingStillWhenTapped() throws {
        let live = try liveTap { pulse in
            WordArt(wordId: "fr.cloche", size: 200, pulse: pulse).environment(\._accessibilityReduceMotion, true)
        }
        XCTAssertLessThan(live.during, 50, "« Réduire les animations » : la cloche ne doit pas bouger")
    }

    /// Affiche `make(0)`, puis « touche » (`make(1)`) : pixels changés 0,2 s après le toucher,
    /// et une fois l'action finie (par rapport à l'image d'avant le toucher).
    private func liveTap<V: View>(_ make: (Int) -> V) throws -> (during: Int, after: Int) {
        let host = NSHostingView(rootView: make(0))
        host.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        let window = NSWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        window.orderFrontRegardless()
        defer { window.orderOut(nil) }
        func settle(_ seconds: TimeInterval) { RunLoop.main.run(until: Date().addingTimeInterval(seconds)) }
        func snapshot() throws -> [UInt8] {
            let rep = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
            host.cacheDisplay(in: host.bounds, to: rep)
            let data = try XCTUnwrap(rep.bitmapData)
            return Array(UnsafeBufferPointer(start: data, count: rep.bytesPerRow * rep.pixelsHigh))
        }
        func changed(_ a: [UInt8], _ b: [UInt8]) -> Int {
            zip(a, b).reduce(0) { $0 + (abs(Int($1.0) - Int($1.1)) > 48 ? 1 : 0) }
        }
        settle(0.3)
        let rest = try snapshot()
        XCTAssertGreaterThan(rest.filter { $0 != 0 }.count, 1_000, "rien de dessiné dans la fenêtre")
        host.rootView = make(1)                                  // l'enfant touche l'image
        settle(0.2)
        let during = try snapshot()
        settle(WordArtSubject.cloche.actionDuration + 0.4)
        let after = try snapshot()
        return (changed(rest, during), changed(rest, after))
    }
    #endif

    // MARK: Planches à relire (EVEIL_RENDER_DIR)

    func testContactSheets() {
        let fr = WordArtSubject.allCases.map(\.rawValue).filter { $0.hasPrefix("fr.") }
        let en = WordArtSubject.allCases.map(\.rawValue).filter { $0.hasPrefix("en.") }
        XCTAssertNotNil(sheet(fr, columns: 7, name: "wordart-planche-fr"))
        XCTAssertNotNil(sheet(en, columns: 6, name: "wordart-planche-en"))
    }

    func testIndividualCards() {
        for subject in WordArtSubject.allCases {
            let card = WordArt(wordId: subject.rawValue, size: 250)
                .background(RoundedRectangle(cornerRadius: 35, style: .continuous).fill(.white))
                .padding(15)
                .background(EveilPalette.skyLight)
            XCTAssertNotNil(RenderSupport.render(card, size: CGSize(width: 280, height: 280),
                                                 name: "wordart-\(subject.rawValue)"))
        }
    }

    func testActionStrips() {
        let subjects = WordArtSubject.allCases
        let perSheet = 9
        let cell: CGFloat = 120
        for (index, start) in stride(from: 0, to: subjects.count, by: perSheet).enumerated() {
            let chunk = Array(subjects[start..<min(subjects.count, start + perSheet)])
            let strip = VStack(alignment: .leading, spacing: 8) {
                ForEach(chunk, id: \.self) { subject in
                    HStack(spacing: 6) {
                        Text(subject.rawValue)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .frame(width: 104, alignment: .leading)
                        ForEach(Self.actionTimes, id: \.self) { t in
                            WordArtCanvas(subject: subject, pose: WordArtPose(t: t), size: cell)
                                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white))
                        }
                        WordArtCanvas(subject: subject, pose: WordArtPose(blink: subject.hasEyes), size: cell)
                            .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(subject.hasEyes ? Color.white : Color.white.opacity(0.4)))
                    }
                }
            }
            .padding(12)
            .background(EveilPalette.skyLight)
            let width = 12 + 104 + 6 + CGFloat(Self.actionTimes.count + 1) * (cell + 6) + 12
            let height = 24 + CGFloat(chunk.count) * (cell + 8)
            XCTAssertNotNil(RenderSupport.render(strip, size: CGSize(width: width, height: height),
                                                 name: "wordart-actions-\(index + 1)"))
        }
    }

    /// Une planche de cartes blanches (comme l'écran de jeu), l'identifiant sous chaque carte.
    private func sheet(_ ids: [String], columns: Int, name: String) -> CGImage? {
        let card: CGFloat = 200, gap: CGFloat = 22, label: CGFloat = 28
        let rows = (ids.count + columns - 1) / columns
        let width = CGFloat(columns) * (card + gap) + gap
        let height = CGFloat(rows) * (card + label + gap) + gap
        let view = VStack(alignment: .leading, spacing: gap) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: gap) {
                    ForEach(ids[(row * columns)..<min(ids.count, (row + 1) * columns)], id: \.self) { id in
                        VStack(spacing: 4) {
                            WordArt(wordId: id, size: card)
                                .background(RoundedRectangle(cornerRadius: card * 0.14, style: .continuous)
                                    .fill(.white)
                                    .shadow(color: .black.opacity(0.12), radius: 8, y: 4))
                            Text(id)
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(EveilPalette.ink)
                                .frame(height: label - 4)
                        }
                    }
                }
            }
        }
        .padding(gap)
        .frame(width: width, height: height, alignment: .topLeading)
        .background(EveilPalette.skyLight)
        return RenderSupport.render(view, size: CGSize(width: width, height: height), name: name)
    }
}

/// Les pixels RGBA d'un rendu 200 × 200 (échelle 1), pour compter l'encre.
@MainActor
private struct Pixels {
    let width: Int
    let height: Int
    let bytes: [UInt8]

    init?<V: View>(_ view: V) {
        let renderer = ImageRenderer(content: view.frame(width: 200, height: 200))
        renderer.scale = 1
        guard let image = renderer.cgImage else { return nil }
        let w = image.width, h = image.height
        var buffer = [UInt8](repeating: 0, count: w * h * 4)
        let drawn: Bool = buffer.withUnsafeMutableBytes { raw in
            guard let context = CGContext(data: raw.baseAddress, width: w, height: h, bitsPerComponent: 8,
                                          bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
            return true
        }
        guard drawn else { return nil }
        width = w
        height = h
        bytes = buffer
    }

    private func alpha(_ x: Int, _ y: Int) -> UInt8 { bytes[(y * width + x) * 4 + 3] }

    /// Pixels encrés (alpha > 10 %) ; avec `border`, seulement ceux de la bande du bord
    /// (`ignoringLeft` : sans la bande de gauche).
    func inkCount(border: Int? = nil, ignoringLeft: Bool = false) -> Int {
        var count = 0
        for y in 0..<height {
            for x in 0..<width where alpha(x, y) > 26 {
                if let border {
                    let left = !ignoringLeft && x < border
                    if left || y < border || x >= width - border || y >= height - border { count += 1 }
                } else {
                    count += 1
                }
            }
        }
        return count
    }

    /// Le cadre de l'encre (pour les messages d'échec).
    func inkBox() -> String {
        var minX = width, minY = height, maxX = -1, maxY = -1
        for y in 0..<height {
            for x in 0..<width where alpha(x, y) > 26 {
                minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
            }
        }
        return "x \(minX)…\(maxX), y \(minY)…\(maxY)"
    }

    /// Nombre de pixels qui diffèrent nettement (couleur ou opacité) entre deux rendus.
    func differingPixels(_ other: Pixels) -> Int {
        var count = 0
        for i in stride(from: 0, to: min(bytes.count, other.bytes.count), by: 4) {
            for c in 0..<4 where abs(Int(bytes[i + c]) - Int(other.bytes[i + c])) > 48 {
                count += 1
                break
            }
        }
        return count
    }
}
#endif
