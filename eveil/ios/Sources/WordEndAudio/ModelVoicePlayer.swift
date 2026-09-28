// ModelVoicePlayer.swift — faire entendre le mot MODÈLE avant d'écouter l'enfant.
//
// Choix produit : des voix humaines enregistrées (FR et EN natifs, validées par
// des orthophonistes), dont une version « lente » qui allonge la fin
// (« dou… chhh »). La synthèse vocale système n'est qu'un repli : elle peut
// adoucir ou avaler la consonne finale — précisément ce qu'on veut montrer.
// Option envisagée : la voix d'un parent, enregistrée sur l'iPad (jamais envoyée).
//
// Retours de l'utilisateur (28/09/2026) : « voix trop générique — voix féminine
// naturelle, qui suit les syllabes ». Donc, en attendant les enregistrements :
//   • la voix est choisie par `VoiceCatalog` (meilleure voix féminine installée,
//     ou celle de l'adulte) ;
//   • la prononciation est IMPOSÉE par l'API du lexique
//     (`AVSpeechSynthesisIPANotationAttribute`) : la consonne finale est dite ;
//   • `speakSegments` dit le mot syllabe par syllabe (un énoncé par wagon) et
//     prévient l'écran au début de chacune : le wagon s'allume avec SA syllabe.

#if canImport(AVFoundation)
import AVFoundation
import WordEndCore

@MainActor
public final class ModelVoicePlayer: NSObject, AVAudioPlayerDelegate, AVSpeechSynthesizerDelegate {
    /// Débit : un mot se dit posément, une syllabe plus lentement (l'enfant suit les wagons).
    public enum Pace: Sendable {
        case word
        case syllable
        case sentence
    }

    /// Voix choisie par l'adulte (`VoiceCatalog.settingKey`) ; nil ou "" : choix automatique.
    public var voiceIdentifier: String?

    private var player: AVAudioPlayer?
    private let synthesizer = AVSpeechSynthesizer()
    private var continuation: CheckedContinuation<Void, Never>?
    /// L'énoncé attendu : la fin (ou l'annulation) d'un AUTRE énoncé ne libère pas l'attente.
    private var pending: ObjectIdentifier?

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
    /// `ipa` impose la prononciation (API du lexique, sans points de syllabe).
    public func speak(_ text: String, locale: String, ipa: String? = nil, pace: Pace = .word) async {
        let utterance = makeUtterance(text, ipa: ipa, locale: locale, pace: pace)
        await say(utterance)
        try? await Task.sleep(nanoseconds: 150_000_000)
    }

    /// Le mot syllabe par syllabe : `onSegment(k)` juste avant que la voix dise le
    /// segment `k` (le wagon `k` s'allume avec sa syllabe). S'arrête net si la tâche
    /// est annulée (l'enfant a quitté l'écran).
    public func speakSegments(_ segments: [VoiceSegment], locale: String,
                              onSegment: (Int) -> Void) async {
        for (k, segment) in segments.enumerated() {
            guard !Task.isCancelled else { return }
            onSegment(k)
            await say(makeUtterance(segment.text, ipa: segment.ipa, locale: locale, pace: .syllable))
        }
        try? await Task.sleep(nanoseconds: 150_000_000)
    }

    /// Coupe la voix (sortie de l'écran) et libère l'attente en cours.
    public func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        player?.stop()
        resume()
    }

    private func say(_ utterance: AVSpeechUtterance) async {
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            store(c)
            pending = ObjectIdentifier(utterance)
            synthesizer.speak(utterance)
        }
    }

    private func makeUtterance(_ text: String, ipa: String?, locale: String, pace: Pace) -> AVSpeechUtterance {
        let utterance: AVSpeechUtterance
        if let ipa, !ipa.isEmpty, !text.isEmpty {
            let attributed = NSMutableAttributedString(string: text)
            attributed.addAttribute(NSAttributedString.Key(AVSpeechSynthesisIPANotationAttribute), value: ipa,
                                    range: NSRange(location: 0, length: attributed.length))
            utterance = AVSpeechUtterance(attributedString: attributed)
        } else {
            utterance = AVSpeechUtterance(string: text)
        }
        utterance.voice = VoiceCatalog.voice(for: locale, preferred: voiceIdentifier)
        switch pace {
        case .word:
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.86
        case .syllable:
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.78
            utterance.postUtteranceDelay = 0.16         // le temps de voir le wagon suivant s'allumer
        case .sentence:
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        }
        return utterance
    }

    /// Une nouvelle lecture libère d'abord l'éventuelle attente précédente (jamais perdue).
    private func store(_ c: CheckedContinuation<Void, Never>) {
        resume()
        continuation = c
    }

    private func resume() {
        pending = nil
        continuation?.resume()
        continuation = nil
    }

    private func finished(_ utterance: ObjectIdentifier) {
        if pending == utterance { resume() }
    }

    nonisolated public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.resume() }
    }

    nonisolated public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in self.resume() }
    }

    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                              didFinish utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.finished(id) }
    }

    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                              didCancel utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.finished(id) }
    }
}
#endif
