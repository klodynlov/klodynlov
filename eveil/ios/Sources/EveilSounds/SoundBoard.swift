// SoundBoard.swift — jouer les bruitages, JAMAIS pendant l'écoute.
//
// Trois étages :
// - `SoundBoard` (MainActor) : l'interface du jeu. Elle tient `isSuspended` et un
//   numéro de GÉNÉRATION, et envoie chaque ordre, dans l'ordre, sur une file
//   série privée : le fil principal ne calcule aucun son et ne démarre jamais
//   le moteur audio lui-même (rien qui fasse sauter une image) ;
// - `SoundBoardCore` (la file) : chaque son est calculé une fois, en
//   arrière-plan (`SoundSynth` est pur), puis confié à la sortie qui le garde
//   par (effet, variante) — 96 sons au plus, le moins récemment joué est
//   oublié. Un son demandé avant d'être prêt part dès que son calcul finit… si
//   sa génération est toujours la bonne ;
// - `EngineOutput` : AVAudioEngine, 8 lecteurs (8 bruitages superposés au plus :
//   au-delà, celui qui finit le plus tôt cède sa place) → mélangeur principal. Tampons
//   `AVAudioPCMBuffer` en 44,1 kHz mono Float : le mélangeur convertit vers le
//   format du matériel.
//
// Tour de parole strict : `isSuspended = true` change la génération, coupe tout
// et démonte le moteur. Un son demandé AVANT la suspension passe par la même
// file, donc avant elle, et elle le coupe ; un son dont le calcul finit APRÈS
// porte une génération périmée : il n'est jamais joué.
//
// Robustesse : le contrôleur d'écoute bascule la session audio
// (`.playAndRecord` / `.measurement`) puis la rend ; le matériel change de
// fréquence ou de route et le moteur reçoit `AVAudioEngineConfigurationChange`.
// On se contente de le marquer « à reconstruire » (Apple déconseille de toucher
// au moteur dans cette notification) ; il est reconstruit au PROCHAIN son. De
// même après une suspension ou une réinitialisation des services média. Tout
// échec est silencieux : un bruitage manqué vaut mieux qu'un plantage. Ce
// module ne touche JAMAIS à la catégorie de la session : elle appartient à
// l'écoute.

#if canImport(AVFoundation)
import AVFoundation
import Foundation

@MainActor
public final class SoundBoard {
    public static let shared = SoundBoard()

    /// Vrai pendant l'écoute de l'enfant (et pendant le mot modèle) : tout se tait,
    /// et `play` ne fait rien. Tour de parole strict.
    public var isSuspended = false {
        didSet {
            if isSuspended {
                generation &+= 1
                core.suspend(generation: generation)
            }
        }
    }

    private let core: SoundBoardCore
    private var generation = 0

    public init() {
        let queue = DispatchQueue(label: "eveil.sounds", qos: .userInitiated)
        core = SoundBoardCore(queue: queue, output: EngineOutput(queue: queue))
    }

    /// Tests : une sortie factice à la place du moteur audio.
    init(output: SoundOutput, capacity: Int = SoundBoardCore.defaultCapacity) {
        core = SoundBoardCore(queue: DispatchQueue(label: "eveil.sounds.test"), output: output, capacity: capacity)
    }

    /// Prépare les effets à l'avance (le premier « bzzz » part sans délai). Calcul en
    /// arrière-plan ; `variants` pour les bestioles qui volent à plusieurs, ou les notes.
    public func preload(_ effects: [SoundEffect], variants: [Int] = [0]) {
        core.preload(effects.flatMap { effect in variants.map { SoundKey(effect: effect, variant: $0) } })
    }

    /// Joue un effet ; plusieurs peuvent se superposer. Sans effet si `isSuspended`.
    public func play(_ effect: SoundEffect, variant: Int = 0, volume: Float = 1) {
        guard !isSuspended else { return }
        let level = volume.isFinite ? min(max(volume, 0), 1) : 0
        core.play(SoundKey(effect: effect, variant: variant), volume: level, generation: generation)
    }

