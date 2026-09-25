// ModelVoicePlayer.swift — faire entendre le mot MODÈLE avant d'écouter l'enfant.
//
// Choix produit : des voix humaines enregistrées (FR et EN natifs, validées par
// des orthophonistes), dont une version « lente » qui allonge la fin
// (« dou… chhh »). La synthèse vocale système n'est qu'un repli : elle peut
// adoucir ou avaler la consonne finale — précisément ce qu'on veut montrer.
// Option envisagée : la voix d'un parent, enregistrée sur l'iPad (jamais envoyée).

#if canImport(AVFoundation)
import AVFoundation

@MainActor
public final class ModelVoicePlayer: NSObject, AVAudioPlayerDelegate, AVSpeechSynthesizerDelegate {
    private var player: AVAudioPlayer?
    private let synthesizer = AVSpeechSynthesizer()
    private var continuation: CheckedContinuation<Void, Never>?

    public override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Joue un enregistrement du paquet de l'app et attend la fin.
    public func play(recording url: URL) async {
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.delegate = self
            player = p
            await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
                store(c)
                if !p.play() { resume() }
            }
        } catch {
            return
        }
        try? await Task.sleep(nanoseconds: 150_000_000)   // marge avant d'ouvrir le micro
    }

    /// Repli : synthèse vocale système (voir la réserve en tête de fichier).
    public func speak(_ text: String, locale: String) async {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: locale)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.8
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            store(c)
            synthesizer.speak(utterance)
        }
        try? await Task.sleep(nanoseconds: 150_000_000)
    }

    /// Une nouvelle lecture libère d'abord l'éventuelle attente précédente (jamais perdue).
    private func store(_ c: CheckedContinuation<Void, Never>) {
        resume()
        continuation = c
    }

    private func resume() {
        continuation?.resume()
        continuation = nil
    }

    nonisolated public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.resume() }
    }

    nonisolated public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in self.resume() }
    }

    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                              didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.resume() }
    }

    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                              didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.resume() }
    }
}
#endif
