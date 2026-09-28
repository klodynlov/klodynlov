// ColoringInstructionsTests.swift — les consignes du mode interactif : « Colorie le soleil en jaune ! »
//
// L'ordre (le sujet, puis le décor), la couleur imposée gardée, sinon la rotation fixe sans
// doublon (rien au hasard), « au choix » laissé à l'enfant, au plus cinq par page, les phrases
// FR/EN, le seuil « assez colorié ». Puis sur les vraies pages : chaque consigne se réussit d'un
// remplissage de SA couleur, sur n'importe laquelle de ses zones, jamais d'une autre couleur (au
// choix : de n'importe laquelle) ; et une vitre de la maison se fait d'un seul coup de pinceau.

#if canImport(SwiftUI) && canImport(AVFoundation)
@testable import ColoringUI
import CoreGraphics
import XCTest

final class ColoringInstructionsTests: XCTestCase {
    private let palette = ColoringView.palette

    private func part(_ fr: String, _ en: String = "the part", color: String? = nil, rank: Int = 0) -> ColoringPart {
        ColoringPart(fr: fr, en: en, color: color, rank: rank, points: [CGPoint(x: 0.5, y: 0.5)])
    }

    private func colors(_ list: [ColoringInstruction]) -> [String] {
        list.map { $0.colorIndex.map { palette[$0].nameFR } ?? ColoringInstructions.anyColor }
    }

    func testImposedColorsStayAndTheOthersFollowTheRotation() {
        let list = ColoringInstructions.list(for: [part("le toit", color: "rouge"), part("le mur"),
                                                   part("les mains", color: "au choix"), part("la porte"),
                                                   part("le soleil", color: "jaune", rank: 1)], palette: palette)
        XCTAssertEqual(list.map(\.part.fr), ["le toit", "le mur", "les mains", "la porte", "le soleil"])
        // Le rouge et le jaune sont déjà demandés : le mur prend le bleu, la porte le vert ; les mains,
        // l'enfant choisit (jamais une couleur de peau imposée).
        XCTAssertEqual(colors(list), ["rouge", "bleu", "au choix", "vert", "jaune"])
    }

    func testAtMostFiveNeverTheSameProposedColorTwiceAndNothingRandom() {
        let parts = (1...8).map { part("la partie \($0)") }
        let list = ColoringInstructions.list(for: parts, palette: palette)
        XCTAssertEqual(list.count, ColoringInstructions.maxPerPage)
        XCTAssertEqual(colors(list), ["rouge", "bleu", "jaune", "vert", "orange"])
        XCTAssertEqual(ColoringInstructions.list(for: parts, palette: palette), list)
    }

    func testEveryRotationColorIsInThePalette() {
        for name in ColoringInstructions.rotation {
            XCTAssertTrue(palette.contains { $0.nameFR == name }, name)
        }
    }

    func testSentences() throws {
        let sun = try XCTUnwrap(ColoringInstructions.list(for: [part("le soleil", "the sun", color: "jaune")],
                                                          palette: palette).first)
        XCTAssertEqual(ColoringInstructions.text(sun, palette: palette, locale: "fr-FR"), "Colorie le soleil en jaune !")
        XCTAssertEqual(ColoringInstructions.text(sun, palette: palette, locale: "en-US"), "Color the sun yellow!")
        XCTAssertEqual(ColoringInstructions.colorReminder(sun, palette: palette, locale: "fr-FR"), "En jaune !")
        XCTAssertEqual(ColoringInstructions.colorReminder(sun, palette: palette, locale: "en-US"), "Yellow!")
        // « Color the sky sky blue! » sonnait faux : en anglais, le bleu ciel est « light blue ».
        let sky = try XCTUnwrap(ColoringInstructions.list(for: [part("le ciel", "the sky", color: "bleu ciel")],
                                                          palette: palette).first)
        XCTAssertEqual(ColoringInstructions.text(sky, palette: palette, locale: "fr-FR"), "Colorie le ciel en bleu ciel !")
        XCTAssertEqual(ColoringInstructions.text(sky, palette: palette, locale: "en-US"), "Color the sky light blue!")
        XCTAssertEqual(ColoringInstructions.colorReminder(sky, palette: palette, locale: "en-US"), "Light blue!")
        // Au choix : pas de couleur dite, pas de rappel.
        let hands = try XCTUnwrap(ColoringInstructions.list(for: [part("les mains", "the hands", color: "au choix")],
                                                            palette: palette).first)
        XCTAssertNil(hands.colorIndex)
        XCTAssertEqual(ColoringInstructions.text(hands, palette: palette, locale: "fr-FR"),
                       "Colorie les mains, de la couleur que tu veux !")
        XCTAssertEqual(ColoringInstructions.text(hands, palette: palette, locale: "en-US"),
                       "Color the hands any color you like!")
        XCTAssertNil(ColoringInstructions.colorReminder(hands, palette: palette, locale: "fr-FR"))
    }

