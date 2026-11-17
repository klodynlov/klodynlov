// MicrophoneStream.swift — micro → blocs 24 kHz mono, en mémoire uniquement.
//
// Le son n'est JAMAIS écrit sur disque ni envoyé : chaque bloc est converti,
// analysé, puis oublié. Pas d'`AVAudioFile(forWriting:)`, pas
// d'`AVAudioRecorder` (le script `eveil/outils/verifier_confidentialite.py`
// le vérifie sur tout le code Swift).
//
// Notes vérifiées dans la doc Apple : la taille de bloc demandée à
// `installTap` n'est pas garantie (« may choose another size ») et le bloc
// est appelé hors du thread principal. `installTap` est déprécié en iOS 27 au
// profit de `installAudioTap(onBus:bufferSize:format:tapProvider:)` : à
// basculer sous `#available(iOS 27, *)` quand le SDK 27 sera la base.

#if canImport(AVFoundation)
import AVFoundation
import WordEndCore

public final class MicrophoneStream {
    public enum StreamError: Error, Equatable {
        case noInput
        case converterUnavailable
    }

    private let engine = AVAudioEngine()
    private var converter: AVAudioConverter?
    private let targetFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                             sampleRate: Double(WordEnd.analysisRate),
                                             channels: 1, interleaved: false)!
    public private(set) var isRunning = false

    public init() {}

    /// Démarre la capture. `onChunk` est appelé HORS du thread principal avec des
    /// blocs 24 kHz mono (Float) ; il doit rester court (copie + envoi sur une file).
    public func start(onChunk: @escaping ([Float]) -> Void) throws {
        guard !isRunning else { return }
        let input = engine.inputNode
        let inFormat = input.outputFormat(forBus: 0)
        guard inFormat.sampleRate > 0, inFormat.channelCount > 0 else { throw StreamError.noInput }
        guard let conv = AVAudioConverter(from: inFormat, to: targetFormat) else {
            throw StreamError.converterUnavailable
        }
        converter = conv
        input.installTap(onBus: 0, bufferSize: 2048, format: inFormat) { [weak self] buffer, _ in
            guard let self, let chunk = self.convert(buffer) else { return }
            onChunk(chunk)
        }
        engine.prepare()
        try engine.start()
        isRunning = true
    }

    public func stop() {
        guard isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        // Pas de `converter.reset()` ici : AVAudioConverter n'est pas thread-safe et le tap
        // peut encore l'utiliser sur le fil audio ; `start()` en recrée un de toute façon.
        isRunning = false
    }

    /// Conversion en flux (l'état du convertisseur est conservé entre les blocs).
    private func convert(_ buffer: AVAudioPCMBuffer) -> [Float]? {
        guard let converter else { return nil }
        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 64
        guard let out = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else { return nil }
        var delivered = false
        var error: NSError?
        let status = converter.convert(to: out, error: &error) { _, inputStatus in
            if delivered {
                inputStatus.pointee = .noDataNow
                return nil
            }
            delivered = true
            inputStatus.pointee = .haveData
            return buffer
        }
        guard status != .error, error == nil, let channel = out.floatChannelData?[0] else { return nil }
        return Array(UnsafeBufferPointer(start: channel, count: Int(out.frameLength)))
    }
}
#endif
