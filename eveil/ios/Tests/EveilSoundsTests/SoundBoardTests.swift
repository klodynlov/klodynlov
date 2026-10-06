// SoundBoardTests.swift — la règle d'or : AUCUN bruitage pendant l'écoute.
//
// Une sortie factice (`RecordingOutput`) remplace le moteur audio : on relit la suite des
// ordres reçus (jouer, couper, suspendre), sans jamais ouvrir la sortie son du Mac.

#if canImport(AVFoundation)
@testable import EveilSounds
import XCTest

/// Journal des ordres reçus. Écrit sur la file du cœur, relu après `waitUntilIdle`
/// (qui synchronise avec cette file).
final class RecordingOutput: SoundOutput {
    enum Event: Equatable {
        case play(SoundEffect, Int, Float)
        case stop
        case suspend
    }

    private(set) var events: [Event] = []
    private(set) var kept: Set<SoundKey> = []
    private(set) var forgotten: [SoundKey] = []

    var plays: [Event] { events.filter { if case .play = $0 { return true } else { return false } } }

    func store(_ key: SoundKey, samples: [Float]) {
        XCTAssertFalse(samples.isEmpty)
        kept.insert(key)
    }

    func forget(_ key: SoundKey) {
        kept.remove(key)
        forgotten.append(key)
    }

    func play(_ key: SoundKey, volume: Float) {
        XCTAssertTrue(kept.contains(key), "\(key) joué sans avoir été confié")
        events.append(.play(key.effect, key.variant, volume))
    }

    func stopAll() { events.append(.stop) }

    func suspend() { events.append(.suspend) }
}

@MainActor
final class SoundBoardTests: XCTestCase {
    func testNothingPlaysWhileSuspended() {
        let output = RecordingOutput()
        let board = SoundBoard(output: output)
        board.isSuspended = true
        board.play(.buzz)
        board.play(.whistle, volume: 0.5)
        XCTAssertTrue(board.waitUntilIdle())
        XCTAssertEqual(output.plays, [], "un son pendant l'écoute")
        XCTAssertEqual(output.events, [.suspend])
    }

    /// Un son demandé juste avant l'écoute, dont le calcul finit après : jamais joué.
    func testALateRenderNeverSoundsDuringListening() {
        let output = RecordingOutput()
        let board = SoundBoard(output: output)
        board.play(.moo)                        // pas encore calculé : il faudra attendre
        board.isSuspended = true                // l'écoute commence tout de suite
        XCTAssertTrue(board.waitUntilIdle())
        if let suspension = output.events.lastIndex(of: .suspend) {
            let after = output.events[suspension...].filter { if case .play = $0 { return true } else { return false } }
            XCTAssertEqual(after, [], "un son est parti après la suspension : \(output.events)")
        } else {
            XCTFail("la suspension n'a pas atteint la sortie")
        }
    }

    func testPreloadedSoundPlaysWithClampedVolume() {
        let output = RecordingOutput()
        let board = SoundBoard(output: output)
        board.preload([.pop], variants: [0, 2])
        XCTAssertTrue(board.waitUntilIdle())
        board.play(.pop, volume: 0.5)
        board.play(.pop, variant: 2, volume: 3)
        board.play(.pop, volume: -1)
        board.play(.pop, volume: .nan)
        XCTAssertTrue(board.waitUntilIdle())
        XCTAssertEqual(output.plays, [.play(.pop, 0, 0.5), .play(.pop, 2, 1), .play(.pop, 0, 0), .play(.pop, 0, 0)])
    }

    func testStopAllCutsWhatIsWaitingForItsRender() {
        let output = RecordingOutput()
        let board = SoundBoard(output: output)
        board.play(.bell)
        board.stopAll()
        XCTAssertTrue(board.waitUntilIdle())
        XCTAssertEqual(output.plays, [], "le calcul a fini après stopAll : rien ne doit partir")
        XCTAssertEqual(output.events, [.stop])
    }

    func testPlayingResumesAfterListening() {
        let output = RecordingOutput()
        let board = SoundBoard(output: output)
        board.isSuspended = true
        board.isSuspended = false
        board.play(.ding, variant: 3)
        board.play(.ding, variant: 3)           // deux demandes pendant le même calcul : deux sons
        XCTAssertTrue(board.waitUntilIdle())
        XCTAssertEqual(output.events, [.suspend, .play(.ding, 3, 1), .play(.ding, 3, 1)])
    }

