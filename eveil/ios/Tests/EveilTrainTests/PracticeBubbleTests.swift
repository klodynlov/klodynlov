// Ce que Lou dit après un essai (décision utilisateur, 17/11/2026) : réussi = juste « Bravo ! » ;
// essai à refaire = pas de « Je n'ai pas bien entendu », la bulle passe à « À toi ! ».

@testable import TrainPracticeUI
import WordEndAudio
@testable import WordEndCore
import XCTest

final class PracticeBubbleTests: XCTestCase {
    private func feedback(_ kind: VerdictKind, attempt: Int = 1, left: Int = 0) -> Feedback {
        let verdict = Verdict(kind: kind, heardNuclei: 2, expectedNuclei: 2, codaExpected: true, codaHeard: false,
                              codaPlace: nil, codaMs: 0, epenthesis: false, snrDb: 30, reasons: [])
        return FeedbackPolicy.feedback(for: verdict, wagons: 2, hasCaboose: true, attempt: attempt, repetitionsLeft: left)
    }

    func testSuccessIsJustBravo() {
        XCTAssertEqual(PracticeView.spokenAfter(feedback(.complete), locale: "fr-FR"), "Bravo !")
        XCTAssertEqual(PracticeView.spokenAfter(feedback(.complete), locale: "en-US"), "Well done!")
        XCTAssertNil(PracticeView.spokenAfter(feedback(.complete, left: 2), locale: "fr-FR"))   // le décompte parle
    }

    func testARetryNeverSaysItDidNotHear() {
        for kind in [VerdictKind.unsure, .noSpeech, .fewerSyllables] {
            let fb = feedback(kind)
            XCTAssertFalse(fb.advance)
            XCTAssertNil(PracticeView.spokenAfter(fb, locale: "fr-FR"), "\(kind)")
        }
        // Le conseil du fourgon reste dit (il apprend quelque chose), puis « À toi ! ».
        XCTAssertEqual(PracticeView.spokenAfter(feedback(.missingFinalConsonant), locale: "fr-FR"),
                       MessageKey.hookCaboose.defaultText(locale: "fr-FR"))
    }

    func testWhatLouSaysHasItsPreparedVoice() {
        for locale in ["fr-FR", "en-US"] {
            XCTAssertNotNil(VoiceClips.url(locale: locale, pace: "sentence",
                                           text: PracticeView.bravo(locale: locale), ipa: nil), locale)
        }
    }
}
