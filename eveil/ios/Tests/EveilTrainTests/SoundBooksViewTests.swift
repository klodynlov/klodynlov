// SoundBooksViewTests.swift — les livres des sons dans le petit train : chaque mot a son
// dessin, et devient un mot du train sans fourgon (l'adulte juge).

#if canImport(SwiftUI) && canImport(SwiftData) && canImport(AVFoundation) && canImport(Observation)
@testable import EveilDesign
import PhraseCore
@testable import TrainPracticeUI
import WordEndCore
import XCTest

final class SoundBooksViewTests: XCTestCase {
    /// Chaque mot des livres a son dessin : un picto, ou le dessin vivant d'un mot du petit train.
    func testEveryBookWordIsDrawn() {
        for book in SoundBooks.all {
            for w in book.words {
                XCTAssertTrue(PictoLibrary.isDrawn(w.drawing), "\(book.id) \(w.id) : dessin \(w.drawing) introuvable")
            }
        }
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
