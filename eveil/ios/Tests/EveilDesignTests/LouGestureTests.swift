// LouGestureTests.swift — les gestes animés de Lou : parité avec la référence Python, repos au
// début et à la fin, bras jamais cassé, suites de sons, peaux ; et des rendus à relire.
//
// Parité : `LouGestureVectors.swift`, généré par `eveil/outils/gestes/generer.py` depuis
// `animation.etat` (poignet, coude, direction de la main, bout de l'index, présence, bouche…).
// Planches (`EVEIL_RENDER_DIR=/chemin swift test --filter LouGestureTests`) :
//   lou-<n°>-<son>-<peau>.png     début du geste, milieu, pose (deux peaux)
//   lou-planche.png               tous les sons, quatre instants (peau de Lou)
//   lou-enchainement.png          « ch » puis « ou » puis « ui » : passage d'un son à l'autre

#if canImport(SwiftUI) && canImport(ImageIO) && canImport(UniformTypeIdentifiers)
@testable import EveilDesign
import SwiftUI
import XCTest

final class LouGestureTests: XCTestCase {

    // MARK: Données

    func testEveryGestureOfThePlancheIsThere() {
        XCTAssertEqual(LouGestures.keys.count, 33)
        for key in ["a", "o", "ou", "i", "u", "é", "è", "eu", "eu ouvert", "e", "an", "on", "in", "oi", "oin", "ch",
                    "s", "z", "j", "f", "v", "p", "b", "t", "d", "k", "g", "m", "n", "gn", "l", "r", "ill"] {
            XCTAssertTrue(LouGestures.has(key), key)
        }
        XCTAssertFalse(LouGestures.has("ui"), "« ui » n'a pas de geste (à trouver)")
        XCTAssertFalse(LouGestures.has("xyz"))
    }

    func testDurationsMatchThePythonReference() {
        for (key, d) in LouGestureVectors.durations {
            XCTAssertEqual(LouGestures.duration(of: key), d, accuracy: 1e-9, key)
        }
        XCTAssertEqual(LouGestures.duration(of: "xyz"), 1, "une étiquette inconnue : Lou au repos 1 s")
        for key in LouGestures.keys {
            let d = LouGestures.duration(of: key)
            XCTAssertTrue((0.6...2.5).contains(d), "\(key) : \(d) s")
        }
        XCTAssertGreaterThan(LouGestures.duration(of: "s"), LouGestures.duration(of: "z"))
    }

    func testParityWithPython() {
        let vectors = LouGestureVectors.all
        XCTAssertGreaterThan(vectors.count, 60)
        for v in vectors {
            let f = LouChronology.of(v.key).frame(at: v.t)
            let where_ = "\(v.key) à \(v.t) s"
            XCTAssertEqual(f.mouth, v.mouth, where_)
            XCTAssertEqual(f.vibrate, v.vibrate, where_)
            XCTAssertEqual(f.lift, v.lift, accuracy: 1e-4, where_)
            XCTAssertEqual(f.table, v.table, accuracy: 1e-4, where_)
            XCTAssertEqual(f.arms.count, v.arms.count, where_)
            for (arm, expected) in zip(f.arms, v.arms) {
                assertClose(arm.wrist, expected.wrist, "\(where_) : poignet")
                assertClose(arm.elbow, expected.elbow, "\(where_) : coude")
                assertClose(arm.tip(.index), expected.indexTip, "\(where_) : bout de l'index")
                XCTAssertEqual(arm.direction, expected.direction, accuracy: 1e-3, "\(where_) : direction")
                XCTAssertEqual(arm.presence, expected.presence, accuracy: 1e-4, "\(where_) : présence")
            }
        }
    }

    private func assertClose(_ a: CGPoint, _ b: CGPoint, _ message: String, tolerance: Double = 0.05,
                             file: StaticString = #filePath, line: UInt = #line) {
        let d = hypot(Double(a.x - b.x), Double(a.y - b.y))
        XCTAssertLessThan(d, tolerance, "\(message) : \(a) au lieu de \(b)", file: file, line: line)
    }

    // MARK: Repos, continuité

    func testEveryGestureStartsAndEndsAtRest() {
        for key in LouGestures.keys + ["ui"] {
            let c = LouChronology.of(key)
            for t in [0, c.duration] {
                let f = c.frame(at: t)
                XCTAssertEqual(f.mouth, "neutre", "\(key) à \(t) s")
                XCTAssertFalse(f.vibrate, "\(key) à \(t) s")
                XCTAssertEqual(f.lift, 0, "\(key) à \(t) s")
                XCTAssertEqual(f.table, 0, "\(key) à \(t) s")
                for arm in f.arms {
                    XCTAssertEqual(arm.presence, 0, "\(key) à \(t) s : bras visible au repos")
                }
            }
        }
    }

