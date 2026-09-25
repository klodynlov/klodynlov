// TapToFillTests.swift — « Remplir d'un toucher » se règle dans l'espace des grands.
//
// Décision de l'utilisateur (25/09/2026) : réglable par l'adulte. Désactivé, l'atelier
// ne propose que le pinceau, et un outil « Remplir » resté en main n'agit plus.

#if canImport(SwiftUI)
@testable import ColoringUI
import EveilDesign
import XCTest

final class TapToFillTests: XCTestCase {
    func testWithoutTapToFillOnlyTheBrushIsOffered() {
        XCTAssertEqual(ColoringView.tools(tapToFill: true), [.fill, .brush])
        XCTAssertEqual(ColoringView.tools(tapToFill: false), [.brush])
    }

    func testAFillToolLeftInHandFallsBackToTheBrush() {
        XCTAssertEqual(ColoringView.activeTool(.fill, tapToFill: true), .fill)
        XCTAssertEqual(ColoringView.activeTool(.fill, tapToFill: false), .brush)
        XCTAssertEqual(ColoringView.activeTool(.brush, tapToFill: false), .brush)
    }

    /// Par défaut, pinceau seul (décision de l'utilisateur) : l'adulte active le remplissage s'il le veut.
    func testDefaultIsBrushOnly() {
        XCTAssertFalse(SuiteSettings.tapToFillDefault)
        XCTAssertEqual(ColoringView.tools(tapToFill: SuiteSettings.tapToFillDefault), [.brush])
        XCTAssertEqual(SuiteSettings.tapToFillKey, "eveil.coloring.tapToFill")
    }
}
#endif
