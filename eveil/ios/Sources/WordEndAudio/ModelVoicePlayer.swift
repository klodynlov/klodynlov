// ModelVoicePlayer.swift — faire entendre le mot MODÈLE avant d'écouter l'enfant.
//
// 17/11/2026 (décision de l'utilisateur) : la voix du jeu est préparée à l'avance avec Supertonic 3,
// style F5 (`VoiceClips`, fichiers livrés avec l'app, rien sur le réseau) ; ce qui n'a pas de fichier
// (sons seuls, mots de la famille) garde la synthèse système ci-dessous. L'adulte peut revenir à la voix
// de l'iPad (espace des grands). Depuis le 17/11/2026 (demande de l'utilisateur), les autres activités ont
// aussi la voix préparée (consignes du coloriage, jeux d'écoute, train des phrases, livres) ; la phrase
// libre du train des phrases se compose de ses wagons (`speak(parts:)`, `ClipJoiner`).
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

        /// Le débit dans la clé des fichiers de voix préparée (`VoiceClips.key`).
        public var key: String {
            switch self {
            case .word: return "word"
            case .syllable: return "syllable"
            case .sentence: return "sentence"
            }
        }
    }

    /// Voix choisie par l'adulte (`VoiceCatalog.settingKey`) ; nil ou "" : choix automatique.
    public var voiceIdentifier: String?
    /// Une seule voix par mot : faux si un morceau du mot en cours n'a pas de fichier préparé
    /// (`VoiceClips.covers`) — tout le mot passe alors par la voix de l'iPad.
    public var clipsAllowed = true

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

    /// La voix préparée (Supertonic 3, F5) si l'énoncé a son fichier et que l'adulte la garde ; sinon la
    /// synthèse vocale système (voir la réserve en tête de fichier), dont `ipa` impose la prononciation
    /// (API du lexique, sans points de syllabe).
    public func speak(_ text: String, locale: String, ipa: String? = nil, pace: Pace = .word) async {
        if VoiceClips.enabled, clipsAllowed,
           let url = VoiceClips.url(locale: locale, pace: pace.key, text: text, ipa: ipa) {
            await playClip(url)
            if pace == .syllable { try? await Task.sleep(nanoseconds: 160_000_000) }   // comme `postUtteranceDelay`
        } else {
            await say(makeUtterance(text, ipa: ipa, locale: locale, pace: pace))
        }
        try? await Task.sleep(nanoseconds: 150_000_000)
    }

    /// Ce que `speak(parts:)` va faire entendre.
    public enum PartsPlan: Equatable, Sendable {
        /// La phrase entière a son fichier (une phrase d'un livre, une consigne).
        case clip(URL)
        /// Chaque morceau a son fichier : on les enchaîne (`ClipJoiner`).
        case joined([URL])
        /// Il manque un fichier (ou l'adulte a choisi la voix de l'iPad) : toute la phrase par la voix de l'iPad.
        case system(String)
    }

    /// Une seule voix par phrase : la phrase entière préparée, sinon tous ses morceaux préparés, sinon tout
    /// par la voix de l'iPad — jamais deux voix dans la même phrase.
    nonisolated public static func plan(parts: [String], locale: String, whole: String? = nil,
                                        prepared: Bool = VoiceClips.enabled) -> PartsPlan {
        let text = whole ?? parts.joined(separator: " ")
        guard prepared, !parts.isEmpty else { return .system(text) }
        let pace = Pace.sentence.key
        if let url = VoiceClips.url(locale: locale, pace: pace, text: text, ipa: nil) { return .clip(url) }
        let urls = parts.compactMap { VoiceClips.url(locale: locale, pace: pace, text: $0, ipa: nil) }
        return urls.count == parts.count ? .joined(urls) : .system(text)
    }

    /// Plusieurs morceaux dits comme une seule phrase (débit « phrase ») : la phrase libre du train des
    /// phrases (ses wagons), « Je t'aide à colorier ! » + la consigne. `whole` : la phrase telle qu'on
    /// l'écrit (« Le chat mange la pêche. »), qu'on cherche d'abord entière et que dit la voix de l'iPad.
    public func speak(parts: [String], locale: String, whole: String? = nil) async {
        switch Self.plan(parts: parts, locale: locale, whole: whole, prepared: VoiceClips.enabled && clipsAllowed) {
        case let .clip(url):
            await playClip(url)
        case let .joined(urls):
            if let data = Self.joinedWAV(urls) {
                await playClip(data: data)
            } else {
                await say(makeUtterance(whole ?? parts.joined(separator: " "), ipa: nil, locale: locale, pace: .sentence))
            }
        case let .system(text):
            await say(makeUtterance(text, ipa: nil, locale: locale, pace: .sentence))
        }
        try? await Task.sleep(nanoseconds: 150_000_000)
    }

    /// Les fichiers décodés, enchaînés par `ClipJoiner`, en WAV en mémoire ; nil si l'un ne se lit pas.
    private static func joinedWAV(_ urls: [URL]) -> Data? {
        var clips: [[Float]] = []
        var rate = 0.0
        for url in urls {
            guard let file = try? AVAudioFile(forReading: url),
                  let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                                frameCapacity: AVAudioFrameCount(file.length)),
                  (try? file.read(into: buffer)) != nil,
                  let channel = buffer.floatChannelData?[0] else { return nil }
            if rate == 0 { rate = file.processingFormat.sampleRate }
            guard file.processingFormat.sampleRate == rate else { return nil }
            clips.append(Array(UnsafeBufferPointer(start: channel, count: Int(buffer.frameLength))))
        }
        guard rate > 0 else { return nil }
        return ClipJoiner.wav(ClipJoiner.join(clips, rate: rate), rate: Int(rate))
    }

    /// Joue un fichier de voix préparée et attend la fin (sans marge : `speak` l'ajoute).
    private func playClip(_ url: URL) async {
        guard let p = try? AVAudioPlayer(contentsOf: url) else { return }
        await play(p)
    }

    /// Joue une phrase composée (WAV en mémoire) et attend la fin.
    private func playClip(data: Data) async {
        guard let p = try? AVAudioPlayer(data: data) else { return }
        await play(p)
    }

    private func play(_ p: AVAudioPlayer) async {
        p.delegate = self
        player = p
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            store(c)
            if !p.play() { resume() }
        }
    }

    /// Le mot syllabe par syllabe : `onSegment(k)` juste avant que la voix dise le
    /// segment `k` (le wagon `k` s'allume avec sa syllabe). S'arrête net si la tâche
    /// est annulée (l'enfant a quitté l'écran).
    public func speakSegments(_ segments: [VoiceSegment], locale: String,
                              onSegment: (Int) -> Void) async {
        for (k, segment) in segments.enumerated() {
            guard !Task.isCancelled else { return }
            onSegment(k)
            if VoiceClips.enabled, clipsAllowed,
               let url = VoiceClips.url(locale: locale, pace: Pace.syllable.key, text: segment.text, ipa: segment.ipa) {
                await playClip(url)
                try? await Task.sleep(nanoseconds: 160_000_000)
            } else {
                await say(makeUtterance(segment.text, ipa: segment.ipa, locale: locale, pace: .syllable))
            }
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
