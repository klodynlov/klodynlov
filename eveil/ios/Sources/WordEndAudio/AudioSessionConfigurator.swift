// AudioSessionConfigurator.swift — une session audio pensée pour MESURER.
//
// Faits vérifiés dans la documentation Apple (docs/EVEIL-SOURCES.md, § Apple) :
// - `AVAudioSession.Mode.measurement` réduit au minimum le traitement système
//   du signal (et utilise le micro principal) ;
// - le « voice processing » (`setVoiceProcessingEnabled`) ajoute AGC, réduction
//   de bruit et annulation d'écho : il fausserait les mesures haute fréquence,
//   or les sibilantes /ʃ/ /s/ SONT du bruit haute fréquence. On ne l'active pas ;
// - la fréquence préférée n'est pas garantie : on lit la valeur réelle.
//
// Pas de `.allowBluetooth` : un micro Bluetooth mains-libres (HFP) échantillonne
// à 8/16 kHz et couperait les sibilantes d'enfant.

#if canImport(AVFoundation) && os(iOS)
import AVFoundation

public enum AudioSessionConfigurator {
    /// Fréquence minimale acceptable pour les sibilantes (énergie de /s/ au-delà de 8 kHz).
    public static let minimumInputRate = 22_050.0

    public enum SetupError: Error, Equatable {
        case inputRateTooLow(Double)
    }

    /// Configure la session pour l'analyse (lecture du modèle + écoute, jamais simultanées).
    @discardableResult
    public static func configureForMeasurement() throws -> AVAudioSession {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
        try session.setPreferredSampleRate(48_000)
        try session.setPreferredIOBufferDuration(0.010)
        if let builtIn = session.availableInputs?.first(where: { $0.portType == .builtInMic }) {
            try session.setPreferredInput(builtIn)
        }
        try session.setActive(true)
        guard session.sampleRate >= minimumInputRate else {
            throw SetupError.inputRateTooLow(session.sampleRate)
        }
        return session
    }

    public static func deactivate() {
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }
}
#endif
