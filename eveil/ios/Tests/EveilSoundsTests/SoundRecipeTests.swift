// SoundRecipeTests.swift — chaque recette a le CARACTÈRE promis, vérifié par la mesure.
//
// On ne peut pas écouter dans un test : on vérifie le trait qui fait reconnaître le son
// (bande de fréquences du « chhh » et du « sss », hauteur du « meuh », deux tons du
// « pin-pon », nombre d'aboiements, notes de la gamme…), avec les outils indépendants
// d'`AudioAnalysis`.

import EveilSounds
import XCTest

final class SoundRecipeTests: XCTestCase {
    private func render(_ effect: SoundEffect, _ variant: Int = 0) -> [Float] {
        Renders.sound(effect, variant)
    }

    private func slice(_ x: [Float], _ from: Double, _ to: Double) -> [Float] {
        let rate = SoundSynth.sampleRate
        return Array(x[min(Int(from * rate), x.count)..<min(Int(to * rate), x.count)])
    }

    private func pitch(_ x: [Float], at t: Double, _ low: Double, _ high: Double) -> Double {
        AudioAnalysis.pitch(x, at: t, minHz: low, maxHz: high) ?? 0
    }

    // MARK: - Le train

    func testSteamIsTheShSoundBand() {
        let steam = render(.steam)
        XCTAssertGreaterThan(AudioAnalysis.bandFraction(steam, 2_000, 7_000), 0.8)
        XCTAssertGreaterThan(AudioAnalysis.centroid(steam), 3_000)
    }

    func testHissIsTheSSoundBandAboveSteam() {
        let hiss = render(.hiss), steam = render(.steam)
        XCTAssertGreaterThan(AudioAnalysis.bandFraction(hiss, 4_500, 10_000), 0.8)
        XCTAssertGreaterThan(AudioAnalysis.centroid(hiss), AudioAnalysis.centroid(steam) + 1_500)
    }

    func testWhistleIsTwoBlowsOfAChord() {
        let x = render(.whistle)
        XCTAssertEqual(AudioAnalysis.bursts(x), 2, "tchou-tchou")
        XCTAssertGreaterThan(AudioAnalysis.bandFraction(x, 400, 1_600), 0.6)
        let strongest = AudioAnalysis.dominantFrequency(x, from: 300, to: 2_000)
        XCTAssertTrue([466.2, 587.3, 698.5].contains { abs(strongest - $0) / $0 < 0.04 }, "\(strongest) Hz")
    }

    func testChimeClimbsThreeNotes() {
        let x = render(.chime)
        let notes = [(0.01, 0.11), (0.13, 0.23), (0.25, 0.5)].map {
            AudioAnalysis.dominantFrequency(slice(x, $0.0, $0.1), from: 900, to: 2_000)
        }
        XCTAssertEqual(notes[0], 1046.5, accuracy: 25)
        XCTAssertEqual(notes[1], 1318.5, accuracy: 25)
        XCTAssertEqual(notes[2], 1568.0, accuracy: 25)
    }

    // MARK: - Les bestioles

    func testFlyBuzzIsALowWobblingSaw() {
        // Hauteur moyenne sur le vol (la mouche ondule et passe : un seul instant ne suffit pas).
        let instants = Array(stride(from: 0.2, through: 0.95, by: 0.075))
        let heard = (0..<4).map { v in instants.map { pitch(render(.buzz, v), at: $0, 120, 400) } }
        let means = heard.map { $0.reduce(0, +) / Double($0.count) }
        for f in means { XCTAssertTrue((175...250).contains(f), "mouche à \(f) Hz") }
        let sorted = means.sorted()
        for (a, b) in zip(sorted, sorted.dropFirst()) {
            XCTAssertGreaterThan(b / a, 1.03, "deux mouches trop proches : \(means)")
        }
    }

    func testBeeIsHigherAndRounderThanTheFly() {
        for variant in 0..<3 {
            let bee = render(.beeBuzz, variant), fly = render(.buzz, variant)
            XCTAssertGreaterThan(pitch(bee, at: 0.5, 120, 500), pitch(fly, at: 0.55, 120, 500))
            XCTAssertLessThan(AudioAnalysis.centroid(bee), AudioAnalysis.centroid(fly))
        }
    }

    func testTweetChirpsInTheBirdRange() {
        for (variant, chirps) in [(0, 2), (1, 3), (2, 4)] {
            let x = render(.tweet, variant)
            XCTAssertEqual(AudioAnalysis.bursts(x), chirps, "variante \(variant)")
            let f = AudioAnalysis.dominantFrequency(x, from: 500, to: 8_000)
            XCTAssertTrue((2_000...4_500).contains(f), "\(f) Hz")
        }
    }

