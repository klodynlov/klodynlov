// OnDeviceLexicalCheck.swift — garde-fou lexical OPTIONNEL (désactivé par défaut).
//
// Rôle unique : éviter de juger la fin d'un AUTRE mot (« bain » dit à la place
// de « douche »). La reconnaissance vocale ne décide JAMAIS de la fin du mot :
// `applyLexical` ne peut que rendre un verdict plus prudent (testé).
//
// Faits vérifiés dans la doc Apple :
// - `requiresOnDeviceRecognition = true` garde l'audio sur l'appareil, SI
//   `supportsOnDeviceRecognition` est vrai — sinon on n'utilise pas l'ASR du tout ;
// - l'autorisation `SFSpeechRecognizer.requestAuthorization` et la clé
//   `NSSpeechRecognitionUsageDescription` restent requises, même en local ;
// - la reconnaissance locale est documentée comme moins précise ;
// - iOS 26 : `SpeechAnalyzer` + `SpeechTranscriber`/`DictationTranscriber`
//   (sans autorisation « reconnaissance vocale », micro seulement) mais modèles
//   à TÉLÉCHARGER par le système au premier usage : chemin futur, derrière
//   `#available(iOS 26, *)` et un écran parent de préparation.

#if canImport(Speech) && canImport(AVFoundation)
import AVFoundation
import Speech
import WordEndCore

public final class OnDeviceLexicalCheck {
    private let recognizer: SFSpeechRecognizer
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var transcript = ""

    /// nil si la locale n'a pas de reconnaissance LOCALE : on ne se rabat jamais sur le serveur.
    public init?(locale: String) {
        guard let r = SFSpeechRecognizer(locale: Locale(identifier: locale)),
              r.supportsOnDeviceRecognition else { return nil }
        recognizer = r
    }

    public static func requestAuthorization() async -> Bool {
        await withCheckedContinuation { c in
            SFSpeechRecognizer.requestAuthorization { c.resume(returning: $0 == .authorized) }
        }
    }

    /// Commence une écoute parallèle pour `word`. Les formes acceptées (mot, forme
    /// tronquée, contraste) sont fournies en `contextualStrings` : la transcription
    /// ne sert qu'à savoir si l'enfant a tenté CE mot.
    public func begin(for word: TargetWord) {
        let req = SFSpeechAudioBufferRecognitionRequest()
        req.requiresOnDeviceRecognition = true          // jamais de serveur
        req.shouldReportPartialResults = false
        req.taskHint = .confirmation
        req.contextualStrings = Array(acceptedForms(word))
        request = req
        transcript = ""
        task = recognizer.recognitionTask(with: req) { [weak self] result, _ in
            if let result { self?.transcript = result.bestTranscription.formattedString }
        }
    }

    /// Alimente la requête avec les mêmes tampons que le détecteur.
    public func append(_ buffer: AVAudioPCMBuffer) {
        request?.append(buffer)
    }

    /// Termine et renvoie le degré de cohérence lexicale.
    public func finish(for word: TargetWord) async -> LexicalEvidence {
        request?.endAudio()
        try? await Task.sleep(nanoseconds: 300_000_000)   // laisser le résultat final arriver
        task?.cancel()
        task = nil
        request = nil
        return lexicalEvidence(transcript: transcript, word: word)
    }
}
#endif
