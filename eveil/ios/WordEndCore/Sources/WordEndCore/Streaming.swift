// Streaming.swift — suivi en flux : allumer les wagons pendant que l'enfant
// parle. Portage de `eveil/reference/wordend/streaming.py`.
//
// Le verdict FINAL passe par le même chemin que l'analyse par lots
// (`analyzeFrames` + `evaluate`) : flux et lots ne peuvent pas diverger sur la
// décision. L'aperçu (wagon allumé, fourgon accroché) est optimiste et
// monotone ; l'interface se recale sur le verdict final.
//
// Non thread-safe : à utiliser depuis une seule file (cf. `ListeningController`).

import Foundation

public enum EndCause: String, Sendable {
    case silence
    case maxDuration = "max_duration"
    case timeout
    case stopped
}

public enum TrackerEvent: Equatable, Sendable {
    case speechStarted(frame: Int)
    case nucleusHeard(count: Int, frame: Int)
    case codaHeard(frame: Int)
    case ended(verdict: Verdict, frame: Int, cause: EndCause)
}

public struct StreamingConfig: Equatable, Sendable {
    public var minPrerollMs = 100.0      // trames nécessaires avant toute décision
    public var onsetFrames = 3           // 30 ms au-dessus du seuil ⇒ début de parole
    public var vadOffDb = 6.0            // « silence » : RMS < plancher + 6 dB
    public var endSilenceMs = 800.0      // > fusion de régions (450 ms) : laisser l'enfant finir
    public var maxWaitMs = 6000.0        // personne ne parle ⇒ fin (aucune parole)
    public var maxUtteranceMs = 4000.0   // garde-fou
    public var previewEveryFrames = 5    // aperçu toutes les 50 ms
    public init() {}
}

public final class StreamingTracker {
    public enum Phase: Sendable { case waiting, speaking, ended }

    public let target: any TargetShape
    public let config: DetectorConfig
    public let stream: StreamingConfig
    public private(set) var phase: Phase = .waiting
    public private(set) var verdict: Verdict?

    private let extractor: FeatureExtractor
    private var samples: [Double] = []
    private var frames: [FrameFeatures] = []
    private var above = 0
    private var silent = 0
    private var speechStart = 0
    private var nucleiShown = 0
    private var codaShown = false

    public init(target: any TargetShape, config: DetectorConfig = DetectorConfig(),
                stream: StreamingConfig = StreamingConfig()) {
        self.target = target
        self.config = config
        self.stream = stream
        extractor = FeatureExtractor(bands: config.bands)
    }

    /// Ajoute un bloc d'échantillons 24 kHz mono ; renvoie les événements produits.
    public func push(_ chunk: [Double]) -> [TrackerEvent] {
        guard phase != .ended else { return [] }
        samples.append(contentsOf: chunk)
        var events: [TrackerEvent] = []
        while phase != .ended {
            let index = frames.count
            if index * WordEnd.hopSize + WordEnd.frameSize > samples.count { break }
            frames.append(extractor.frame(samples, index: index))
            events.append(contentsOf: onFrame(index))
        }
        return events
    }

    /// Fin forcée (bouton « stop », changement d'écran…).
    public func stop() -> [TrackerEvent] {
        guard phase != .ended else { return [] }
        return [end(frames.count - 1, .stopped)]
    }

    // MARK: interne

    private func noiseFloor() -> Double { percentile(frames.map(\.rmsDb), config.floorPercentile) }

    private func onFrame(_ t: Int) -> [TrackerEvent] {
        if t + 1 < WordEnd.msToFrames(stream.minPrerollMs) { return [] }
        let floorDb = noiseFloor()
        let rms = frames[t].rmsDb
        var events: [TrackerEvent] = []
        if phase == .waiting {
            above = rms >= floorDb + config.vadOnDb ? above + 1 : 0
            if above >= stream.onsetFrames {
                phase = .speaking
                speechStart = t - stream.onsetFrames + 1
                events.append(.speechStarted(frame: speechStart))
            } else if t + 1 >= WordEnd.msToFrames(stream.maxWaitMs) {
                events.append(end(t, .timeout))
            }
            return events
        }
        silent = rms < floorDb + stream.vadOffDb ? silent + 1 : 0
        if (t - speechStart) % stream.previewEveryFrames == 0 {
            events.append(contentsOf: preview())
        }
        if silent >= WordEnd.msToFrames(stream.endSilenceMs) {
            events.append(contentsOf: preview())
            events.append(end(t, .silence))
        } else if t - speechStart + 1 >= WordEnd.msToFrames(stream.maxUtteranceMs) {
            events.append(contentsOf: preview())
            events.append(end(t, .maxDuration))
        }
        return events
    }

    private func preview() -> [TrackerEvent] {
        let an = analyzeFrames(frames, samples: samples, config: config, withF0: false)
        var events: [TrackerEvent] = []
        let dip = config.nucleusMinDipDb
        let confirmed = an.nuclei.filter { n in
            an.envelope[(n.frame + 1)...].contains { $0 <= n.levelDb - dip }
        }
        if confirmed.count > nucleiShown {
            nucleiShown = confirmed.count
            events.append(.nucleusHeard(count: nucleiShown, frame: confirmed[confirmed.count - 1].frame))
        }
        if let lastConfirmed = confirmed.last, !codaShown, target.coda != nil,
           let coda = codaAfter(lastConfirmed, an.frications, config) {
            codaShown = true
            events.append(.codaHeard(frame: coda.start))
        }
        return events
    }

    private func end(_ t: Int, _ cause: EndCause) -> TrackerEvent {
        phase = .ended
        let an = analyzeFrames(frames, samples: samples, config: config, withF0: true)
        let v = evaluate(an, target: target, config: config)
        verdict = v
        return .ended(verdict: v, frame: t, cause: cause)
    }
}