    func testPopRisesAndDripFalls() {
        let pop = render(.pop), drip = render(.drip)
        // Fenêtres courtes (8 ms) : la hauteur change en quelques millisecondes.
        let at: ([Float], Double) -> Double = {
            AudioAnalysis.pitch($0, at: $1, window: 0.008, minHz: 300, maxHz: 4_000) ?? 0
        }
        let popStart = at(pop, 0.008), popEnd = at(pop, 0.06)
        XCTAssertGreaterThan(popEnd, popStart * 1.4, "pop : \(popStart) → \(popEnd)")
        let dripStart = at(drip, 0.008), dripEnd = at(drip, 0.05)
        XCTAssertLessThan(dripEnd, dripStart * 0.8, "goutte : \(dripStart) → \(dripEnd)")
    }

    func testDingPlaysThePentatonicScale() {
        var seen: Set<Int> = []
        for variant in -5..<10 {
            let expected = SoundLevels.dingFrequency(variant)
            let heard = AudioAnalysis.dominantFrequency(render(.ding, variant), from: 200, to: 2_000)
            XCTAssertEqual(heard, expected, accuracy: expected * 0.01, "variante \(variant)")
            let semitones = Int((12 * log2(expected / 261.6256)).rounded())
            XCTAssertTrue([0, 2, 4, 7, 9].contains(semitones % 12), "hors gamme : \(expected) Hz")
            seen.insert(Int(expected))
        }
        XCTAssertEqual(seen.count, 15, "15 notes différentes sur trois octaves")
        XCTAssertEqual(SoundLevels.dingFrequency(0), 523.25, accuracy: 0.01, "variante 0 = do5")
        XCTAssertEqual(SoundLevels.dingFrequency(15), SoundLevels.dingFrequency(0), "la gamme boucle")
    }

    // MARK: - Les objets des mots

    func testMooHasACowFundamental() {
        let x = render(.moo)
        for t in [0.4, 0.7, 1.0] {
            let f = pitch(x, at: t, 60, 300)
            XCTAssertTrue((80...110).contains(f), "meuh à \(f) Hz (t = \(t) s)")
        }
    }

    func testSirenAlternatesPinPon() {
        let x = render(.siren)
        let heard = [0.2, 0.6, 1.0, 1.4].map { pitch(x, at: $0, 200, 1_000) }
        for (f, expected) in zip(heard, [580.0, 435, 580, 435]) {
            XCTAssertEqual(f, expected, accuracy: expected * 0.03, "pin-pon : \(heard)")
        }
    }

    func testMeowRisesThenFalls() {
        let x = render(.meow)
        let (start, top, end) = (pitch(x, at: 0.08, 300, 1_200), pitch(x, at: 0.3, 300, 1_200),
                                 pitch(x, at: 0.75, 300, 1_200))
        XCTAssertGreaterThan(top, start * 1.2, "miaou : \(start) → \(top)")
        XCTAssertLessThan(end, top * 0.8, "miaou : \(top) → \(end)")
        XCTAssertTrue((400...850).contains(top))
    }

    func testDogsBarkTwiceAndThePoodleIsHigher() {
        let woof = render(.woof), yap = render(.yap)
        XCTAssertEqual(AudioAnalysis.bursts(woof), 2, "ouaf ouaf")
        XCTAssertEqual(AudioAnalysis.bursts(yap), 2)
        // Plages séparées : le formant F1 (≈ 750 Hz) gonfle l'harmonique 2 de l'aboiement, et YIN
        // sans borne haute peut sauter à l'octave.
        let dog = pitch(woof, at: 0.05, 200, 500), poodle = pitch(yap, at: 0.03, 450, 1_200)
        XCTAssertTrue((260...420).contains(dog), "ouaf à \(dog) Hz")
        XCTAssertGreaterThan(poodle, 1.6 * dog, "caniche \(poodle) Hz, chien \(dog) Hz")
        XCTAssertLessThan(yap.count, woof.count)
    }

    func testSqueakIsHigh() {
        let x = render(.squeak)
        XCTAssertGreaterThan(AudioAnalysis.dominantFrequency(x, from: 200, to: 8_000), 1_400)
        XCTAssertGreaterThan(pitch(x, at: 0.08, 800, 4_000), 2_000, "couic : ça monte")
    }

    func testClipClopTrots() {
        XCTAssertTrue((4...6).contains(AudioAnalysis.bursts(render(.clipClop))))
    }