    /// Image par image : rien d'infini, aucun bras cassé (avant-bras de longueur raisonnable),
    /// pas de saut (la main avance de moins de 45 px par image à 60 images/s).
    func testArmsNeverBreakNorJump() {
        for key in LouGestures.keys {
            let c = LouChronology.of(key)
            var previous: LouFrame?
            var t = 0.0
            while t <= c.duration {
                let f = c.frame(at: t)
                for (n, arm) in f.arms.enumerated() {
                    for p in [arm.elbow, arm.wrist, arm.tip(.index)] {
                        XCTAssertTrue(p.x.isFinite && p.y.isFinite, "\(key) à \(t) s")
                    }
                    let fore = hypot(Double(arm.wrist.x - arm.elbow.x), Double(arm.wrist.y - arm.elbow.y))
                    let upper = hypot(Double(arm.elbow.x - arm.shoulder.x), Double(arm.elbow.y - arm.shoulder.y))
                    XCTAssertTrue((25...140).contains(fore), "\(key) à \(t) s : avant-bras de \(fore)")
                    XCTAssertGreaterThan(upper, 25, "\(key) à \(t) s : haut du bras de \(upper)")
                    if let previous, arm.presence > 0.3 {
                        let a = previous.arms[n]
                        let step = hypot(Double(arm.wrist.x - a.wrist.x), Double(arm.wrist.y - a.wrist.y))
                        XCTAssertLessThan(step, 45, "\(key) à \(t) s : la main saute de \(step) px")
                    }
                }
                previous = f
                t += 1.0 / 60
            }
        }
    }

    /// La pose tenue (« Réduire les animations ») : le bras est là, avec la bouche du son.
    func testThePoseShowsTheGestureAndTheMouth() {
        for key in LouGestures.keys {
            let c = LouChronology.of(key)
            let f = c.frame(at: c.posed)
            XCTAssertTrue(f.arms.contains { $0.presence == 1 && !$0.setup.behind }, key)
            XCTAssertNotEqual(f.mouth, "neutre", "\(key) : la pose montre la bouche du son")
        }
    }

    // MARK: Suites de sons

    func testPerformanceChainsTheSounds() {
        let start = Date(timeIntervalSinceReferenceDate: 1000)
        let p = LouPerformance(keys: ["ch", "ui", "ou"], start: start)
        let dch = LouGestures.duration(of: "ch"), dui = LouGestures.duration(of: "ui")
        XCTAssertEqual(p.duration, dch + dui + LouGestures.duration(of: "ou"), accuracy: 1e-9)
        XCTAssertNil(p.key(at: start.addingTimeInterval(-0.01)))
        XCTAssertEqual(p.key(at: start), "ch")
        XCTAssertEqual(p.key(at: start.addingTimeInterval(dch - 0.001)), "ch")
        XCTAssertEqual(p.key(at: start.addingTimeInterval(dch + 0.001)), "ui")
        XCTAssertEqual(p.key(at: start.addingTimeInterval(dch + dui + 0.5)), "ou")
        XCTAssertNil(p.key(at: start.addingTimeInterval(p.duration)))
        // « ui » : la bouche seule.
        let ui = p.frame(at: start.addingTimeInterval(dch + 0.5), reduceMotion: false)
        XCTAssertTrue(ui.arms.isEmpty)
        XCTAssertEqual(ui.mouth, "mi_ouverte")
        // Fini : au repos.
        let after = p.frame(at: start.addingTimeInterval(p.duration + 1), reduceMotion: false)
        XCTAssertTrue(after.arms.isEmpty)
        XCTAssertEqual(after.mouth, "neutre")
        XCTAssertEqual(LouPerformance(keys: [], start: start).duration, 0)
    }

    func testReducedMotionHoldsThePose() {
        let start = Date(timeIntervalSinceReferenceDate: 0)
        let p = LouPerformance(keys: ["s"], start: start)
        let c = LouChronology.of("s")
        let posed = c.frame(at: c.posed)
        for t in [0.01, 0.5, 1.2, c.duration - 0.01] {
            let f = p.frame(at: start.addingTimeInterval(t), reduceMotion: true)
            XCTAssertEqual(f.arms[0].wrist, posed.arms[0].wrist, "à \(t) s")
            XCTAssertNil(f.pulse, "pas de battement quand les animations sont réduites")
        }
    }

