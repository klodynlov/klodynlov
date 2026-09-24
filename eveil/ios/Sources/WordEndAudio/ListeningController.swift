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

    @ObservationIgnored private let microphone = MicrophoneStream()
    @ObservationIgnored private let analysisQueue = DispatchQueue(label: "eveil.wordend.analysis",
                                                                  qos: .userInitiated)
    @ObservationIgnored private var tracker: StreamingTracker?
    @ObservationIgnored private let config: DetectorConfig

    public init(config: DetectorConfig = DetectorConfig()) {
        self.config = config
    }

    /// Autorisation micro (iOS 17 : `AVAudioApplication`). À demander depuis
    /// l'espace parent, après une explication destinée à l'adulte.
    public static func requestMicrophone() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    /// Écoute l'enfant dire `word` ; le verdict final arrive dans `phase`.
    public func listen(for word: TargetWord) {
        guard phase != .listening else { return }
        let tracker = StreamingTracker(target: word, config: config)
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
            try microphone.start { [weak self] chunk in
                let samples = chunk.map(Double.init)
                queue.async {
                    let events = tracker.push(samples)
                    guard !events.isEmpty else { return }
                    Task { @MainActor in self?.apply(events) }
                }
            }
        } catch {
            phase = .failed(String(describing: error))
        }
    }

    /// Arrêt anticipé (l'enfant quitte l'écran…) : le verdict reste « incertain » au besoin.
    public func stop() {
        guard phase == .listening, let tracker else { return }
        microphone.stop()
        analysisQueue.async {
            let events = tracker.stop()
            Task { @MainActor [weak self] in self?.apply(events) }
        }
    }

    public func reset() {
        microphone.stop()
        phase = .idle
        litWagons = 0
        cabooseHeard = false
        childIsSpeaking = false
    }

    private func apply(_ events: [TrackerEvent]) {
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
