// VoiceCatalog.swift — choisir la voix du mot modèle : féminine, naturelle, sur l'iPad.
//
// Retour de l'utilisateur (28/09/2026) : « la voix est trop générique — voix féminine
// naturelle ». La synthèse vocale de l'iPad existe en trois qualités : standard
// (compacte, livrée avec le système), améliorée et premium. Les deux dernières se
// téléchargent dans Réglages › Accessibilité › Contenu énoncé › Voix : c'est l'ADULTE
// qui le fait, l'app ne télécharge rien. On prend la meilleure voix installée pour la
// langue du jeu, dans cet ordre :
//   1. l'accent de la langue du jeu (fr-FR avant fr-CA, en-US avant en-GB) ;
//   2. une voix « naturelle » : ni voix fantaisie (bulles, cloches…), ni voix
//      « Eloquence » (Flo, Grandma…, volontairement robotiques) ;
//   3. une voix féminine ;
//   4. la meilleure qualité (premium, puis améliorée, puis standard).
// L'adulte peut en choisir une autre dans l'espace des grands, y compris sa propre
// « Voix personnelle » (iOS 17), qui reste elle aussi sur l'appareil.
//
// Provisoire : la cible reste des voix humaines enregistrées et validées
// (docs/EVEIL.md § 10) ; la synthèse n'est qu'un repli, mais un repli choisi.

#if canImport(AVFoundation)
import AVFoundation

/// Une voix installée, décrite pour l'espace des grands.
public struct VoiceOption: Identifiable, Equatable, Sendable {
    public enum Quality: Int, Comparable, Sendable {
        case standard = 1, enhanced = 2, premium = 3

        public static func < (a: Quality, b: Quality) -> Bool { a.rawValue < b.rawValue }

        public func label(locale: String) -> String {
            let fr = locale.hasPrefix("fr")
            switch self {
            case .standard: return fr ? "standard" : "standard"
            case .enhanced: return fr ? "améliorée" : "enhanced"
            case .premium: return "premium"
            }
        }
    }

    /// Identifiant système de la voix (`AVSpeechSynthesisVoice.identifier`).
    public let id: String
    public let name: String
    /// Langue et accent (« fr-FR », « fr-CA »…).
    public let language: String
    public let quality: Quality
    public let isFemale: Bool
    /// « Voix personnelle » créée par l'adulte sur cet appareil.
    public let isPersonal: Bool
    /// Voix fantaisie ou « Eloquence » : jamais choisie automatiquement.
    public let isNovelty: Bool

    public init(id: String, name: String, language: String, quality: Quality, isFemale: Bool,
                isPersonal: Bool = false, isNovelty: Bool = false) {
        self.id = id
        self.name = name
        self.language = language
        self.quality = quality
        self.isFemale = isFemale
        self.isPersonal = isPersonal
        self.isNovelty = isNovelty
    }
}

public enum VoiceCatalog {
    /// Clé du réglage : identifiant de la voix choisie par l'adulte ("" = automatique).
    public static let settingKey = "eveil.voice"

    /// Les voix installées pour la langue du jeu, la meilleure d'abord.
    public static func voices(for locale: String) -> [VoiceOption] {
        let language = locale.split(separator: "-").first.map(String.init) ?? locale
        let options = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix(language) }
            .map(option)
        return ranked(options, locale: locale)
    }

    /// Tri du catalogue (fonction pure : testée sans iPad).
    public static func ranked(_ options: [VoiceOption], locale: String) -> [VoiceOption] {
        options.sorted { a, b in
            let ka = key(a, locale: locale), kb = key(b, locale: locale)
            if ka != kb { return ka.lexicographicallyPrecedes(kb) }
            return a.name.localizedStandardCompare(b.name) == .orderedAscending
        }
    }

    /// La meilleure voix à choisir SANS l'adulte : jamais une voix personnelle ni fantaisie.
    public static func automaticChoice(_ options: [VoiceOption], locale: String) -> VoiceOption? {
        ranked(options, locale: locale).first { !$0.isPersonal && !$0.isNovelty }
    }

    /// La voix du jeu : celle choisie par l'adulte si elle est encore installée et parle
    /// la bonne langue, sinon le choix automatique, sinon la voix système de la langue.
    public static func voice(for locale: String, preferred: String?) -> AVSpeechSynthesisVoice? {
        let language = locale.split(separator: "-").first.map(String.init) ?? locale
        if let preferred, !preferred.isEmpty,
           let chosen = AVSpeechSynthesisVoice(identifier: preferred), chosen.language.hasPrefix(language) {
            return chosen
        }
        if let best = automaticChoice(voices(for: locale), locale: locale),
           let voice = AVSpeechSynthesisVoice(identifier: best.id) {
            return voice
        }
        return AVSpeechSynthesisVoice(language: locale)
    }

    // MARK: Voix personnelle (iOS 17)

    /// Vrai si l'adulte n'a encore ni accepté ni refusé l'accès à sa Voix personnelle.
    public static var canAskForPersonalVoice: Bool {
        AVSpeechSynthesizer.personalVoiceAuthorizationStatus == .notDetermined
    }

    /// Demande l'accès à la Voix personnelle (la voix reste sur l'appareil).
    public static func requestPersonalVoice() async -> Bool {
        await withCheckedContinuation { (c: CheckedContinuation<Bool, Never>) in
            AVSpeechSynthesizer.requestPersonalVoiceAuthorization { status in
                c.resume(returning: status == .authorized)
            }
        }
    }

    // MARK: Détails

    /// Clé de tri, plus petite = meilleure : accent, naturel, féminine, qualité.
    private static func key(_ v: VoiceOption, locale: String) -> [Int] {
        [v.language == locale ? 0 : 1,
         v.isNovelty ? 1 : 0,
         v.isPersonal ? 1 : 0,
         v.isFemale ? 0 : 1,
         3 - v.quality.rawValue]
    }

    private static func option(_ voice: AVSpeechSynthesisVoice) -> VoiceOption {
        let quality: VoiceOption.Quality
        switch voice.quality {
        case .premium: quality = .premium
        case .enhanced: quality = .enhanced
        default: quality = .standard
        }
        let traits = voice.voiceTraits
        let eloquence = voice.identifier.lowercased().contains("eloquence")
        return VoiceOption(id: voice.identifier, name: voice.name, language: voice.language, quality: quality,
                           isFemale: voice.gender == .female,
                           isPersonal: traits.contains(.isPersonalVoice),
                           isNovelty: traits.contains(.isNoveltyVoice) || eloquence)
    }
}
#endif