    // MARK: Peaux

    func testSkins() {
        XCTAssertEqual(LouSkin.allCases.map(\.id), ["claire", "doree", "lou", "brune", "foncee"])
        XCTAssertEqual(LouSkin.allCases.map(\.hex), ["#FCDCC0", "#E4AC7A", "#B8784E", "#A66C44", "#623C26"])
        XCTAssertEqual(LouSkin.lou.hex, "#B8784E")
        XCTAssertEqual(LouSkin.with(id: "foncee")?.name(locale: "fr-FR"), "peau foncée")
        XCTAssertEqual(LouSkin.with(id: "claire")?.name(locale: "en-US"), "light skin")
        XCTAssertNil(LouSkin.with(id: "verte"))
        // Les couleurs calculées : celles de `ombre_de` / `levres_de` (peau de Lou).
        let c = LouColors(hex: "#B8784E")
        XCTAssertTrue(c.shade == (144, 91, 58), "\(c.shade)")
        XCTAssertTrue(c.lips == (184, 89, 76), "\(c.lips)")
    }

    // MARK: Rendus

    private static func canvas(_ frame: LouFrame, _ skin: LouSkin, width: CGFloat) -> some View {
        LouCanvas(frame: frame, colors: LouColors(hex: skin.hex))
            .frame(width: width, height: width * 300 / 260)
            .background(Color.white)
    }

    private func instants(_ key: String) -> [(String, Double)] {
        let c = LouChronology.of(key)
        return [("début", 0.22), ("milieu", c.duration / 2), ("pose", c.posed)]
    }

    @MainActor
    func testRenderEveryGestureInTwoSkins() throws {
        let skins = [LouSkin.with(id: "claire")!, LouSkin.with(id: "foncee")!]
        for (n, key) in LouGestures.keys.enumerated() {
            let c = LouChronology.of(key)
            for skin in skins {
                let view = HStack(spacing: 6) {
                    ForEach(Array(self.instants(key).enumerated()), id: \.offset) { _, item in
                        VStack(spacing: 2) {
                            Self.canvas(c.frame(at: item.1), skin, width: 260)
                            Text("\(key) · \(item.0) · \(String(format: "%.2f", item.1)) s")
                                .font(.system(size: 13)).foregroundStyle(.black)
                        }
                    }
                }
                .padding(6).background(Color(white: 0.92))
                let image = RenderSupport.render(view, size: CGSize(width: 3 * 260 + 24, height: 300 + 34),
                                                 name: String(format: "lou-%02d-%@-%@", n, slug(key), skin.id),
                                                 scale: 1)
                XCTAssertNotNil(image, key)
            }
        }
    }

