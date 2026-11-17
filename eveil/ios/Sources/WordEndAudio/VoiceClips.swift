// VoiceClips.swift — la voix du jeu préparée à l'avance (Supertonic 3, style F5).
//
// Décision de l'utilisateur (17/11/2026) : essai de Supertonic 3, choix du style F5 (mesures et écoute à
// l'aveugle), intégration « préparée à l'avance ». `eveil/outils/voix/generer.py` rend sur le Mac tout ce
// que le petit train et les livres des sons font dire (mots, syllabes, « Encore ! »), le vérifie avec le
// détecteur de fin de mot, et écrit ici des fichiers audio et `manifest.json` (clé → fichier). Pas de
// modèle dans l'app, rien sur le réseau. Voix de synthèse (Supertonic 3, Supertone, poids OpenRAIL-M) :
// l'espace des grands le dit (restriction d'usage « contenu généré par machine »).
//
// La clé est celle du générateur : « langue|débit|texte|API » (NFC, API sans points de syllabe).

import Foundation
import WordEndCore

public enum VoiceClips {
    /// Réglage de l'adulte : la voix préparée (par défaut) ou la voix de l'iPad.
    public static let settingKey = "eveil.voice.prepared"

    public static var enabled: Bool {
        UserDefaults.standard.object(forKey: settingKey) as? Bool ?? true
    }

    public static func key(locale: String, pace: String, text: String, ipa: String?) -> String {
        "\(locale)|\(pace)|\(text)|\(ipa ?? "")".precomposedStringWithCanonicalMapping
    }

    private struct Manifest: Decodable {
        let voix: String
        let clips: [String: String]
    }

    private static let manifest: Manifest? = {
        guard let url = Bundle.module.url(forResource: "manifest", withExtension: "json", subdirectory: "voix"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Manifest.self, from: data)
    }()

    /// Le nom de la voix préparée (« Supertonic 3, style F5 »), nil si aucune n'est livrée.
    public static var voiceName: String? { manifest?.voix }

    /// Combien d'énoncés ont leur fichier.
    public static var count: Int { manifest?.clips.count ?? 0 }

    /// Le fichier d'un énoncé, s'il existe.
    public static func url(locale: String, pace: String, text: String, ipa: String?) -> URL? {
        guard let file = manifest?.clips[key(locale: locale, pace: pace, text: text, ipa: ipa)] else { return nil }
        let name = (file as NSString).deletingPathExtension
        return Bundle.module.url(forResource: name, withExtension: "m4a", subdirectory: "voix")
    }

    /// Tout ce que le jeu dit d'un mot a son fichier : le mot entier, ses syllabes (modèle et wagons).
    /// Sinon une seule voix pour tout le mot : celle de l'iPad (jamais deux voix dans le même mot).
    public static func covers(_ word: TargetWord, locale: String) -> Bool {
        guard let ipa = word.ipa, !ipa.isEmpty else { return false }
        let whole = ipa.replacingOccurrences(of: ".", with: "")
        guard url(locale: locale, pace: "word", text: word.text, ipa: whole) != nil else { return false }
        return (word.voiceSegments + word.wagonSegments).allSatisfy {
            url(locale: locale, pace: "syllable", text: $0.text, ipa: $0.ipa) != nil
        }
    }
}