    /// Coupe tout ce qui joue (et ce qui attendait la fin de son calcul).
    public func stopAll() {
        generation &+= 1
        core.stopAll(generation: generation)
    }

    /// Tests : attend que les calculs en cours et la file soient finis.
    @discardableResult
    func waitUntilIdle(timeout: TimeInterval = 20) -> Bool { core.waitUntilIdle(timeout: timeout) }

    /// Tests : lit l'état de la sortie, sur sa file.
    func inspectOutput<T>(_ body: (SoundOutput) -> T) -> T { core.inspect(body) }
}

/// Un son : l'effet et sa variante.
struct SoundKey: Hashable, Sendable {
    let effect: SoundEffect
    let variant: Int
}

/// La sortie audio (le moteur en vrai, un enregistreur dans les tests). Toujours appelée
/// depuis la file de `SoundBoardCore`, jamais depuis deux fils à la fois.
protocol SoundOutput: AnyObject {
    /// Garde une copie jouable du son (appelé une fois par son, avant tout `play`).
    func store(_ key: SoundKey, samples: [Float])
    /// Oublie un son gardé (le cache est plein).
    func forget(_ key: SoundKey)
    func play(_ key: SoundKey, volume: Float)
    func stopAll()
    /// Suspension : tout se tait et le moteur est rendu (il renaîtra au prochain son).
    func suspend()
}

/// Tout son état vit sur `queue` (file série) : c'est ce confinement, et non le
/// compilateur, qui le protège — d'où `@unchecked Sendable`.
final class SoundBoardCore: @unchecked Sendable {
    static let defaultCapacity = 96

    private let queue: DispatchQueue
    private let output: SoundOutput
    private let capacity: Int
    private var stored: [SoundKey] = []                      // du moins au plus récemment joué
    private var rendering: Set<SoundKey> = []
    private var waiting: [SoundKey: [Float]] = [:]           // volumes des lectures en attente
    private var generation = 0

    init(queue: DispatchQueue, output: SoundOutput, capacity: Int = defaultCapacity) {
        self.queue = queue
        self.output = output
        self.capacity = max(capacity, 1)
    }

    func preload(_ keys: [SoundKey]) {
        queue.async { for key in keys { self.render(key) } }
    }

    func play(_ key: SoundKey, volume: Float, generation: Int) {
        queue.async {
            guard generation == self.generation else { return }
            if let index = self.stored.firstIndex(of: key) {
                self.stored.append(self.stored.remove(at: index))
                self.output.play(key, volume: volume)
            } else {
                self.waiting[key, default: []].append(volume)
                self.render(key)
            }
        }
    }

    func stopAll(generation: Int) {
        queue.async {
            self.generation = generation
            self.waiting.removeAll()
            self.output.stopAll()
        }
    }

    func suspend(generation: Int) {
        queue.async {
            self.generation = generation
            self.waiting.removeAll()
            self.output.suspend()
        }
    }

    /// Sur la file : lance le calcul hors de la file (un « meuh » en calcul ne retarde pas un
    /// « pop » déjà prêt), puis revient sur la file pour confier le son à la sortie et servir
    /// les attentes. Les attentes sont vidées par `stopAll` / `suspend` : ce qui reste est
    /// d'actualité.
    private func render(_ key: SoundKey) {
        guard !stored.contains(key), !rendering.contains(key) else { return }
        rendering.insert(key)
        DispatchQueue.global(qos: .userInitiated).async {
            let samples = SoundSynth.render(key.effect, variant: key.variant)
            self.queue.async {
                self.rendering.remove(key)
                self.output.store(key, samples: samples)
                self.stored.append(key)
                if self.stored.count > self.capacity { self.output.forget(self.stored.removeFirst()) }
                for volume in self.waiting.removeValue(forKey: key) ?? [] { self.output.play(key, volume: volume) }
            }
        }
    }

    func inspect<T>(_ body: (SoundOutput) -> T) -> T { queue.sync { body(output) } }

    func waitUntilIdle(timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if queue.sync(execute: { rendering.isEmpty }) { return true }
            Thread.sleep(forTimeInterval: 0.005)
        }
        return false
    }
}