    func testFootstepsAreTwoBigThumpsHeardOnSmallSpeakers() {
        let x = render(.footsteps)
        XCTAssertEqual(AudioAnalysis.bursts(x), 2, "boum boum")
        XCTAssertGreaterThan(AudioAnalysis.bandFraction(x, 40, 160), 0.3, "le sol tremble")
        XCTAssertGreaterThan(AudioAnalysis.bandFraction(x, 160, 2_000), 0.2, "un iPad doit l'entendre")
    }

    func testHornIsTwoBlastsOfAMajorThird() {
        let x = render(.horn)
        XCTAssertEqual(AudioAnalysis.bursts(x), 2, "tut-tut")
        XCTAssertEqual(AudioAnalysis.dominantFrequency(x, from: 350, to: 450), 400, accuracy: 6)
        XCTAssertEqual(AudioAnalysis.dominantFrequency(x, from: 450, to: 550), 500, accuracy: 6)
        XCTAssertGreaterThan(AudioAnalysis.bandFraction(x, 380, 520), 0.3)
    }

    func testDoorbellGoesDingDong() {
        let x = render(.doorbell)
        XCTAssertEqual(AudioAnalysis.dominantFrequency(slice(x, 0.02, 0.45), from: 300, to: 1_000), 659.3, accuracy: 8)
        XCTAssertEqual(AudioAnalysis.dominantFrequency(slice(x, 0.55, 1.2), from: 300, to: 1_000), 523.3, accuracy: 8)
    }

    func testBellStrikesTwice() {
        let x = render(.bell)
        let before = AudioAnalysis.envelope(slice(x, 0.5, 0.58), step: 0.08).first ?? 0
        let after = AudioAnalysis.envelope(slice(x, 0.62, 0.7), step: 0.08).first ?? 0
        XCTAssertGreaterThan(after, 1.5 * before, "« dong » : second coup")
        XCTAssertGreaterThan(Double(x.count) / SoundSynth.sampleRate, 1.5, "une cloche résonne")
    }

    func testFanfareClimbs() {
        let x = render(.fanfare)
        let notes = [0.07, 0.21, 0.35, 0.65].map { pitch(x, at: $0, 250, 1_000) }
        XCTAssertEqual(notes, notes.sorted(), "ta-ta-ta-taaa : \(notes)")
        XCTAssertEqual(notes[0], 392, accuracy: 12)
        XCTAssertEqual(notes[3], 784, accuracy: 20)
    }

    func testHonkIsNasalTwice() {
        let x = render(.honk)
        XCTAssertEqual(AudioAnalysis.bursts(x), 2)
        XCTAssertGreaterThan(AudioAnalysis.bandFraction(x, 600, 1_100), 0.35, "formant nasal ≈ 800 Hz")
    }

    func testBellowIsALongLowCall() {
        let x = render(.bellow)
        XCTAssertGreaterThan(Double(x.count) / SoundSynth.sampleRate, 1.5)
        let f = pitch(x, at: 0.8, 60, 400)
        XCTAssertTrue((100...160).contains(f), "\(f) Hz")
    }

    // MARK: - Les animaux des livres (17/11/2026)

    /// Pics d'une enveloppe (pas `step`) entre `from` et `to` s : maxima locaux qui dominent leurs
    /// voisins d'au moins `rise` (relatif au maximum de la tranche) — trilles, roulements, chevrotements.
    private func peaks(_ x: [Float], _ from: Double, _ to: Double, step: Double, rise: Double = 0.08) -> Int {
        let e = AudioAnalysis.envelope(slice(x, from, to), step: step)
        let top = e.max() ?? 0
        guard top > 0, e.count > 4 else { return 0 }
        var count = 0, low = e[0]
        var climbing = false
        for i in 1..<e.count {
            if e[i] > e[i - 1] {
                climbing = true
            } else if climbing, e[i] < e[i - 1] {
                if e[i - 1] - low > rise * top { count += 1 }
                climbing = false
                low = e[i]
            }
            low = min(low, e[i])
        }
        return count
    }

    /// Râpe d'un passage tenu : écart moyen de l'enveloppe (10 ms) à la moyenne de ses deux voisines,
    /// rapporté à son niveau — les à-coups rapides comptent, la forme lente du cri ne compte pas.
    private func roughness(_ x: [Float], _ from: Double, _ to: Double) -> Double {
        let e = AudioAnalysis.envelope(slice(x, from, to), step: 0.01).dropLast()
        let mean = e.reduce(0, +) / Double(e.count)
        let jumps = (1..<(e.count - 1)).map { abs(e[$0] - (e[$0 - 1] + e[$0 + 1]) / 2) }
        return jumps.reduce(0, +) / Double(jumps.count) / max(mean, 1e-12)
    }

