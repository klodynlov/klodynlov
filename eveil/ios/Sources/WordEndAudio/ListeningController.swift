// ListeningController.swift — l'écoute d'un mot, du micro au verdict.
//
// Tour de parole strict : le modèle (voix enregistrée) est joué, PUIS on écoute.
// Jamais les deux à la fois : sans annulation d'écho (mode `.measurement`), la
// voix du modèle serait analysée comme celle de l'enfant.
//
// Fils d'exécution : le micro livre ses blocs sur un fil audio ; ils sont
// sérialisés sur `analysisQueue` (le traqueur n'est jamais touché en
// concurrence) ; les événements remontent sur le MainActor pour l'interface.

#if canImport(AVFoundation) && canImport(Observation)
import AVFoundation
import Foundation
import Observation
import WordEndCore

/// Le traqueur n'est pas thread-safe : `push` et `stop` ne tournent que sur
/// `analysisQueue` (file série), et le MainActor ne s'en sert que pour comparer
/// des identités (`===`). Le compilateur ne sait pas prouver un confinement par
/// file : cette boîte porte le contrat, au lieu de déclarer `StreamingTracker`
/// Sendable dans le cœur (ce qu'il n'est pas).
private final class ConfinedTracker: @unchecked Sendable {
    let tracker: StreamingTracker
    init(_ tracker: StreamingTracker) { self.tracker = tracker }
}

@MainActor
@Observable
public final class ListeningController {
    public enum Phase: Equatable {
        case idle
        case listening
        case finished(Verdict)
        case failed(String)
    }

    public private(set) var phase: Phase = .idle
    /// Aperçu en direct : nombre de wagons allumés pendant que l'enfant parle.
    public private(set) var litWagons = 0
    /// Aperçu en direct : une friction finale a été entendue (le fourgon s'accroche).
    public private(set) var cabooseHeard = false
    public private(set) var childIsSpeaking = false
    /// Niveau du micro (dBFS, RMS du dernier bloc) : le vumètre du test micro de
    /// l'espace des grands. Un nombre, jamais le son.
    public private(set) var inputLevelDb = -120.0

    /// Seuils du détecteur et réglages du flux, pris en compte à la PROCHAINE écoute
    /// (l'espace des grands peut, par exemple, accepter les voix d'adulte pour un essai).
    public var config: DetectorConfig
    public var stream: StreamingConfig

    private let microphone = MicrophoneStream()
    private let analysisQueue = DispatchQueue(label: "eveil.wordend.analysis", qos: .userInitiated)
    @ObservationIgnored private var tracker: StreamingTracker?
    @ObservationIgnored private var demoTask: Task<Void, Never>?

    public init(config: DetectorConfig = DetectorConfig(), stream: StreamingConfig = StreamingConfig()) {
        self.config = config
        self.stream = stream
    }

    /// Autorisation micro (iOS 17 : `AVAudioApplication`). À demander depuis
    /// l'espace parent, après une explication destinée à l'adulte.
    public static func requestMicrophone() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    /// Écoute l'enfant dire `word` ; le verdict final arrive dans `phase`.
    public func listen(for word: TargetWord) {
        guard phase != .listening else { return }
        let tracker = StreamingTracker(target: word, config: config, stream: stream)
        self.tracker = tracker
        litWagons = 0
        cabooseHeard = false
        childIsSpeaking = false
        do {
            #if os(iOS)
            try AudioSessionConfigurator.configureForMeasurement()
            #endif
            phase = .listening
            let queue = analysisQueue
            let confined = ConfinedTracker(tracker)
            try microphone.start { [weak self] chunk in
                let samples = chunk.map(Double.init)
                queue.async {
                    let level = Self.rmsDb(samples)
                    let events = confined.tracker.push(samples)
                    Task { @MainActor in
                        self?.inputLevelDb = level
                        if !events.isEmpty { self?.apply(events, from: confined.tracker) }
                    }
                }
            }
        } catch {
            phase = .failed(String(describing: error))
        }
    }

    /// « Micro simulé » (mode démo) : pousse un signal déjà prêt (pseudo-parole de
    /// `Synth`) dans le VRAI traqueur, par blocs de 20 ms au rythme du temps réel.
    /// Aucun micro n'est ouvert ; le train réagit comme avec un enfant.
    public func listenDemo(for word: TargetWord, samples: [Double]) {
        guard phase != .listening else { return }
        let tracker = StreamingTracker(target: word, config: config, stream: stream)
        self.tracker = tracker
        litWagons = 0
        cabooseHeard = false
        childIsSpeaking = false
        phase = .listening
        let queue = analysisQueue
        let confined = ConfinedTracker(tracker)
        demoTask?.cancel()
        demoTask = Task { [weak self] in
            let step = WordEnd.analysisRate / 50
            var start = 0
            while start < samples.count, !Task.isCancelled {
                let chunk = Array(samples[start..<min(start + step, samples.count)])
                start += step
                queue.async {
                    let events = confined.tracker.push(chunk)
                    guard !events.isEmpty else { return }
                    Task { @MainActor in self?.apply(events, from: confined.tracker) }
                }
                try? await Task.sleep(nanoseconds: 20_000_000)
            }
            guard !Task.isCancelled else { return }
            queue.async {                       // sans effet si l'énoncé est déjà clos
                let events = confined.tracker.stop()
                Task { @MainActor in self?.apply(events, from: confined.tracker) }
            }
        }
    }

    /// Arrêt anticipé (l'enfant quitte l'écran…) : le verdict reste « incertain » au besoin.
    public func stop() {
        guard phase == .listening, let tracker else { return }
        demoTask?.cancel()
        microphone.stop()
        let confined = ConfinedTracker(tracker)
        analysisQueue.async { [weak self] in
            let events = confined.tracker.stop()
            Task { @MainActor in self?.apply(events, from: confined.tracker) }
        }
    }

    public func reset() {
        demoTask?.cancel()
        microphone.stop()
        tracker = nil                      // les événements encore en vol seront ignorés
        phase = .idle
        litWagons = 0
        cabooseHeard = false
        childIsSpeaking = false
        inputLevelDb = -120
    }

    /// RMS d'un bloc en dBFS (plancher −120).
    nonisolated static func rmsDb(_ x: [Double]) -> Double {
        guard !x.isEmpty else { return -120 }
        let power = x.reduce(0) { $0 + $1 * $1 } / Double(x.count)
        return max(-120, 10 * log10(max(power, 1e-12)))
    }

    private func apply(_ events: [TrackerEvent], from source: StreamingTracker) {
        // Une écoute relancée (reset + listen) ne doit jamais recevoir le verdict de la précédente.
        guard source === tracker else { return }
        for event in events {
            switch event {
            case .speechStarted:
                childIsSpeaking = true
            case let .nucleusHeard(count, _):
                litWagons = count
            case .codaHeard:
                cabooseHeard = true
            case let .ended(verdict, _, _):
                microphone.stop()
                childIsSpeaking = false
                phase = .finished(verdict)
            }
        }
    }
}
#endif
