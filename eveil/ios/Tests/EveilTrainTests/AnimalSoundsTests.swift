// AnimalSoundsTests.swift — dans les livres des sons, toucher un animal fait entendre SON cri.
//
// Demande de l'utilisateur (17/11/2026) : « quand on est sur un animal, si on appuie sur
// l'image, fais entendre le son : ex. rugissement pour le lion ». Dans un livre, l'identifiant
// du mot est son DESSIN (`SoundBooksView.targetWord`) ; dans le petit train, les mots venus des
// livres (`fr.livre.lion`) portent ce dessin dans `drawing` : les deux trouvent le même cri.

#if canImport(SwiftUI) && canImport(SwiftData) && canImport(AVFoundation) && canImport(Observation)
import EveilSounds
import Foundation
import PhraseCore
@testable import TrainPracticeUI
import WordEndCore
import XCTest

final class AnimalSoundsTests: XCTestCase {
    /// Tous les animaux des mots des livres, par dessin, et le bruit attendu.
    static let animals: [String: SoundEffect] = [
        // Déjà dessinés pour le petit train (sons existants).
        "fr.minouche": .meow, "fr.caniche": .yap, "fr.perruche": .tweet, "en.mouse": .squeak,
        "en.fish": .blub, "en.goose": .honk, "en.moose": .bellow, "fr.vache": .moo, "fr.biche": .hooves,
        "fr.autruche": .footsteps, "fr.limace": .slime, "fr.mouche": .buzz,
        // Les animaux des livres (17/11/2026).
        "mot.lion": .roar, "mot.dinosaure": .dinoRoar, "mot.dragon": .dragonRoar, "mot.loup": .howl,
        "mot.poule": .cluck, "mot.coq": .crow, "mot.canard": .quack, "mot.cheval": .neigh, "mot.zebre": .neigh,
        "mot.grenouille": .croak, "mot.mouton": .baa, "mot.phoque": .sealBark, "mot.dauphin": .dolphin,
        "mot.crocodile": .jawSnap, "mot.papillon": .flutter, "mot.lapin": .nibble, "mot.araignee": .tiptoe,
        "mot.girafe": .rustle,
    ]

    private func lexicon(_ locale: String) throws -> Lexicon {
        let eveil = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        return try Lexicon.decode(Data(contentsOf: eveil.appendingPathComponent("lexique/\(locale).json")))
    }

    /// Le cas de l'utilisateur : le lion du livre rugit.
    func testTheBookLionRoars() {
        let lion = TargetWord.bookWord(id: "mot.lion", text: "lion", ipa: "ljɔ̃", wagons: ["lion"])
        XCTAssertEqual(WordScene.forWord(lion).sound, .roar)
    }

    /// Chaque animal est bien dans les livres (la liste ne vieillit pas en silence), et, touché dans
    /// un livre, il fait son bruit — jamais le carillon par défaut.
    func testEveryBookAnimalMakesItsOwnSound() {
        var drawings: [String: SoundBookWord] = [:]
        for book in SoundBooks.all { for w in book.words { drawings[w.drawing] = w } }
        for (drawing, sound) in Self.animals.sorted(by: { $0.key < $1.key }) {
            guard let w = drawings[drawing] else {
                XCTFail("\(drawing) n'est dans aucun livre")
                continue
            }
            let scene = WordScene.forWord(SoundBooksView.targetWord(w))
            XCTAssertNotEqual(scene.sound, .chime, "\(drawing) : carillon par défaut")
            XCTAssertEqual(scene.sound, sound, drawing)
            XCTAssertGreaterThan(scene.count, 0, drawing)
        }
    }

    /// Les mots des livres entrés dans le petit train (`fr.livre.*`, `en.livre.*`) trouvent le bruit
    /// de leur dessin ; les mots du train, eux, gardent le leur.
    func testTrainWordsFindTheSoundOfTheirDrawing() throws {
        var checked = 0
        for locale in ["fr-FR", "en-US"] {
            for word in try lexicon(locale).words {
                if let drawing = word.drawing, let sound = Self.animals[drawing] {
                    XCTAssertEqual(WordScene.forWord(word).sound, sound, "\(word.id) (\(drawing))")
                    checked += 1
                } else if let scene = WordScene.table[word.id] {
                    XCTAssertEqual(WordScene.forWord(word), scene, word.id)
                }
            }
        }
        XCTAssertGreaterThan(checked, 30, "les animaux des livres sont aussi dans le petit train")
        let vache = TargetWord.bookWord(id: "fr.vache", text: "vache", ipa: nil, wagons: ["vache"])
        XCTAssertEqual(WordScene.forWord(vache).sound, .moo)
        let nid = TargetWord.bookWord(id: "mot.nid", text: "nid", ipa: nil, wagons: ["nid"])
        XCTAssertEqual(WordScene.forWord(nid).sound, .chime, "un objet sans bruit garde le carillon")
    }
}
#endif