    func testLionRoarIsALongLowRaspyCall() {
        let x = render(.roar)
        XCTAssertGreaterThan(Double(x.count) / SoundSynth.sampleRate, 1.2, "un rugissement se tient")
        for t in [0.45, 0.8] {
            let f = pitch(x, at: t, 100, 250)
            XCTAssertTrue((110...180).contains(f), "rugissement à \(f) Hz (t = \(t) s)")
        }
        XCTAssertGreaterThan(AudioAnalysis.bandFraction(x, 100, 1_500), 0.6)
        let raspy = roughness(x, 0.3, 0.9), smooth = roughness(render(.moo), 0.3, 0.9)
        XCTAssertGreaterThan(raspy, 4 * smooth, "râpe : \(raspy) vs meuh \(smooth)")
        XCTAssertGreaterThan(raspy, 0.15)
    }

    func testDinosaurIsBiggerThanTheLionAndDragonBreathesFire() {
        let lion = render(.roar), dino = render(.dinoRoar), dragon = render(.dragonRoar)
        XCTAssertLessThan(AudioAnalysis.centroid(dino), AudioAnalysis.centroid(lion), "dinosaure plus grave")
        XCTAssertGreaterThan(dino.count, lion.count, "et plus long")
        XCTAssertGreaterThan(AudioAnalysis.bandFraction(slice(dino, 0, 0.12), 40, 200), 0.5, "« boum » d'abord")
        // Le dragon : la voix (grave), puis le souffle (bruit large, plus aigu).
        let voice = slice(dragon, 0.1, 0.5), fire = slice(dragon, 1.0, 1.5)
        XCTAssertTrue((120...230).contains(pitch(dragon, at: 0.35, 100, 300)))
        XCTAssertGreaterThan(AudioAnalysis.centroid(fire), AudioAnalysis.centroid(voice) + 800)
        XCTAssertGreaterThan(AudioAnalysis.bandFraction(fire, 1_000, 6_000), 0.5, "souffle de feu")
    }

    func testWolfHowlRisesHoldsAndFalls() {
        let x = render(.howl)
        XCTAssertEqual(AudioAnalysis.bursts(x), 1, "un seul « aouuu »")
        let (start, top, end) = (pitch(x, at: 0.05, 250, 900), pitch(x, at: 0.6, 250, 900), pitch(x, at: 1.7, 250, 900))
        XCTAssertTrue((480...650).contains(top), "\(top) Hz")
        XCTAssertLessThan(start, top * 0.75, "monte : \(start) → \(top)")
        XCTAssertLessThan(end, top * 0.85, "redescend : \(top) → \(end)")
        XCTAssertGreaterThan(Double(x.count) / SoundSynth.sampleRate, 1.5)
    }

    func testHenGoesCotCotCotCodet() {
        let x = render(.cluck)
        XCTAssertEqual(AudioAnalysis.bursts(x), 5, "cot · cot · cot · co · dêêt")
        let cot = pitch(x, at: 0.03, 300, 600), det = pitch(x, at: 0.75, 400, 900)
        XCTAssertGreaterThan(det, cot * 1.3, "« dêêt » plus haut : \(cot) → \(det)")
    }

    func testRoosterCrowsFourSyllablesUpThenDown() {
        let x = render(.crow)
        XCTAssertEqual(AudioAnalysis.bursts(x), 4, "co · co · ri · cooo")
        let heard = [0.07, 0.22, 0.37, 0.62].map { pitch(x, at: $0, 400, 1_100) }
        XCTAssertEqual(heard, heard.sorted(), "ça monte : \(heard)")
        XCTAssertGreaterThan(heard[3], heard[0] * 1.4)
        XCTAssertLessThan(pitch(x, at: 1.17, 400, 1_100), heard[3] * 0.85, "puis la dernière retombe")
    }

    func testDuckQuacksTwiceNasalAndBelowTheGoose() {
        let x = render(.quack), goose = render(.honk)
        XCTAssertEqual(AudioAnalysis.bursts(x), 2, "coin-coin")
        let f = pitch(x, at: 0.05, 150, 400)
        XCTAssertTrue((200...300).contains(f), "\(f) Hz")
        XCTAssertLessThan(f, pitch(goose, at: 0.05, 150, 600), "voix plus grave que l'oie")
        XCTAssertGreaterThan(AudioAnalysis.bandFraction(x, 800, 2_000), 0.4, "formants nasaux hauts")
    }