/// AVAudioEngine + lecteurs. Confiné à la file du cœur (voir `SoundBoardCore`).
final class EngineOutput: SoundOutput, @unchecked Sendable {
    private static let voices = 8
    private let queue: DispatchQueue
    private let format = AVAudioFormat(standardFormatWithSampleRate: SoundSynth.sampleRate, channels: 1)
    private var buffers: [SoundKey: AVAudioPCMBuffer] = [:]
    private var engine: AVAudioEngine?
    private var players: [AVAudioPlayerNode] = []
    private var busyUntil: [UInt64] = []
    private var observers: [NSObjectProtocol] = []
    private var stale = false
    /// Compteurs pour les tests : moteurs construits, lectures lancées.
    private(set) var builds = 0
    private(set) var started = 0

    var isRunning: Bool { engine?.isRunning == true }

    init(queue: DispatchQueue) { self.queue = queue }

    deinit {
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
    }

    func store(_ key: SoundKey, samples: [Float]) {
        guard let format, !samples.isEmpty,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)),
              let channel = buffer.floatChannelData?[0] else { return }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { source in
            if let base = source.baseAddress { channel.update(from: base, count: samples.count) }
        }
        buffers[key] = buffer
    }

    func forget(_ key: SoundKey) { buffers[key] = nil }      // un lecteur en cours garde sa copie

    func play(_ key: SoundKey, volume: Float) {
        guard let buffer = buffers[key], let engine = runningEngine() else { return }
        let now = DispatchTime.now().uptimeNanoseconds
        let voice = busyUntil.firstIndex { $0 <= now } ?? busyUntil.indices.min { busyUntil[$0] < busyUntil[$1] } ?? 0
        let player = players[voice]
        player.stop()                                   // voix libre, sinon celle qui finit le plus tôt
        player.volume = volume
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        guard engine.isRunning else { return }          // `play()` sur un moteur arrêté lèverait une exception
        player.play()
        started += 1
        busyUntil[voice] = now + UInt64(Double(buffer.frameLength) / SoundSynth.sampleRate * 1e9)
    }

    func stopAll() {
        for player in players { player.stop() }
        busyUntil = busyUntil.map { _ in 0 }
    }

    func suspend() { tearDown() }

    /// Le moteur prêt à jouer : reconstruit s'il est périmé ou absent, relancé s'il s'est
    /// arrêté (interruption) ; `nil` si le système refuse (on reste silencieux).
    private func runningEngine() -> AVAudioEngine? {
        if stale { tearDown() }
        if engine == nil { build() }
        guard let engine else { return nil }
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                tearDown()                              // on retentera au prochain son
                return nil
            }
        }
        return engine
    }

    private func build() {
        guard let format else { return }
        let engine = AVAudioEngine()
        var nodes: [AVAudioPlayerNode] = []
        for _ in 0..<Self.voices {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            nodes.append(player)
        }
        engine.prepare()
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine,
                                            queue: nil) { [weak self] _ in self?.markStale() })
        #if os(iOS) || os(tvOS) || os(visionOS)
        observers.append(center.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil,
                                            queue: nil) { [weak self] _ in self?.markStale() })
        #endif
        self.engine = engine
        players = nodes
        busyUntil = Array(repeating: 0, count: nodes.count)
        stale = false
        builds += 1
    }

    /// Tests : la notification que le système envoie quand la session change de route ou de
    /// fréquence (l'écoute passe en `.playAndRecord` / `.measurement`).
    func simulateConfigurationChange() {
        guard let engine else { return }
        NotificationCenter.default.post(name: .AVAudioEngineConfigurationChange, object: engine)
    }

    /// Appelé depuis le fil de la notification : on ne touche au moteur QUE sur la file.
    private func markStale() {
        queue.async { self.stale = true }
    }

    private func tearDown() {
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
        observers.removeAll()
        for player in players { player.stop() }
        engine?.stop()
        engine = nil
        players = []
        busyUntil = []
        stale = false
    }
}
#endif
