// SoundBooksTests.swift — les livres des sons : chaque mot montre son son.
//
// Les données (`SoundBooksData.swift`) sont générées par eveil/outils/livres. Ici : le son est
// dans le wagon annoncé, avec des lettres qu'on retrouve dans ce wagon ; une syllabe par wagon ;
// les mots vont du début à la fin ; chaque langue a ses livres.

import Foundation
import XCTest
@testable import PhraseCore

final class SoundBooksTests: XCTestCase {
    func testEveryWordShowsItsSound() {
        XCTAssertFalse(SoundBooks.all.isEmpty)
        for book in SoundBooks.all {
            XCTAssertGreaterThanOrEqual(book.words.count, 5, book.id)
            XCTAssertEqual(Set(book.words.map(\.id)).count, book.words.count, "\(book.id) : mot en double")
            XCTAssertEqual(Set(book.words.map(\.drawing)).count, book.words.count, "\(book.id) : dessin en double")
            for w in book.words {
                XCTAssertEqual(w.ipa.split(separator: ".").count, w.wagons.count, "\(book.id) \(w.id) : une syllabe par wagon")
                guard w.wagons.indices.contains(w.targetWagon) else {
                    XCTFail("\(book.id) \(w.id) : wagon \(w.targetWagon) hors du train")
                    continue
                }
                let wagon = w.wagons[w.targetWagon]
                XCTAssertFalse(w.letters.isEmpty, "\(book.id) \(w.id)")
                XCTAssertNotNil(wagon.range(of: w.letters, options: [.caseInsensitive, .diacriticInsensitive]),
                                "\(book.id) \(w.id) : « \(w.letters) » absent de « \(wagon) »")
            }
        }
    }

    /// Dans un livre : d'abord les mots où le son est au début, puis au milieu, puis à la fin.
    func testWordsGoFromStartToEnd() {
        let order: [SoundPosition] = [.start, .middle, .end]
        for book in SoundBooks.all {
            let ranks = book.words.compactMap { order.firstIndex(of: $0.position) }
            XCTAssertEqual(ranks, ranks.sorted(), book.id)
        }
    }

    func testBooksByLanguage() throws {
        let fr = SoundBooks.books(locale: "fr-FR")
        let en = SoundBooks.books(locale: "en-US")
        XCTAssertTrue(fr.allSatisfy { $0.locale == "fr-FR" })
        XCTAssertTrue(en.allSatisfy { $0.locale == "en-US" })
        XCTAssertEqual(fr.count + en.count, SoundBooks.all.count)
        XCTAssertEqual(Set(SoundBooks.all.map(\.id)).count, SoundBooks.all.count)
        let ch = try XCTUnwrap(fr.first { $0.label == "ch" })
        XCTAssertEqual(SoundBooks.title(ch), "Le livre du « ch »")
        XCTAssertEqual(SoundBooks.book(id: ch.id)?.label, "ch")
        XCTAssertFalse(ch.image.isEmpty)
        XCTAssertFalse(ch.game.isEmpty)
        XCTAssertFalse(en.isEmpty)
    }
}