    /// Le cache est borné : le son le moins récemment joué est oublié (et recalculé au besoin).
    func testCacheForgetsTheLeastRecentlyPlayed() {
        let output = RecordingOutput()
        let board = SoundBoard(output: output, capacity: 2)
        board.preload([.pop, .drip])
        XCTAssertTrue(board.waitUntilIdle())
        board.play(.pop)                        // « pop » devient le plus récent
        board.preload([.click])
        XCTAssertTrue(board.waitUntilIdle())
        XCTAssertEqual(output.forgotten, [SoundKey(effect: .drip, variant: 0)])
        board.play(.drip)                       // recalculé, puis joué
        XCTAssertTrue(board.waitUntilIdle())
        XCTAssertEqual(output.plays, [.play(.pop, 0, 1), .play(.drip, 0, 1)])
    }

    /// Le VRAI moteur, sur demande : `EVEIL_SOUNDS_ENGINE=silence` (volume 0 : on vérifie
    /// démarrage, polyphonie, démontage à la suspension, reconstruction après un changement de
    /// configuration) ou `EVEIL_SOUNDS_ENGINE=listen` (même chose, mais on ENTEND chaque effet,
    /// l'un après l'autre, sur la sortie son du Mac).
    func testRealEngineWhenAsked() throws {
        guard let mode = ProcessInfo.processInfo.environment["EVEIL_SOUNDS_ENGINE"], !mode.isEmpty else { return }
        let listen = mode == "listen"
        let volume: Float = listen ? 0.8 : 0
        let board = SoundBoard()
        func engine<T>(_ read: (EngineOutput) -> T) throws -> T {
            try XCTUnwrap(board.inspectOutput { ($0 as? EngineOutput).map(read) })
        }
        board.preload(SoundEffect.allCases)
        XCTAssertTrue(board.waitUntilIdle(timeout: 120))
        for effect in SoundEffect.allCases {
            board.play(effect, volume: volume)
            if listen {
                print("▶︎ \(effect.rawValue)")
                Thread.sleep(forTimeInterval: Double(Renders.sound(effect).count) / SoundSynth.sampleRate + 0.35)
            }
        }
        XCTAssertTrue(board.waitUntilIdle())
        guard try engine({ $0.isRunning }) else {
            throw XCTSkip("pas de sortie audio utilisable ici : le moteur n'a pas démarré (silence, sans plantage)")
        }
        XCTAssertEqual(try engine { $0.started }, SoundEffect.allCases.count,
                       "8 voix pour 53 sons : on prend la voix qui finit le plus tôt")
        XCTAssertEqual(try engine { $0.builds }, 1)

        board.isSuspended = true                // l'écoute commence : moteur démonté
        board.play(.pop, volume: volume)
        XCTAssertTrue(board.waitUntilIdle())
        XCTAssertFalse(try engine { $0.isRunning })
        board.isSuspended = false
        board.play(.ding, variant: 4, volume: volume)
        XCTAssertTrue(board.waitUntilIdle())
        XCTAssertTrue(try engine { $0.isRunning }, "reconstruit au premier son après l'écoute")
        XCTAssertEqual(try engine { $0.builds }, 2)

        _ = board.inspectOutput { ($0 as? EngineOutput)?.simulateConfigurationChange() }
        XCTAssertTrue(board.waitUntilIdle())
        board.play(.chime, volume: volume)
        XCTAssertTrue(board.waitUntilIdle())
        XCTAssertEqual(try engine { $0.builds }, 3, "reconstruit après le changement de configuration")
        XCTAssertTrue(try engine { $0.isRunning })
        if listen { Thread.sleep(forTimeInterval: 1.2) }
        board.stopAll()
        XCTAssertTrue(board.waitUntilIdle())
    }

    /// Le vrai moteur : sûr quand l'écoute tourne (aucun démarrage, aucun plantage).
    func testRealBoardStaysQuietAndSafeWhileSuspended() {
        let board = SoundBoard()
        board.isSuspended = true
        board.play(.siren)
        board.stopAll()
        board.preload([.pop])
        XCTAssertTrue(board.waitUntilIdle())
        board.isSuspended = false
        XCTAssertTrue(board.waitUntilIdle())
    }
}
#endif