    @MainActor
    func testRenderContactSheetAndChaining() throws {
        let skin = LouSkin.lou
        let keys = LouGestures.keys
        let width: CGFloat = 116
        func row(_ key: String) -> some View {
            let c = LouChronology.of(key)
            let ts = [0.2, 0.35, c.duration / 2, c.posed]
            return HStack(spacing: 3) {
                Text(key).font(.system(size: 16, weight: .bold)).foregroundStyle(.black).frame(width: 64)
                ForEach(Array(ts.enumerated()), id: \.offset) { _, t in Self.canvas(c.frame(at: t), skin, width: width) }
            }
        }
        let half = (keys.count + 1) / 2
        let sheet = HStack(alignment: .top, spacing: 18) {
            VStack(spacing: 3) { ForEach(keys[..<half], id: \.self) { row($0) } }
            VStack(spacing: 3) { ForEach(keys[half...], id: \.self) { row($0) } }
        }
        .padding(10).background(Color(white: 0.92))
        let h = CGFloat(half) * (width * 300 / 260 + 3) + 20
        XCTAssertNotNil(RenderSupport.render(sheet, size: CGSize(width: 2 * (64 + 4 * (width + 3)) + 38, height: h),
                                             name: "lou-planche", scale: 1))

        // Les bascules d'une forme de main à l'autre, au quart, à la moitié, aux trois quarts.
        var morphs: [(String, Double)] = []
        for key in keys {
            let c = LouChronology.of(key)
            for (k0, k1) in zip(c.keys, c.keys.dropFirst())
            where zip(k0.joints, k1.joints).contains(where: { $0.form != $1.form }) {
                for x in [0.25, 0.5, 0.75] { morphs.append((key, k0.t + (k1.t - k0.t) * x)) }
            }
        }
        let morphSheet = LazyVGrid(columns: Array(repeating: GridItem(.fixed(width), spacing: 3), count: 9), spacing: 3) {
            ForEach(Array(morphs.enumerated()), id: \.offset) { _, item in
                VStack(spacing: 1) {
                    Self.canvas(LouChronology.of(item.0).frame(at: item.1), skin, width: width)
                    Text(String(format: "%@ %.2f", item.0, item.1)).font(.system(size: 11)).foregroundStyle(.black)
                }
            }
        }
        .padding(6).background(Color(white: 0.92))
        let rows = CGFloat((morphs.count + 8) / 9)
        XCTAssertNotNil(RenderSupport.render(morphSheet, size: CGSize(width: 9 * (width + 3) + 12,
                                                                      height: rows * (width * 300 / 260 + 20) + 12),
                                             name: "lou-bascules", scale: 1))

        // Enchaînement : « ch » puis « ui » (bouche seule) puis « ou ».
        let start = Date(timeIntervalSinceReferenceDate: 0)
        let p = LouPerformance(keys: ["ch", "ui", "ou"], start: start)
        let ts = stride(from: 0.0, through: p.duration, by: p.duration / 11).map { $0 }
        let chain = HStack(spacing: 3) {
            ForEach(Array(ts.enumerated()), id: \.offset) { _, t in
                VStack(spacing: 1) {
                    Self.canvas(p.frame(at: start.addingTimeInterval(t), reduceMotion: false), skin, width: width)
                    Text(String(format: "%@ %.2f", p.key(at: start.addingTimeInterval(t)) ?? "fin", t))
                        .font(.system(size: 11)).foregroundStyle(.black)
                }
            }
        }
        .padding(6).background(Color(white: 0.92))
        XCTAssertNotNil(RenderSupport.render(chain, size: CGSize(width: 12 * (width + 3) + 12, height: width * 300 / 260 + 30),
                                             name: "lou-enchainement", scale: 1))
        // La vue publique se rend (au repos, et pendant une suite).
        XCTAssertNotNil(RenderSupport.render(LouGestureView(performance: nil, skin: skin, size: 130),
                                             size: CGSize(width: 130, height: 150), name: "lou-repos"))
        XCTAssertNotNil(RenderSupport.render(LouGestureView(performance: LouPerformance(keys: ["a"], start: Date()),
                                                            skin: skin, size: 130),
                                             size: CGSize(width: 130, height: 150), name: "lou-vue"))
    }

    /// La vue publique, pendant une suite commencée il y a 0,8 s : le bras et la main sont peints
    /// (beaucoup de pixels diffèrent de Lou au repos) ; au repos, aucun bras (comme sur la planche).
    @MainActor
    func testPublicViewPaintsTheArmDuringAPerformance() throws {
        func pixels(_ view: some View, _ name: String) throws -> [UInt8] {
            let image = try XCTUnwrap(RenderSupport.render(view.background(Color.white),
                                                           size: CGSize(width: 260, height: 300), name: name, scale: 1))
            var data = [UInt8](repeating: 0, count: 260 * 300 * 4)
            let ctx = try XCTUnwrap(CGContext(data: &data, width: 260, height: 300, bitsPerComponent: 8,
                                              bytesPerRow: 260 * 4, space: CGColorSpaceCreateDeviceRGB(),
                                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
            ctx.draw(image, in: CGRect(x: 0, y: 0, width: 260, height: 300))
            return data
        }
        let rest = try pixels(LouGestureView(performance: nil, skin: .lou, size: 260), "lou-vue-repos")
        for key in ["s", "o", "a"] {
            let running = LouPerformance(keys: [key], start: Date().addingTimeInterval(-0.8))
            let now = try pixels(LouGestureView(performance: running, skin: .lou, size: 260), "lou-vue-\(key)")
            var changed = 0
            for i in stride(from: 0, to: rest.count, by: 4) where abs(Int(rest[i]) - Int(now[i])) > 30 {
                changed += 1
            }
            XCTAssertGreaterThan(changed, 1500, "\(key) : la main n'est pas peinte (\(changed) pixels)")
        }
    }

    private func slug(_ key: String) -> String {
        key.replacingOccurrences(of: " ", with: "-").replacingOccurrences(of: "é", with: "e-aigu")
            .replacingOccurrences(of: "è", with: "e-grave")
    }
}
#endif
