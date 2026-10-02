// SoundBooksViewTests.swift — les livres des sons dans le petit train : chaque mot a son
// dessin, et devient un mot du train sans fourgon ; le micro l'écoute comme dans le petit train
// (les syllabes), l'adulte juge le son du livre.

#if canImport(SwiftUI) && canImport(SwiftData) && canImport(AVFoundation) && canImport(Observation)
@testable import EveilDesign
import PhraseCore
@testable import TrainPracticeUI
import WordEndCore
import XCTest

final class SoundBooksViewTests: XCTestCase {
    /// Dans un livre, le micro écoute comme dans le petit train, et « Il l'a dit ! » reste à l'adulte.
    func testBooksListenLikeTheTrain() {
        XCTAssertTrue(SoundBooksView.judge.listens)
        XCTAssertTrue(SoundBooksView.judge.adultJudges)
        XCTAssertFalse(PracticeJudge.listen.adultJudges)
        XCTAssertFalse(PracticeJudge.adult.listens)
    }

    /// Le détecteur entend les mots des livres : le mot entier allume tout le train (verdict complet),
    /// une syllabe en moins ne l'est pas — pour chaque nombre de wagons des livres.
    func testTheDetectorHearsBookWords() throws {
        var seen = Set<Int>()
        for book in SoundBooks.all {
            for w in book.words {
                let word = SoundBooksView.targetWord(w)
                guard seen.insert(word.nuclei).inserted else { continue }
                XCTAssertNil(word.coda, w.text)
                let whole = try XCTUnwrap(DemoScenario.complete.samples(for: word))
                XCTAssertEqual(detect(whole, target: word).kind, .complete, "\(w.text) : \(word.nuclei) wagon(s)")
                if let short = DemoScenario.fewerSyllables.samples(for: word) {
                    XCTAssertEqual(detect(short, target: word).kind, .fewerSyllables, w.text)
                }
            }
        }
        XCTAssertGreaterThan(seen.count, 1)
    }

    /// Chaque mot des livres a son dessin : un picto, ou le dessin vivant d'un mot du petit train.
    func testEveryBookWordIsDrawn() {
        for book in SoundBooks.all {
            for w in book.words {
                XCTAssertTrue(PictoLibrary.isDrawn(w.drawing), "\(book.id) \(w.id) : dessin \(w.drawing) introuvable")
            }
        }
    }

    /// Chaque phrase de livre se joue : un sujet, un verbe qui bouge, l'objet ou le lieu dessiné,
    /// et l'ancre de la préposition (« dans la niche » : le sujet sait où se mettre).
    func testEveryBookSentenceCanBePlayed() {
        for book in SoundBooks.all {
            for sentence in book.sentences {
                let scene = SentenceScene(cards: sentence.cards)
                XCTAssertNotNil(scene.subject, sentence.text)
                XCTAssertTrue(scene.verb.map { SentenceMotion.verbs.contains($0) } ?? false, sentence.text)
                if sentence.level == 2 {
                    XCTAssertTrue(scene.object.map(PictoLibrary.isDrawn) ?? false, sentence.text)
                } else {
                    let place = scene.place.flatMap(PictoLibrary.drawing)
                    XCTAssertNotNil(scene.preposition.flatMap { place?.anchors[$0] }, sentence.text)
                }
                for choices in sentence.choices {
                    for card in choices {
                        XCTAssertTrue(PictoLibrary.isDrawn(PhraseLexicon.drawing(of: card)), "\(sentence.text) : \(card.key)")
                    }
                }
            }
        }
    }

    func testLevelNames() {
        XCTAssertEqual(BookSentenceView.levelName(1, locale: "fr-FR"), "Les mots")
        XCTAssertEqual(BookSentenceView.levelName(2, locale: "fr-FR"), "Les phrases")
        XCTAssertEqual(BookSentenceView.levelName(3, locale: "en-US"), "And where?")
    }

    @MainActor
    func testBookWordBecomesATrainWord() throws {
        for book in SoundBooks.all {
            for w in book.words {
                let t = SoundBooksView.targetWord(w)
                XCTAssertEqual(t.id, w.drawing)
                XCTAssertEqual(t.wagons, w.wagons)
                XCTAssertNil(t.caboose, w.id)
                XCTAssertEqual(t.voiceSegments.count, w.wagons.count, w.id)
                XCTAssertTrue(t.voiceSegments.allSatisfy { $0.ipa != nil }, "\(w.id) : la voix suit l'API")
            }
        }
    }
}
#endif
