// ColoringPagesTests.swift — les pages du coloriage (identifiants, titres).

#if canImport(SwiftUI)
@testable import ColoringUI
import XCTest

final class ColoringPagesTests: XCTestCase {
    func testPagesHaveUniqueIdsAndTitles() {
        let pages = ColoringPages.all
        XCTAssertGreaterThanOrEqual(pages.count, 3)
        XCTAssertEqual(Set(pages.map(\.id)).count, pages.count)
        for page in pages {
            XCTAssertFalse(page.title(locale: "fr-FR").isEmpty)
            XCTAssertFalse(page.title(locale: "en-US").isEmpty)
        }
    }
}
#endif