    func testHorseNeighsDownInATrill() {
        let x = render(.neigh)
        let high = pitch(x, at: 0.17, 300, 1_400), low = pitch(x, at: 1.0, 300, 1_400)
        XCTAssertGreaterThan(high, 1.6 * low, "le hennissement descend : \(high) → \(low)")
        XCTAssertGreaterThan(high, 800)
        let trill = peaks(x, 0.35, 1.1, step: 0.01)
        XCTAssertTrue((5...10).contains(trill), "trille ≈ 11/s : \(trill) battements")
    }

    func testFrogCroaksTwiceRolled() {
        let x = render(.croak)
        XCTAssertEqual(AudioAnalysis.bursts(x), 2, "coâ-coâ")
        XCTAssertTrue((120...190).contains(pitch(x, at: 0.1, 100, 300)))
        XCTAssertGreaterThanOrEqual(peaks(x, 0.04, 0.26, step: 0.004), 4, "coassement roulé")
    }

    func testSheepBleatQuavers() {
        let x = render(.baa)
        XCTAssertEqual(AudioAnalysis.bursts(x), 1, "un seul « bêêê »")
        let f = pitch(x, at: 0.5, 200, 450)
        XCTAssertTrue((270...400).contains(f), "\(f) Hz")
        XCTAssertTrue((3...7).contains(peaks(x, 0.15, 0.85, step: 0.01)), "chevrotement ≈ 7/s")
    }

    func testSealBarksThreeTimes() {
        let x = render(.sealBark)
        XCTAssertEqual(AudioAnalysis.bursts(x), 3, "ar-ar-ar")
        XCTAssertTrue((250...450).contains(pitch(x, at: 0.05, 200, 500)))
    }

    func testDolphinClicksThenWhistlesUp() {
        let x = render(.dolphin)
        XCTAssertGreaterThanOrEqual(AudioAnalysis.bursts(slice(x, 0, 0.38)), 8, "rafale de clics")
        let (low, high) = (pitch(x, at: 0.47, 1_000, 5_000), pitch(x, at: 0.62, 1_000, 5_000))
        XCTAssertGreaterThan(high, low * 1.3, "sifflet qui monte : \(low) → \(high)")
        XCTAssertTrue((1_500...4_000).contains(AudioAnalysis.dominantFrequency(x, from: 500, to: 8_000)))
    }

    func testCrocodileSnapsItsJawsTwice() {
        let x = render(.jawSnap)
        XCTAssertEqual(AudioAnalysis.bursts(x), 2, "clac · clac")
        // Attaque sèche : de moins de 10 % à plus de la moitié du maximum en 3 ms.
        let fine = AudioAnalysis.envelope(x, step: 0.001)
        let top = fine.max() ?? 0
        let onset = fine.firstIndex { $0 > 0.5 * top } ?? 0
        XCTAssertLessThan(fine[max(onset - 3, 0)], 0.1 * top, "« clac ! » : attaque sèche")
    }

    func testRabbitNibblesAndSpiderClimbs() {
        let nibble = render(.nibble)
        XCTAssertTrue((6...12).contains(AudioAnalysis.bursts(nibble)), "trois bouchées croquantes")
        XCTAssertGreaterThan(AudioAnalysis.centroid(nibble), 1_200)
        let spider = render(.tiptoe)
        XCTAssertEqual(AudioAnalysis.bursts(spider), 8, "huit petits pas")
        let first = AudioAnalysis.dominantFrequency(slice(spider, 0, 0.1), from: 300, to: 2_000)
        let last = AudioAnalysis.dominantFrequency(slice(spider, 0.77, 0.95), from: 300, to: 2_000)
        XCTAssertEqual(first, 523.25, accuracy: 25)
        XCTAssertGreaterThan(last, 2 * first, "elle grimpe")
    }

    /// Les sons graves gardent un « corps » que les haut-parleurs d'un iPad reproduisent.
    func testLowSoundsKeepABodyAbove160Hz() {
        for effect in [SoundEffect.plop, .slime, .splat, .blub, .moo, .bell, .bellow, .footsteps, .crunch,
                       .roar, .dinoRoar, .dragonRoar, .croak] {
            let audible = AudioAnalysis.bandFraction(render(effect), 160, 5_000)
            XCTAssertGreaterThan(audible, effect == .footsteps ? 0.2 : 0.4, "\(effect) : \(audible)")
        }
    }
}