    func testEnoughColor() {
        let page = 1024 * 1024
        XCTAssertFalse(ColoringInstructions.isDone(painted: 0, area: 0, pageArea: page))
        // Petite zone : jamais moins de 120 pixels.
        XCTAssertFalse(ColoringInstructions.isDone(painted: 119, area: 800, pageArea: page))
        XCTAssertTrue(ColoringInstructions.isDone(painted: 120, area: 800, pageArea: page))
        // Zone moyenne : un huitième.
        XCTAssertFalse(ColoringInstructions.isDone(painted: 4_999, area: 40_000, pageArea: page))
        XCTAssertTrue(ColoringInstructions.isDone(painted: 5_000, area: 40_000, pageArea: page))
        // Le ciel, immense : 2 % de la page suffisent.
        XCTAssertFalse(ColoringInstructions.isDone(painted: page / 50 - 1, area: 500_000, pageArea: page))
        XCTAssertTrue(ColoringInstructions.isDone(painted: page / 50, area: 500_000, pageArea: page))
    }

    /// La maison, écrite à la main : ses consignes dans l'ordre, avec leurs couleurs.
    func testTheHouseInstructions() throws {
        let house = try XCTUnwrap(ColoringPages.all.first { $0.id == "maison" })
        let list = ColoringInstructions.list(for: house.parts, palette: palette)
        XCTAssertEqual(list.map(\.part.fr), ["le toit", "le mur", "la porte", "les fenêtres", "le soleil"])
        XCTAssertEqual(colors(list), ["rouge", "bleu", "vert", "bleu ciel", "jaune"])
    }

    /// Chaque consigne de chaque page se réussit d'un remplissage de sa couleur (sur sa dernière
    /// zone : n'importe laquelle compte), et jamais d'une autre couleur ; au choix, de n'importe laquelle.
    @MainActor
    func testEveryInstructionCanBeDone() {
        var done = 0
        for page in ColoringPages.all {
            let studio = ColoringStudio(pages: [page])
            studio.open(0)
            studio.loadSynchronously()
            let list = ColoringInstructions.list(for: page.parts, palette: palette)
            XCTAssertGreaterThanOrEqual(list.count, 2, "\(page.id) : une page, au moins deux consignes")
            XCTAssertEqual(list.first?.part.rank, 0, "\(page.id) : la première consigne est du sujet")
            for i in list {
                let label = "\(page.id) : « \(i.part.fr) »"
                let point = i.part.points[i.part.points.count - 1]
                XCTAssertFalse(studio.isDone(i, palette: palette), "\(label) déjà faite")
                if let index = i.colorIndex {
                    studio.fill(at: point, color: palette[(index + 1) % palette.count])
                    XCTAssertFalse(studio.isDone(i, palette: palette), "\(label) faite d'une autre couleur")
                    studio.fill(at: point, color: palette[index])
                } else {
                    studio.fill(at: point, color: palette[(done * 5) % palette.count])
                }
                XCTAssertTrue(studio.isDone(i, palette: palette), "\(label) impossible à faire")
                done += 1
            }
        }
        XCTAssertGreaterThan(done, 3 * ColoringPages.all.count)
    }

    /// Au pinceau (le réglage par défaut), une vitre se fait d'un seul coup.
    @MainActor
    func testOneBrushDabDoesAWindowPane() throws {
        let house = try XCTUnwrap(ColoringPages.all.first { $0.id == "maison" })
        let studio = ColoringStudio(pages: [house])
        studio.open(0)
        studio.loadSynchronously()
        let windows = try XCTUnwrap(ColoringInstructions.list(for: house.parts, palette: palette)
            .first { $0.part.fr == "les fenêtres" })
        XCTAssertFalse(studio.isDone(windows, palette: palette))
        let index = try XCTUnwrap(windows.colorIndex)
        studio.beginStroke(at: windows.part.points[0], color: palette[index])
        XCTAssertTrue(studio.endStroke())
        XCTAssertTrue(studio.isDone(windows, palette: palette))
    }
}
#endif
