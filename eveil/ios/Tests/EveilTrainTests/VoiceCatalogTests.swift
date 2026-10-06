// VoiceCatalogTests.swift — la voix du modèle : féminine, naturelle, dans le bon accent.
//
// Retour de l'utilisateur (28/09/2026) : « la voix est trop générique — voix féminine
// naturelle ». Le tri du catalogue est une fonction pure : testée ici sans iPad.

#if canImport(AVFoundation)
import XCTest
@testable import WordEndAudio

final class VoiceCatalogTests: XCTestCase {
    private let options = [
        VoiceOption(id: "thomas", name: "Thomas", language: "fr-FR", quality: .enhanced, isFemale: false),
        VoiceOption(id: "amelie", name: "Amélie", language: "fr-CA", quality: .premium, isFemale: true),
        VoiceOption(id: "aurelie", name: "Aurélie", language: "fr-FR", quality: .standard, isFemale: true),
        VoiceOption(id: "audrey", name: "Audrey", language: "fr-FR", quality: .enhanced, isFemale: true),
        VoiceOption(id: "flo", name: "Flo", language: "fr-FR", quality: .standard, isFemale: true, isNovelty: true),
        VoiceOption(id: "maman", name: "Maman", language: "fr-FR", quality: .premium, isFemale: false, isPersonal: true),
    ]

    /// Accent du jeu, puis voix naturelle, puis féminine, puis qualité.
    func testRankingPrefersAccentNaturalFemaleThenQuality() {
        XCTAssertEqual(VoiceCatalog.ranked(options, locale: "fr-FR").map(\.id),
                       ["audrey", "aurelie", "thomas", "maman", "flo", "amelie"])
    }

    /// Sans l'adulte, jamais une voix personnelle ni une voix fantaisie.
    func testAutomaticChoiceIsNeverPersonalNorNovelty() {
        XCTAssertEqual(VoiceCatalog.automaticChoice(options, locale: "fr-FR")?.id, "audrey")
        let odd = options.filter { $0.isPersonal || $0.isNovelty }
        XCTAssertNil(VoiceCatalog.automaticChoice(odd, locale: "fr-FR"))
        // Aucune voix de l'accent du jeu : la voix québécoise plutôt que rien.
        let quebec = options.filter { $0.language == "fr-CA" }
        XCTAssertEqual(VoiceCatalog.automaticChoice(quebec, locale: "fr-FR")?.id, "amelie")
    }

    func testQualityLabels() {
        XCTAssertEqual(VoiceOption.Quality.enhanced.label(locale: "fr-FR"), "améliorée")
        XCTAssertEqual(VoiceOption.Quality.premium.label(locale: "en-US"), "premium")
        XCTAssertLessThan(VoiceOption.Quality.standard, VoiceOption.Quality.premium)
    }
}
#endif
